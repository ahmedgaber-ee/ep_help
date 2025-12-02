local mathFloor = math.floor

local silentExport

do
    local validStates = { ["running"] = true, ["starting"] = true, ["stopping"] = true }

    silentExport = function(resourceName, functionName, ...)
        local resource = getResourceFromName(resourceName)
        
        if resource and validStates[getResourceState(resource)] then
            return call(resource, functionName, ...)
        end
    end
end

local deathmatch = event1.managers.deathmatch

local cw

cw = {
    settings = {
        resultsFilePath = "client/arena/modes/cw_results.txt",
        resultsJSONFilePath = "client/arena/modes/cw_results.json"
    },

    start = function(teamsCount)
        if not cw.data then
            local data = {}

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local coreElement = getElementData(arenaElement, "coreElement", false)

            local refereeClanTeamElement = getElementData(coreElement, "refereeClanTeamElement", false)
            local spectatorsClanTeamElement = getElementData(coreElement, "spectatorsClanTeamElement", false)

            local eventHandlers = cw.eventHandlers

            addEventHandler("event1:deathmatch:onClientWasted", localPlayer, eventHandlers.onClientArenaDeathmatchWasted)
            addEventHandler("event1:deathmatch:onVehicleWeaponsUpdate", localPlayer, eventHandlers.onClientArenaDeathmatchVehicleWeaponsUpdate)
            addEventHandler("event1:deathmatch:onClientSpectatorCameraTargetChanged", localPlayer, eventHandlers.onClientArenaDeathmatchSpectatorCameraTargetChanged)

            addEventHandler("lobby:ui:onStateSet", localPlayer, eventHandlers.onClientLobbyUIStateSet)

            addEventHandler("event1:cw:onClientArenaCountdownStarted", arenaElement, eventHandlers.onArenaCWCountdownStarted)
            addEventHandler("event1:cw:onClientArenaCountdownValueUpdate", arenaElement, eventHandlers.onArenaCWCountdownValueUpdate)
            addEventHandler("event1:cw:onClientArenaResultsSaved", arenaElement, eventHandlers.onArenaCWResultsSaved)

            addEventHandler("event1:deathmatch:onClientArenaStateSet", arenaElement, eventHandlers.onArenaDeathmatchStateSet)
            addEventHandler("event1:deathmatch:onClientPlayerReachedHunter", arenaElement, eventHandlers.onArenaDeathmatchPlayerReachedHunter)

            --addEventHandler("onClientElementDestroy", root, eventHandlers.onElementDestroy)
            addEventHandler("onClientExplosion", arenaElement, eventHandlers.onArenaExplosion)
            addEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)

            addEventHandler("onClientProjectileCreation", root, eventHandlers.onProjectileCreation)

            local commandHandlers = cw.commandHandlers

            addCommandHandler("w", commandHandlers.w)
            addCommandHandler("st", commandHandlers.st)
            addCommandHandler("setlines", commandHandlers.setLines)

            data.coreElement = coreElement

            data.refereeClanTeamElement = refereeClanTeamElement
            data.spectatorsClanTeamElement = spectatorsClanTeamElement

            data.teamsCount = teamsCount

            cw.data = data

            cw.getEventClansTeamElements()
            cw.startUI()
            cw.updateVehicleWeapons()
            cw.loadHunterModel()
        end
    end,

    stop = function()
        local data = cw.data

        if data then
            cw.stopHunterSpray()
            cw.killHideUICountdownTimer()
            cw.unloadHunterModel()
            cw.stopUI()

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = cw.eventHandlers

            removeEventHandler("event1:deathmatch:onClientWasted", localPlayer, eventHandlers.onClientArenaDeathmatchWasted)
            removeEventHandler("event1:deathmatch:onVehicleWeaponsUpdate", localPlayer, eventHandlers.onClientArenaDeathmatchVehicleWeaponsUpdate)
            removeEventHandler("event1:deathmatch:onClientSpectatorCameraTargetChanged", localPlayer, eventHandlers.onClientArenaDeathmatchSpectatorCameraTargetChanged)

            removeEventHandler("lobby:ui:onStateSet", localPlayer, eventHandlers.onClientLobbyUIStateSet)

            removeEventHandler("event1:cw:onClientArenaCountdownStarted", arenaElement, eventHandlers.onArenaCWCountdownStarted)
            removeEventHandler("event1:cw:onClientArenaCountdownValueUpdate", arenaElement, eventHandlers.onArenaCWCountdownValueUpdate)
            removeEventHandler("event1:cw:onClientArenaResultsSaved", arenaElement, eventHandlers.onArenaCWResultsSaved)

            removeEventHandler("event1:deathmatch:onClientArenaStateSet", arenaElement, eventHandlers.onArenaDeathmatchStateSet)
            removeEventHandler("event1:deathmatch:onClientPlayerReachedHunter", arenaElement, eventHandlers.onArenaDeathmatchPlayerReachedHunter)

            --removeEventHandler("onClientElementDestroy", root, eventHandlers.onElementDestroy)
            removeEventHandler("onClientExplosion", arenaElement, eventHandlers.onArenaExplosion)
            removeEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)
            
            removeEventHandler("onClientProjectileCreation", root, eventHandlers.onProjectileCreation)

            local commandHandlers = cw.commandHandlers

            removeCommandHandler("w", commandHandlers.w)
            removeCommandHandler("st", commandHandlers.st)
            removeCommandHandler("setlines", commandHandlers.setLines)

            local killerTimer = data.killerTimer

            if isTimer(killerTimer) then
                killTimer(killerTimer)
            end

            silentExport("ep_raceui", "setCountdownState", false)
            silentExport("ep_raceui", "setCountdownValue", -1)

            silentExport("ep_raceui", "setProjectileLabelState", false)

            silentExport("ep_raceui", "setSpectateState", false)

            toggleControl("vehicle_fire", true)
            toggleControl("vehicle_secondary_fire", true)

            deathmatch.updateVehicleWeapons()

            cw.data = nil
        end
    end,

    getEventClansTeamElements = function()
        local data = cw.data

        local teamsCount = data.teamsCount

        local coreElement = data.coreElement

        local eventClansTeamElements = {}

        for i = 1, teamsCount do
            eventClansTeamElements[i] = getElementData(coreElement, "eventTeam" .. tostring(i), false)
        end

        data.eventClansTeamElements = eventClansTeamElements
    end,

    addEventClansDataToUI = function()
        local data = cw.data

        local eventClansTeamElements = data.eventClansTeamElements

        local cwUIItemlistElement = cw.ui.itemlistElement

        local cwUIItemlistElementCustomAddPlayer = cwUIItemlistElement.custom.addPlayer
        local cwUIItemlistElementCustomAddTeam = cwUIItemlistElement.custom.addTeam

        for i = 1, #eventClansTeamElements do
            local teamElement = eventClansTeamElements[i]

            cwUIItemlistElementCustomAddTeam(cwUIItemlistElement, teamElement)

            local teamElementPlayers = getPlayersInTeam(teamElement)

            for i = 1, #teamElementPlayers do
                local player = teamElementPlayers[i]

                cwUIItemlistElementCustomAddPlayer(cwUIItemlistElement, player)
            end
        end
    end,

    startUI = function()
        local cwUI = cw.ui

        cwUI.create()

        local data = cw.data

        local cwUIItemlistElement = cwUI.itemlistElement

        local cwUIItemlistElementCustom = cwUIItemlistElement.custom

        cwUIItemlistElementCustom.eventClansTeamElements = data.eventClansTeamElements

        cw.addEventClansDataToUI()

        cwUIItemlistElement:setAnimationState(true)
    end,

    stopUI = function()
        local cwUI = cw.ui

        local cwUIItemlistElement = cwUI.itemlistElement

        cwUIItemlistElement:setAnimationState(false)
        cwUIItemlistElement:setAnimationProgress(0)

        cwUI.destroy()
    end,

    isEventTeamElement = function(teamElement)
        local data = cw.data

        local eventClansTeamElements = data.eventClansTeamElements

        for i = 1, #eventClansTeamElements do
            if eventClansTeamElements[i] == teamElement then
                return true
            end
        end
    end,

    updateVehicleWeapons = function()
        local vehicle = getPedOccupiedVehicle(localPlayer)

        if isElement(vehicle) then
            local model = getElementModel(vehicle)

            local controlsState = not cw.armedVehicleIDs[model]

            toggleControl("vehicle_fire", controlsState)
            toggleControl("vehicle_secondary_fire", controlsState)
        end
    end,

    loadHunterModel = function()
        local txd = engineLoadTXD("client/models/hunter.txd")

        engineImportTXD(txd, 425)

        local dff = engineLoadDFF("client/models/hunter.dff")

        engineReplaceModel(dff, 425)

        local data = cw.data

        data.hunterModel = { txd, dff }
    end,

    unloadHunterModel = function()
        local data = cw.data

        local hunterModel = data.hunterModel

        for i = 1, #hunterModel do
            local modelElement = hunterModel[i]

            if isElement(modelElement) then
                destroyElement(modelElement)
            end
        end

        data.hunterModel = nil
    end,

    startHunterSpray = function()
        local data = cw.data

        data.hunterProjectileCount = 0

        silentExport("ep_raceui", "setProjectileLabelState", true)
                            
        local timers = cw.timers

        data.hunterIntervalTimer = setTimer(timers.checkHunterInterval, 1000, 5)
    end,

    stopHunterSpray = function()
        local data = cw.data

        local hunterIntervalTimer = data.hunterIntervalTimer

        if isTimer(hunterIntervalTimer) then
            killTimer(hunterIntervalTimer)
        end

        data.hunterIntervalTimer = nil

        data.hunterProjectileCount = nil

        silentExport("ep_raceui", "setProjectileLabelState", false)

        cw.killHunterProjectilesCheckTimer()
    end,

    startHunterProjectilesCheckTimer = function()
        local data = cw.data

        local timers = cw.timers

        data.hunterProjectileTimer = setTimer(timers.checkHunterProjectiles, 2000, 1)
    end,

    killHunterProjectilesCheckTimer = function()
        local data = cw.data

        local hunterProjectileTimer = data.hunterProjectileTimer

        if isTimer(hunterProjectileTimer) then
            killTimer(hunterProjectileTimer)
        end

        data.hunterProjectileTimer = nil
    end,

    killHideUICountdownTimer = function(stateData)
        local data = cw.data

        local hideUICountdownTimer = data.hideUICountdownTimer

        if isTimer(hideUICountdownTimer) then
            killTimer(hideUICountdownTimer)
        end

        data.hideUICountdownTimer = nil
    end,

    eventHandlers = {
        onClientArenaCreated = function()
            local eventHandlers = cw.eventHandlers

            addEventHandler("event1:cw:onClientEventModeStart", localPlayer, eventHandlers.onClientArenaEventModeStart)
            addEventHandler("event1:cw:onClientEventModeStop", localPlayer, eventHandlers.onClientArenaEventModeStop)

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            addEventHandler("event1:cw:onClientEventModeCreatedInternal", arenaElement, eventHandlers.onArenaEventModeCreated)
            addEventHandler("event1:cw:onClientEventModeDestroyInternal", arenaElement, eventHandlers.onArenaEventModeDestroy)
        end,

        onClientArenaDestroy = function()
            local eventHandlers = cw.eventHandlers

            removeEventHandler("event1:cw:onClientEventModeStart", localPlayer, eventHandlers.onClientArenaEventModeStart)
            removeEventHandler("event1:cw:onClientEventModeStop", localPlayer, eventHandlers.onClientArenaEventModeStop)

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            removeEventHandler("event1:cw:onClientEventModeCreatedInternal", arenaElement, eventHandlers.onArenaEventModeCreated)
            removeEventHandler("event1:cw:onClientEventModeDestroyInternal", arenaElement, eventHandlers.onArenaEventModeDestroy)

            cw.stop()
        end,

        ---

        onClientArenaEventModeStart = function(teamsCount)
            cw.start(teamsCount)
        end,

        onClientArenaEventModeStop = function()
            cw.stop()
        end,

        onArenaEventModeCreated = function(teamsCount)
            cw.start(teamsCount)
        end,

        onArenaEventModeDestroy = function()
            cw.stop()
        end,

        ---

        onClientArenaDeathmatchWasted = function()
            local data = cw.data

            local killer = data.killer

            if killer then
                local killerTimer = data.killerTimer
                local killerPing = data.killerPing

                if isTimer(killerTimer) then
                    killTimer(killerTimer)
                end

                data.killerTimer = nil

                data.killer = nil
                data.killerPing = nil

                triggerServerEvent("event1:cw:onPlayerWasted", localPlayer, killer, killerPing)
            else
                triggerServerEvent("event1:cw:onPlayerWasted", localPlayer)
            end
        end,

        onClientArenaDeathmatchVehicleWeaponsUpdate = function()
            local data = cw.data

            if not data.countdownStarted then
                cw.updateVehicleWeapons()
            end
        end,

        onClientArenaDeathmatchSpectatorCameraTargetChanged = function(oldTarget, newTarget)
            local spectateState = false

            if isElement(newTarget) then
                if newTarget ~= localPlayer then
                    spectateState = true
                end
            end

            silentExport("ep_raceui", "setSpectateState", spectateState)

            local data = cw.data

            data.spectateState = spectateState
        end,

        onClientLobbyUIStateSet = function(state)
            local cwUIState = not state

            cw.ui.itemlistElement:setAnimationState(cwUIState)

            if cwUIState then
                local data = cw.data

                if data.spectateState then
                    silentExport("ep_raceui", "setSpectateState", true)
                end
            else
                silentExport("ep_raceui", "setSpectateState", false)
            end
        end,

        onArenaCWCountdownStarted = function()
            --deathmatch.updateCountdownState()
        end,

        onArenaCWCountdownValueUpdate = function(countdownValue)
            local data = cw.data

            silentExport("ep_raceui", "setCountdownValue", countdownValue)
            silentExport("ep_raceui", "setCountdownState", true)

            data.hideUICountdownTimer = setTimer(cw.timers.hideUICountdown, 500, 1)

            deathmatch.updateCountdownState()

            if countdownValue == 0 then
                data.countdownStarted = true

                toggleControl("vehicle_fire", true)
                toggleControl("vehicle_secondary_fire", true)
                
                deathmatch.updateVehicleWeapons()
            end
        end,

        onArenaCWResultsSaved = function(resultsString, resultsJSONString)
            local resultsFilePath = cw.settings.resultsFilePath
            local resultsJSONFilePath = cw.settings.resultsJSONFilePath

            if fileExists(resultsFilePath) then
                fileDelete(resultsFilePath)
            end

            if fileExists(resultsJSONFilePath) then
                fileDelete(resultsJSONFilePath)
            end
    
            local fileHandler = fileCreate(resultsFilePath)
            local jsonFileHandler = fileCreate(resultsJSONFilePath)
    
            if fileHandler then
                fileWrite(fileHandler, resultsString)
                fileClose(fileHandler)
            end

            if jsonFileHandler then
                fileWrite(jsonFileHandler, resultsJSONString)
                fileClose(jsonFileHandler)
            end
        end,

        onArenaDeathmatchStateSet = function(state)
            local arenaDeathmatchStateFunction = cw.arenaDeathmatchStateFunctions[state]

            if arenaDeathmatchStateFunction then
                arenaDeathmatchStateFunction()
            end
        end,

        onArenaDeathmatchPlayerReachedHunter = function()
            setWeather(1)
            setTime(0, 0)
            setWaterColor(15,192,252)
            setCloudsEnabled(false)
            resetSkyGradient()
        end,

        --[[ onElementDestroy = function()
            if getElementType(source) == "projectile" and getProjectileType(source) == 19 then
                local vehicle = getPedOccupiedVehicle(localPlayer)

                if isElement(vehicle) then
                    local vx, vy, vz = getElementPosition(vehicle)
                    local x, y, z = getElementPosition(source)
                    
                    if getDistanceBetweenPoints3D(vx, vy, vz, x, y, z) <= getElementRadius(vehicle) + 4 then
                        local projectileData = getElementData(source, "projectileData", false)

                        if projectileData then
                            local data = cw.data

                            data.killer = projectileData.playerCreator
                            data.killerPing = projectileData.playerCreatorPing

                            local killerTimer = data.killerTimer

                            if isTimer(killerTimer) then
                                killTimer(killerTimer)
                            end

                            data.killerTimer = setTimer(
                                function()
                                    data.killer = nil
                                    data.killerPing = nil
                                end,
                            7000, 1)
                        end
                    end
                end
            end
        end, ]]

        onArenaExplosion = function(x, y, z, type)
            if source ~= localPlayer then
                local vehicle = getPedOccupiedVehicle(localPlayer)
    
                if isElement(vehicle) then
                    local vx, vy, vz = getElementPosition(vehicle)
    
                    if type == 2 or type == 10 then
                        if getDistanceBetweenPoints3D(vx, vy, vz, x, y, z) <= getElementRadius(vehicle) + 4 then
                            local data = cw.data

                            data.killer = source
                            data.killerPing = getPlayerPing(source)

                            local killerTimer = data.killerTimer

                            if isTimer(killerTimer) then
                                killTimer(killerTimer)
                            end

                            data.killerTimer = setTimer(
                                function()
                                    data.killer = nil
                                    data.killerPing = nil
                                end,
                            7000, 1)
                        end
                    end
                end
            end
        end,

        onArenaPlayerTeamChange = function(oldTeam, newTeam)
            local data = cw.data

            local cwUIItemlistElement = cw.ui.itemlistElement

            cwUIItemlistElement.custom.removePlayer(cwUIItemlistElement, source)

            if cw.isEventTeamElement(newTeam) then
                cwUIItemlistElement.custom.addPlayer(cwUIItemlistElement, source)
            end
        end,

        onProjectileCreation = function(creator)
            if getElementType(creator) == "vehicle" then
                if getElementModel(creator) == 425 then
                    local player = getVehicleOccupant(creator)

                    if player == localPlayer then
                        local data = cw.data

                        cw.killHunterProjectilesCheckTimer()
                        cw.startHunterProjectilesCheckTimer()

                        if not isTimer(data.hunterIntervalTimer) then
                            cw.startHunterSpray()
                        end

                        local newHunterProjectileCount = data.hunterProjectileCount + 1

                        data.hunterProjectileCount = newHunterProjectileCount

                        if newHunterProjectileCount % 2 == 0 then
                            local remaining, executesRemaining, timeInterval = getTimerDetails(data.hunterIntervalTimer)

                            local hunterShotsCount = mathFloor(newHunterProjectileCount/2)

                            silentExport("ep_raceui", "setProjectileLabelText", tostring(hunterShotsCount) .. " shots fired\nInterval: " .. tostring(executesRemaining) .. " seconds")
                        end

                        --[[ if newHunterProjectileCount % 2 == 0 then
                            local hunterShotsCount = mathFloor(newHunterProjectileCount/2)

                            local remaining, executesRemaining, timeInterval = getTimerDetails(data.hunterIntervalTimer)

                            silentExport("ep_raceui", "setProjectileLabelText", tostring(hunterShotsCount) .. " shots fired\nInterval: " .. tostring(executesRemaining) .. " seconds")

                            if hunterShotsCount > 3 then
                                triggerServerEvent("event1:cw:onPlayerHunterSpray", localPlayer, hunterShotsCount)

                                cw.stopHunterSpray()
                            end
                        end ]]
                    end

                    if player then
                        setElementData(source, "projectileData", {playerCreator = player, playerCreatorPing = getPlayerPing(player)}, false)
                    end
                end
            end
        end
    },

    commandHandlers = {
        w = function(commandName, weatherID)
            setWeather(tonumber(weatherID) or 0)
        end,

        st = function(commandName, hour, minute)
            setTime(tonumber(hour) or 0, tonumber(minute) or 0)
        end,

        setLines = function(commandName, lines)
            lines = tonumber(lines)

            if lines then
                local cwUIItemlistElement = cw.ui.itemlistElement

                cwUIItemlistElement.custom.setMaxTeamRows(cwUIItemlistElement, lines)

                outputChatBox("#CCCCCCLines have been set to #FFFFFF" .. tostring(lines), 255, 255, 255, true)
            else
                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [lines]", 255, 255, 255, true)
            end
        end
    },

    timers = {
        checkHunterInterval = function()
            local data = cw.data

            local remaining, executesRemaining, timeInterval = getTimerDetails(sourceTimer)

            local hunterShotsCount = mathFloor(data.hunterProjectileCount/2)

            silentExport("ep_raceui", "setProjectileLabelText", tostring(hunterShotsCount) .. " shots fired\nInterval: " .. tostring(executesRemaining - 1) .. " seconds")

            if executesRemaining == 1 then
                if hunterShotsCount > 3 then
                    triggerServerEvent("event1:cw:onPlayerHunterSpray", localPlayer, hunterShotsCount)
                end

                cw.stopHunterSpray()
            end
        end,

        checkHunterProjectiles = function()
            local data = cw.data

            local hunterShotsCount = mathFloor(data.hunterProjectileCount/2)

            if hunterShotsCount - 1 < 3 then
                cw.stopHunterSpray()
            end
        end,

        hideUICountdown = function()
            silentExport("ep_raceui", "setCountdownState", false)
        end
    },

    arenaDeathmatchStateFunctions = {
        ["map unloading"] = function()
            cw.stopHunterSpray()

            silentExport("ep_raceui", "setSpectateState", false)

            local data = cw.data

            data.countdownStarted = nil

            data.spectateState = nil
        end
    },

    armedVehicleIDs = { [425] = true, [447] = true, [520] = true, [430] = true, [464] = true, [432] = true }
}

event1.modes.cw = cw

addEvent("event1:onClientArenaCreated")
addEvent("event1:onClientArenaDestroy")

addEvent("event1:cw:onClientEventModeStart", true)
addEvent("event1:cw:onClientEventModeStop", true)

addEvent("event1:cw:onClientEventModeCreatedInternal", true)
addEvent("event1:cw:onClientEventModeDestroyInternal", true)

addEvent("event1:deathmatch:onClientWasted")
addEvent("event1:deathmatch:onClientArenaStateSet")
addEvent("event1:deathmatch:onClientPlayerReachedHunter")
addEvent("event1:deathmatch:onVehicleWeaponsUpdate")
addEvent("event1:deathmatch:onClientSpectatorCameraTargetChanged")

addEvent("lobby:ui:onStateSet")

addEvent("onClientPlayerTeamChange")

addEvent("event1:cw:onClientArenaCountdownStarted", true)
addEvent("event1:cw:onClientArenaCountdownValueUpdate", true)
addEvent("event1:cw:onClientArenaResultsSaved", true)

do
    local eventHandlers = cw.eventHandlers

    addEventHandler("event1:onClientArenaCreated", localPlayer, eventHandlers.onClientArenaCreated)
    addEventHandler("event1:onClientArenaDestroy", localPlayer, eventHandlers.onClientArenaDestroy)
end