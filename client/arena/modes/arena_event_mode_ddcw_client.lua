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

local derby = event1.managers.derby

local ddcw

ddcw = {
    settings = {
        resultsFilePath = "client/arena/modes/ddcw_results.txt"
    },

    start = function(teamsCount)
        if not ddcw.data then
            local data = {}

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local coreElement = getElementData(arenaElement, "coreElement", false)

            local refereeClanTeamElement = getElementData(coreElement, "refereeClanTeamElement", false)
            local spectatorsClanTeamElement = getElementData(coreElement, "spectatorsClanTeamElement", false)

            local eventHandlers = ddcw.eventHandlers

            addEventHandler("event1:derby:onClientWasted", localPlayer, eventHandlers.onClientArenaDeathmatchWasted)

            addEventHandler("lobby:ui:onStateSet", localPlayer, eventHandlers.onClientLobbyUIStateSet)

            addEventHandler("event1:ddcw:onClientUnloadRepairRacePickups", arenaElement, eventHandlers.onArenaUnloadRepairRacePickups)
            addEventHandler("event1:ddcw:onClientArenaResultsSaved", arenaElement, eventHandlers.onArenaCWResultsSaved)

            addEventHandler("onClientVehicleCollision", arenaElement, eventHandlers.onArenaVehicleCollision)
            addEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)

            local commandHandlers = ddcw.commandHandlers

            addCommandHandler("setlines", commandHandlers.setLines)

            data.coreElement = coreElement

            data.refereeClanTeamElement = refereeClanTeamElement
            data.spectatorsClanTeamElement = spectatorsClanTeamElement

            data.teamsCount = teamsCount

            ddcw.data = data

            ddcw.getEventClansTeamElements()
            ddcw.startUI()
        end
    end,

    stop = function()
        local data = ddcw.data

        if data then
            ddcw.stopUI()

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = ddcw.eventHandlers

            removeEventHandler("event1:derby:onClientWasted", localPlayer, eventHandlers.onClientArenaDeathmatchWasted)

            removeEventHandler("lobby:ui:onStateSet", localPlayer, eventHandlers.onClientLobbyUIStateSet)

            removeEventHandler("event1:ddcw:onClientUnloadRepairRacePickups", arenaElement, eventHandlers.onArenaUnloadRepairRacePickups)
            removeEventHandler("event1:ddcw:onClientArenaResultsSaved", arenaElement, eventHandlers.onArenaCWResultsSaved)

            removeEventHandler("onClientVehicleCollision", arenaElement, eventHandlers.onArenaVehicleCollision)
            removeEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)
            
            local commandHandlers = ddcw.commandHandlers

            removeCommandHandler("setlines", commandHandlers.setLines)

            local killerTimer = data.killerTimer

            if isTimer(killerTimer) then
                killTimer(killerTimer)
            end

            ddcw.data = nil
        end
    end,

    getEventClansTeamElements = function()
        local data = ddcw.data

        local teamsCount = data.teamsCount

        local coreElement = data.coreElement

        local eventClansTeamElements = {}

        for i = 1, teamsCount do
            eventClansTeamElements[i] = getElementData(coreElement, "eventTeam" .. tostring(i), false)
        end

        data.eventClansTeamElements = eventClansTeamElements
    end,

    addEventClansDataToUI = function()
        local data = ddcw.data

        local eventClansTeamElements = data.eventClansTeamElements

        local ddcwUIItemlistElement = ddcw.ui.itemlistElement

        local ddcwUIItemlistElementCustomAddPlayer = ddcwUIItemlistElement.custom.addPlayer
        local ddcwUIItemlistElementCustomAddTeam = ddcwUIItemlistElement.custom.addTeam

        for i = 1, #eventClansTeamElements do
            local teamElement = eventClansTeamElements[i]

            ddcwUIItemlistElementCustomAddTeam(ddcwUIItemlistElement, teamElement)

            local teamElementPlayers = getPlayersInTeam(teamElement)

            for i = 1, #teamElementPlayers do
                local player = teamElementPlayers[i]

                ddcwUIItemlistElementCustomAddPlayer(ddcwUIItemlistElement, player)
            end
        end
    end,

    startUI = function()
        local ddcwUI = ddcw.ui

        ddcwUI.create()

        local data = ddcw.data

        local ddcwUIItemlistElement = ddcwUI.itemlistElement

        local ddcwUIItemlistElementCustom = ddcwUIItemlistElement.custom

        ddcwUIItemlistElementCustom.eventClansTeamElements = data.eventClansTeamElements

        ddcw.addEventClansDataToUI()

        ddcwUIItemlistElement:setAnimationState(true)
    end,

    stopUI = function()
        local ddcwUI = ddcw.ui

        local ddcwUIItemlistElement = ddcwUI.itemlistElement

        ddcwUIItemlistElement:setAnimationState(false)
        ddcwUIItemlistElement:setAnimationProgress(0)

        ddcwUI.destroy()
    end,

    isEventTeamElement = function(teamElement)
        local data = ddcw.data

        local eventClansTeamElements = data.eventClansTeamElements

        for i = 1, #eventClansTeamElements do
            if eventClansTeamElements[i] == teamElement then
                return true
            end
        end
    end,

    eventHandlers = {
        onClientArenaCreated = function()
            local eventHandlers = ddcw.eventHandlers

            addEventHandler("event1:ddcw:onClientEventModeStart", localPlayer, eventHandlers.onClientArenaEventModeStart)
            addEventHandler("event1:ddcw:onClientEventModeStop", localPlayer, eventHandlers.onClientArenaEventModeStop)

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            addEventHandler("event1:ddcw:onClientEventModeCreatedInternal", arenaElement, eventHandlers.onArenaEventModeCreated)
            addEventHandler("event1:ddcw:onClientEventModeDestroyInternal", arenaElement, eventHandlers.onArenaEventModeDestroy)
        end,

        onClientArenaDestroy = function()
            local eventHandlers = ddcw.eventHandlers

            removeEventHandler("event1:ddcw:onClientEventModeStart", localPlayer, eventHandlers.onClientArenaEventModeStart)
            removeEventHandler("event1:ddcw:onClientEventModeStop", localPlayer, eventHandlers.onClientArenaEventModeStop)

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            removeEventHandler("event1:ddcw:onClientEventModeCreatedInternal", arenaElement, eventHandlers.onArenaEventModeCreated)
            removeEventHandler("event1:ddcw:onClientEventModeDestroyInternal", arenaElement, eventHandlers.onArenaEventModeDestroy)

            ddcw.stop()
        end,

        ---

        onClientArenaEventModeStart = function(teamsCount)
            ddcw.start(teamsCount)
        end,

        onClientArenaEventModeStop = function()
            ddcw.stop()
        end,

        onArenaEventModeCreated = function(teamsCount)
            ddcw.start(teamsCount)
        end,

        onArenaEventModeDestroy = function()
            ddcw.stop()
        end,

        ---

        onClientArenaDeathmatchWasted = function()
            local data = ddcw.data

            local killer = data.killer

            if killer then
                local killerTimer = data.killerTimer

                if isTimer(killerTimer) then
                    killTimer(killerTimer)
                end

                data.killerTimer = nil

                data.killer = nil

                triggerServerEvent("event1:ddcw:onPlayerWasted", localPlayer, killer)
            else
                triggerServerEvent("event1:ddcw:onPlayerWasted", localPlayer)
            end
        end,

        onClientLobbyUIStateSet = function(state)
            local ddcwUIState = not state

            ddcw.ui.itemlistElement:setAnimationState(ddcwUIState)
        end,

        onArenaUnloadRepairRacePickups = function()
            local racePickups = getElementsByType("racepickup")

            for i = 1, #racePickups do
                local racePickupElement = racePickups[i]

                local racePickupType = getElementData(racePickupElement, "type", false)

                if racePickupType == "repair" then
                    silentExport("ep_mapmanager", "unloadRacePickup", racePickupElement)
                end
            end
        end,

        onArenaCWResultsSaved = function(resultsString)
            local resultsFilePath = ddcw.settings.resultsFilePath

            if fileExists(resultsFilePath) then
                fileDelete(resultsFilePath)
            end
    
            local fileHandler = fileCreate(resultsFilePath)
    
            if fileHandler then
                fileWrite(fileHandler, resultsString)
                fileClose(fileHandler)
            end
        end,

        onArenaVehicleCollision = function(theHitElement)
            local vehicleOccupant = getVehicleOccupant(source)

            if vehicleOccupant == localPlayer then
                if getElementType(theHitElement) == "vehicle" then
                    local theHitElementOccupant = getVehicleOccupant(theHitElement)

                    if theHitElementOccupant then
                        local data = ddcw.data

                        data.killer = theHitElementOccupant

                        local killerTimer = data.killerTimer

                        if isTimer(killerTimer) then
                            killTimer(killerTimer)
                        end

                        data.killerTimer = setTimer(
                            function()
                                data.killer = nil
                            end,
                        7000, 1)
                    end
                end
            end
        end,

        onArenaPlayerTeamChange = function(oldTeam, newTeam)
            local data = ddcw.data

            local ddcwUIItemlistElement = ddcw.ui.itemlistElement

            ddcwUIItemlistElement.custom.removePlayer(ddcwUIItemlistElement, source)

            if ddcw.isEventTeamElement(newTeam) then
                ddcwUIItemlistElement.custom.addPlayer(ddcwUIItemlistElement, source)
            end
        end
    },

    commandHandlers = {
        setLines = function(commandName, lines)
            lines = tonumber(lines)

            if lines then
                local ddcwUIItemlistElement = ddcw.ui.itemlistElement

                ddcwUIItemlistElement.custom.setMaxTeamRows(ddcwUIItemlistElement, lines)

                outputChatBox("#CCCCCCLines have been set to #FFFFFF" .. tostring(lines), 255, 255, 255, true)
            else
                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [lines]", 255, 255, 255, true)
            end
        end
    },
}

event1.modes.ddcw = ddcw

addEvent("event1:onClientArenaCreated")
addEvent("event1:onClientArenaDestroy")

addEvent("event1:ddcw:onClientEventModeStart", true)
addEvent("event1:ddcw:onClientEventModeStop", true)

addEvent("event1:ddcw:onClientEventModeCreatedInternal", true)
addEvent("event1:ddcw:onClientEventModeDestroyInternal", true)

addEvent("event1:derby:onClientWasted")

addEvent("lobby:ui:onStateSet")

addEvent("onClientPlayerTeamChange")

addEvent("event1:ddcw:onClientUnloadRepairRacePickups", true)
addEvent("event1:ddcw:onClientArenaResultsSaved", true)

do
    local eventHandlers = ddcw.eventHandlers

    addEventHandler("event1:onClientArenaCreated", localPlayer, eventHandlers.onClientArenaCreated)
    addEventHandler("event1:onClientArenaDestroy", localPlayer, eventHandlers.onClientArenaDestroy)
end