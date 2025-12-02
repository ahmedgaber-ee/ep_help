local mathMin = math.min
local mathFloor = math.floor

local stringFormat = string.format

local debuggerPrepareString = debugger.prepareString

local formatMS = function(ms)
    return stringFormat("%02d:%02d:%03d", tostring(mathFloor(ms/60000)), tostring(mathFloor((ms/1000) % 60)), tostring(mathFloor(ms % 1000)))
end

local tableCount = function(table)
    local count = 0

    for _ in pairs(table) do
        count = count + 1
    end

    return count
end

local triggerClientResourceEvent = function(resource, ...)
    if getResourceState(resource) == "running" then
        return triggerClientEvent(...)
    end
end

local silentExport

do
    local validStates = { ["running"] = true, ["starting"] = true }

    silentExport = function(resourceName, functionName, ...)
        local resource = getResourceFromName(resourceName)
        
        if resource and validStates[getResourceState(resource)] then
            return call(resource, functionName, ...)
        end
    end
end

local resourceName = getResourceName(resource)

local deathmatch

deathmatch = {
    start = function(mapResource)
        if not deathmatch.data then
            local gamemodeElements = silentExport("ep_mapmanager", "getMapData", mapResource, "data", "gamemodeElements")

            if gamemodeElements then
                local mapAllSpawnpoints = {}

                for i = 1, #gamemodeElements do
                    local data = gamemodeElements[i]

                    local mapGamemodeElements = data[2]

                    local mapSpawnpoints = mapGamemodeElements["11"]

                    if mapSpawnpoints then
                        for j = 1, #mapSpawnpoints do
                            mapAllSpawnpoints[#mapAllSpawnpoints + 1] = mapSpawnpoints[j]
                        end
                    end
                end

                if #mapAllSpawnpoints > 0 then
                    local data = {}

                    data.mapResource = mapResource
                    data.mapSpawnpoints = mapAllSpawnpoints
                    
                    data.playerSpawnpointVehicles = {}

                    deathmatch.data = data

                    deathmatch.setState("map loaded")
                else
                    outputDebugString(debuggerPrepareString("Failed to start map. No spawnpoints found (resourceName: " .. tostring(getResourceName(mapResource)) .. ").", 2))

                    event1.loadMap()
                end
            end
        end
    end,

    stop = function()
        local data = deathmatch.data

        if data then
            deathmatch.setState("map unloading")

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
                local data = deathmatch.data

                local oldStateData = states[oldState]

                if oldStateData then
                    oldStateData:onStateChanging()
                end

                data.state = state
                
                stateData:onStateSet()

                local eventData = event1.data

                local arenaElement = eventData.arenaElement
                
                setElementData(arenaElement, "state", state--[[ , "subscribe" *]])
    
                local sourceElement = eventData.sourceElement

                triggerClientResourceEvent(resource, arenaElement, "event1:deathmatch:onClientArenaStateSetInternal", sourceElement, state)

                triggerEvent("event1:deathmatch:onArenaStateSet", sourceElement, state)
            end
        end
    end,

    spawnPlayerAtSpawnpoint = function(player, spawnpointID)
        local data = deathmatch.data

        local spawnpoint = data.mapSpawnpoints[spawnpointID]

        local posX, posY, posZ = unpack(spawnpoint, 3, 5)
        local rotX, rotY, rotZ = unpack(spawnpoint, 6, 8)

        local modelID = spawnpoint[9]

        local vehicle = createVehicle(modelID, posX, posY, posZ, rotX, rotY, rotZ)

        local eventData = event1.data

        local arenaElement = eventData.arenaElement

        setElementParent(vehicle, arenaElement)
        setElementData(vehicle, "spawnpointID", spawnpointID, "local")

        local dimension = getElementDimension(arenaElement)

        setElementDimension(vehicle, dimension)
        setElementFrozen(vehicle, true)
        setVehicleDamageProof(vehicle, true)
        setElementCollisionsEnabled(vehicle, false)
        setVehicleOverrideLights(vehicle, 2)

        spawnPlayer(player, posX, posY, posZ, 0, 0, 0, dimension)
        fadeCamera(player, true)
        setCameraTarget(player, player)
        setElementFrozen(player, true)
        
        setPedStat(player, 160, 1000)
        setPedStat(player, 229, 1000)
        setPedStat(player, 230, 1000)

        warpPedIntoVehicle(player, vehicle)
        setCameraTarget(player, player)

        deathmatch.destroyPlayerSpawnpointVehicle(player)

        data.playerSpawnpointVehicles[player] = vehicle
    end,

    unfreezePlayerSpawnpointVehicle = function(player)
        local data = deathmatch.data

        local vehicle = data.playerSpawnpointVehicles[player]

        if isElement(vehicle) then
            setElementFrozen(vehicle, false)
            setVehicleDamageProof(vehicle, false)
            setElementCollisionsEnabled(vehicle, true)
        end

        setElementFrozen(player, false)
    end,

    destroyPlayerSpawnpointVehicle = function(player)
        local data = deathmatch.data

        local playerSpawnpointVehicles = data.playerSpawnpointVehicles

        local vehicle = playerSpawnpointVehicles[player]

        if isElement(vehicle) then
            destroyElement(vehicle)
        end

        playerSpawnpointVehicles[player] = nil
    end,

    destroyAllPlayerSpawnpointVehicles = function()
        local data = deathmatch.data

        for player, vehicle in pairs(data.playerSpawnpointVehicles) do
            if isElement(vehicle) then
                destroyElement(vehicle)
            end
        end

        data.playerSpawnpointVehicles = {}
    end,

    addPlayerAllElementDataSubscriptions = function(player)
        setElementData(player, "state", nil--[[ , "subscribe" *]])

        local eventData = event1.data

        local arenaElement = eventData.arenaElement

        local arenaPlayers = getElementChildren(arenaElement, "player")

        addElementDataSubscriber(arenaElement, "state", player)
        addElementDataSubscriber(arenaElement, "mapDuration", player)

        for i = 1, #arenaPlayers do
            local arenaPlayer = arenaPlayers[i]

            addElementDataSubscriber(arenaPlayer, "state", player)
            addElementDataSubscriber(player, "state", arenaPlayer)
        end
    end,

    removePlayerAllElementDataSubscriptions = function(player)
        setElementData(player, "state", nil--[[ , "subscribe" *]])

        local eventData = event1.data

        local arenaElement = eventData.arenaElement

        local arenaPlayers = getElementChildren(arenaElement, "player")

        removeElementDataSubscriber(arenaElement, "state", player)
        removeElementDataSubscriber(arenaElement, "mapDuration", player)

        for i = 1, #arenaPlayers do
            local arenaPlayer = arenaPlayers[i]

            removeElementDataSubscriber(arenaPlayer, "state", player)
            removeElementDataSubscriber(player, "state", arenaPlayer)
        end
    end,

    getPlayerVehicle = function(player)
        local data = deathmatch.data

        return data.playerSpawnpointVehicles[player]
    end,

    states = {
        ["map loaded"] = {
            settings = {
                forcedCountdownTimerDelay = 15000,

                defaultMapDuration = 1800
            },

            onStateSet = function(stateData)
                stateData.playersToLoad = {}
                
                stateData.playersToLoadCount = 0

                stateData:cacheMapDuration()
                stateData:loadPlayers()
                stateData:startForcedCountdownTimer()

                local data = deathmatch.data

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local mapResource = data.mapResource

                silentExport("ep_toplist", "sendTopTimes", mapResource, nil, getElementData(arenaElement, "mapInfo", false).name, arenaElement)
                
                if getElementData(arenaElement, "deathmatchTrainingMode", false) then
                    silentExport("ep_toplist", "sendTopTimesSplitTimes", mapResource, nil, arenaElement)
                end

                local sharedEventHandlers = stateData.sharedEventHandlers

                addEventHandler("event1:onPlayerArenaJoin", arenaElement, sharedEventHandlers.onArenaPlayerJoin)
                addEventHandler("event1:onPlayerArenaQuit", arenaElement, sharedEventHandlers.onArenaPlayerQuit)

                addEventHandler("topList:topTimes:onPlayerThisResourceStart", arenaElement, sharedEventHandlers.onArenaPlayerTopTimesResourceStart)
                addEventHandler("topList:topTimes:onTopTimeUpdated", arenaElement, sharedEventHandlers.onArenaPlayerTopTimeUpdated)
                addEventHandler("topList:topTimes:onTopTimeAdded", arenaElement, sharedEventHandlers.onArenaPlayerTopTimeAdded)
                addEventHandler("topList:topTimes:onTopTimeDeleted", arenaElement, sharedEventHandlers.onArenaPlayerTopTimeDeleted)
                addEventHandler("topList:topTimes:onTopTimeRenamed", arenaElement, sharedEventHandlers.onArenaPlayerTopTimeRenamed)

                addEventHandler("onVehicleStartExit", arenaElement, sharedEventHandlers.onArenaVehicleStartExit)
                addEventHandler("onVehicleExit", arenaElement, sharedEventHandlers.onArenaVehicleExit)
                addEventHandler("onElementDestroy", arenaElement, sharedEventHandlers.onArenaElementDestroy)

                local sharedCommandHandlers = stateData.sharedCommandHandlers

                addCommandHandler("deletetoptime", sharedCommandHandlers.deleteTopTime)
                addCommandHandler("renametoptime", sharedCommandHandlers.renameTopTime)
                addCommandHandler("toggletrainingmode", sharedCommandHandlers.toggleTrainingMode)

                local localEventHandlers = stateData.localEventHandlers

                addEventHandler("event1:deathmatch:onPlayerAllMapResourceElementsLoaded", arenaElement, localEventHandlers.onArenaDeathmatchPlayerAllMapResourceElementsLoaded)

                addEventHandler("event1:deathmatch:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
                addEventHandler("event1:deathmatch:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaDeathmatchPlayerQuit)

                addEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:deathmatch:onPlayerAllMapResourceElementsLoaded", arenaElement, localEventHandlers.onArenaDeathmatchPlayerAllMapResourceElementsLoaded)

                removeEventHandler("event1:deathmatch:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
                removeEventHandler("event1:deathmatch:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaDeathmatchPlayerQuit)

                removeEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)

                stateData:killForcedCountdownTimer()

                stateData.playersToLoadCount = nil

                stateData.playersToLoad = nil
            end,

            cacheMapDuration = function(stateData)
                local data = deathmatch.data

                local mapSettings = silentExport("ep_mapmanager", "getMapData", data.mapResource, "data", "settings")

                local mapDuration

                for i = 1, #mapSettings do
                    local mapSetting = mapSettings[i]

                    if mapSetting[1] == 11 then
                        mapDuration = mapSetting[2]
                    end
                end

                local eventData = event1.data

                setElementData(eventData.arenaElement, "mapDuration", mathMin((tonumber(mapDuration) or stateData.settings.defaultMapDuration), 5940)*1000--[[ , "subscribe" *]])
            end,

            loadPlayers = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local arenaPlayers = getElementChildren(arenaElement, "player")
                
                local addPlayerAllElementDataSubscriptions = deathmatch.addPlayerAllElementDataSubscriptions
                
                local spawnPlayerAtSpawnpoint = deathmatch.spawnPlayerAtSpawnpoint

                local data = deathmatch.data
                
                local spawnpointsCount = #data.mapSpawnpoints
                
                for i = 1, #arenaPlayers do
                    local arenaPlayer = arenaPlayers[i]
                    
                    addPlayerAllElementDataSubscriptions(arenaPlayer)

                    setElementData(arenaPlayer, "state", "not ready"--[[ , "subscribe" *]])

                    --spawnPlayerAtSpawnpoint(arenaPlayer, (i - 1) % spawnpointsCount + 1)
                    spawnPlayerAtSpawnpoint(arenaPlayer, 1)
                    
                    stateData:addPlayerToLoadQueue(arenaPlayer)
                end
            end,

            checkForCountdown = function(stateData)
                if stateData:arePlayersLoaded() then
                    stateData:killForcedCountdownTimer()

                    local loadedPlayers = stateData:getLoadedPlayers()

                    stateData.alivePlayers = loadedPlayers

                    stateData.alivePlayersCount = tableCount(loadedPlayers)

                    deathmatch.setState("countdown starting")
                end
            end,

            startForcedCountdownTimer = function(stateData)
                local localTimers = stateData.localTimers

                local settings = stateData.settings
                
                stateData.forcedCountdownTimer = setTimer(localTimers.forcedCountdown, settings.forcedCountdownTimerDelay, 1)
            end,
            
            killForcedCountdownTimer = function(stateData)
                local forcedCountdownTimer = stateData.forcedCountdownTimer
                
                if isTimer(forcedCountdownTimer) then
                    killTimer(forcedCountdownTimer)
                end
                
                stateData.forcedCountdownTimer = nil
            end,

            addPlayerToLoadQueue = function(stateData, player)
                local playersToLoad = stateData.playersToLoad

                if not playersToLoad[player] then
                    playersToLoad[player] = {}

                    stateData.playersToLoadCount = stateData.playersToLoadCount + 1
                end
            end,

            removePlayerFromLoadQueue = function(stateData, player)
                local playersToLoad = stateData.playersToLoad

                if playersToLoad[player] then
                    stateData:setPlayerUnloaded(player)

                    playersToLoad[player] = nil
                    
                    stateData.playersToLoadCount = stateData.playersToLoadCount - 1

                    triggerEvent("onPlayerWasted", player)
                end
            end,

            setPlayerLoaded = function(stateData, player)
                local playerData = stateData.playersToLoad[player]

                if playerData then
                    if not playerData.loaded then
                        playerData.loaded = true

                        local eventData = event1.data

                        triggerClientResourceEvent(resource, eventData.arenaElement, "event1:deathmatch:onClientPlayerLoaded", player)
                    end
                end
            end,

            setPlayerUnloaded = function(stateData, player)
                local playerData = stateData.playersToLoad[player]

                if playerData then
                    if playerData.loaded then
                        playerData.loaded = nil

                        local eventData = event1.data

                        triggerClientResourceEvent(resource, eventData.arenaElement, "event1:deathmatch:onClientPlayerUnloaded", player)
                    end
                end
            end,

            setPlayerSpawnpointID = function(stateData, player, spawnpointID)
                local data = deathmatch.data

                local spawnpoint = data.mapSpawnpoints[spawnpointID]
                
                local posX, posY, posZ = unpack(spawnpoint, 3, 5)
                local rotX, rotY, rotZ = unpack(spawnpoint, 6, 8)
                
                local modelID = spawnpoint[9]

                local vehicle = getPedOccupiedVehicle(player)

                setElementData(vehicle, "spawnpointID", spawnpointID, "local")

                setElementPosition(vehicle, posX, posY, posZ)
                setElementRotation(vehicle, rotX, rotY, rotZ)
                setElementModel(vehicle, modelID)

                setCameraTarget(player, player)
            end,

            arePlayersLoaded = function(stateData)
                local allPlayersLoaded = false

                local loadedPlayersCount = 0

                for player, stateData in pairs(stateData.playersToLoad) do
                    if stateData.loaded then
                        loadedPlayersCount = loadedPlayersCount + 1
                    end
                end

                return loadedPlayersCount == stateData.playersToLoadCount
            end,

            getLoadedPlayers = function(stateData)
                local loadedPlayers = {}

                for player, stateData in pairs(stateData.playersToLoad) do
                    if stateData.loaded then
                        loadedPlayers[player] = true
                    end
                end

                return loadedPlayers
            end,

            getNotLoadedPlayers = function(stateData)
                local notLoadedPlayers = {}

                for player, stateData in pairs(stateData.playersToLoad) do
                    if not stateData.loaded then
                        notLoadedPlayers[player] = true
                    end
                end

                return notLoadedPlayers
            end,

            sharedEventHandlers = {
                onArenaPlayerJoin = function()
                    deathmatch.addPlayerAllElementDataSubscriptions(source)

                    local data = deathmatch.data

                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    local mapResource = data.mapResource

                    silentExport("ep_toplist", "sendTopTimes", mapResource, nil, getElementData(arenaElement, "mapInfo", false).name, source)

                    if getElementData(arenaElement, "deathmatchTrainingMode", false) then
                        silentExport("ep_toplist", "sendTopTimesSplitTimes", mapResource, nil, source)
                    end

                    triggerEvent("event1:deathmatch:onPlayerArenaJoin", source)
                end,

                onArenaPlayerQuit = function()
                    triggerEvent("event1:deathmatch:onPlayerArenaQuit", source)

                    silentExport("ep_toplist", "unloadTopTimes", source)
                    silentExport("ep_toplist", "unloadTopTimesSplitTimes", source)

                    deathmatch.removePlayerAllElementDataSubscriptions(source)
                end,

                onArenaPlayerTopTimesResourceStart = function()
                    local data = deathmatch.data

                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement
        
                    local mapResource = data.mapResource

                    silentExport("ep_toplist", "sendTopTimes", mapResource, nil, getElementData(arenaElement, "mapInfo", false).name, source)

                    if getElementData(arenaElement, "deathmatchTrainingMode", false) then
                        silentExport("ep_toplist", "sendTopTimesSplitTimes", mapResource, nil, source)
                    end
                end,

                onArenaPlayerTopTimeUpdated = function(resource, arenaID, player, time, oldArenaTime, arenaPosition, oldArenaPosition, position, oldPosition)
                    local differenceText = "#00FF00(-" .. formatMS(oldArenaTime - time) .. ")"

                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    if position == 1 and getElementData(arenaElement, "deathmatchTrainingMode", false) then
                        local data = deathmatch.data

                        local mapResource = data.mapResource

                        silentExport("ep_toplist", "unloadTopTimesSplitTimes", arenaElement)
                        silentExport("ep_toplist", "sendTopTimesSplitTimes", mapResource, nil, arenaElement)
                    end

                    outputChatBox(getPlayerName(player) .. " #CCCCCChas made a new top time with time: #FFFFFF" .. formatMS(time) .. " " .. differenceText .. " #CCCCCCand position: #FFFFFF" .. position .. " #CCCCCC(old position: #FFFFFF" .. oldPosition .. "#CCCCCC)", arenaElement, 255, 255, 255, true)
                end,

                onArenaPlayerTopTimeAdded = function(resource, arenaID, player, time, arenaPosition, position)
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    if position == 1 and getElementData(arenaElement, "deathmatchTrainingMode", false) then
                        local data = deathmatch.data

                        local mapResource = data.mapResource

                        silentExport("ep_toplist", "unloadTopTimesSplitTimes", arenaElement)
                        silentExport("ep_toplist", "sendTopTimesSplitTimes", mapResource, nil, arenaElement)
                    end

                    outputChatBox(getPlayerName(player) .. " #CCCCCChas made a new top time with time: #FFFFFF" .. formatMS(time) .. " #CCCCCCand position: #FFFFFF" .. position, arenaElement, 255, 255, 255, true)
                end,

                onArenaPlayerTopTimeDeleted = function(resource, arenaID, position, playerName)
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    if position == 1 and getElementData(arenaElement, "deathmatchTrainingMode", false) then
                        local data = deathmatch.data

                        local mapResource = data.mapResource

                        silentExport("ep_toplist", "unloadTopTimesSplitTimes", arenaElement)
                        silentExport("ep_toplist", "sendTopTimesSplitTimes", mapResource, nil, arenaElement)
                    end

                    outputChatBox("#CCCCCCTop time at position: #FFFFFF" .. position .. " #CCCCCC- #FFFFFF" .. playerName .. " #CCCCCChas been deleted by #FFFFFF" .. getPlayerName(source), arenaElement, 255, 255, 255, true)
                end,

                onArenaPlayerTopTimeRenamed = function(resource, arenaID, position, name, oldPlayerName)
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    outputChatBox("#CCCCCCTop time at position: #FFFFFF" .. position .. " #CCCCCC- #FFFFFF" .. oldPlayerName .. " #CCCCCChas been renamed to: #FFFFFF" .. name .. " #CCCCCCby #FFFFFF" .. getPlayerName(source), arenaElement, 255, 255, 255, true)
                end,

                onArenaVehicleStartExit = function()
                    cancelEvent()
                end,

                onArenaVehicleExit = function(player)
                    triggerEvent("onPlayerWasted", player)
                end,

                onArenaElementDestroy = function()
                    if getElementType(source) == "vehicle" then
                        local player = getVehicleOccupant(source)

                        if player then
                            if deathmatch.getPlayerVehicle(player) then
                                triggerEvent("onPlayerWasted", player)
                            end
                        end
                    end
                end
            },

            sharedCommandHandlers = {
                deleteTopTime = function(player, commandName, position)
                    if hasObjectPermissionTo(player, "resource." .. resourceName .. ".deathmatch_cmd_" .. commandName, false) then
                        local eventData = event1.data

                        local arenaElement = eventData.arenaElement
            
                        local playerArenaElement = event1.getPlayerArenaElement(player)
            
                        if playerArenaElement == arenaElement then
                            position = tonumber(position)

                            if position then
                                local data = deathmatch.data

                                local mapResource = data.mapResource

                                local eventData = event1.data

                                local arenaElement = eventData.arenaElement

                                silentExport("ep_toplist", "deleteTopTime", mapResource, nil, position, player)
                                silentExport("ep_toplist", "sendTopTimes", mapResource, nil, nil, arenaElement)
                            else
                                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [position]", player, 255, 255, 255, true)
                            end
                        end
                    end
                end,

                renameTopTime = function(player, commandName, position, name)
                    if hasObjectPermissionTo(player, "resource." .. resourceName .. ".deathmatch_cmd_" .. commandName, false) then
                        local eventData = event1.data

                        local arenaElement = eventData.arenaElement
            
                        local playerArenaElement = event1.getPlayerArenaElement(player)
            
                        if playerArenaElement == arenaElement then
                            position = tonumber(position)

                            if position then
                                if name then
                                    local data = deathmatch.data

                                    local mapResource = data.mapResource

                                    local eventData = event1.data

                                    local arenaElement = eventData.arenaElement
        
                                    silentExport("ep_toplist", "renameTopTime", mapResource, nil, position, name, player)
                                    silentExport("ep_toplist", "sendTopTimes", mapResource, nil, nil, arenaElement)
                                else
                                    outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [position] [name]", player, 255, 255, 255, true)
                                end
                            else
                                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [position] [name]", player, 255, 255, 255, true)
                            end
                        end
                    end
                end,

                toggleTrainingMode = function(player, commandName)
                    if hasObjectPermissionTo(player, "resource." .. resourceName .. ".deathmatch_cmd_" .. commandName, false) then
                        local eventData = event1.data

                        local arenaElement = eventData.arenaElement
            
                        local playerArenaElement = event1.getPlayerArenaElement(player)
            
                        if playerArenaElement == arenaElement then
                            local newState = not getElementData(arenaElement, "deathmatchTrainingMode", false)

                            setElementData(arenaElement, "deathmatchTrainingMode", newState)

                            if newState then
                                local data = deathmatch.data

                                local mapResource = data.mapResource

                                silentExport("ep_toplist", "sendTopTimesSplitTimes", mapResource, nil, arenaElement)

                                outputChatBox("#CCCCCCTraining mode has been #00FF00enabled #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                            else
                                silentExport("ep_toplist", "unloadTopTimesSplitTimes", arenaElement)

                                outputChatBox("#CCCCCCTraining mode has been #FF0000disabled #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                            end
                        end
                    end
                end,
            },

            localEventHandlers = {
                onArenaDeathmatchPlayerAllMapResourceElementsLoaded = function()
                    if source == client then
                        local data = deathmatch.data

                        local stateData = deathmatch.states[data.state]
    
                        if stateData.playersToLoad[client] then
                            setElementData(client, "state", "alive"--[[ , "subscribe" *]])
    
                            stateData:setPlayerLoaded(client)
                            stateData:checkForCountdown()
                        end
                    end
                end,

                onArenaDeathmatchPlayerJoin = function()
                    setElementData(source, "state", "not ready"--[[ , "subscribe" *]])

                    local eventData = event1.data

                    local data = deathmatch.data

                    local arenaPlayers = getElementChildren(eventData.arenaElement, "player")

                    --deathmatch.spawnPlayerAtSpawnpoint(source, (#arenaPlayers + 1 - 1) % #data.mapSpawnpoints + 1)
                    deathmatch.spawnPlayerAtSpawnpoint(source, 1)

                    local stateData = deathmatch.states[data.state]

                    stateData:addPlayerToLoadQueue(source)

                    triggerEvent("event1:deathmatch:onPlayerJoinSpawn", source)
                end,

                onArenaDeathmatchPlayerQuit = function()
                    local data = deathmatch.data

                    local stateData = deathmatch.states[data.state]
                    
                    stateData:removePlayerFromLoadQueue(source)
                    stateData:checkForCountdown()
                end,

                onArenaPlayerWasted = function()
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    local data = deathmatch.data

                    local stateData = deathmatch.states[data.state]

                    local playersToLoad = stateData.playersToLoad
                    
                    if playersToLoad[source] then
                        local arenaPlayers = getElementChildren(arenaElement, "player")

                        --deathmatch.spawnPlayerAtSpawnpoint(source, (#arenaPlayers + 1 - 1) % #data.mapSpawnpoints + 1)
                        deathmatch.spawnPlayerAtSpawnpoint(source, 1)
                    else
                        spawnPlayer(source, 0, 0, 0, 0, 0, 0, getElementDimension(arenaElement))
                        setElementFrozen(source, true)

                        if getElementData(source, "state", false) ~= "dead" then
                            setElementData(source, "state", "dead"--[[ , "subscribe" *]])
    
                            local playerVehicle = deathmatch.getPlayerVehicle(source)

                            if isElement(playerVehicle) then
                                setElementPosition(playerVehicle, 0, 0, 0)
                                setElementRotation(playerVehicle, 0, 0, 0)
                                setElementFrozen(playerVehicle, true)
                                setVehicleDamageProof(playerVehicle, true)
                                setElementCollisionsEnabled(playerVehicle, false)
                            end

                            triggerClientResourceEvent(resource, arenaElement, "event1:deathmatch:onClientPlayerWastedInternal", source)

                            triggerEvent("event1:deathmatch:onPlayerWasted", source)

                            if not next(playersToLoad) then
                                deathmatch.setState("ended")
                            end
                        end
                    end
                end
            },

            localTimers = {
                forcedCountdown = function()
                    local data = deathmatch.data

                    local stateData = deathmatch.states[data.state]

                    local loadedPlayers = stateData:getLoadedPlayers()

                    if next(loadedPlayers) then
                        local notLoadedPlayers = stateData:getNotLoadedPlayers()

                        if next(notLoadedPlayers) then
                            local removePlayerFromLoadQueue = stateData.removePlayerFromLoadQueue

                            for player in pairs(notLoadedPlayers) do
                                removePlayerFromLoadQueue(stateData, player)
                            end
                        end

                        stateData.alivePlayers = loadedPlayers

                        stateData.alivePlayersCount = tableCount(loadedPlayers)

                        deathmatch.setState("countdown starting")
                    else
                        deathmatch.setState("ended")
                    end
                end
            }
        },

        ["countdown starting"] = {
            settings = {
                countdownDelay = 5000
            },

            onStateSet = function(stateData)
                stateData:startCountdownStartTimer()

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                addEventHandler("event1:deathmatch:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
                addEventHandler("event1:deathmatch:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaDeathmatchPlayerQuit)

                addEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:deathmatch:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
                removeEventHandler("event1:deathmatch:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaDeathmatchPlayerQuit)

                removeEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)

                stateData:killCountdownStartTimer()
            end,

            startCountdownStartTimer = function(stateData)
                local localTimers = stateData.localTimers

                local settings = stateData.settings

                stateData.countdownStartTimer = setTimer(localTimers.countdownStart, settings.countdownDelay, 1)
            end,

            killCountdownStartTimer = function(stateData)
                local countdownStartTimer = stateData.countdownStartTimer

                if isTimer(countdownStartTimer) then
                    killTimer(countdownStartTimer)
                end

                stateData.countdownStartTimer = nil
            end,

            localEventHandlers = {
                onArenaDeathmatchPlayerJoin = function()
                    setElementData(source, "state", "dead"--[[ , "subscribe" *]])
                end,

                onArenaDeathmatchPlayerQuit = function()
                    triggerEvent("onPlayerWasted", source)
                end,

                onArenaPlayerWasted = function()
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    spawnPlayer(source, 0, 0, 0, 0, 0, 0, getElementDimension(arenaElement))
                    setElementFrozen(source, true)

                    local mapLoadedStateData = deathmatch.states["map loaded"]

                    local alivePlayers = mapLoadedStateData.alivePlayers

                    if alivePlayers[source] then
                        setElementData(source, "state", "dead"--[[ , "subscribe" *]])
    
                        local playerVehicle = deathmatch.getPlayerVehicle(source)

                        if isElement(playerVehicle) then
                            setElementPosition(playerVehicle, 0, 0, 0)
                            setElementRotation(playerVehicle, 0, 0, 0)
                            setElementFrozen(playerVehicle, true)
                            setVehicleDamageProof(playerVehicle, true)
                            setElementCollisionsEnabled(playerVehicle, false)
                        end
    
                        local alivePlayersCount = mapLoadedStateData.alivePlayersCount - 1
    
                        mapLoadedStateData.alivePlayersCount = alivePlayersCount
                        
                        alivePlayers[source] = nil

                        triggerClientResourceEvent(resource, arenaElement, "event1:deathmatch:onClientPlayerWastedInternal", source, alivePlayersCount)

                        triggerEvent("event1:deathmatch:onPlayerWasted", source)
    
                        if not next(alivePlayers) then
                            deathmatch.setState("ended")
                        end
                    end
                end
            },

            localTimers = {
                countdownStart = function()
                    deathmatch.setState("countdown started")
                end
            }
        },

        ["countdown started"] = {
            onStateSet = function(stateData)
                stateData:startCountdownTimer()

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                addEventHandler("event1:deathmatch:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
                addEventHandler("event1:deathmatch:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaDeathmatchPlayerQuit)

                addEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:deathmatch:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
                removeEventHandler("event1:deathmatch:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaDeathmatchPlayerQuit)

                removeEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)

                stateData:killCountdownTimer()
            end,

            startCountdownTimer = function(stateData)
                local localTimers = stateData.localTimers

                stateData.countdownTimer = setTimer(localTimers.countdown, 1000, 4)
            end,

            killCountdownTimer = function(stateData)
                local countdownTimer = stateData.countdownTimer

                if isTimer(countdownTimer) then
                    killTimer(countdownTimer)
                end

                stateData.countdownTimer = nil
            end,

            localEventHandlers = {
                onArenaDeathmatchPlayerJoin = function()
                    setElementData(source, "state", "dead"--[[ , "subscribe" *]])
                end,

                onArenaDeathmatchPlayerQuit = function()
                    triggerEvent("onPlayerWasted", source)
                end,

                onArenaPlayerWasted = function()
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    spawnPlayer(source, 0, 0, 0, 0, 0, 0, getElementDimension(arenaElement))
                    setElementFrozen(source, true)

                    local mapLoadedStateData = deathmatch.states["map loaded"]

                    local alivePlayers = mapLoadedStateData.alivePlayers

                    if alivePlayers[source] then
                        setElementData(source, "state", "dead"--[[ , "subscribe" *]])
    
                        local playerVehicle = deathmatch.getPlayerVehicle(source)

                        if isElement(playerVehicle) then
                            setElementPosition(playerVehicle, 0, 0, 0)
                            setElementRotation(playerVehicle, 0, 0, 0)
                            setElementFrozen(playerVehicle, true)
                            setVehicleDamageProof(playerVehicle, true)
                            setElementCollisionsEnabled(playerVehicle, false)
                        end
    
                        local alivePlayersCount = mapLoadedStateData.alivePlayersCount - 1
                        
                        mapLoadedStateData.alivePlayersCount = alivePlayersCount
                        
                        alivePlayers[source] = nil
    
                        triggerClientResourceEvent(resource, arenaElement, "event1:deathmatch:onClientPlayerWastedInternal", source, alivePlayersCount)

                        triggerEvent("event1:deathmatch:onPlayerWasted", source)
    
                        if not next(alivePlayers) then
                            deathmatch.setState("ended")
                        end
                    end
                end
            },

            localTimers = {
                countdown = function()
                    local remaining, executesRemaining, timeInterval = getTimerDetails(sourceTimer)

                    local countdownValue = executesRemaining - 1

                    local eventData = event1.data

                    triggerClientResourceEvent(resource, eventData.arenaElement, "event1:deathmatch:onClientArenaCountdownValueUpdate", eventData.sourceElement, countdownValue)

                    if countdownValue == 0 then
                        deathmatch.setState("running")
                    end
                end
            }
        },

        ["running"] = {
            onStateSet = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                stateData.unloadedRacePickupIDs = {}

                stateData.racePickupRespawnTimers = {}

                stateData:startTimeIsUpTimer()

                local localEventHandlers = stateData.localEventHandlers

                addEventHandler("event1:deathmatch:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
                addEventHandler("event1:deathmatch:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaDeathmatchPlayerQuit)

                addEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)

                addEventHandler("event1:deathmatch:onPlayerAllMapResourceElementsLoaded", arenaElement, localEventHandlers.onArenaDeathmatchPlayerAllMapResourceElementsLoaded)
                addEventHandler("event1:deathmatch:onPlayerRequestVehicleModelsSync", arenaElement, localEventHandlers.onArenaDeathmatchPlayerRequestVehicleModelsSync)
                addEventHandler("event1:deathmatch:onPlayerUnfreeze", arenaElement, localEventHandlers.onArenaDeathmatchPlayerUnfreeze)
                addEventHandler("event1:deathmatch:onPlayerKill", arenaElement, localEventHandlers.onArenaDeathmatchPlayerKill)
                addEventHandler("event1:deathmatch:onPlayerPickupRacePickup", arenaElement, localEventHandlers.onArenaDeathmatchPlayerPickupRacePickup)
                addEventHandler("event1:deathmatch:onPlayerReachedHunterInternal", arenaElement, localEventHandlers.onArenaDeathmatchPlayerReachedHunter)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:deathmatch:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
                removeEventHandler("event1:deathmatch:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaDeathmatchPlayerQuit)

                removeEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)

                removeEventHandler("event1:deathmatch:onPlayerAllMapResourceElementsLoaded", arenaElement, localEventHandlers.onArenaDeathmatchPlayerAllMapResourceElementsLoaded)
                removeEventHandler("event1:deathmatch:onPlayerRequestVehicleModelsSync", arenaElement, localEventHandlers.onArenaDeathmatchPlayerRequestVehicleModelsSync)
                removeEventHandler("event1:deathmatch:onPlayerUnfreeze", arenaElement, localEventHandlers.onArenaDeathmatchPlayerUnfreeze)
                removeEventHandler("event1:deathmatch:onPlayerKill", arenaElement, localEventHandlers.onArenaDeathmatchPlayerKill)
                removeEventHandler("event1:deathmatch:onPlayerPickupRacePickup", arenaElement, localEventHandlers.onArenaDeathmatchPlayerPickupRacePickup)
                removeEventHandler("event1:deathmatch:onPlayerReachedHunterInternal", arenaElement, localEventHandlers.onArenaDeathmatchPlayerReachedHunter)

                stateData:killTimeIsUpTimer()
                stateData:killRacePickupRespawnTimers()

                stateData.unloadedRacePickupIDs = nil

                stateData.racePickupRespawnTimers = nil
            end,

            startTimeIsUpTimer = function(stateData)
                local localTimers = stateData.localTimers

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                stateData.timeIsUpTimer = setTimer(localTimers.timeIsUp, getElementData(arenaElement, "mapDuration", false), 1)
            end,

            killTimeIsUpTimer = function(stateData)
                local timeIsUpTimer = stateData.timeIsUpTimer

                if isTimer(timeIsUpTimer) then
                    killTimer(timeIsUpTimer)
                end

                stateData.timeIsUpTimer = nil
            end,

            killRacePickupRespawnTimers = function(stateData)
                local racePickupRespawnTimers = stateData.racePickupRespawnTimers

                for i = 1, #racePickupRespawnTimers do
                    local timer = racePickupRespawnTimers[i]

                    if isTimer(timer) then
                        killTimer(timer)
                    end
                end

                stateData.racePickupRespawnTimers = {}
            end,

            localEventHandlers = {
                onArenaDeathmatchPlayerJoin = function()
                    setElementData(source, "state", "dead"--[[ , "subscribe" *]])
                end,

                onArenaDeathmatchPlayerQuit = function()
                    triggerEvent("onPlayerWasted", source)
                end,

                onArenaPlayerWasted = function()
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    spawnPlayer(source, 0, 0, 0, 0, 0, 0, getElementDimension(arenaElement))
                    setElementFrozen(source, true)

                    local mapLoadedStateData = deathmatch.states["map loaded"]

                    local alivePlayers = mapLoadedStateData.alivePlayers

                    if alivePlayers[source] then
                        setElementData(source, "state", "dead"--[[ , "subscribe" *]])
    
                        local playerVehicle = deathmatch.getPlayerVehicle(source)

                        if isElement(playerVehicle) then
                            setElementPosition(playerVehicle, 0, 0, 0)
                            setElementRotation(playerVehicle, 0, 0, 0)
                            setElementFrozen(playerVehicle, true)
                            setVehicleDamageProof(playerVehicle, true)
                            setElementCollisionsEnabled(playerVehicle, false)
                        end
    
                        local alivePlayersCount = mapLoadedStateData.alivePlayersCount - 1
    
                        mapLoadedStateData.alivePlayersCount = alivePlayersCount
                        
                        alivePlayers[source] = nil

                        triggerClientResourceEvent(resource, arenaElement, "event1:deathmatch:onClientPlayerWastedInternal", source, alivePlayersCount)

                        triggerEvent("event1:deathmatch:onPlayerWasted", source)
    
                        if not next(alivePlayers) then
                            deathmatch.setState("ended")
                        end
                    end
                end,

                onArenaDeathmatchPlayerAllMapResourceElementsLoaded = function()
                    if source == client then
                        local data = deathmatch.data

                        local stateData = deathmatch.states[data.state]

                        local unloadedRacePickupIDs = stateData.unloadedRacePickupIDs

                        if next(unloadedRacePickupIDs) then
                            triggerClientResourceEvent(resource, client, "event1:deathmatch:onClientRacePickupsUnload", client, unloadedRacePickupIDs)
                        end
                    end
                end,

                onArenaDeathmatchPlayerRequestVehicleModelsSync = function()
                    if source == client then
                        local vehicleModels = {}

                        for player, vehicle in pairs(deathmatch.data.playerSpawnpointVehicles) do
                            local customVehicleModel = getElementData(vehicle, "customModel", false)
        
                            if customVehicleModel then
                                vehicleModels[vehicle] = customVehicleModel
                            end
                        end
        
                        if next(vehicleModels) then
                            triggerClientResourceEvent(resource, client, "event1:deathmatch:onClientVehicleModelsSync", client, vehicleModels)
                        end
                    end
                end,

                onArenaDeathmatchPlayerUnfreeze = function()
                    if source == client then
                        if deathmatch.states["map loaded"].alivePlayers[client] then
                            deathmatch.unfreezePlayerSpawnpointVehicle(client)
                        end
                    end
                end,

                onArenaDeathmatchPlayerKill = function()
                    if source == client then
                        triggerEvent("onPlayerWasted", client)
                    end
                end,

                onArenaDeathmatchPlayerPickupRacePickup = function(id, type, respawn, vehicle)
                    if source == client then
                        local data = deathmatch.data

                        local stateData = deathmatch.states[data.state]

                        respawn = tonumber(respawn)

                        if respawn and respawn + 1 > 50 then
                            local eventData = event1.data

                            triggerClientResourceEvent(resource, eventData.arenaElement, "event1:deathmatch:onClientPlayerRacePickupUnload", client, id)

                            stateData.unloadedRacePickupIDs[id] = true

                            local racePickupRespawnTimers = stateData.racePickupRespawnTimers

                            local localTimers = stateData.localTimers

                            racePickupRespawnTimers[#racePickupRespawnTimers + 1] = setTimer(localTimers.loadPickup, respawn, 1, client, id)
                        end

                        local racePickupFunction = stateData.localRacePickupFunctions[type]

                        if racePickupFunction then
                            racePickupFunction(client, id, vehicle)
                        end
                    end
                end,

                onArenaDeathmatchPlayerReachedHunter = function(timePassed, splitTimes)
                    if source == client then
                        timePassed = tonumber(timePassed)

                        if timePassed then
                            local data = deathmatch.data

                            local mapResource = data.mapResource

                            local eventData = event1.data

                            local arenaElement = eventData.arenaElement

                            local arenaElementID = getElementID(arenaElement)

                            silentExport("ep_toplist", "addTopTime", mapResource, "main", client, timePassed, splitTimes, client)
                            silentExport("ep_toplist", "sendTopTimes", mapResource, nil, getElementData(arenaElement, "mapInfo", false).name, arenaElement)

                            triggerClientResourceEvent(resource, arenaElement, "event1:deathmatch:onClientPlayerReachedHunterInternal", client)

                            triggerEvent("event1:deathmatch:onPlayerReachedHunter", client, timePassed)
                        end
                    end
                end
            },

            localTimers = {
                timeIsUp = function()
                    for player in pairs(deathmatch.states["map loaded"].alivePlayers) do
                        triggerEvent("onPlayerWasted", player)
                    end

                    local eventData = event1.data

                    outputChatBox("#CCCCCCTime is up!", eventData.arenaElement, 255, 255, 255, true)
                end,

                loadPickup = function(player, id)
                    local eventData = event1.data

                    triggerClientResourceEvent(resource, eventData.arenaElement, "event1:deathmatch:onClientPlayerRacePickupLoad", player, id)

                    local data = deathmatch.data

                    local stateData = deathmatch.states[data.state]

                    stateData.unloadedRacePickupIDs[id] = nil
                end
            },

            localRacePickupFunctions = {
                ["vehiclechange"] = function(player, id, vehicle)
                    local data = deathmatch.data

                    local playerVehicle = deathmatch.getPlayerVehicle(player)

                    if playerVehicle then
                        vehicle = tonumber(vehicle)
    
                        if vehicle then
                            local eventData = event1.data

                            triggerClientResourceEvent(resource, eventData.arenaElement, "event1:deathmatch:onClientPlayerSyncFunction", player, "setElementModel", playerVehicle, vehicle)

                            setElementData(playerVehicle, "customModel", vehicle, "local")
                        end
                    end
                end,

                ["nitro"] = function(player)
                    local data = deathmatch.data

                    local playerVehicle = deathmatch.getPlayerVehicle(player)

                    if playerVehicle then
                        local eventData = event1.data

                        triggerClientResourceEvent(resource, eventData.arenaElement, "event1:deathmatch:onClientPlayerSyncFunction", player, "addVehicleUpgrade", playerVehicle, 1010)
                    end
                end,

                ["repair"] = function(player)
                    local data = deathmatch.data

                    local playerVehicle = deathmatch.getPlayerVehicle(player)

                    if playerVehicle then
                        local eventData = event1.data

                        triggerClientResourceEvent(resource, eventData.arenaElement, "event1:deathmatch:onClientPlayerSyncFunction", player, "fixVehicle", playerVehicle)
                    end
                end
            }
        },

        ["ended"] = {
            settings = {
                nextmapDelay = 5000
            },

            onStateSet = function(stateData)
                stateData:startNextMapTimer()

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                addEventHandler("event1:deathmatch:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:deathmatch:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)

                stateData:killNextMapTimer()
            end,

            startNextMapTimer = function(stateData)
                local localTimers = stateData.localTimers

                local settings = stateData.settings

                stateData.nextMapTimer = setTimer(localTimers.nextMap, settings.nextmapDelay, 1)
            end,

            killNextMapTimer = function(stateData)
                local nextMapTimer = stateData.nextMapTimer

                if isTimer(nextMapTimer) then
                    killTimer(nextMapTimer)
                end

                stateData.nextMapTimer = nil
            end,

            localEventHandlers = {
                onArenaDeathmatchPlayerJoin = function()
                    setElementData(source, "state", "dead"--[[ , "subscribe" *]])
                end
            },

            localTimers = {
                nextMap = function()
                    event1.loadMap()
                end
            }
        },

        ["map unloading"] = {
            onStateSet = function()
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local mapLoadedStateData = deathmatch.states["map loaded"]

                local mapLoadedSharedEventHandlers = mapLoadedStateData.sharedEventHandlers

                removeEventHandler("event1:onPlayerArenaJoin", arenaElement, mapLoadedSharedEventHandlers.onArenaPlayerJoin)
                removeEventHandler("event1:onPlayerArenaQuit", arenaElement, mapLoadedSharedEventHandlers.onArenaPlayerQuit)

                removeEventHandler("topList:topTimes:onPlayerThisResourceStart", arenaElement, mapLoadedSharedEventHandlers.onArenaPlayerTopTimesResourceStart)
                removeEventHandler("topList:topTimes:onTopTimeUpdated", arenaElement, mapLoadedSharedEventHandlers.onArenaPlayerTopTimeUpdated)
                removeEventHandler("topList:topTimes:onTopTimeAdded", arenaElement, mapLoadedSharedEventHandlers.onArenaPlayerTopTimeAdded)
                removeEventHandler("topList:topTimes:onTopTimeDeleted", arenaElement, mapLoadedSharedEventHandlers.onArenaPlayerTopTimeDeleted)
                removeEventHandler("topList:topTimes:onTopTimeRenamed", arenaElement, mapLoadedSharedEventHandlers.onArenaPlayerTopTimeRenamed)

                removeEventHandler("onVehicleStartExit", arenaElement, mapLoadedSharedEventHandlers.onArenaVehicleStartExit)
                removeEventHandler("onVehicleExit", arenaElement, mapLoadedSharedEventHandlers.onArenaVehicleExit)
                removeEventHandler("onElementDestroy", arenaElement, mapLoadedSharedEventHandlers.onArenaElementDestroy)

                local mapLoadedSharedCommandHandlers = mapLoadedStateData.sharedCommandHandlers

                removeCommandHandler("deletetoptime", mapLoadedSharedCommandHandlers.deleteTopTime)
                removeCommandHandler("renametoptime", mapLoadedSharedCommandHandlers.renameTopTime)
                removeCommandHandler("toggletrainingmode", mapLoadedSharedCommandHandlers.toggleTrainingMode)

                silentExport("ep_toplist", "unloadTopTimes", arenaElement)
                silentExport("ep_toplist", "unloadTopTimesSplitTimes", arenaElement)
                
                setElementData(arenaElement, "state", nil--[[ , "subscribe" *]])
                setElementData(arenaElement, "mapDuration", nil--[[ , "subscribe" *]])

                local arenaPlayers = getElementChildren(arenaElement, "player")

                local removePlayerAllElementDataSubscriptions = deathmatch.removePlayerAllElementDataSubscriptions
                
                for i = 1, #arenaPlayers do
                    removePlayerAllElementDataSubscriptions(arenaPlayers[i])
                end

                deathmatch.destroyAllPlayerSpawnpointVehicles()

                mapLoadedStateData.alivePlayers = nil

                mapLoadedStateData.alivePlayersCount = nil
            end,

            onStateChanging = function()

            end
        }
    },

    eventHandlers = {
        onArenaCreated = function()
            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = deathmatch.eventHandlers

            addEventHandler("event1:dm:onArenaMapResourceLoaded", arenaElement, eventHandlers.onArenaDeathmatchMapResourceLoaded)
            addEventHandler("event1:dm:onArenaMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)
        
            addEventHandler("event1:os:onArenaMapResourceLoaded", arenaElement, eventHandlers.onArenaDeathmatchMapResourceLoaded)
            addEventHandler("event1:os:onArenaMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)
        
            addEventHandler("event1:hdm:onArenaMapResourceLoaded", arenaElement, eventHandlers.onArenaDeathmatchMapResourceLoaded)
            addEventHandler("event1:hdm:onArenaMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)

            addEventHandler("event1:hunter:onArenaMapResourceLoaded", arenaElement, eventHandlers.onArenaDeathmatchMapResourceLoaded)
            addEventHandler("event1:hunter:onArenaMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)
        end,

        onArenaDestroy = function()
            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = deathmatch.eventHandlers

            removeEventHandler("event1:dm:onArenaMapResourceLoaded", arenaElement, eventHandlers.onArenaDeathmatchMapResourceLoaded)
            removeEventHandler("event1:dm:onArenaMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)
        
            removeEventHandler("event1:os:onArenaMapResourceLoaded", arenaElement, eventHandlers.onArenaDeathmatchMapResourceLoaded)
            removeEventHandler("event1:os:onArenaMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)
        
            removeEventHandler("event1:hdm:onArenaMapResourceLoaded", arenaElement, eventHandlers.onArenaDeathmatchMapResourceLoaded)
            removeEventHandler("event1:hdm:onArenaMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)

            removeEventHandler("event1:hunter:onArenaMapResourceLoaded", arenaElement, eventHandlers.onArenaDeathmatchMapResourceLoaded)
            removeEventHandler("event1:hunter:onArenaMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)

            deathmatch.stop()
        end,

        ---

        onArenaDeathmatchMapResourceLoaded = function(mapResource)
            deathmatch.start(mapResource)
        end,

        onArenaDeathmatchMapResourceUnloading = function(mapResource)
            deathmatch.stop()
        end
    }
}

event1.managers.deathmatch = deathmatch

addEvent("event1:onArenaCreated")
addEvent("event1:onArenaDestroy")

addEvent("event1:dm:onArenaMapResourceLoaded")
addEvent("event1:dm:onArenaMapResourceUnloading")

addEvent("event1:os:onArenaMapResourceLoaded")
addEvent("event1:os:onArenaMapResourceUnloading")

addEvent("event1:hdm:onArenaMapResourceLoaded")
addEvent("event1:hdm:onArenaMapResourceUnloading")

addEvent("event1:hunter:onArenaMapResourceLoaded")
addEvent("event1:hunter:onArenaMapResourceUnloading")

addEvent("event1:onPlayerArenaJoin")
addEvent("event1:onPlayerArenaQuit")

addEvent("topList:topTimes:onPlayerThisResourceStart")
addEvent("topList:topTimes:onTopTimeUpdated")
addEvent("topList:topTimes:onTopTimeAdded")
addEvent("topList:topTimes:onTopTimeDeleted")
addEvent("topList:topTimes:onTopTimeRenamed")

addEvent("event1:deathmatch:onPlayerArenaJoin")
addEvent("event1:deathmatch:onPlayerArenaQuit")

addEvent("event1:deathmatch:onPlayerAllMapResourceElementsLoaded", true)
addEvent("event1:deathmatch:onPlayerRequestVehicleModelsSync", true)
addEvent("event1:deathmatch:onPlayerUnfreeze", true)
addEvent("event1:deathmatch:onPlayerKill", true)
addEvent("event1:deathmatch:onPlayerPickupRacePickup", true)
addEvent("event1:deathmatch:onPlayerReachedHunterInternal", true)

do
    local eventHandlers = deathmatch.eventHandlers

    addEventHandler("event1:onArenaCreated", resourceRoot, eventHandlers.onArenaCreated)
    addEventHandler("event1:onArenaDestroy", resourceRoot, eventHandlers.onArenaDestroy)
end