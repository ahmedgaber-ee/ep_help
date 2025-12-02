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

local race

race = {
    start = function(mapResource)
        if not race.data then
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

                    race.data = data

                    race.setState("map loaded")
                else
                    outputDebugString(debuggerPrepareString("Failed to start map. No spawnpoints found (resourceName: " .. tostring(getResourceName(mapResource)) .. ").", 2))

                    event1.loadMap()
                end
            end
        end
    end,

    stop = function()
        local data = race.data

        if data then
            race.setState("map unloading")

            race.data = nil
        end
    end,

    setState = function(state)
        local states = race.states

        local stateData = states[state]

        if stateData then
            local data = race.data

            local oldState = data.state

            if state ~= oldState then
                local data = race.data

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

                triggerClientResourceEvent(resource, arenaElement, "event1:race:onClientArenaStateSetInternal", sourceElement, state)

                triggerEvent("event1:race:onArenaStateSet", sourceElement, state)
            end
        end
    end,

    spawnPlayerAtSpawnpoint = function(player, spawnpointID)
        local data = race.data

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

        race.destroyPlayerSpawnpointVehicle(player)

        data.playerSpawnpointVehicles[player] = vehicle
    end,

    unfreezePlayerSpawnpointVehicle = function(player)
        local data = race.data

        local vehicle = data.playerSpawnpointVehicles[player]

        if isElement(vehicle) then
            setElementFrozen(vehicle, false)
            setVehicleDamageProof(vehicle, false)
            setElementCollisionsEnabled(vehicle, true)
        end

        setElementFrozen(player, false)
    end,

    destroyPlayerSpawnpointVehicle = function(player)
        local data = race.data

        local playerSpawnpointVehicles = data.playerSpawnpointVehicles

        local vehicle = playerSpawnpointVehicles[player]

        if isElement(vehicle) then
            destroyElement(vehicle)
        end

        playerSpawnpointVehicles[player] = nil
    end,

    destroyAllPlayerSpawnpointVehicles = function()
        local data = race.data

        for player, vehicle in pairs(data.playerSpawnpointVehicles) do
            if isElement(vehicle) then
                destroyElement(vehicle)
            end
        end

        data.playerSpawnpointVehicles = {}
    end,

    addPlayerAllElementDataSubscriptions = function(player)
        setElementData(player, "state", nil--[[ , "subscribe" *]])
        setElementData(player, "raceCheckpointID", nil--[[ , "subscribe" *]])

        local eventData = event1.data

        local arenaElement = eventData.arenaElement

        local arenaPlayers = getElementChildren(arenaElement, "player")

        addElementDataSubscriber(arenaElement, "state", player)
        addElementDataSubscriber(arenaElement, "mapDuration", player)

        for i = 1, #arenaPlayers do
            local arenaPlayer = arenaPlayers[i]

            addElementDataSubscriber(arenaPlayer, "state", player)
            addElementDataSubscriber(player, "state", arenaPlayer)

            addElementDataSubscriber(arenaPlayer, "raceCheckpointID", player)
            addElementDataSubscriber(player, "raceCheckpointID", arenaPlayer)
        end
    end,

    removePlayerAllElementDataSubscriptions = function(player)
        setElementData(player, "state", nil--[[ , "subscribe" *]])
        setElementData(player, "raceCheckpointID", nil--[[ , "subscribe" *]])

        local eventData = event1.data

        local arenaElement = eventData.arenaElement

        local arenaPlayers = getElementChildren(arenaElement, "player")

        removeElementDataSubscriber(arenaElement, "state", player)
        removeElementDataSubscriber(arenaElement, "mapDuration", player)

        for i = 1, #arenaPlayers do
            local arenaPlayer = arenaPlayers[i]

            removeElementDataSubscriber(arenaPlayer, "state", player)
            removeElementDataSubscriber(player, "state", arenaPlayer)

            removeElementDataSubscriber(arenaPlayer, "raceCheckpointID", player)
            removeElementDataSubscriber(player, "raceCheckpointID", arenaPlayer)
        end
    end,

    getPlayerVehicle = function(player)
        local data = race.data

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

                local data = race.data

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local mapResource = data.mapResource

                silentExport("ep_toplist", "sendTopTimes", mapResource, nil, getElementData(arenaElement, "mapInfo", false).name, arenaElement)
                
                if getElementData(arenaElement, "raceTrainingMode", false) then
                    silentExport("ep_toplist", "sendTopTimesSplitTimes", mapResource, nil, arenaElement)
                end

                local sharedEventHandlers = stateData.sharedEventHandlers

                addEventHandler("event1:onPlayerArenaJoin", arenaElement, sharedEventHandlers.onArenaPlayerJoin)
                addEventHandler("event1:onPlayerArenaQuit", arenaElement, sharedEventHandlers.onArenaPlayerQuit)

                addEventHandler("event1:race:onPlayerSetCurrentRaceCheckpoint", arenaElement, sharedEventHandlers.onArenaRacePlayerSetCurrentRaceCheckpoint)

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

                addEventHandler("event1:race:onPlayerAllMapResourceElementsLoaded", arenaElement, localEventHandlers.onArenaRacePlayerAllMapResourceElementsLoaded)

                addEventHandler("event1:race:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaRacePlayerJoin)
                addEventHandler("event1:race:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaRacePlayerQuit)

                addEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:race:onPlayerAllMapResourceElementsLoaded", arenaElement, localEventHandlers.onArenaRacePlayerAllMapResourceElementsLoaded)

                removeEventHandler("event1:race:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaRacePlayerJoin)
                removeEventHandler("event1:race:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaRacePlayerQuit)

                removeEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)

                stateData:killForcedCountdownTimer()

                stateData.playersToLoadCount = nil

                stateData.playersToLoad = nil
            end,

            cacheMapDuration = function(stateData)
                local data = race.data

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
                
                local addPlayerAllElementDataSubscriptions = race.addPlayerAllElementDataSubscriptions
                
                local spawnPlayerAtSpawnpoint = race.spawnPlayerAtSpawnpoint

                local data = race.data
                
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

                    race.setState("countdown starting")
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

                        triggerClientResourceEvent(resource, eventData.arenaElement, "event1:race:onClientPlayerLoaded", player)
                    end
                end
            end,

            setPlayerUnloaded = function(stateData, player)
                local playerData = stateData.playersToLoad[player]

                if playerData then
                    if playerData.loaded then
                        playerData.loaded = nil

                        local eventData = event1.data

                        triggerClientResourceEvent(resource, eventData.arenaElement, "event1:race:onClientPlayerUnloaded", player)
                    end
                end
            end,

            setPlayerSpawnpointID = function(stateData, player, spawnpointID)
                local data = race.data

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
                    race.addPlayerAllElementDataSubscriptions(source)

                    local data = race.data

                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    local mapResource = data.mapResource

                    silentExport("ep_toplist", "sendTopTimes", mapResource, nil, getElementData(arenaElement, "mapInfo", false).name, source)

                    if getElementData(arenaElement, "raceTrainingMode", false) then
                        silentExport("ep_toplist", "sendTopTimesSplitTimes", mapResource, nil, source)
                    end

                    triggerEvent("event1:race:onPlayerArenaJoin", source)
                end,

                onArenaPlayerQuit = function()
                    triggerEvent("event1:race:onPlayerArenaQuit", source)

                    silentExport("ep_toplist", "unloadTopTimes", source)

                    race.removePlayerAllElementDataSubscriptions(source)
                end,

                onArenaRacePlayerSetCurrentRaceCheckpoint = function(raceCheckpointID)
                    if source == client then
                        local eventData = event1.data

                        setElementData(client, "raceCheckpointID", raceCheckpointID--[[ , "subscribe" *]])

                        triggerClientResourceEvent(resource, eventData.arenaElement, "event1:race:onClientPlayerSetCurrentRaceCheckpoint", client, raceCheckpointID)
                    end
                end,

                onArenaPlayerTopTimesResourceStart = function()
                    local data = race.data

                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement
        
                    local mapResource = data.mapResource

                    silentExport("ep_toplist", "sendTopTimes", mapResource, nil, getElementData(arenaElement, "mapInfo", false).name, source)

                    if getElementData(arenaElement, "raceTrainingMode", false) then
                        silentExport("ep_toplist", "sendTopTimesSplitTimes", mapResource, nil, source)
                    end
                end,

                onArenaPlayerTopTimeUpdated = function(resource, arenaID, player, time, oldArenaTime, arenaPosition, oldArenaPosition, position, oldPosition)
                    local differenceText = "#00FF00(-" .. formatMS(oldArenaTime - time) .. ")"

                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    if position == 1 and getElementData(arenaElement, "raceTrainingMode", false) then
                        local data = race.data

                        local mapResource = data.mapResource

                        silentExport("ep_toplist", "unloadTopTimesSplitTimes", arenaElement)
                        silentExport("ep_toplist", "sendTopTimesSplitTimes", mapResource, nil, arenaElement)
                    end

                    outputChatBox(getPlayerName(player) .. " #CCCCCChas made a new top time with time: #FFFFFF" .. formatMS(time) .. " " .. differenceText .. " #CCCCCCand position: #FFFFFF" .. position .. " #CCCCCC(old position: #FFFFFF" .. oldPosition .. "#CCCCCC)", arenaElement, 255, 255, 255, true)
                end,

                onArenaPlayerTopTimeAdded = function(resource, arenaID, player, time, arenaPosition, position)
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    if position == 1 and getElementData(arenaElement, "raceTrainingMode", false) then
                        local data = race.data

                        local mapResource = data.mapResource

                        silentExport("ep_toplist", "unloadTopTimesSplitTimes", arenaElement)
                        silentExport("ep_toplist", "sendTopTimesSplitTimes", mapResource, nil, arenaElement)
                    end

                    outputChatBox(getPlayerName(player) .. " #CCCCCChas made a new top time with time: #FFFFFF" .. formatMS(time) .. " #CCCCCCand position: #FFFFFF" .. position, arenaElement, 255, 255, 255, true)
                end,

                onArenaPlayerTopTimeDeleted = function(resource, arenaID, position, playerName)
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    if position == 1 and getElementData(arenaElement, "raceTrainingMode", false) then
                        local data = race.data

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
                            if race.getPlayerVehicle(player) then
                                triggerEvent("onPlayerWasted", player)
                            end
                        end
                    end
                end
            },
            
            sharedCommandHandlers = {
                deleteTopTime = function(player, commandName, position)
                    if hasObjectPermissionTo(player, "resource." .. resourceName .. ".race_cmd_" .. commandName, false) then
                        local eventData = event1.data

                        local arenaElement = eventData.arenaElement
            
                        local playerArenaElement = event1.getPlayerArenaElement(player)
            
                        if playerArenaElement == arenaElement then
                            position = tonumber(position)

                            if position then
                                local data = race.data

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
                    if hasObjectPermissionTo(player, "resource." .. resourceName .. ".race_cmd_" .. commandName, false) then
                        local eventData = event1.data

                        local arenaElement = eventData.arenaElement
            
                        local playerArenaElement = event1.getPlayerArenaElement(player)
            
                        if playerArenaElement == arenaElement then
                            position = tonumber(position)

                            if position then
                                if name then
                                    local data = race.data

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
                    if hasObjectPermissionTo(player, "resource." .. resourceName .. ".race_cmd_" .. commandName, false) then
                        local eventData = event1.data

                        local arenaElement = eventData.arenaElement
            
                        local playerArenaElement = event1.getPlayerArenaElement(player)
            
                        if playerArenaElement == arenaElement then
                            local newState = not getElementData(arenaElement, "raceTrainingMode", false)

                            setElementData(arenaElement, "raceTrainingMode", newState)

                            if newState then
                                local data = race.data

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
                onArenaRacePlayerAllMapResourceElementsLoaded = function()
                    if source == client then
                        local data = race.data

                        local stateData = race.states[data.state]
    
                        if stateData.playersToLoad[client] then
                            setElementData(client, "state", "alive"--[[ , "subscribe" *]])
    
                            stateData:setPlayerLoaded(client)
                            stateData:checkForCountdown()
                        end
                    end
                end,

                onArenaRacePlayerJoin = function()
                    setElementData(source, "state", "not ready"--[[ , "subscribe" *]])

                    local eventData = event1.data

                    local data = race.data

                    local arenaPlayers = getElementChildren(eventData.arenaElement, "player")

                    --race.spawnPlayerAtSpawnpoint(source, (#arenaPlayers + 1 - 1) % #data.mapSpawnpoints + 1)
                    race.spawnPlayerAtSpawnpoint(source, 1)

                    local stateData = race.states[data.state]

                    stateData:addPlayerToLoadQueue(source)

                    triggerEvent("event1:race:onPlayerJoinSpawn", source)
                end,

                onArenaRacePlayerQuit = function()
                    local data = race.data

                    local stateData = race.states[data.state]
                    
                    stateData:removePlayerFromLoadQueue(source)
                    stateData:checkForCountdown()
                end,

                onArenaPlayerWasted = function()
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    local data = race.data

                    local stateData = race.states[data.state]

                    local playersToLoad = stateData.playersToLoad
                    
                    if playersToLoad[source] then
                        local arenaPlayers = getElementChildren(arenaElement, "player")

                        --race.spawnPlayerAtSpawnpoint(source, (#arenaPlayers + 1 - 1) % #data.mapSpawnpoints + 1)
                        race.spawnPlayerAtSpawnpoint(source, 1)
                    else
                        spawnPlayer(source, 0, 0, 0, 0, 0, 0, getElementDimension(arenaElement))
                        setElementFrozen(source, true)

                        if getElementData(source, "state", false) ~= "dead" then
                            setElementData(source, "state", "dead"--[[ , "subscribe" *]])
    
                            local playerVehicle = race.getPlayerVehicle(source)

                            if isElement(playerVehicle) then
                                setElementPosition(playerVehicle, 0, 0, 0)
                                setElementRotation(playerVehicle, 0, 0, 0)
                                setElementFrozen(playerVehicle, true)
                                setVehicleDamageProof(playerVehicle, true)
                                setElementCollisionsEnabled(playerVehicle, false)
                            end

                            triggerClientResourceEvent(resource, arenaElement, "event1:race:onClientPlayerWastedInternal", source)

                            triggerEvent("event1:race:onPlayerWasted", source)

                            if not next(playersToLoad) then
                                race.setState("ended")
                            end
                        end
                    end
                end
            },

            localTimers = {
                forcedCountdown = function()
                    local data = race.data

                    local stateData = race.states[data.state]

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

                        race.setState("countdown starting")
                    else
                        race.setState("ended")
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

                addEventHandler("event1:race:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaRacePlayerJoin)
                addEventHandler("event1:race:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaRacePlayerQuit)

                addEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:race:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaRacePlayerJoin)
                removeEventHandler("event1:race:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaRacePlayerQuit)

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
                onArenaRacePlayerJoin = function()
                    setElementData(source, "state", "dead"--[[ , "subscribe" *]])
                end,

                onArenaRacePlayerQuit = function()
                    triggerEvent("onPlayerWasted", source)
                end,

                onArenaPlayerWasted = function()
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    spawnPlayer(source, 0, 0, 0, 0, 0, 0, getElementDimension(arenaElement))
                    setElementFrozen(source, true)

                    local mapLoadedStateData = race.states["map loaded"]

                    local alivePlayers = mapLoadedStateData.alivePlayers

                    if alivePlayers[source] then
                        setElementData(source, "state", "dead"--[[ , "subscribe" *]])
    
                        local playerVehicle = race.getPlayerVehicle(source)

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

                        triggerClientResourceEvent(resource, arenaElement, "event1:race:onClientPlayerWastedInternal", source, alivePlayersCount)

                        triggerEvent("event1:race:onPlayerWasted", source)
    
                        if not next(alivePlayers) then
                            race.setState("ended")
                        end
                    end
                end
            },

            localTimers = {
                countdownStart = function()
                    race.setState("countdown started")
                end
            }
        },

        ["countdown started"] = {
            onStateSet = function(stateData)
                stateData:startCountdownTimer()

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                addEventHandler("event1:race:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaRacePlayerJoin)
                addEventHandler("event1:race:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaRacePlayerQuit)

                addEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:race:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaRacePlayerJoin)
                removeEventHandler("event1:race:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaRacePlayerQuit)

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
                onArenaRacePlayerJoin = function()
                    setElementData(source, "state", "dead"--[[ , "subscribe" *]])
                end,

                onArenaRacePlayerQuit = function()
                    triggerEvent("onPlayerWasted", source)
                end,

                onArenaPlayerWasted = function()
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    spawnPlayer(source, 0, 0, 0, 0, 0, 0, getElementDimension(arenaElement))
                    setElementFrozen(source, true)

                    local mapLoadedStateData = race.states["map loaded"]

                    local alivePlayers = mapLoadedStateData.alivePlayers

                    if alivePlayers[source] then
                        setElementData(source, "state", "dead"--[[ , "subscribe" *]])
    
                        local playerVehicle = race.getPlayerVehicle(source)

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
    
                        triggerClientResourceEvent(resource, arenaElement, "event1:race:onClientPlayerWastedInternal", source, alivePlayersCount)

                        triggerEvent("event1:race:onPlayerWasted", source)
    
                        if not next(alivePlayers) then
                            race.setState("ended")
                        end
                    end
                end
            },

            localTimers = {
                countdown = function()
                    local remaining, executesRemaining, timeInterval = getTimerDetails(sourceTimer)

                    local countdownValue = executesRemaining - 1

                    local eventData = event1.data

                    triggerClientResourceEvent(resource, eventData.arenaElement, "event1:race:onClientArenaCountdownValueUpdate", eventData.sourceElement, countdownValue)

                    if countdownValue == 0 then
                        race.setState("running")
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

                addEventHandler("event1:race:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaRacePlayerJoin)
                addEventHandler("event1:race:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaRacePlayerQuit)

                addEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)

                addEventHandler("event1:race:onPlayerAllMapResourceElementsLoaded", arenaElement, localEventHandlers.onArenaRacePlayerAllMapResourceElementsLoaded)
                addEventHandler("event1:race:onPlayerRequestVehicleModelsSync", arenaElement, localEventHandlers.onArenaRacePlayerRequestVehicleModelsSync)
                addEventHandler("event1:race:onPlayerUnfreeze", arenaElement, localEventHandlers.onArenaRacePlayerUnfreeze)
                addEventHandler("event1:race:onPlayerKill", arenaElement, localEventHandlers.onArenaRacePlayerKill)
                addEventHandler("event1:race:onPlayerPickupRacePickup", arenaElement, localEventHandlers.onArenaRacePlayerPickupRacePickup)
                addEventHandler("event1:race:onPlayerReachedFinishLineInternal", arenaElement, localEventHandlers.onArenaRacePlayerReachedFinishLine)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:race:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaRacePlayerJoin)
                removeEventHandler("event1:race:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaRacePlayerQuit)

                removeEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)

                removeEventHandler("event1:race:onPlayerAllMapResourceElementsLoaded", arenaElement, localEventHandlers.onArenaRacePlayerAllMapResourceElementsLoaded)
                removeEventHandler("event1:race:onPlayerRequestVehicleModelsSync", arenaElement, localEventHandlers.onArenaRacePlayerRequestVehicleModelsSync)
                removeEventHandler("event1:race:onPlayerUnfreeze", arenaElement, localEventHandlers.onArenaRacePlayerUnfreeze)
                removeEventHandler("event1:race:onPlayerKill", arenaElement, localEventHandlers.onArenaRacePlayerKill)
                removeEventHandler("event1:race:onPlayerPickupRacePickup", arenaElement, localEventHandlers.onArenaRacePlayerPickupRacePickup)
                removeEventHandler("event1:race:onPlayerReachedFinishLineInternal", arenaElement, localEventHandlers.onArenaRacePlayerReachedFinishLine)

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
                onArenaRacePlayerJoin = function()
                    setElementData(source, "state", "dead"--[[ , "subscribe" *]])
                end,

                onArenaRacePlayerQuit = function()
                    triggerEvent("onPlayerWasted", source)
                end,

                onArenaPlayerWasted = function()
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    spawnPlayer(source, 0, 0, 0, 0, 0, 0, getElementDimension(arenaElement))
                    setElementFrozen(source, true)

                    local mapLoadedStateData = race.states["map loaded"]

                    local alivePlayers = mapLoadedStateData.alivePlayers

                    if alivePlayers[source] then
                        setElementData(source, "state", "dead"--[[ , "subscribe" *]])
    
                        local playerVehicle = race.getPlayerVehicle(source)

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

                        triggerClientResourceEvent(resource, arenaElement, "event1:race:onClientPlayerWastedInternal", source, alivePlayersCount)

                        triggerEvent("event1:race:onPlayerWasted", source)
    
                        if not next(alivePlayers) then
                            race.setState("ended")
                        end
                    end
                end,

                onArenaRacePlayerAllMapResourceElementsLoaded = function()
                    if source == client then
                        local data = race.data

                        local stateData = race.states[data.state]

                        local unloadedRacePickupIDs = stateData.unloadedRacePickupIDs

                        if next(unloadedRacePickupIDs) then
                            triggerClientResourceEvent(resource, client, "event1:race:onClientRacePickupsUnload", client, unloadedRacePickupIDs)
                        end
                    end
                end,

                onArenaRacePlayerRequestVehicleModelsSync = function()
                    if source == client then
                        local vehicleModels = {}

                        for player, vehicle in pairs(race.data.playerSpawnpointVehicles) do
                            local customVehicleModel = getElementData(vehicle, "customModel", false)
        
                            if customVehicleModel then
                                vehicleModels[vehicle] = customVehicleModel
                            end
                        end
        
                        if next(vehicleModels) then
                            triggerClientResourceEvent(resource, client, "event1:race:onClientVehicleModelsSync", client, vehicleModels)
                        end
                    end
                end,

                onArenaRacePlayerUnfreeze = function()
                    if source == client then
                        if race.states["map loaded"].alivePlayers[client] then
                            race.unfreezePlayerSpawnpointVehicle(client)
                        end
                    end
                end,

                onArenaRacePlayerKill = function()
                    if source == client then
                        triggerEvent("onPlayerWasted", client)
                    end
                end,

                onArenaRacePlayerPickupRacePickup = function(id, type, respawn, vehicle)
                    if source == client then
                        local data = race.data

                        local stateData = race.states[data.state]

                        respawn = tonumber(respawn)

                        if respawn and respawn + 1 > 50 then
                            local eventData = event1.data

                            triggerClientResourceEvent(resource, eventData.arenaElement, "event1:race:onClientPlayerRacePickupUnload", client, id)

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

                onArenaRacePlayerReachedFinishLine = function(timePassed, splitTimes)
                    if source == client then
                        timePassed = tonumber(timePassed)

                        if timePassed then
                            local data = race.data

                            local mapResource = data.mapResource

                            local eventData = event1.data

                            local arenaElement = eventData.arenaElement

                            local arenaElementID = getElementID(arenaElement)

                            triggerEvent("onPlayerWasted", client)

                            silentExport("ep_toplist", "addTopTime", mapResource, "main", client, timePassed, splitTimes, client)
                            silentExport("ep_toplist", "sendTopTimes", mapResource, nil, getElementData(arenaElement, "mapInfo", false).name, arenaElement)

                            --triggerClientResourceEvent(resource, arenaElement, "event1:race:onClientPlayerReachedFinishLineInternal", client)

                            triggerEvent("event1:race:onPlayerReachedFinishLine", client, timePassed)
                        end
                    end
                end
            },

            localTimers = {
                timeIsUp = function()
                    for player in pairs(race.states["map loaded"].alivePlayers) do
                        triggerEvent("onPlayerWasted", player)
                    end

                    local eventData = event1.data

                    outputChatBox("#CCCCCCTime is up!", eventData.arenaElement, 255, 255, 255, true)
                end,

                loadPickup = function(player, id)
                    local eventData = event1.data

                    triggerClientResourceEvent(resource, eventData.arenaElement, "event1:race:onClientPlayerRacePickupLoad", player, id)

                    local data = race.data

                    local stateData = race.states[data.state]

                    stateData.unloadedRacePickupIDs[id] = nil
                end
            },

            localRacePickupFunctions = {
                ["vehiclechange"] = function(player, id, vehicle)
                    local data = race.data

                    local playerVehicle = race.getPlayerVehicle(player)

                    if playerVehicle then
                        vehicle = tonumber(vehicle)
    
                        if vehicle then
                            local eventData = event1.data

                            triggerClientResourceEvent(resource, eventData.arenaElement, "event1:race:onClientPlayerSyncFunction", player, "setElementModel", playerVehicle, vehicle)

                            setElementData(playerVehicle, "customModel", vehicle, "local")
                        end
                    end
                end,

                ["nitro"] = function(player)
                    local data = race.data

                    local playerVehicle = race.getPlayerVehicle(player)

                    if playerVehicle then
                        local eventData = event1.data

                        triggerClientResourceEvent(resource, eventData.arenaElement, "event1:race:onClientPlayerSyncFunction", player, "addVehicleUpgrade", playerVehicle, 1010)
                    end
                end,

                ["repair"] = function(player)
                    local data = race.data

                    local playerVehicle = race.getPlayerVehicle(player)

                    if playerVehicle then
                        local eventData = event1.data

                        triggerClientResourceEvent(resource, eventData.arenaElement, "event1:race:onClientPlayerSyncFunction", player, "fixVehicle", playerVehicle)
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

                addEventHandler("event1:race:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaRacePlayerJoin)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:race:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaRacePlayerJoin)

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
                onArenaRacePlayerJoin = function()
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

                local mapLoadedStateData = race.states["map loaded"]

                local mapLoadedSharedEventHandlers = mapLoadedStateData.sharedEventHandlers

                removeEventHandler("event1:onPlayerArenaJoin", arenaElement, mapLoadedSharedEventHandlers.onArenaPlayerJoin)
                removeEventHandler("event1:onPlayerArenaQuit", arenaElement, mapLoadedSharedEventHandlers.onArenaPlayerQuit)

                removeEventHandler("event1:race:onPlayerSetCurrentRaceCheckpoint", arenaElement, mapLoadedSharedEventHandlers.onArenaRacePlayerSetCurrentRaceCheckpoint)

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
                
                setElementData(arenaElement, "state", nil--[[ , "subscribe" *]])
                setElementData(arenaElement, "mapDuration", nil--[[ , "subscribe" *]])

                local arenaPlayers = getElementChildren(arenaElement, "player")

                local removePlayerAllElementDataSubscriptions = race.removePlayerAllElementDataSubscriptions
                
                for i = 1, #arenaPlayers do
                    removePlayerAllElementDataSubscriptions(arenaPlayers[i])
                end

                race.destroyAllPlayerSpawnpointVehicles()

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

            local eventHandlers = race.eventHandlers

            addEventHandler("event1:race:onArenaMapResourceLoaded", arenaElement, eventHandlers.onArenaRaceMapResourceLoaded)
            addEventHandler("event1:race:onArenaMapResourceUnloading", arenaElement, eventHandlers.onArenaRaceMapResourceUnloading)
        end,

        onArenaDestroy = function()
            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = race.eventHandlers

            removeEventHandler("event1:race:onArenaMapResourceLoaded", arenaElement, eventHandlers.onArenaRaceMapResourceLoaded)
            removeEventHandler("event1:race:onArenaMapResourceUnloading", arenaElement, eventHandlers.onArenaRaceMapResourceUnloading)

            race.stop()
        end,

        ---

        onArenaRaceMapResourceLoaded = function(mapResource)
            race.start(mapResource)
        end,

        onArenaRaceMapResourceUnloading = function(mapResource)
            race.stop()
        end
    }
}

event1.managers.race = race

addEvent("event1:onArenaCreated")
addEvent("event1:onArenaDestroy")

addEvent("event1:race:onArenaMapResourceLoaded")
addEvent("event1:race:onArenaMapResourceUnloading")

addEvent("event1:onPlayerArenaJoin")
addEvent("event1:onPlayerArenaQuit")

addEvent("topList:topTimes:onPlayerThisResourceStart")
addEvent("topList:topTimes:onTopTimeUpdated")
addEvent("topList:topTimes:onTopTimeAdded")
addEvent("topList:topTimes:onTopTimeDeleted")
addEvent("topList:topTimes:onTopTimeRenamed")

addEvent("event1:race:onPlayerArenaJoin")
addEvent("event1:race:onPlayerArenaQuit")

addEvent("event1:race:onPlayerAllMapResourceElementsLoaded", true)
addEvent("event1:race:onPlayerSetCurrentRaceCheckpoint", true)
addEvent("event1:race:onPlayerRequestVehicleModelsSync", true)
addEvent("event1:race:onPlayerUnfreeze", true)
addEvent("event1:race:onPlayerKill", true)
addEvent("event1:race:onPlayerPickupRacePickup", true)
addEvent("event1:race:onPlayerReachedFinishLineInternal", true)

do
    local eventHandlers = race.eventHandlers

    addEventHandler("event1:onArenaCreated", resourceRoot, eventHandlers.onArenaCreated)
    addEventHandler("event1:onArenaDestroy", resourceRoot, eventHandlers.onArenaDestroy)
end