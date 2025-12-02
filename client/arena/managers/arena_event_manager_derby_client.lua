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

local nth = function(value)
    if value > 3 and value < 21 then
        return "th"
    end

    local a = value % 10

    if a == 1 then
        return "st"
    elseif a == 2 then
        return "nd"
    elseif a == 3 then
        return "rd"
    else
        return "th"
    end
end

local derby

derby = {
    start = function()
        if not derby.data then
            local data = {}

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = derby.eventHandlers

            addEventHandler("mapManager:mapLoader:onClientMapResourceAllElementsLoaded", localPlayer, eventHandlers.onClientMapLoaderMapResourceAllElementsLoaded)

            addEventHandler("event1:derby:onClientArenaStateSetInternal", arenaElement, eventHandlers.onArenaDeathmatchStateSet)
            
            derby.data = data

            local state = getElementData(arenaElement, "state", false)
            
            if state and state ~= "map unloading" then
                local setState = derby.setState

                setState("map loaded")

                setState(state)
            end
        end
    end,

    stop = function()
        local data = derby.data

        if data then
            derby.setState("map unloading")

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = derby.eventHandlers

            removeEventHandler("mapManager:mapLoader:onClientMapResourceAllElementsLoaded", localPlayer, eventHandlers.onClientMapLoaderMapResourceAllElementsLoaded)

            removeEventHandler("event1:derby:onClientArenaStateSetInternal", arenaElement, eventHandlers.onArenaDeathmatchStateSet)

            derby.data = nil
        end
    end,

    setState = function(state)
        local states = derby.states

        local stateData = states[state]

        if stateData then
            local data = derby.data

            local oldState = data.state

            if state ~= oldState then
                local oldStateData = states[oldState]

                if oldStateData then
                    oldStateData:onStateChanging()
                end

                data.state = state
    
                stateData:onStateSet()

                triggerEvent("event1:derby:onClientArenaStateSet", localPlayer, state)
            end
        end
    end,

    setNextMapName = function(nextMapName)
        local radarNextMapPosX = silentExport("ep_raceui", "getRadarSetting", "nextMapPosX")
        local radarNextMapPosY = silentExport("ep_raceui", "getRadarSetting", "nextMapPosY")

        silentExport("ep_raceui", "animateRadarPosition", radarNextMapPosX, radarNextMapPosY)
        
        local heightBarNextMapPosX = silentExport("ep_raceui", "getHeightBarSetting", "nextMapPosX")
        local heightBarNextMapPosY = silentExport("ep_raceui", "getHeightBarSetting", "nextMapPosY")

        silentExport("ep_raceui", "animateHeightBarPosition", heightBarNextMapPosX, heightBarNextMapPosY)

        local deathlistNextMapPosX = silentExport("ep_raceui", "getDeathlistSetting", "nextMapPosX")
        local deathlistNextMapPosY = silentExport("ep_raceui", "getDeathlistSetting", "nextMapPosY")

        silentExport("ep_raceui", "animateDeathlistPosition", deathlistNextMapPosX, deathlistNextMapPosY)

        silentExport("ep_raceui", "setNextMapLabelName", nextMapName)
    end,

    setObjectsDrawDistance = function(distance)
        local objects = getElementsByType("object")
        
        for i = 1, #objects do
            engineSetModelLODDistance(getElementModel(objects[i]), distance)
        end
    end,

    setPlayerFreezeEnabled = function(player, enabled)
        local vehicle = getPedOccupiedVehicle(player)

        if isElement(vehicle) then
            setElementFrozen(vehicle, enabled)
            setVehicleDamageProof(vehicle, enabled)
            setElementCollisionsEnabled(vehicle, not enabled)
        end
        
        setElementFrozen(player, enabled)
    end,

    updateCountdownState = function()
        local lobbyUIState = silentExport("ep_arena_lobby", "getUIState")

        silentExport("ep_raceui", "setCountdownState", not lobbyUIState)
    end,

    updateUIState = function()
        local lobbyUIState = silentExport("ep_arena_lobby", "getUIState")

        if lobbyUIState then
            silentExport("ep_raceui", "setRadarState", false)

            silentExport("ep_raceui", "setMapLabelState", false)
            silentExport("ep_raceui", "setNextMapLabelState", false)

            silentExport("ep_raceui", "setTimersState", false)

            silentExport("ep_raceui", "setSpeedoState", false)

            silentExport("ep_raceui", "setNotificationsState", false)

            silentExport("ep_raceui", "setNametagsState", false)

            silentExport("ep_raceui", "setDeathlistState", false)

            silentExport("ep_raceui", "setAfkState", false)

            silentExport("ep_scoreboard", "setUIState", false)
            silentExport("ep_scoreboard", "setUIToggleState", false)
        else
            silentExport("ep_raceui", "setMapLabelState", true)

            silentExport("ep_raceui", "setTimersState", true)

            silentExport("ep_raceui", "setSpeedoState", true)

            silentExport("ep_raceui", "setNametagsState", true)

            if derby.radarState then
                silentExport("ep_raceui", "setRadarState", true)
            end

            if derby.notificationsState then
                silentExport("ep_raceui", "setNotificationsState", true)
            end

            if derby.deathlistState then
                silentExport("ep_raceui", "setDeathlistState", true)
            end

            if derby.afk then
                silentExport("ep_raceui", "setAfkState", true)
            end

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            if getElementData(arenaElement, "nextMapName", false) then
                silentExport("ep_raceui", "setNextMapLabelState", true)
            end

            silentExport("ep_scoreboard", "setUIToggleState", true)
        end
    end,

    states = {
        ["map loaded"] = {
            onStateSet = function(stateData)
                setBlurLevel(0)
                setCloudsEnabled(false)
                setPedCanBeKnockedOffBike(localPlayer, false)

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local mapInfo = getElementData(arenaElement, "mapInfo", false) or {}

                silentExport("ep_raceui", "setMapLabelName", mapInfo.name or "Unnamed")

                local mapDuration = getElementData(arenaElement, "mapDuration", false)

                silentExport("ep_raceui", "setTimeLeftTimerTime", mapDuration)

                local nextMapName = getElementData(arenaElement, "nextMapName", false)
        
                if nextMapName then
                    derby.setNextMapName(nextMapName)
                end

                derby.updateUIState()

                local localEventHandlers = stateData.localEventHandlers

                addEventHandler("event1:derby:onClientPlayerLoaded", arenaElement, localEventHandlers.onArenaDeathmatchPlayerLoaded)
                addEventHandler("event1:derby:onClientPlayerUnloaded", arenaElement, localEventHandlers.onArenaDeathmatchPlayerUnloaded)

                local sharedEventHandlers = stateData.sharedEventHandlers

                addEventHandler("event1:derby:onClientPlayerWastedInternal", localPlayer, sharedEventHandlers.onClientArenaDeathmatchWasted)

                addEventHandler("lobby:ui:onStateSet", localPlayer, sharedEventHandlers.onClientLobbyUIStateSet)

                addEventHandler("spectator:onCameraTargetChanged", localPlayer, sharedEventHandlers.onClientSpectatorCameraTargetChanged)

                addEventHandler("onClientResourceStart", root, sharedEventHandlers.onClientResourceStart)

                addEventHandler("event1:derby:onClientPlayerWastedInternal", arenaElement, sharedEventHandlers.onArenaDeathmatchPlayerWasted)

                addEventHandler("event1:onClientArenaNextMapSet", arenaElement, sharedEventHandlers.onArenaNextMapSet)

                addEventHandler("onClientPlayerTeamChange", arenaElement, sharedEventHandlers.onArenaPlayerTeamChange)

                local settings = stateData.settings

                local sharedKeyBinds = stateData.sharedKeyBinds

                bindKey("m", "down", sharedKeyBinds.toggleSounds)
                bindKey("n", "down", sharedKeyBinds.toggleShaders)
                bindKey("F3", "down", sharedKeyBinds.toggleRadar)
                bindKey("F4", "down", sharedKeyBinds.toggleDeathlist)
                bindKey("F6", "down", sharedKeyBinds.toggleNotifications)

                if getElementData(localPlayer, "state", false) == "dead" then
                    local arenaPlayers = getElementChildren(arenaElement, "player")

                    for i = 1, #arenaPlayers do
                        local arenaPlayer = arenaPlayers[i]
        
                        if arenaPlayer ~= localPlayer then
                            if getElementData(arenaPlayer, "state", false) == "alive" then
                                local vehicle = getPedOccupiedVehicle(arenaPlayer)

                                if isElement(vehicle) then
                                    local r, g, b = 255, 255, 255
            
                                    local team = getPlayerTeam(arenaPlayer)
                                    
                                    if team then
                                        r, g, b = getTeamColor(team)
                                    end
            
                                    silentExport("ep_raceui", "addRadarElementBlip", arenaPlayer, nil, nil, r, g, b)
    
                                    silentExport("ep_spectator", "addTarget", arenaPlayer)
                                    
                                    silentExport("ep_raceui", "addNametag", arenaPlayer)
                                    silentExport("ep_raceui", "setNametagAlpha", arenaPlayer, 1)
                                end
                            end
                        end
                    end

                    silentExport("ep_spectator", "setState", true)
                end
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:derby:onClientPlayerLoaded", arenaElement, localEventHandlers.onArenaDeathmatchPlayerLoaded)
                removeEventHandler("event1:derby:onClientPlayerUnloaded", arenaElement, localEventHandlers.onArenaDeathmatchPlayerUnloaded)
            end,

            localEventHandlers = {
                onArenaDeathmatchPlayerLoaded = function()
                    if source ~= localPlayer then
                        local vehicle = getPedOccupiedVehicle(source)

                        if isElement(vehicle) then
                            local r, g, b = 255, 255, 255

                            local team = getPlayerTeam(source)
                            
                            if team then
                                r, g, b = getTeamColor(team)
                            end

                            silentExport("ep_raceui", "addRadarElementBlip", source, nil, nil, r, g, b)

                            silentExport("ep_spectator", "addTarget", source)

                            silentExport("ep_raceui", "addNametag", source)
                            silentExport("ep_raceui", "setNametagAlpha", source, 1)

                            if getElementData(localPlayer, "state", false) == "dead" then
                                local cameraTarget = silentExport("ep_spectator", "getTarget")

                                if not cameraTarget or cameraTarget == localPlayer then
                                    silentExport("ep_spectator", "setRandomTarget")
                                end
                            end
                        end
                    end
                end,

                onArenaDeathmatchPlayerUnloaded = function()
                    if source ~= localPlayer then
                        silentExport("ep_raceui", "removeRadarElementBlip", source)

                        silentExport("ep_raceui", "removeNametag", source)

                        silentExport("ep_spectator", "removeTarget", source)
                    end
                end
            },

            sharedEventHandlers = {
                onClientArenaDeathmatchWasted = function()
                    silentExport("ep_spectator", "setState", true)

                    triggerEvent("event1:derby:onClientWasted", localPlayer)
                end,

                onClientLobbyUIStateSet = function(state)
                    derby.updateUIState()
                end,

                onClientSpectatorCameraTargetChanged = function(oldTarget, newTarget)
                    local carHideState = silentExport("ep_carhide", "getState")
                    
                    if isElement(oldTarget) then
                        local vehicle = getPedOccupiedVehicle(oldTarget)
                        
                        if isElement(vehicle) then
                            if oldTarget ~= localPlayer then
                                if getElementData(oldTarget, "state", false) == "alive" then
                                    local r, g, b = 255, 255, 255
                                    
                                    local team = getPlayerTeam(oldTarget)
                                    
                                    if team then
                                        r, g, b = getTeamColor(team)
                                    end
                                    
                                    silentExport("ep_raceui", "addRadarElementBlip", oldTarget, nil, nil, r, g, b)
                                end
                            end
                        end
                    end

                    if isElement(newTarget) then
                        if newTarget ~= localPlayer then
                            silentExport("ep_raceui", "removeRadarElementBlip", newTarget)
                        end
                    end

                    triggerEvent("event1:derby:onClientSpectatorCameraTargetChanged", localPlayer, oldTarget, newTarget)
                end,

                onClientResourceStart = function(startedResource)
                    local resourceStartFunction = derby.states["map loaded"].sharedResourceStartFunctions[getResourceName(startedResource)]
        
                    if resourceStartFunction then
                        resourceStartFunction(startedResource)
                    end
                end,

                onArenaDeathmatchPlayerWasted = function()
                    if source ~= localPlayer then
                        silentExport("ep_raceui", "removeRadarElementBlip", source)

                        silentExport("ep_raceui", "removeNametag", source)

                        silentExport("ep_spectator", "removeTarget", source)
                    end
                end,

                onArenaNextMapSet = function(nextMapName)
                    derby.setNextMapName(nextMapName)
                end,

                onArenaPlayerTeamChange = function(oldTeam, newTeam)
                    if source ~= localPlayer then
                        local cameraTarget = silentExport("ep_spectator", "getTarget")

                        if source ~= cameraTarget then
                            if getElementData(source, "state", false) == "alive" then
                                local r, g, b = 255, 255, 255

                                if newTeam then
                                    r, g, b = getTeamColor(newTeam)
                                end
            
                                silentExport("ep_raceui", "setRadarElementBlipColor", source, r, g, b)
                            end
                        end
                    end
                end
            },

            sharedKeyBinds = {
                toggleSounds = function()
                    local soundsState = silentExport("ep_mapmanager", "getSoundsState")
        
                    if soundsState ~= nil then
                        soundsState = not soundsState
            
                        silentExport("ep_mapmanager", "setSoundsState", soundsState)
            
                        if soundsState then
                            outputChatBox("#CCCCCCMap sounds are now #00FF00enabled", 255, 255, 255, true)
                        else
                            outputChatBox("#CCCCCCMap sounds are now #FF0000disabled", 255, 255, 255, true)
                        end
                    end
                end,
        
                toggleShaders = function()
                    local shadersState = silentExport("ep_mapmanager", "getShadersState")
        
                    if shadersState ~= nil then
                        shadersState = not shadersState
            
                        silentExport("ep_mapmanager", "setShadersState", shadersState)
            
                        if shadersState then
                            outputChatBox("#CCCCCCMap shaders are now #00FF00enabled", 255, 255, 255, true)
                        else
                            outputChatBox("#CCCCCCMap shaders are now #FF0000disabled", 255, 255, 255, true)
                        end
                    end
                end,
        
                toggleRadar = function()
                    local state = not derby.radarState
        
                    silentExport("ep_raceui", "setRadarState", state)
                    silentExport("ep_raceui", "setHeightBarState", state)
        
                    derby.radarState = state
        
                    if state then
                        outputChatBox("#CCCCCCRadar is now #00FF00enabled", 255, 255, 255, true)
                    else
                        outputChatBox("#CCCCCCRadar is now #FF0000disabled", 255, 255, 255, true)
                    end
                end,
        
                toggleDeathlist = function()
                    local state = not derby.deathlistState
        
                    silentExport("ep_raceui", "setDeathlistState", state)
        
                    derby.deathlistState = state
        
                    if state then
                        outputChatBox("#CCCCCCDeathlist is now #00FF00enabled", 255, 255, 255, true)
                    else
                        outputChatBox("#CCCCCCDeathlist is now #FF0000disabled", 255, 255, 255, true)
                    end
                end,
        
                toggleNotifications = function()
                    local state = not derby.notificationsState
        
                    silentExport("ep_raceui", "setNotificationsState", state)
        
                    derby.notificationsState = state
        
                    if state then
                        outputChatBox("#CCCCCCNotifications are now enabled", 255, 255, 255, true)
                    else
                        outputChatBox("#CCCCCCNotifications are now disabled", 255, 255, 255, true)
                    end
                end
            },

            sharedResourceStartFunctions = {
                ["ep_raceui"] = function(resource)
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    local mapInfo = getElementData(arenaElement, "mapInfo", false) or {}

                    silentExport("ep_raceui", "setMapLabelName", mapInfo.name or "Unnamed")

                    local mapDuration = getElementData(arenaElement, "mapDuration", false)

                    silentExport("ep_raceui", "setTimeLeftTimerTime", mapDuration)
        
                    local arenaPlayers = getElementChildren(arenaElement, "player")

                    local cameraTarget = silentExport("ep_spectator", "getTarget")

                    for i = 1, #arenaPlayers do
                        local arenaPlayer = arenaPlayers[i]
        
                        if arenaPlayer ~= localPlayer then
                            if getElementData(arenaPlayer, "state", false) == "alive" then
                                if arenaPlayer ~= cameraTarget then
                                    local r, g, b = 255, 255, 255
            
                                    local team = getPlayerTeam(arenaPlayer)
                                    
                                    if team then
                                        r, g, b = getTeamColor(team)
                                    end
            
                                    silentExport("ep_raceui", "addRadarElementBlip", arenaPlayer, nil, nil, r, g, b)
                                end

                                silentExport("ep_raceui", "addNametag", arenaPlayer)
                                silentExport("ep_raceui", "setNametagAlpha", arenaPlayer, 1)
                            end
                        end
                    end

                    local nextMapName = getElementData(arenaElement, "nextMapName", false)
        
                    if nextMapName then
                        derby.setNextMapName(nextMapName)
                    end

                    derby.updateUIState()
                end,

                ["ep_spectator"] = function(resource)
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    local arenaPlayers = getElementChildren(arenaElement, "player")
        
                    for i = 1, #arenaPlayers do
                        local arenaPlayer = arenaPlayers[i]
        
                        if arenaPlayer ~= localPlayer then
                            if getElementData(arenaPlayer, "state", false) == "alive" then
                                silentExport("ep_spectator", "addTarget", arenaPlayer)
                            end
                        end
                    end
        
                    if getElementData(localPlayer, "state", false) == "dead" then
                        silentExport("ep_spectator", "setState", true)
                    end
                end
            }
        },

        ["countdown starting"] = {
            onStateSet = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                addEventHandler("event1:derby:onClientPlayerWastedInternal", arenaElement, localEventHandlers.onArenaDeathmatchPlayerWasted)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:derby:onClientPlayerWastedInternal", arenaElement, localEventHandlers.onArenaDeathmatchPlayerWasted)
            end,

            localEventHandlers = {
                onArenaDeathmatchPlayerWasted = function(alivePlayersCount)
                    local place = alivePlayersCount + 1

                    silentExport("ep_raceui", "addDeathlistText", "#C6C6C6" .. tostring(place) .. nth(place) .. " - #FFFFFF" .. getPlayerName(source))
                end
            }
        },

        ["countdown started"] = {
            onStateSet = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                addEventHandler("lobby:ui:onStateSet", localPlayer, localEventHandlers.onClientLobbyUIStateSet)

                addEventHandler("onClientResourceStart", root, localEventHandlers.onClientResourceStart)

                addEventHandler("event1:derby:onClientArenaCountdownValueUpdate", arenaElement, localEventHandlers.onArenaDeathmatchCountdownValueUpdate)

                addEventHandler("event1:derby:onClientPlayerWastedInternal", arenaElement, localEventHandlers.onArenaDeathmatchPlayerWasted)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("lobby:ui:onStateSet", localPlayer, localEventHandlers.onClientLobbyUIStateSet)

                removeEventHandler("onClientResourceStart", root, localEventHandlers.onClientResourceStart)

                removeEventHandler("event1:derby:onClientArenaCountdownValueUpdate", arenaElement, localEventHandlers.onArenaDeathmatchCountdownValueUpdate)

                removeEventHandler("event1:derby:onClientPlayerWastedInternal", arenaElement, localEventHandlers.onArenaDeathmatchPlayerWasted)

                --stateData:killHideUICountdownTimer()
            end,

            killHideUICountdownTimer = function(stateData)
                local hideUICountdownTimer = stateData.hideUICountdownTimer

                if isTimer(hideUICountdownTimer) then
                    killTimer(hideUICountdownTimer)
                end

                stateData.hideUICountdownTimer = nil
            end,

            localEventHandlers = {
                onClientLobbyUIStateSet = function(state)
                    derby.updateCountdownState()
                end,

                onClientResourceStart = function(startedResource)
                    local data = derby.data

                    local stateData = derby.states[data.state]

                    local resourceStartFunction = stateData.localResourceStartFunctions[getResourceName(startedResource)]
        
                    if resourceStartFunction then
                        resourceStartFunction(startedResource)
                    end
                end,

                onArenaDeathmatchCountdownValueUpdate = function(countdownValue)
                    local data = derby.data

                    local stateData = derby.states[data.state]

                    silentExport("ep_raceui", "setCountdownValue", countdownValue)
                    silentExport("ep_raceui", "setCountdownState", true)

                    stateData.hideUICountdownTimer = setTimer(stateData.localTimers.hideUICountdown, 500, 1)

                    derby.updateCountdownState()
                end,

                onArenaDeathmatchPlayerWasted = function(alivePlayersCount)
                    local place = alivePlayersCount + 1

                    silentExport("ep_raceui", "addDeathlistText", "#C6C6C6" .. tostring(place) .. nth(place) .. " - #FFFFFF" .. getPlayerName(source))
                end
            },

            localTimers = {
                hideUICountdown = function()
                    silentExport("ep_raceui", "setCountdownState", false)
                end
            },

            localResourceStartFunctions = {
                ["ep_raceui"] = function(resource)
                    derby.updateCountdownState()
                end
            }
        },

        ["running"] = {
            onStateSet = function(stateData)
                silentExport("ep_raceui", "startTimeLeftTimer")

                local localEventHandlers = stateData.localEventHandlers

                addEventHandler("event1:derby:onClientRacePickupsUnload", localPlayer, localEventHandlers.onClientArenaDeathmatchRacePickupsUnload)
                addEventHandler("event1:derby:onClientPlayerWastedInternal", localPlayer, localEventHandlers.onClientArenaDeathmatchWasted)

                addEventHandler("mapManager:racePickup:onClientPickup", localPlayer, localEventHandlers.onClientRacePickupPickup)

                addEventHandler("onClientResourceStart", root, localEventHandlers.onClientResourceStart)

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                addEventHandler("event1:derby:onClientPlayerRacePickupUnload", arenaElement, localEventHandlers.onArenaDeathmatchPlayerRacePickupUnload)
                addEventHandler("event1:derby:onClientPlayerRacePickupLoad", arenaElement, localEventHandlers.onArenaDeathmatchPlayerRacePickupLoad)
                addEventHandler("event1:derby:onClientPlayerSyncFunction", arenaElement, localEventHandlers.onArenaDeathmatchPlayerSyncFunction)
                addEventHandler("event1:derby:onClientPlayerWastedInternal", arenaElement, localEventHandlers.onArenaDeathmatchPlayerWasted)

                if getElementData(localPlayer, "state", false) == "alive" then
                    silentExport("ep_raceui", "startTimePassedTimer")

                    stateData:bindKillRequestKey()
                    stateData:startWaterCheckTimer()
                    stateData:startAfkTimer()
                    stateData:bindAfkResetKeys()

                    derby.setPlayerFreezeEnabled(localPlayer, false)

                    triggerServerEvent("event1:derby:onPlayerUnfreeze", localPlayer)

                    stateData.unfreezeTick = getTickCount()
                end
            end,

            onStateChanging = function(stateData)
                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:derby:onClientRacePickupsUnload", localPlayer, localEventHandlers.onClientArenaDeathmatchRacePickupsUnload)
                removeEventHandler("event1:derby:onClientPlayerWastedInternal", localPlayer, localEventHandlers.onClientArenaDeathmatchWasted)

                removeEventHandler("mapManager:racePickup:onClientPickup", localPlayer, localEventHandlers.onClientRacePickupPickup)

                removeEventHandler("onClientResourceStart", root, localEventHandlers.onClientResourceStart)

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                removeEventHandler("event1:derby:onClientPlayerRacePickupUnload", arenaElement, localEventHandlers.onArenaDeathmatchPlayerRacePickupUnload)
                removeEventHandler("event1:derby:onClientPlayerRacePickupLoad", arenaElement, localEventHandlers.onArenaDeathmatchPlayerRacePickupLoad)
                removeEventHandler("event1:derby:onClientPlayerSyncFunction", arenaElement, localEventHandlers.onArenaDeathmatchPlayerSyncFunction)
                removeEventHandler("event1:derby:onClientPlayerWastedInternal", arenaElement, localEventHandlers.onArenaDeathmatchPlayerWasted)

                stateData:unbindKillRequestKey()
                stateData:killWaterCheckTimer()
                stateData:stopAfk()
                stateData:unbindAfkResetKeys()

                stateData.unfreezeTick = nil
            end,

            bindKillRequestKey = function(stateData)
                local killKey = next(getBoundKeys("enter_exit"))
    
                if killKey then
                    local localKeyBinds = stateData.localKeyBinds

                    bindKey(killKey, "down", localKeyBinds.requestKill)

                    stateData.killKey = killKey
                end
            end,

            unbindKillRequestKey = function(stateData)
                local killKey = stateData.killKey

                if killKey then
                    local localKeyBinds = stateData.localKeyBinds

                    unbindKey(killKey, "down", localKeyBinds.requestKill)

                    stateData.killKey = nil
                end
            end,

            startWaterCheckTimer = function(stateData)
                local localTimers = stateData.localTimers

                stateData.waterCheckTimer = setTimer(localTimers.waterCheck, 1000, 0)
            end,

            killWaterCheckTimer = function(stateData)
                local waterCheckTimer = stateData.waterCheckTimer

                if isTimer(waterCheckTimer) then
                    killTimer(waterCheckTimer)
                end

                stateData.waterCheckTimer = nil
            end,

            startAfkTimer = function(stateData)
                local localTimers = stateData.localTimers

                stateData.afkTimer = setTimer(localTimers.afk, 15000, 1)
            end,

            stopAfk = function(stateData)
                local afkTimer = stateData.afkTimer

                if isTimer(afkTimer) then
                    killTimer(afkTimer)
                end

                local afkWarningUpdateTimer = stateData.afkWarningUpdateTimer

                if isTimer(afkWarningUpdateTimer) then
                    killTimer(afkWarningUpdateTimer)
                end

                stateData.afkTimer = nil

                stateData.afkWarningUpdateTimer = nil

                silentExport("ep_raceui", "setAfkState", false)

                derby.afk = nil
            end,

            bindAfkResetKeys = function(stateData)
                local localKeyBinds = stateData.localKeyBinds

                local afkReset = localKeyBinds.afkReset

                bindKey("accelerate", "both", afkReset)
                bindKey("brake_reverse", "both", afkReset)
                bindKey("vehicle_left", "both", afkReset)
                bindKey("vehicle_right", "both", afkReset)
            end,

            unbindAfkResetKeys = function(stateData)
                local localKeyBinds = stateData.localKeyBinds

                local afkReset = localKeyBinds.afkReset

                unbindKey("accelerate", "both", afkReset)
                unbindKey("brake_reverse", "both", afkReset)
                unbindKey("vehicle_left", "both", afkReset)
                unbindKey("vehicle_right", "both", afkReset)
            end,

            localEventHandlers = {
                onClientArenaDeathmatchRacePickupsUnload = function(unloadedRacePickupIDs)
                    for racePickupID in pairs(unloadedRacePickupIDs) do
                        local racePickupElement = silentExport("ep_mapmanager", "getRacePickupFromID", racePickupID)

                        if isElement(racePickupElement) then
                            silentExport("ep_mapmanager", "unloadRacePickup", racePickupElement)
                        end
                    end
                end,

                onClientArenaDeathmatchWasted = function()
                    local data = derby.data

                    local stateData = derby.states[data.state]

                    stateData:unbindKillRequestKey()
                    stateData:killWaterCheckTimer()
                    stateData:stopAfk()
                    stateData:unbindAfkResetKeys()

                    silentExport("ep_raceui", "stopTimePassedTimer")
                    
                    local timePassed = getTickCount() - stateData.unfreezeTick
                    
                    silentExport("ep_raceui", "setTimePassedTimerTime", timePassed)
                end,

                onClientRacePickupPickup = function(racePickupElement)
                    local racePickupID = silentExport("ep_mapmanager", "getRacePickupData", racePickupElement, "id")

                    local racePickupType = getElementData(racePickupElement, "type", false)
                    local racePickupRespawn = getElementData(racePickupElement, "respawn", false)
                    local racePickupVehicle = getElementData(racePickupElement, "vehicle", false)

                    triggerServerEvent("event1:derby:onPlayerPickupRacePickup", localPlayer, racePickupID, racePickupType, racePickupRespawn, racePickupVehicle)
                end,

                onClientResourceStart = function(startedResource)
                    local data = derby.data

                    local stateData = derby.states[data.state]

                    local resourceStartFunction = stateData.localResourceStartFunctions[getResourceName(startedResource)]
        
                    if resourceStartFunction then
                        resourceStartFunction(startedResource)
                    end
                end,

                onArenaDeathmatchPlayerRacePickupUnload = function(racePickupID)
                    local racePickupElement = silentExport("ep_mapmanager", "getRacePickupFromID", racePickupID)

                    if isElement(racePickupElement) then
                        silentExport("ep_mapmanager", "unloadRacePickup", racePickupElement)
                    end
                end,

                onArenaDeathmatchPlayerRacePickupLoad = function(racePickupID)
                    local racePickupElement = silentExport("ep_mapmanager", "getRacePickupFromID", racePickupID)

                    if isElement(racePickupElement) then
                        silentExport("ep_mapmanager", "loadRacePickup", racePickupElement)
                    end
                end,

                onArenaDeathmatchPlayerSyncFunction = function(functionName, ...)
                    if source ~= localPlayer then
                        _G[functionName](...)
                    end
                end,

                onArenaDeathmatchPlayerWasted = function(alivePlayersCount)
                    local place = alivePlayersCount + 1

                    silentExport("ep_raceui", "addDeathlistText", "#C6C6C6" .. tostring(place) .. nth(place) .. " - #FFFFFF" .. getPlayerName(source))
                end
            },

            localKeyBinds = {
                requestKill = function()
                    triggerServerEvent("event1:derby:onPlayerKill", localPlayer)
                end,

                afkReset = function()
                    local data = derby.data

                    local stateData = derby.states[data.state]

                    stateData:stopAfk()
                    stateData:startAfkTimer()                    
                end
            },

            localTimers = {
                waterCheck = function()
                    local vehicle = getPedOccupiedVehicle(localPlayer)
            
                    if isElement(vehicle) then
                        if getVehicleType(vehicle) ~= "Boat" then
                            local x, y, z = getElementPosition(localPlayer)

                            local waterZ = getWaterLevel(x, y, z)
                            
                            if waterZ and z < waterZ - 0.5 then
                                triggerServerEvent("event1:derby:onPlayerKill", localPlayer)
                            end
                        end
            
                        if not getVehicleEngineState(vehicle) then
                            setVehicleEngineState(vehicle, true)
                        end
                    end
                end,

                afk = function()
                    local data = derby.data

                    local stateData = derby.states[data.state]

                    if getPedControlState(localPlayer, "accelerate") or getPedControlState(localPlayer, "brake_reverse") or getPedControlState(localPlayer, "vehicle_left") or getPedControlState(localPlayer, "vehicle_right") then
                        stateData:startAfkTimer()
                    else
                        derby.afk = true

                        silentExport("ep_raceui", "setAfkState", true)
                        silentExport("ep_raceui", "setAfkValue", 5)

                        local localTimers = stateData.localTimers

                        stateData.afkWarningUpdateTimer = setTimer(localTimers.afkWarningUpdate, 1000, 5)
                    end
                end,

                afkWarningUpdate = function()
                    local remaining, executesRemaining, timeInterval = getTimerDetails(sourceTimer)

                    local value = executesRemaining - 1

                    silentExport("ep_raceui", "setAfkValue", value)

                    if value == 0 then
                        triggerServerEvent("event1:derby:onPlayerKill", localPlayer)

                        silentExport("ep_raceui", "setAfkState", false)

                        derby.afk = nil
                    end
                end
            },

            localResourceStartFunctions = {
                ["ep_raceui"] = function(resource)
                    local data = derby.data

                    local stateData = derby.states[data.state]

                    local unfreezeTick = stateData.unfreezeTick

                    if unfreezeTick then
                        local timePassed = getTickCount() - unfreezeTick

                        silentExport("ep_raceui", "setTimePassedTimerTime", timePassed)
                        silentExport("ep_raceui", "startTimePassedTimer")
                    end
                end
            }
        },

        ["ended"] = {
            onStateSet = function(stateData)
                silentExport("ep_raceui", "setRadarState", false)

                silentExport("ep_raceui", "setMapLabelState", false)
                silentExport("ep_raceui", "setNextMapLabelState", false)

                silentExport("ep_raceui", "setRequestLabelState", false)

                silentExport("ep_raceui", "setTimersState", false)

                silentExport("ep_raceui", "setSpeedoState", false)

                silentExport("ep_raceui", "setNotificationsState", false)

                silentExport("ep_raceui", "setNametagsState", false)

                silentExport("ep_raceui", "setDeathlistState", false)

                local localEventHandlers = stateData.localEventHandlers
                
                addEventHandler("lobby:ui:onStateSet", localPlayer, localEventHandlers.onClientLobbyUIStateSet)
                
                addEventHandler("mapManager:mapLoader:onClientMapResourceElementFilesDownloadStarted", localPlayer, localEventHandlers.onClientMapLoaderMapResourceElementFilesDownloadStarted)
                addEventHandler("mapManager:mapLoader:onClientMapResourceFilesDownloadStarted", localPlayer, localEventHandlers.onClientMapLoaderMapResourceFilesDownloadStarted)

                addEventHandler("onClientResourceStart", root, localEventHandlers.onClientResourceStart)

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                addEventHandler("event1:onClientArenaNextMapSet", arenaElement, localEventHandlers.onArenaNextMapSet)
            end,

            onStateChanging = function(stateData)
                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("lobby:ui:onStateSet", localPlayer, localEventHandlers.onClientLobbyUIStateSet)
                
                removeEventHandler("mapManager:mapLoader:onClientMapResourceElementFilesDownloadStarted", localPlayer, localEventHandlers.onClientMapLoaderMapResourceElementFilesDownloadStarted)
                removeEventHandler("mapManager:mapLoader:onClientMapResourceFilesDownloadStarted", localPlayer, localEventHandlers.onClientMapLoaderMapResourceFilesDownloadStarted)

                removeEventHandler("onClientResourceStart", root, localEventHandlers.onClientResourceStart)

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                removeEventHandler("event1:onClientArenaNextMapSet", arenaElement, localEventHandlers.onArenaNextMapSet)
            end,

            localEventHandlers = {
                onClientLobbyUIStateSet = function()
                    silentExport("ep_raceui", "setRadarState", false)

                    silentExport("ep_raceui", "setMapLabelState", false)
                    silentExport("ep_raceui", "setNextMapLabelState", false)
    
                    silentExport("ep_raceui", "setRequestLabelState", false)
    
                    silentExport("ep_raceui", "setTimersState", false)
    
                    silentExport("ep_raceui", "setSpeedoState", false)

                    silentExport("ep_raceui", "setNotificationsState", false)
    
                    silentExport("ep_raceui", "setNametagsState", false)
    
                    silentExport("ep_raceui", "setDeathlistState", false)
                end,

                onClientMapLoaderMapResourceElementFilesDownloadStarted = function()
                    silentExport("ep_raceui", "setRequestLabelState", false)
                end,

                onClientMapLoaderMapResourceFilesDownloadStarted = function()
                    silentExport("ep_raceui", "setRequestLabelState", false)
                end,

                onClientResourceStart = function(startedResource)
                    local data = derby.data

                    local stateData = derby.states[data.state]

                    local resourceStartFunction = stateData.localResourceStartFunctions[getResourceName(startedResource)]
        
                    if resourceStartFunction then
                        resourceStartFunction(startedResource)
                    end
                end,

                onArenaNextMapSet = function()
                    silentExport("ep_raceui", "setNextMapLabelState", false)
                end
            },

            localResourceStartFunctions = {
                ["ep_raceui"] = function(resource)
                    silentExport("ep_raceui", "setRadarState", false)

                    silentExport("ep_raceui", "setMapLabelState", false)
                    silentExport("ep_raceui", "setNextMapLabelState", false)
    
                    silentExport("ep_raceui", "setRequestLabelState", false)
    
                    silentExport("ep_raceui", "setTimersState", false)
    
                    silentExport("ep_raceui", "setSpeedoState", false)

                    silentExport("ep_raceui", "setNotificationsState", false)
    
                    silentExport("ep_raceui", "setNametagsState", false)
    
                    silentExport("ep_raceui", "setDeathlistState", false)
                end
            }
        },

        ["map unloading"] = {
            onStateSet = function(stateData)
                local mapLoadedStateData = derby.states["map loaded"]

                local mapLoadedSharedEventHandlers = mapLoadedStateData.sharedEventHandlers

                removeEventHandler("event1:derby:onClientPlayerWastedInternal", localPlayer, mapLoadedSharedEventHandlers.onClientArenaDeathmatchWasted)

                removeEventHandler("lobby:ui:onStateSet", localPlayer, mapLoadedSharedEventHandlers.onClientLobbyUIStateSet)

                removeEventHandler("spectator:onCameraTargetChanged", localPlayer, mapLoadedSharedEventHandlers.onClientSpectatorCameraTargetChanged)

                removeEventHandler("onClientResourceStart", root, mapLoadedSharedEventHandlers.onClientResourceStart)

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                removeEventHandler("event1:derby:onClientPlayerWastedInternal", arenaElement, mapLoadedSharedEventHandlers.onArenaDeathmatchPlayerWasted)

                removeEventHandler("event1:onClientArenaNextMapSet", arenaElement, mapLoadedSharedEventHandlers.onArenaNextMapSet)

                removeEventHandler("onClientPlayerTeamChange", arenaElement, mapLoadedSharedEventHandlers.onArenaPlayerTeamChange)

                local mapLoadedSharedKeyBinds = mapLoadedStateData.sharedKeyBinds

                unbindKey("m", "down", mapLoadedSharedKeyBinds.toggleSounds)
                unbindKey("n", "down", mapLoadedSharedKeyBinds.toggleShaders)
                unbindKey("F3", "down", mapLoadedSharedKeyBinds.toggleRadar)
                unbindKey("F4", "down", mapLoadedSharedKeyBinds.toggleDeathlist)
                unbindKey("F6", "down", mapLoadedSharedKeyBinds.toggleNotifications)

                silentExport("ep_raceui", "setRadarState", false)
                silentExport("ep_raceui", "removeRadarElementBlips")

                silentExport("ep_raceui", "setMapLabelState", false)
                silentExport("ep_raceui", "setNextMapLabelState", false)

                silentExport("ep_raceui", "setRequestLabelState", false)

                silentExport("ep_raceui", "setTimersState", false)
                silentExport("ep_raceui", "resetTimePassedTimer")
                silentExport("ep_raceui", "resetTimeLeftTimer")

                silentExport("ep_raceui", "setSpeedoState", false)

                silentExport("ep_raceui", "setNotificationsState", false)

                silentExport("ep_raceui", "setNametagsState", false)
                silentExport("ep_raceui", "resetNametags")

                silentExport("ep_raceui", "setCountdownState", false)
                silentExport("ep_raceui", "setCountdownValue", -1)

                silentExport("ep_raceui", "setDeathlistState", false)
                silentExport("ep_raceui", "resetDeathlist")

                silentExport("ep_raceui", "setAfkState", false)
                silentExport("ep_raceui", "setAfkValue", nil)

                silentExport("ep_spectator", "setState", false)
                silentExport("ep_spectator", "resetTargets")
    
                local radarPosX = silentExport("ep_raceui", "getRadarSetting", "posX")
                local radarPosY = silentExport("ep_raceui", "getRadarSetting", "posY")
    
                silentExport("ep_raceui", "animateRadarPosition", radarPosX, radarPosY)

                local heightBarPosX = silentExport("ep_raceui", "getHeightBarSetting", "posX")
                local heightBarPosY = silentExport("ep_raceui", "getHeightBarSetting", "posY")
        
                silentExport("ep_raceui", "animateHeightBarPosition", heightBarPosX, heightBarPosY)

                local deathlistPosX = silentExport("ep_raceui", "getDeathlistSetting", "posX")
                local deathlistPosY = silentExport("ep_raceui", "getDeathlistSetting", "posY")
        
                silentExport("ep_raceui", "animateDeathlistPosition", deathlistPosX, deathlistPosY)

                setPedCanBeKnockedOffBike(localPlayer, true)
                setCloudsEnabled(true)
                resetBlurLevel()
            end,

            onStateChanging = function(stateData)

            end
        }
    },

    eventHandlers = {
        onClientArenaCreated = function()
            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = derby.eventHandlers

            addEventHandler("event1:dd:onClientMapResourceStarting", arenaElement, eventHandlers.onArenaDeathmatchMapResourceStarting)
            addEventHandler("event1:dd:onClientMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)
        end,

        onClientArenaDestroy = function()
            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = derby.eventHandlers

            removeEventHandler("event1:dd:onClientMapResourceStarting", arenaElement, eventHandlers.onArenaDeathmatchMapResourceStarting)
            removeEventHandler("event1:dd:onClientMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)

            derby.stop()
        end,

        ---

        onArenaDeathmatchMapResourceStarting = function()
            derby.start()
        end,

        onArenaDeathmatchMapResourceUnloading = function()
            derby.stop()
        end,

        ---

        onClientMapLoaderMapResourceAllElementsLoaded = function()
            derby.setObjectsDrawDistance(300)

            triggerServerEvent("event1:derby:onPlayerAllMapResourceElementsLoaded", localPlayer)
        end,

        onArenaDeathmatchStateSet = function(state)
            derby.setState(state)
        end
    },

    radarState = true,

    notificationsState = true,

    deathlistState = true
}

event1.managers.derby = derby

addEvent("event1:onClientArenaCreated")
addEvent("event1:onClientArenaDestroy")

addEvent("event1:dd:onClientMapResourceStarting")
addEvent("event1:dd:onClientMapResourceUnloading")

addEvent("lobby:ui:onStateSet")

addEvent("spectator:onCameraTargetChanged")

addEvent("mapManager:mapLoader:onClientMapResourceAllElementsLoaded")
addEvent("mapManager:racePickup:onClientPickup")

addEvent("onClientPlayerTeamChange")

addEvent("event1:derby:onClientPlayerLoaded", true)
addEvent("event1:derby:onClientPlayerUnloaded", true)
addEvent("event1:derby:onClientPlayerWastedInternal", true)
addEvent("event1:derby:onClientRacePickupsUnload", true)
addEvent("event1:derby:onClientPlayerRacePickupUnload", true)
addEvent("event1:derby:onClientPlayerRacePickupLoad", true)
addEvent("event1:derby:onClientPlayerSyncFunction", true)
addEvent("event1:derby:onClientArenaStateSetInternal", true)
addEvent("event1:derby:onClientArenaCountdownValueUpdate", true)

addEvent("event1:onClientArenaNextMapSet", true)

do
    local eventHandlers = derby.eventHandlers

    addEventHandler("event1:onClientArenaCreated", localPlayer, eventHandlers.onClientArenaCreated)
    addEventHandler("event1:onClientArenaDestroy", localPlayer, eventHandlers.onClientArenaDestroy)
end