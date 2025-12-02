local mathAbs = math.abs
local mathFloor = math.floor

local stringFormat = string.format

local formatMS = function(ms)
    return stringFormat("%02d:%02d:%03d", tostring(mathFloor(ms/60000)), tostring(mathFloor((ms/1000) % 60)), tostring(mathFloor(ms % 1000)))
end

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

local deathmatch

deathmatch = {
    start = function()
        if not deathmatch.data then
            local data = {}

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = deathmatch.eventHandlers

            addEventHandler("mapManager:mapLoader:onClientMapResourceAllElementsLoaded", localPlayer, eventHandlers.onClientMapLoaderMapResourceAllElementsLoaded)

            addEventHandler("event1:deathmatch:onClientArenaStateSetInternal", arenaElement, eventHandlers.onArenaDeathmatchStateSet)
            
            data.elementBlips = {}

            deathmatch.data = data

            local state = getElementData(arenaElement, "state", false)
            
            if state and state ~= "map unloading" then
                local setState = deathmatch.setState

                setState("map loaded")

                setState(state)
            end
        end
    end,

    stop = function()
        local data = deathmatch.data

        if data then
            deathmatch.setState("map unloading")

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = deathmatch.eventHandlers

            removeEventHandler("mapManager:mapLoader:onClientMapResourceAllElementsLoaded", localPlayer, eventHandlers.onClientMapLoaderMapResourceAllElementsLoaded)

            removeEventHandler("event1:deathmatch:onClientArenaStateSetInternal", arenaElement, eventHandlers.onArenaDeathmatchStateSet)

            deathmatch.data = nil
        end
    end,

    setState = function(state)
        local states = deathmatch.states

        local stateData = states[state]

        if stateData then
            local data = deathmatch.data

            local oldState = data.state

            if state ~= oldState then
                local oldStateData = states[oldState]

                if oldStateData then
                    oldStateData:onStateChanging()
                end

                data.state = state
    
                stateData:onStateSet()

                triggerEvent("event1:deathmatch:onClientArenaStateSet", localPlayer, state)
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

    createBlipAttachedTo = function(elementToAttachTo, ...)
        local data = deathmatch.data

        local elementBlips = data.elementBlips

        if not elementBlips[elementToAttachTo] then
            local blipElement = createBlipAttachedTo(elementToAttachTo, ...)

            if blipElement then
                local data = deathmatch.data

                elementBlips[elementToAttachTo] = blipElement
            end
        end
    end,

    setBlipColor = function(attachedToElement, ...)
        local data = deathmatch.data

        local blipElement = data.elementBlips[attachedToElement]

        if isElement(blipElement) then
            setBlipColor(blipElement, ...)
        end
    end,

    destroyBlipAttachedTo = function(attachedToElement)
        local data = deathmatch.data

        local elementBlips = data.elementBlips 

        local blipElement = elementBlips[attachedToElement]

        if isElement(blipElement) then
            destroyElement(blipElement)
        end

        elementBlips[attachedToElement] = nil
    end,

    destroyAllBlips = function()
        local data = deathmatch.data

        for attachedToElement, blipElement in pairs(data.elementBlips) do
            if isElement(blipElement) then
                destroyElement(blipElement)
            end
        end

        data.elementBlips = {}
    end,

    setObjectsDrawDistance = function(distance)
        local objects = getElementsByType("object")
        
        for i = 1, #objects do
            engineSetModelLODDistance(getElementModel(objects[i]), distance)
        end
    end,

    setPlayerAlpha = function(player, alpha)
        setElementAlpha(player, alpha)

        local vehicle = getPedOccupiedVehicle(player)

        if vehicle then
            setElementAlpha(vehicle, alpha)
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

    resetPlayersAlpha = function()
        local eventData = event1.data

        local arenaPlayers = getElementChildren(eventData.arenaElement, "player")

        local setPlayerAlpha = deathmatch.setPlayerAlpha

        for i = 1, #arenaPlayers do
            setPlayerAlpha(arenaPlayers[i], 255)
        end
    end,

    updateGhostmodeCollisions = function(ghostmodeState)
        local eventData = event1.data

        local collidable = ghostmodeState == false

        local elements = event1.getArenaVehicles()

        local arenaPlayers = getElementChildren(eventData.arenaElement, "player")

        for i = 1, #arenaPlayers do
            elements[#elements + 1] = arenaPlayers[i]
        end

        local elementsCount = #elements

        for i = 1, elementsCount do
            for j = 1, elementsCount do
                setElementCollidableWith(elements[i], elements[j], collidable)
            end
        end
    end,

    updateGhostmodeCollisionsWithElement = function(element, ghostmodeState)
        local eventData = event1.data

        local collidable = ghostmodeState == false

        local elements = event1.getArenaVehicles()

        local arenaPlayers = getElementChildren(eventData.arenaElement, "player")

        for i = 1, #arenaPlayers do
            elements[#elements + 1] = arenaPlayers[i]
        end

        for i = 1, #elements do
            setElementCollidableWith(element, elements[i], collidable)
        end
    end,

    updateVehicleWeapons = function()
        local vehicle = getPedOccupiedVehicle(localPlayer)

        if isElement(vehicle) then
            local model = getElementModel(vehicle)

            local controlsState = not deathmatch.armedVehicleIDs[model]

            if model ~= 425 then
                toggleControl("vehicle_fire", controlsState)
            end
            
            toggleControl("vehicle_secondary_fire", controlsState)

            triggerEvent("event1:deathmatch:onVehicleWeaponsUpdate", localPlayer)
        end
    end,

    updateHeightBarState = function()
        local heightBarState = false

        local lobbyUIState = silentExport("ep_arena_lobby", "getUIState")

        if not lobbyUIState then
            local cameraTarget = silentExport("ep_spectator", "getTarget")

            if cameraTarget then
                local vehicle = getPedOccupiedVehicle(cameraTarget)
                
                if isElement(vehicle) then
                    local vehicleType = getVehicleType(vehicle)
                    
                    if vehicleType == "Plane" or vehicleType == "Helicopter" then
                        heightBarState = true
                    end
                end
            end
        end

        silentExport("ep_raceui", "setHeightBarState", heightBarState)
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

            silentExport("ep_raceui", "setHeightBarState", false)

            silentExport("ep_raceui", "setNotificationsState", false)

            silentExport("ep_raceui", "setNametagsState", false)

            silentExport("ep_raceui", "setDeathlistState", false)

            silentExport("ep_raceui", "setAfkState", false)

            silentExport("ep_scoreboard", "setUIState", false)
            silentExport("ep_scoreboard", "setUIToggleState", false)

            silentExport("ep_toplist", "setTopTimesUIState", false)
            silentExport("ep_toplist", "setTopTimesUIToggleState", false)
        else
            silentExport("ep_raceui", "setMapLabelState", true)

            silentExport("ep_raceui", "setTimersState", true)

            silentExport("ep_raceui", "setSpeedoState", true)

            silentExport("ep_raceui", "setNametagsState", true)

            if deathmatch.radarState then
                silentExport("ep_raceui", "setRadarState", true)
            end

            if deathmatch.notificationsState then
                silentExport("ep_raceui", "setNotificationsState", true)
            end

            if deathmatch.deathlistState then
                silentExport("ep_raceui", "setDeathlistState", true)
            end

            if deathmatch.afk then
                silentExport("ep_raceui", "setAfkState", true)
            end

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            if getElementData(arenaElement, "nextMapName", false) then
                silentExport("ep_raceui", "setNextMapLabelState", true)
            end

            silentExport("ep_scoreboard", "setUIToggleState", true)

            local mapInfo = getElementData(arenaElement, "mapInfo", false)

            if mapInfo.directory ~= "hunter" then
                silentExport("ep_toplist", "setTopTimesUIToggleState", true)
            end

            deathmatch.updateHeightBarState()
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
                    deathmatch.setNextMapName(nextMapName)
                end

                deathmatch.updateUIState()
                deathmatch.updateVehicleWeapons()
                deathmatch.updateGhostmodeCollisions(true)

                local localEventHandlers = stateData.localEventHandlers

                addEventHandler("event1:deathmatch:onClientPlayerLoaded", arenaElement, localEventHandlers.onArenaDeathmatchPlayerLoaded)
                addEventHandler("event1:deathmatch:onClientPlayerUnloaded", arenaElement, localEventHandlers.onArenaDeathmatchPlayerUnloaded)

                local sharedEventHandlers = stateData.sharedEventHandlers

                addEventHandler("event1:deathmatch:onClientPlayerWastedInternal", localPlayer, sharedEventHandlers.onClientArenaDeathmatchWasted)

                addEventHandler("lobby:ui:onStateSet", localPlayer, sharedEventHandlers.onClientLobbyUIStateSet)

                addEventHandler("carHide:onStateSet", localPlayer, sharedEventHandlers.onClientCarHideStateSet)

                addEventHandler("spectator:onCameraTargetChanged", localPlayer, sharedEventHandlers.onClientSpectatorCameraTargetChanged)

                addEventHandler("onClientElementDataChange", localPlayer, sharedEventHandlers.onClientElementDataChange)

                addEventHandler("onClientResourceStart", root, sharedEventHandlers.onClientResourceStart)

                addEventHandler("event1:deathmatch:onClientPlayerWastedInternal", arenaElement, sharedEventHandlers.onArenaDeathmatchPlayerWasted)

                addEventHandler("event1:onClientArenaNextMapSet", arenaElement, sharedEventHandlers.onArenaNextMapSet)

                addEventHandler("onClientElementModelChange", arenaElement, sharedEventHandlers.onArenaElementModelChange)

                addEventHandler("onClientElementStreamIn", arenaElement, sharedEventHandlers.onArenaElementStreamIn)

                addEventHandler("onClientPlayerTeamChange", arenaElement, sharedEventHandlers.onArenaPlayerTeamChange)

                local sharedCommandHandlers = stateData.sharedCommandHandlers

                addCommandHandler("setblipsize", sharedCommandHandlers.setBlipSize)

                local sharedKeyBinds = stateData.sharedKeyBinds

                bindKey("o", "down", sharedKeyBinds.toggleCarHide)
                bindKey("c", "down", sharedKeyBinds.toggleCarFade)
                bindKey("j", "down", sharedKeyBinds.toggleDecoHide)
                bindKey("m", "down", sharedKeyBinds.toggleSounds)
                bindKey("n", "down", sharedKeyBinds.toggleShaders)
                bindKey("F3", "down", sharedKeyBinds.toggleRadar)
                bindKey("F4", "down", sharedKeyBinds.toggleDeathlist)
                bindKey("F6", "down", sharedKeyBinds.toggleNotifications)
                bindKey("F7", "down", sharedKeyBinds.toggleNametags)
                bindKey("F9", "down", sharedKeyBinds.toggleBlips)

                if getElementData(localPlayer, "state", false) == "dead" then
                    stateData:handleJoin()
                end
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:deathmatch:onClientPlayerLoaded", arenaElement, localEventHandlers.onArenaDeathmatchPlayerLoaded)
                removeEventHandler("event1:deathmatch:onClientPlayerUnloaded", arenaElement, localEventHandlers.onArenaDeathmatchPlayerUnloaded)
            end,

            handleJoin = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local createBlipAttachedTo = deathmatch.createBlipAttachedTo
            
                local setBlipColor = deathmatch.setBlipColor

                local setPlayerAlpha = deathmatch.setPlayerAlpha

                local carfadeAlpha = deathmatch.carfadeAlpha

                local blipSize = deathmatch.blipSize

                local blipsState = deathmatch.blipsState

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
        
                                if blipsState then
                                    silentExport("ep_raceui", "addRadarElementBlip", arenaPlayer, nil, nil, r, g, b)

                                    createBlipAttachedTo(arenaPlayer, 0, blipSize)
                                    
                                    setBlipColor(arenaPlayer, r, g, b, 255)
                                end

                                silentExport("ep_spectator", "addTarget", arenaPlayer)

                                if getElementModel(vehicle) == 425 then
                                    silentExport("ep_raceui", "addNametag", arenaPlayer)
                                    silentExport("ep_raceui", "setNametagAlpha", arenaPlayer, 1)
                                else
                                    local carHideState = silentExport("ep_carhide", "getState")
                                
                                    if not carHideState then
                                        if deathmatch.nametagsState then
                                            silentExport("ep_raceui", "addNametag", arenaPlayer)
                                            silentExport("ep_raceui", "setNametagAlpha", arenaPlayer, carfadeAlpha/255)
                                        else
                                            silentExport("ep_raceui", "removeNametag", arenaPlayer)

                                            setPlayerNametagShowing(arenaPlayer, false)
                                        end
                                    end
                                    
                                    silentExport("ep_carhide", "addPlayer", arenaPlayer)
                                    
                                    setPlayerAlpha(arenaPlayer, carfadeAlpha)
                                end
                            end
                        end
                    end
                end

                silentExport("ep_spectator", "setState", true)
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

                            if deathmatch.blipsState then
                                silentExport("ep_raceui", "addRadarElementBlip", source, nil, nil, r, g, b)

                                deathmatch.createBlipAttachedTo(source, 0, deathmatch.blipSize)
    
                                deathmatch.setBlipColor(source, r, g, b, 255)
                            end

                            silentExport("ep_spectator", "addTarget", source)

                            if getElementModel(vehicle) == 425 then
                                silentExport("ep_raceui", "addNametag", source)
                                silentExport("ep_raceui", "setNametagAlpha", source, 1)
                            else
                                local carHideState = silentExport("ep_carhide", "getState")
                            
                                if not carHideState then
                                    if deathmatch.nametagsState then
                                        silentExport("ep_raceui", "addNametag", source)
                                        silentExport("ep_raceui", "setNametagAlpha", source, deathmatch.carfadeAlpha/255)
                                    else
                                        silentExport("ep_raceui", "removeNametag", source)

                                        setPlayerNametagShowing(source, false)
                                    end
                                end
                                
                                silentExport("ep_carhide", "addPlayer", source)
                                
                                deathmatch.setPlayerAlpha(source, deathmatch.carfadeAlpha)
                            end

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

                        silentExport("ep_carhide", "removePlayer", source)

                        silentExport("ep_spectator", "removeTarget", source)

                        deathmatch.destroyBlipAttachedTo(source)

                        deathmatch.setPlayerAlpha(source, 255)
                    end
                end
            },

            sharedEventHandlers = {
                onClientArenaDeathmatchWasted = function()
                    silentExport("ep_spectator", "setState", true)

                    triggerEvent("event1:deathmatch:onClientWasted", localPlayer)
                end,

                onClientLobbyUIStateSet = function(state)
                    deathmatch.updateUIState()
                end,

                onClientCarHideStateSet = function(state)
                    local carHidePlayers = silentExport("ep_carhide", "getPlayers")

                    if state then
                        for i = 1, #carHidePlayers do
                            silentExport("ep_raceui", "removeNametag", carHidePlayers[i])
                        end
                    else
                        local nametagsState = deathmatch.nametagsState

                        local carfadeAlpha = deathmatch.carfadeAlpha

                        for i = 1, #carHidePlayers do
                            local carHidePlayer = carHidePlayers[i]

                            if nametagsState then
                                silentExport("ep_raceui", "addNametag", carHidePlayer)
                                silentExport("ep_raceui", "setNametagAlpha", carHidePlayer, carfadeAlpha/255)
                            else
                                silentExport("ep_raceui", "removeNametag", carHidePlayer)

                                setPlayerNametagShowing(carHidePlayer, false)
                            end
                        end
                    end
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
                                    
                                    if deathmatch.blipsState then
                                        silentExport("ep_raceui", "addRadarElementBlip", oldTarget, nil, nil, r, g, b)

                                        deathmatch.destroyBlipAttachedTo(oldTarget)
                                        deathmatch.createBlipAttachedTo(oldTarget, 0, deathmatch.blipSize)
                                        deathmatch.setBlipColor(oldTarget, r, g, b, 255)
                                    end
                                    
                                    if getElementModel(vehicle) ~= 425 then
                                        if carHideState then
                                            silentExport("ep_raceui", "removeNametag", oldTarget)
                                        else
                                            if deathmatch.nametagsState then
                                                silentExport("ep_raceui", "addNametag", oldTarget)
                                                silentExport("ep_raceui", "setNametagAlpha", oldTarget, deathmatch.carfadeAlpha/255)
                                            else
                                                silentExport("ep_raceui", "removeNametag", oldTarget)

                                                setPlayerNametagShowing(oldTarget, false)
                                            end
                                        end

                                        silentExport("ep_carhide", "addPlayer", oldTarget)

                                        deathmatch.setPlayerAlpha(oldTarget, deathmatch.carfadeAlpha)
                                    end
                                end
                            end
                        end
                    end

                    if isElement(newTarget) then
                        if newTarget ~= localPlayer then
                            silentExport("ep_raceui", "removeRadarElementBlip", newTarget)

                            silentExport("ep_raceui", "addNametag", newTarget)
                            silentExport("ep_raceui", "setNametagAlpha", newTarget, 1)
                            
                            silentExport("ep_carhide", "removePlayer", newTarget)

                            deathmatch.destroyBlipAttachedTo(newTarget)

                            if deathmatch.blipsState then
                                deathmatch.createBlipAttachedTo(newTarget, 2, deathmatch.blipSize)
                            end

                            deathmatch.setPlayerAlpha(newTarget, 255)
                        end
                    end

                    deathmatch.updateHeightBarState()

                    triggerEvent("event1:deathmatch:onClientSpectatorCameraTargetChanged", localPlayer, oldTarget, newTarget)
                end,

                onClientElementDataChange = function(theKey, oldValue, newValue)
                    if theKey == "state" and newValue == "dead" then
                        local mapLoadedStateData = deathmatch.states["map loaded"]

                        mapLoadedStateData:handleJoin()

                        removeEventHandler("onClientElementDataChange", localPlayer, mapLoadedStateData.sharedEventHandlers.onClientElementDataChange)
                    end
                end,

                onClientResourceStart = function(startedResource)
                    local resourceStartFunction = deathmatch.states["map loaded"].sharedResourceStartFunctions[getResourceName(startedResource)]
        
                    if resourceStartFunction then
                        resourceStartFunction(startedResource)
                    end
                end,

                onArenaDeathmatchPlayerWasted = function()
                    if source ~= localPlayer then
                        silentExport("ep_raceui", "removeRadarElementBlip", source)

                        silentExport("ep_raceui", "removeNametag", source)

                        silentExport("ep_carhide", "removePlayer", source)

                        silentExport("ep_spectator", "removeTarget", source)

                        deathmatch.destroyBlipAttachedTo(source)

                        deathmatch.setPlayerAlpha(source, 255)
                    end
                end,

                onArenaNextMapSet = function(nextMapName)
                    deathmatch.setNextMapName(nextMapName)
                end,

                onArenaElementModelChange = function(oldModel, newModel)
                    if getElementType(source) == "vehicle" then
                        local player = getVehicleOccupant(source)

                        if player then
                            if player == localPlayer then
                                deathmatch.updateVehicleWeapons()
                                deathmatch.updateHeightBarState()
                            else
                                local cameraTarget = silentExport("ep_spectator", "getTarget")

                                if getElementModel(source) == 425 then
                                    if player ~= cameraTarget then
                                        silentExport("ep_raceui", "addNametag", player)
                                        silentExport("ep_raceui", "setNametagAlpha", player, 1)
            
                                        silentExport("ep_carhide", "removePlayer", player)
                                    end
            
                                    deathmatch.setPlayerAlpha(player, 255)
                                else
                                    if player ~= cameraTarget then
                                        local carHideState = silentExport("ep_carhide", "getState")

                                        if carHideState then
                                            silentExport("ep_raceui", "removeNametag", player)
                                        end

                                        silentExport("ep_carhide", "addPlayer", player)

                                        deathmatch.setPlayerAlpha(player, deathmatch.carfadeAlpha)
                                    end
                                end

                                if cameraTarget then
                                    deathmatch.updateHeightBarState()
                                end
                            end

                            if getVehicleType(newModel) == "Helicopter" then
                                setHeliBladeCollisionsEnabled(source, false)
                            end
                        end
                    end
                end,

                onArenaElementStreamIn = function()
                    if getElementType(source) == "vehicle" then
                        deathmatch.updateGhostmodeCollisionsWithElement(source, true)
                    end
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
            
                                if deathmatch.blipsState then
                                    silentExport("ep_raceui", "setRadarElementBlipColor", source, r, g, b)

                                    deathmatch.setBlipColor(source, r, g, b, 255)
                                end
                            end
                        end
                    end
                end
            },

            sharedCommandHandlers = {
                setBlipSize = function(commandName, size)
                    size = tonumber(size)

                    if size then
                        deathmatch.blipSize = size

                        for attachedToElement, blipElement in pairs(deathmatch.data.elementBlips) do
                            if isElement(blipElement) then
                                setBlipSize(blipElement, size)
                            end
                        end

                        outputChatBox("#CCCCCCBlip size has been set to #FFFFFF" .. tostring(size))
                    end
                end
            },

            sharedKeyBinds = {
                toggleCarHide = function()
                    local carHideState = silentExport("ep_carhide", "getState")
        
                    if carHideState ~= nil then
                        carHideState = not carHideState
            
                        silentExport("ep_carhide", "setState", carHideState)
            
                        if carHideState then
                            outputChatBox("#CCCCCCCar hide is now #00FF00enabled", 255, 255, 255, true)
                        else
                            outputChatBox("#CCCCCCCar hide is now #FF0000disabled", 255, 255, 255, true)
                        end
                    end
                end,

                toggleCarFade = function()
                    local carfadeState = not deathmatch.carfadeState

                    deathmatch.carfadeState = carfadeState

                    local carHidePlayers = silentExport("ep_carhide", "getPlayers")

                    local setPlayerAlpha = deathmatch.setPlayerAlpha

                    if carfadeState then
                        deathmatch.carfadeAlpha = 32

                        local carfadeAlpha = deathmatch.carfadeAlpha

                        for i = 1, #carHidePlayers do
                            local carHidePlayer = carHidePlayers[i]

                            silentExport("ep_raceui", "setNametagAlpha", carHidePlayer, carfadeAlpha/255)

                            setPlayerAlpha(carHidePlayer, carfadeAlpha)
                        end

                        outputChatBox("#CCCCCCCar fade is now #00FF00enabled", 255, 255, 255, true)
                    else
                        deathmatch.carfadeAlpha = 255

                        local carfadeAlpha = deathmatch.carfadeAlpha

                        for i = 1, #carHidePlayers do
                            local carHidePlayer = carHidePlayers[i]

                            silentExport("ep_raceui", "setNametagAlpha", carHidePlayer, carfadeAlpha/255)

                            setPlayerAlpha(carHidePlayer, carfadeAlpha)
                        end

                        outputChatBox("#CCCCCCCar fade is now #FF0000disabled", 255, 255, 255, true)
                    end
                end,

                toggleDecoHide = function()
                    local decoHideState = silentExport("ep_decohide", "getState")
        
                    if decoHideState ~= nil then
                        decoHideState = not decoHideState
            
                        silentExport("ep_decohide", "setState", decoHideState)
            
                        if decoHideState then
                            outputChatBox("#CCCCCCDecorations are now #00FF00hidden", 255, 255, 255, true)
                        else
                            outputChatBox("#CCCCCCDecorations are now #FF0000visible", 255, 255, 255, true)
                        end
                    end
                end,

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
                    local state = not deathmatch.radarState
        
                    silentExport("ep_raceui", "setRadarState", state)
                    silentExport("ep_raceui", "setHeightBarState", state)
        
                    deathmatch.radarState = state
        
                    if state then
                        outputChatBox("#CCCCCCRadar is now #00FF00enabled", 255, 255, 255, true)
                    else
                        outputChatBox("#CCCCCCRadar is now #FF0000disabled", 255, 255, 255, true)
                    end
                end,
        
                toggleDeathlist = function()
                    local state = not deathmatch.deathlistState
        
                    silentExport("ep_raceui", "setDeathlistState", state)
        
                    deathmatch.deathlistState = state
        
                    if state then
                        outputChatBox("#CCCCCCDeathlist is now #00FF00enabled", 255, 255, 255, true)
                    else
                        outputChatBox("#CCCCCCDeathlist is now #FF0000disabled", 255, 255, 255, true)
                    end
                end,
        
                toggleNotifications = function()
                    local state = not deathmatch.notificationsState
        
                    silentExport("ep_raceui", "setNotificationsState", state)
        
                    deathmatch.notificationsState = state
        
                    if state then
                        outputChatBox("#CCCCCCNotifications are now #00FF00enabled", 255, 255, 255, true)
                    else
                        outputChatBox("#CCCCCCNotifications are now #FF0000disabled", 255, 255, 255, true)
                    end
                end,

                toggleNametags = function()
                    local state = not deathmatch.nametagsState
        
                    deathmatch.nametagsState = state
                    
                    local carHidePlayers = silentExport("ep_carhide", "getPlayers")

                    if state then
                        local carfadeAlpha = deathmatch.carfadeAlpha

                        for i = 1, #carHidePlayers do
                            local carHidePlayer = carHidePlayers[i]

                            silentExport("ep_raceui", "addNametag", carHidePlayer)
                            silentExport("ep_raceui", "setNametagAlpha", carHidePlayer, carfadeAlpha/255)
                        end

                        outputChatBox("#CCCCCCNametags are now #00FF00enabled", 255, 255, 255, true)
                    else
                        for i = 1, #carHidePlayers do
                            local carHidePlayer = carHidePlayers[i]

                            silentExport("ep_raceui", "removeNametag", carHidePlayer)

                            setPlayerNametagShowing(carHidePlayer, false)
                        end

                        outputChatBox("#CCCCCCNametags are now #FF0000disabled", 255, 255, 255, true)
                    end
                end,

                toggleBlips = function()
                    local state = not deathmatch.blipsState
        
                    deathmatch.blipsState = state

                    if state then
                        local createBlipAttachedTo = deathmatch.createBlipAttachedTo

                        local blipSize = deathmatch.blipSize

                        local setBlipColor = deathmatch.setBlipColor

                        local arenaPlayers = getElementChildren(event1.data.arenaElement, "player")

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

                                        createBlipAttachedTo(arenaPlayer, 0, blipSize)
                                        
                                        setBlipColor(arenaPlayer, r, g, b, 255)
                                    end
                                end
                            end
                        end

                        outputChatBox("#CCCCCCBlips are now #00FF00enabled", 255, 255, 255, true)
                    else
                        silentExport("ep_raceui", "removeRadarElementBlips")

                        deathmatch.destroyAllBlips()

                        outputChatBox("#CCCCCCBlips are now #FF0000disabled", 255, 255, 255, true)
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

                    local carHideState = silentExport("ep_carhide", "getState")

                    local cameraTarget = silentExport("ep_spectator", "getTarget")

                    local blipsState = deathmatch.blipsState

                    local carfadeAlpha = deathmatch.carfadeAlpha

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
            
                                    if blipsState then
                                        silentExport("ep_raceui", "addRadarElementBlip", arenaPlayer, nil, nil, r, g, b)
                                    end

                                    if not carHideState then
                                        if deathmatch.nametagsState then
                                            silentExport("ep_raceui", "addNametag", arenaPlayer)
                                            silentExport("ep_raceui", "setNametagAlpha", arenaPlayer, carfadeAlpha/255)
                                        end
                                    end
                                else
                                    if not carHideState then
                                        silentExport("ep_raceui", "addNametag", arenaPlayer)
                                        silentExport("ep_raceui", "setNametagAlpha", arenaPlayer, 1)
                                    end
                                end
                            end
                        end
                    end

                    local nextMapName = getElementData(arenaElement, "nextMapName", false)
        
                    if nextMapName then
                        deathmatch.setNextMapName(nextMapName)
                    end

                    deathmatch.updateUIState()
                end,

                ["ep_carhide"] = function(resource)
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    local arenaPlayers = getElementChildren(arenaElement, "player")
        
                    local cameraTarget = silentExport("ep_spectator", "getTarget")
        
                    for i = 1, #arenaPlayers do
                        local arenaPlayer = arenaPlayers[i]
        
                        if arenaPlayer ~= localPlayer then
                            if arenaPlayer ~= cameraTarget then
                                if getElementData(arenaPlayer, "state", false) == "alive" then
                                    silentExport("ep_carhide", "addPlayer", arenaPlayer)
                                end
                            end
                        end
                    end
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
                end,

                ["ep_toplist"] = function(resource)
                    local arenaElement = eventData.arenaElement

                    local mapInfo = getElementData(arenaElement, "mapInfo", false)

                    if mapInfo.directory ~= "hunter" then
                        silentExport("ep_toplist", "setTopTimesUIToggleState", true)
                    end
                end
            }
        },

        ["countdown starting"] = {
            onStateSet = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                addEventHandler("event1:deathmatch:onClientPlayerWastedInternal", arenaElement, localEventHandlers.onArenaDeathmatchPlayerWasted)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:deathmatch:onClientPlayerWastedInternal", arenaElement, localEventHandlers.onArenaDeathmatchPlayerWasted)
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

                addEventHandler("event1:deathmatch:onClientArenaCountdownValueUpdate", arenaElement, localEventHandlers.onArenaDeathmatchCountdownValueUpdate)

                addEventHandler("event1:deathmatch:onClientPlayerWastedInternal", arenaElement, localEventHandlers.onArenaDeathmatchPlayerWasted)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("lobby:ui:onStateSet", localPlayer, localEventHandlers.onClientLobbyUIStateSet)

                removeEventHandler("onClientResourceStart", root, localEventHandlers.onClientResourceStart)

                removeEventHandler("event1:deathmatch:onClientArenaCountdownValueUpdate", arenaElement, localEventHandlers.onArenaDeathmatchCountdownValueUpdate)

                removeEventHandler("event1:deathmatch:onClientPlayerWastedInternal", arenaElement, localEventHandlers.onArenaDeathmatchPlayerWasted)

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
                    deathmatch.updateCountdownState()
                end,

                onClientResourceStart = function(startedResource)
                    local data = deathmatch.data

                    local stateData = deathmatch.states[data.state]

                    local resourceStartFunction = stateData.localResourceStartFunctions[getResourceName(startedResource)]
        
                    if resourceStartFunction then
                        resourceStartFunction(startedResource)
                    end
                end,

                onArenaDeathmatchCountdownValueUpdate = function(countdownValue)
                    local data = deathmatch.data

                    local stateData = deathmatch.states[data.state]

                    silentExport("ep_raceui", "setCountdownValue", countdownValue)
                    silentExport("ep_raceui", "setCountdownState", true)

                    stateData.hideUICountdownTimer = setTimer(stateData.localTimers.hideUICountdown, 500, 1)

                    deathmatch.updateCountdownState()
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
                    deathmatch.updateCountdownState()
                end
            }
        },

        ["running"] = {
            settings = {
                splitTimesDelay = 15000
            },

            onStateSet = function(stateData)
                silentExport("ep_raceui", "startTimeLeftTimer")

                local localEventHandlers = stateData.localEventHandlers

                addEventHandler("event1:deathmatch:onClientRacePickupsUnload", localPlayer, localEventHandlers.onClientArenaDeathmatchRacePickupsUnload)
                addEventHandler("event1:deathmatch:onClientVehicleModelsSync", localPlayer, localEventHandlers.onClientArenaDeathmatchVehicleModelsSync)
                addEventHandler("event1:deathmatch:onClientPlayerWastedInternal", localPlayer, localEventHandlers.onClientArenaDeathmatchWasted)

                addEventHandler("topList:topTimes:onClientPlayerHitSplitTimeMarker", localPlayer, localEventHandlers.onClientTopTimesHitSplitTimeMarker)

                addEventHandler("mapManager:racePickup:onClientPickup", localPlayer, localEventHandlers.onClientRacePickupPickup)

                addEventHandler("onClientResourceStart", root, localEventHandlers.onClientResourceStart)

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                addEventHandler("event1:deathmatch:onClientPlayerRacePickupUnload", arenaElement, localEventHandlers.onArenaDeathmatchPlayerRacePickupUnload)
                addEventHandler("event1:deathmatch:onClientPlayerRacePickupLoad", arenaElement, localEventHandlers.onArenaDeathmatchPlayerRacePickupLoad)
                addEventHandler("event1:deathmatch:onClientPlayerSyncFunction", arenaElement, localEventHandlers.onArenaDeathmatchPlayerSyncFunction)
                addEventHandler("event1:deathmatch:onClientPlayerReachedHunterInternal", arenaElement, localEventHandlers.onArenaDeathmatchPlayerReachedHunter)
                addEventHandler("event1:deathmatch:onClientPlayerWastedInternal", arenaElement, localEventHandlers.onArenaDeathmatchPlayerWasted)

                addEventHandler("topList:topTimes:onClientPlayerHitSplitTimeMarker", arenaElement, localEventHandlers.onArenaPlayerTopTimesHitSplitTimeMarker)

                addEventHandler("onClientExplosion", arenaElement, localEventHandlers.onArenaExplosion)

                if getElementData(localPlayer, "state", false) == "alive" then
                    silentExport("ep_raceui", "startTimePassedTimer")

                    stateData:bindKillRequestKey()
                    stateData:startSplitTimesTimer()
                    stateData:startWaterCheckTimer()
                    stateData:startAfkTimer()
                    stateData:bindAfkResetKeys()

                    deathmatch.setPlayerFreezeEnabled(localPlayer, false)

                    triggerServerEvent("event1:deathmatch:onPlayerUnfreeze", localPlayer)

                    silentExport("ep_toplist", "setTopTimesSplitTimesStartTick", getTickCount())

                    stateData.unfreezeTick = getTickCount()
                else
                    triggerServerEvent("event1:deathmatch:onPlayerRequestVehicleModelsSync", localPlayer)
                end
            end,

            onStateChanging = function(stateData)
                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:deathmatch:onClientRacePickupsUnload", localPlayer, localEventHandlers.onClientArenaDeathmatchRacePickupsUnload)
                removeEventHandler("event1:deathmatch:onClientVehicleModelsSync", localPlayer, localEventHandlers.onClientArenaDeathmatchVehicleModelsSync)
                removeEventHandler("event1:deathmatch:onClientPlayerWastedInternal", localPlayer, localEventHandlers.onClientArenaDeathmatchWasted)

                removeEventHandler("topList:topTimes:onClientPlayerHitSplitTimeMarker", localPlayer, localEventHandlers.onClientTopTimesHitSplitTimeMarker)

                removeEventHandler("mapManager:racePickup:onClientPickup", localPlayer, localEventHandlers.onClientRacePickupPickup)

                removeEventHandler("onClientResourceStart", root, localEventHandlers.onClientResourceStart)

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                removeEventHandler("event1:deathmatch:onClientPlayerRacePickupUnload", arenaElement, localEventHandlers.onArenaDeathmatchPlayerRacePickupUnload)
                removeEventHandler("event1:deathmatch:onClientPlayerRacePickupLoad", arenaElement, localEventHandlers.onArenaDeathmatchPlayerRacePickupLoad)
                removeEventHandler("event1:deathmatch:onClientPlayerSyncFunction", arenaElement, localEventHandlers.onArenaDeathmatchPlayerSyncFunction)
                removeEventHandler("event1:deathmatch:onClientPlayerReachedHunterInternal", arenaElement, localEventHandlers.onArenaDeathmatchPlayerReachedHunter)
                removeEventHandler("event1:deathmatch:onClientPlayerWastedInternal", arenaElement, localEventHandlers.onArenaDeathmatchPlayerWasted)

                removeEventHandler("topList:topTimes:onClientPlayerHitSplitTimeMarker", arenaElement, localEventHandlers.onArenaPlayerTopTimesHitSplitTimeMarker)

                removeEventHandler("onClientExplosion", arenaElement, localEventHandlers.onArenaExplosion)

                stateData:unbindKillRequestKey()
                stateData:killSplitTimesTimer()
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

            startSplitTimesTimer = function(stateData)
                local localTimers = stateData.localTimers

                local settings = stateData.settings

                stateData.splitTimesTimer = setTimer(localTimers.addSplitTime, settings.splitTimesDelay, 0)
            end,

            killSplitTimesTimer = function(stateData)
                local splitTimesTimer = stateData.splitTimesTimer

                if isTimer(splitTimesTimer) then
                    killTimer(splitTimesTimer)
                end

                stateData.splitTimesTimer = nil
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

                deathmatch.afk = nil
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

                onClientArenaDeathmatchVehicleModelsSync = function(vehicleModels)
                    for vehicle, customModel in pairs(vehicleModels) do
                        if isElement(vehicle) then
                            setElementModel(vehicle, customModel)
                        end
                    end
                end,

                onClientArenaDeathmatchWasted = function()
                    local data = deathmatch.data

                    local stateData = deathmatch.states[data.state]

                    stateData:unbindKillRequestKey()
                    stateData:killWaterCheckTimer()
                    stateData:stopAfk()
                    stateData:unbindAfkResetKeys()

                    silentExport("ep_raceui", "stopTimePassedTimer")
                    
                    local timePassed = getTickCount() - stateData.unfreezeTick
                    
                    silentExport("ep_raceui", "setTimePassedTimerTime", timePassed)
                end,

                onClientTopTimesHitSplitTimeMarker = function(deltaTime)
                    local deltaTimeHex = deltaTime < 0 and "#00FF00" or "#FF0000"
    
                    local deltaTimePrefix = deltaTime < 0 and "-" or "+"

                    outputChatBox("#CCCCCCSplit time: #FFFFFF" .. deltaTimeHex .. deltaTimePrefix .. formatMS(mathAbs(deltaTime)), 255, 255, 255, true)
                end,

                onClientRacePickupPickup = function(racePickupElement)
                    local racePickupID = silentExport("ep_mapmanager", "getRacePickupData", racePickupElement, "id")

                    local racePickupType = getElementData(racePickupElement, "type", false)
                    local racePickupRespawn = getElementData(racePickupElement, "respawn", false)
                    local racePickupVehicle = getElementData(racePickupElement, "vehicle", false)

                    triggerServerEvent("event1:deathmatch:onPlayerPickupRacePickup", localPlayer, racePickupID, racePickupType, racePickupRespawn, racePickupVehicle)

                    if racePickupType == "vehiclechange" then
                        local data = deathmatch.data

                        local stateData = deathmatch.states[data.state]

                        if racePickupVehicle == 425 then
                            local unfreezeTick = stateData.unfreezeTick

                            if unfreezeTick then
                                local timePassed = getTickCount() - unfreezeTick

                                local splitTimes = silentExport("ep_toplist", "getTopTimesSplitTimes")

                                triggerServerEvent("event1:deathmatch:onPlayerReachedHunterInternal", localPlayer, timePassed, #(splitTimes or {}) > 0 and splitTimes)
                            end
                        end
                    end
                end,

                onClientResourceStart = function(startedResource)
                    local data = deathmatch.data

                    local stateData = deathmatch.states[data.state]

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

                onArenaDeathmatchPlayerReachedHunter = function()
                    triggerEvent("event1:deathmatch:onClientPlayerReachedHunter", source)
                end,

                onArenaDeathmatchPlayerWasted = function(alivePlayersCount)
                    local place = alivePlayersCount + 1

                    silentExport("ep_raceui", "addDeathlistText", "#C6C6C6" .. tostring(place) .. nth(place) .. " - #FFFFFF" .. getPlayerName(source))
                end,

                onArenaPlayerTopTimesHitSplitTimeMarker = function(deltaTime)
                    if source ~= localPlayer then
                        local cameraTarget = silentExport("ep_spectator", "getTarget")

                        if source == cameraTarget then
                            local deltaTimeHex = deltaTime < 0 and "#00FF00" or "#FF0000"
    
                            local deltaTimePrefix = deltaTime < 0 and "-" or "+"
        
                            outputChatBox(getPlayerName(source) .. " #CCCCCCSplit time: #FFFFFF" .. deltaTimeHex .. deltaTimePrefix .. formatMS(mathAbs(deltaTime)), 255, 255, 255, true)
                        end
                    end
                end,

                onArenaExplosion = function(x, y, z, type)
                    if source ~= localPlayer then
                        local vehicle = getPedOccupiedVehicle(localPlayer)
            
                        if isElement(vehicle) then
                            local vx, vy, vz = getElementPosition(vehicle)
            
                            if type == 4 or type == 5 or type == 6 or type == 7 then
                                if getDistanceBetweenPoints3D(vx, vy, vz, x, y, z) <= getElementRadius(vehicle) + 4 then
                                    cancelEvent()
                                end
                            end
                        end
                    end
                end
            },

            localKeyBinds = {
                requestKill = function()
                    triggerServerEvent("event1:deathmatch:onPlayerKill", localPlayer)
                end,

                afkReset = function()
                    local data = deathmatch.data

                    local stateData = deathmatch.states[data.state]

                    stateData:stopAfk()
                    stateData:startAfkTimer()                    
                end
            },

            localTimers = {
                addSplitTime = function()
                    local data = deathmatch.data

                    local stateData = deathmatch.states[data.state]

                    local unfreezeTick = stateData.unfreezeTick

                    if unfreezeTick then
                        local timePassed = getTickCount() - unfreezeTick

                        silentExport("ep_toplist", "addTopTimesSplitTime", timePassed)
                    end
                end,

                waterCheck = function()
                    local vehicle = getPedOccupiedVehicle(localPlayer)
            
                    if isElement(vehicle) then
                        if getVehicleType(vehicle) ~= "Boat" then
                            local x, y, z = getElementPosition(localPlayer)

                            local waterZ = getWaterLevel(x, y, z)
                            
                            if waterZ and z < waterZ - 0.5 then
                                triggerServerEvent("event1:deathmatch:onPlayerKill", localPlayer)
                            end
                        end
            
                        if not getVehicleEngineState(vehicle) then
                            setVehicleEngineState(vehicle, true)
                        end
                    end
                end,

                afk = function()
                    local data = deathmatch.data

                    local stateData = deathmatch.states[data.state]

                    if getPedControlState(localPlayer, "accelerate") or getPedControlState(localPlayer, "brake_reverse") or getPedControlState(localPlayer, "vehicle_left") or getPedControlState(localPlayer, "vehicle_right") then
                        stateData:startAfkTimer()
                    else
                        deathmatch.afk = true

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
                        triggerServerEvent("event1:deathmatch:onPlayerKill", localPlayer)

                        silentExport("ep_raceui", "setAfkState", false)

                        deathmatch.afk = nil
                    end
                end
            },

            localResourceStartFunctions = {
                ["ep_raceui"] = function(resource)
                    local data = deathmatch.data

                    local stateData = deathmatch.states[data.state]

                    local unfreezeTick = stateData.unfreezeTick

                    if unfreezeTick then
                        local timePassed = getTickCount() - unfreezeTick

                        silentExport("ep_raceui", "setTimePassedTimerTime", timePassed)
                        silentExport("ep_raceui", "startTimePassedTimer")
                    end
                end,

                ["ep_toplist"] = function(resource)
                    local data = deathmatch.data

                    local stateData = deathmatch.states[data.state]

                    local unfreezeTick = stateData.unfreezeTick

                    if unfreezeTick then
                        silentExport("ep_toplist", "setTopTimesSplitTimesStartTick", unfreezeTick)
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

                silentExport("ep_raceui", "setHeightBarState", false)

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

                    silentExport("ep_raceui", "setHeightBarState", false)
    
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
                    local data = deathmatch.data

                    local stateData = deathmatch.states[data.state]

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

                    silentExport("ep_raceui", "setHeightBarState", false)
    
                    silentExport("ep_raceui", "setNotificationsState", false)
    
                    silentExport("ep_raceui", "setNametagsState", false)
    
                    silentExport("ep_raceui", "setDeathlistState", false)
                end
            }
        },

        ["map unloading"] = {
            onStateSet = function(stateData)
                local mapLoadedStateData = deathmatch.states["map loaded"]

                local mapLoadedSharedEventHandlers = mapLoadedStateData.sharedEventHandlers

                removeEventHandler("event1:deathmatch:onClientPlayerWastedInternal", localPlayer, mapLoadedSharedEventHandlers.onClientArenaDeathmatchWasted)

                removeEventHandler("lobby:ui:onStateSet", localPlayer, mapLoadedSharedEventHandlers.onClientLobbyUIStateSet)

                removeEventHandler("carHide:onStateSet", localPlayer, mapLoadedSharedEventHandlers.onClientCarHideStateSet)

                removeEventHandler("spectator:onCameraTargetChanged", localPlayer, mapLoadedSharedEventHandlers.onClientSpectatorCameraTargetChanged)

                removeEventHandler("onClientElementDataChange", localPlayer, mapLoadedSharedEventHandlers.onClientElementDataChange)

                removeEventHandler("onClientResourceStart", root, mapLoadedSharedEventHandlers.onClientResourceStart)

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                removeEventHandler("event1:deathmatch:onClientPlayerWastedInternal", arenaElement, mapLoadedSharedEventHandlers.onArenaDeathmatchPlayerWasted)

                removeEventHandler("event1:onClientArenaNextMapSet", arenaElement, mapLoadedSharedEventHandlers.onArenaNextMapSet)

                removeEventHandler("onClientElementModelChange", arenaElement, mapLoadedSharedEventHandlers.onArenaElementModelChange)

                removeEventHandler("onClientElementStreamIn", arenaElement, mapLoadedSharedEventHandlers.onArenaElementStreamIn)

                removeEventHandler("onClientPlayerTeamChange", arenaElement, mapLoadedSharedEventHandlers.onArenaPlayerTeamChange)

                local mapLoadedSharedCommandHandlers = mapLoadedStateData.sharedCommandHandlers

                removeCommandHandler("setblipsize", mapLoadedSharedCommandHandlers.setBlipSize)

                local mapLoadedSharedKeyBinds = mapLoadedStateData.sharedKeyBinds

                unbindKey("o", "down", mapLoadedSharedKeyBinds.toggleCarHide)
                unbindKey("c", "down", mapLoadedSharedKeyBinds.toggleCarFade)
                unbindKey("j", "down", mapLoadedSharedKeyBinds.toggleDecoHide)
                unbindKey("m", "down", mapLoadedSharedKeyBinds.toggleSounds)
                unbindKey("n", "down", mapLoadedSharedKeyBinds.toggleShaders)
                unbindKey("F3", "down", mapLoadedSharedKeyBinds.toggleRadar)
                unbindKey("F4", "down", mapLoadedSharedKeyBinds.toggleDeathlist)
                unbindKey("F6", "down", mapLoadedSharedKeyBinds.toggleNotifications)
                unbindKey("F7", "down", mapLoadedSharedKeyBinds.toggleNametags)
                unbindKey("F9", "down", mapLoadedSharedKeyBinds.toggleBlips)

                silentExport("ep_raceui", "setRadarState", false)
                silentExport("ep_raceui", "removeRadarElementBlips")

                silentExport("ep_raceui", "setMapLabelState", false)
                silentExport("ep_raceui", "setNextMapLabelState", false)

                silentExport("ep_raceui", "setRequestLabelState", false)

                silentExport("ep_raceui", "setTimersState", false)
                silentExport("ep_raceui", "resetTimePassedTimer")
                silentExport("ep_raceui", "resetTimeLeftTimer")

                silentExport("ep_raceui", "setSpeedoState", false)

                silentExport("ep_raceui", "setHeightBarState", false)

                silentExport("ep_raceui", "setNotificationsState", false)

                silentExport("ep_raceui", "setNametagsState", false)
                silentExport("ep_raceui", "resetNametags")

                silentExport("ep_raceui", "setCountdownState", false)
                silentExport("ep_raceui", "setCountdownValue", -1)

                silentExport("ep_raceui", "setDeathlistState", false)
                silentExport("ep_raceui", "resetDeathlist")

                silentExport("ep_raceui", "setAfkState", false)
                silentExport("ep_raceui", "setAfkValue", nil)

                silentExport("ep_carhide", "resetPlayers", false)

                silentExport("ep_decohide", "resetModifiedObjects")

                silentExport("ep_spectator", "setState", false)
                silentExport("ep_spectator", "resetTargets")

                silentExport("ep_toplist", "setTopTimesUIState", false)
                silentExport("ep_toplist", "setTopTimesUIToggleState", false)
                silentExport("ep_toplist", "resetTopTimesSplitTimes")
                silentExport("ep_toplist", "setTopTimesSplitTimesStartTick", nil)
    
                local radarPosX = silentExport("ep_raceui", "getRadarSetting", "posX")
                local radarPosY = silentExport("ep_raceui", "getRadarSetting", "posY")
    
                silentExport("ep_raceui", "animateRadarPosition", radarPosX, radarPosY)

                local heightBarPosX = silentExport("ep_raceui", "getHeightBarSetting", "posX")
                local heightBarPosY = silentExport("ep_raceui", "getHeightBarSetting", "posY")
        
                silentExport("ep_raceui", "animateHeightBarPosition", heightBarPosX, heightBarPosY)

                local deathlistPosX = silentExport("ep_raceui", "getDeathlistSetting", "posX")
                local deathlistPosY = silentExport("ep_raceui", "getDeathlistSetting", "posY")
        
                silentExport("ep_raceui", "animateDeathlistPosition", deathlistPosX, deathlistPosY)

                deathmatch.destroyAllBlips()
                deathmatch.resetPlayersAlpha()

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

            local eventHandlers = deathmatch.eventHandlers

            addEventHandler("event1:dm:onClientMapResourceStarting", arenaElement, eventHandlers.onArenaDeathmatchMapResourceStarting)
            addEventHandler("event1:dm:onClientMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)
        
            addEventHandler("event1:os:onClientMapResourceStarting", arenaElement, eventHandlers.onArenaDeathmatchMapResourceStarting)
            addEventHandler("event1:os:onClientMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)
        
            addEventHandler("event1:hdm:onClientMapResourceStarting", arenaElement, eventHandlers.onArenaDeathmatchMapResourceStarting)
            addEventHandler("event1:hdm:onClientMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)

            addEventHandler("event1:hunter:onClientMapResourceStarting", arenaElement, eventHandlers.onArenaDeathmatchMapResourceStarting)
            addEventHandler("event1:hunter:onClientMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)
        end,

        onClientArenaDestroy = function()
            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = deathmatch.eventHandlers

            removeEventHandler("event1:dm:onClientMapResourceStarting", arenaElement, eventHandlers.onArenaDeathmatchMapResourceStarting)
            removeEventHandler("event1:dm:onClientMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)
        
            removeEventHandler("event1:os:onClientMapResourceStarting", arenaElement, eventHandlers.onArenaDeathmatchMapResourceStarting)
            removeEventHandler("event1:os:onClientMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)
        
            removeEventHandler("event1:hdm:onClientMapResourceStarting", arenaElement, eventHandlers.onArenaDeathmatchMapResourceStarting)
            removeEventHandler("event1:hdm:onClientMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)

            removeEventHandler("event1:hunter:onClientMapResourceStarting", arenaElement, eventHandlers.onArenaDeathmatchMapResourceStarting)
            removeEventHandler("event1:hunter:onClientMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)

            deathmatch.stop()
        end,

        ---

        onArenaDeathmatchMapResourceStarting = function()
            deathmatch.start()
        end,

        onArenaDeathmatchMapResourceUnloading = function()
            deathmatch.stop()
        end,

        ---

        onClientMapLoaderMapResourceAllElementsLoaded = function()
            deathmatch.setObjectsDrawDistance(300)
            deathmatch.updateGhostmodeCollisions(true)

            silentExport("ep_decohide", "updateObjects")

            triggerServerEvent("event1:deathmatch:onPlayerAllMapResourceElementsLoaded", localPlayer)
        end,

        onArenaDeathmatchStateSet = function(state)
            deathmatch.setState(state)
        end
    },

    armedVehicleIDs = { [425] = true, [447] = true, [520] = true, [430] = true, [464] = true, [432] = true },

    radarState = true,

    notificationsState = true,

    deathlistState = true,

    nametagsState = true,

    blipsState = true,

    carfadeState = true,

    carfadeAlpha = 32,

    blipSize = 1
}

event1.managers.deathmatch = deathmatch

addEvent("event1:onClientArenaCreated")
addEvent("event1:onClientArenaDestroy")

addEvent("event1:dm:onClientMapResourceStarting")
addEvent("event1:dm:onClientMapResourceUnloading")

addEvent("event1:os:onClientMapResourceStarting")
addEvent("event1:os:onClientMapResourceUnloading")

addEvent("event1:hdm:onClientMapResourceStarting")
addEvent("event1:hdm:onClientMapResourceUnloading")

addEvent("event1:hunter:onClientMapResourceStarting")
addEvent("event1:hunter:onClientMapResourceUnloading")

addEvent("lobby:ui:onStateSet")

addEvent("carHide:onStateSet")

addEvent("spectator:onCameraTargetChanged")

addEvent("topList:topTimes:onClientPlayerHitSplitTimeMarker")

addEvent("mapManager:mapLoader:onClientMapResourceAllElementsLoaded")
addEvent("mapManager:racePickup:onClientPickup")

addEvent("onClientPlayerTeamChange")

addEvent("event1:deathmatch:onClientPlayerLoaded", true)
addEvent("event1:deathmatch:onClientPlayerUnloaded", true)
addEvent("event1:deathmatch:onClientVehicleModelsSync", true)
addEvent("event1:deathmatch:onClientPlayerWastedInternal", true)
addEvent("event1:deathmatch:onClientRacePickupsUnload", true)
addEvent("event1:deathmatch:onClientPlayerRacePickupUnload", true)
addEvent("event1:deathmatch:onClientPlayerRacePickupLoad", true)
addEvent("event1:deathmatch:onClientPlayerReachedHunterInternal", true)
addEvent("event1:deathmatch:onClientPlayerSyncFunction", true)
addEvent("event1:deathmatch:onClientArenaStateSetInternal", true)
addEvent("event1:deathmatch:onClientArenaCountdownValueUpdate", true)

addEvent("event1:onClientArenaNextMapSet", true)

do
    local eventHandlers = deathmatch.eventHandlers

    addEventHandler("event1:onClientArenaCreated", localPlayer, eventHandlers.onClientArenaCreated)
    addEventHandler("event1:onClientArenaDestroy", localPlayer, eventHandlers.onClientArenaDestroy)
end