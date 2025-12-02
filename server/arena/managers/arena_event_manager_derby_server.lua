local mathMin = math.min

local debuggerPrepareString = debugger.prepareString

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

local derby

derby = {
    start = function(mapResource)
        if not derby.data then
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

                    derby.data = data

                    derby.setState("map loaded")
                else
                    outputDebugString(debuggerPrepareString("Failed to start map. No spawnpoints found (resourceName: " .. tostring(getResourceName(mapResource)) .. ").", 2))

                    event1.loadMap()
                end
            end
        end
    end,

    stop = function()
        local data = derby.data

        if data then
            derby.setState("map unloading")

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
                local data = derby.data

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

                triggerClientResourceEvent(resource, arenaElement, "event1:derby:onClientArenaStateSetInternal", sourceElement, state)

                triggerEvent("event1:derby:onArenaStateSet", sourceElement, state)
            end
        end
    end,

    spawnPlayerAtSpawnpoint = function(player, spawnpointID)
        local data = derby.data

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

        derby.destroyPlayerSpawnpointVehicle(player)

        data.playerSpawnpointVehicles[player] = vehicle
    end,

    unfreezePlayerSpawnpointVehicle = function(player)
        local data = derby.data

        local vehicle = data.playerSpawnpointVehicles[player]

        if isElement(vehicle) then
            setElementFrozen(vehicle, false)
            setVehicleDamageProof(vehicle, false)
            setElementCollisionsEnabled(vehicle, true)
        end

        setElementFrozen(player, false)
    end,

    destroyPlayerSpawnpointVehicle = function(player)
        local data = derby.data

        local playerSpawnpointVehicles = data.playerSpawnpointVehicles

        local vehicle = playerSpawnpointVehicles[player]

        if isElement(vehicle) then
            destroyElement(vehicle)
        end

        playerSpawnpointVehicles[player] = nil
    end,

    destroyAllPlayerSpawnpointVehicles = function()
        local data = derby.data

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
        local data = derby.data

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

                local data = derby.data

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local sharedEventHandlers = stateData.sharedEventHandlers

                addEventHandler("event1:onPlayerArenaJoin", arenaElement, sharedEventHandlers.onArenaPlayerJoin)
                addEventHandler("event1:onPlayerArenaQuit", arenaElement, sharedEventHandlers.onArenaPlayerQuit)

                addEventHandler("onVehicleStartExit", arenaElement, sharedEventHandlers.onArenaVehicleStartExit)
                addEventHandler("onVehicleExit", arenaElement, sharedEventHandlers.onArenaVehicleExit)
                addEventHandler("onElementDestroy", arenaElement, sharedEventHandlers.onArenaElementDestroy)

                local localEventHandlers = stateData.localEventHandlers

                addEventHandler("event1:derby:onPlayerAllMapResourceElementsLoaded", arenaElement, localEventHandlers.onArenaDeathmatchPlayerAllMapResourceElementsLoaded)

                addEventHandler("event1:derby:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
                addEventHandler("event1:derby:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaDeathmatchPlayerQuit)

                addEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:derby:onPlayerAllMapResourceElementsLoaded", arenaElement, localEventHandlers.onArenaDeathmatchPlayerAllMapResourceElementsLoaded)

                removeEventHandler("event1:derby:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
                removeEventHandler("event1:derby:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaDeathmatchPlayerQuit)

                removeEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)

                stateData:killForcedCountdownTimer()

                stateData.playersToLoadCount = nil

                stateData.playersToLoad = nil
            end,

            cacheMapDuration = function(stateData)
                local data = derby.data

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
                
                local addPlayerAllElementDataSubscriptions = derby.addPlayerAllElementDataSubscriptions
                
                local spawnPlayerAtSpawnpoint = derby.spawnPlayerAtSpawnpoint

                local data = derby.data
                
                local spawnpointsCount = #data.mapSpawnpoints

                for i = 1, #arenaPlayers do
                    local arenaPlayer = arenaPlayers[i]
                    
                    addPlayerAllElementDataSubscriptions(arenaPlayer)

                    setElementData(arenaPlayer, "state", "not ready"--[[ , "subscribe" *]])

                    spawnPlayerAtSpawnpoint(arenaPlayer, (i - 1) % spawnpointsCount + 1)
                    
                    stateData:addPlayerToLoadQueue(arenaPlayer)
                end
            end,

            checkForCountdown = function(stateData)
                if stateData:arePlayersLoaded() then
                    stateData:killForcedCountdownTimer()

                    local loadedPlayers = stateData:getLoadedPlayers()

                    stateData.alivePlayers = loadedPlayers

                    stateData.alivePlayersCount = tableCount(loadedPlayers)

                    derby.setState("countdown starting")
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

                        triggerClientResourceEvent(resource, eventData.arenaElement, "event1:derby:onClientPlayerLoaded", player)
                    end
                end
            end,

            setPlayerUnloaded = function(stateData, player)
                local playerData = stateData.playersToLoad[player]

                if playerData then
                    if playerData.loaded then
                        playerData.loaded = nil

                        local eventData = event1.data

                        triggerClientResourceEvent(resource, eventData.arenaElement, "event1:derby:onClientPlayerUnloaded", player)
                    end
                end
            end,

            setPlayerSpawnpointID = function(stateData, player, spawnpointID)
                local data = derby.data

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
                    derby.addPlayerAllElementDataSubscriptions(source)

                    triggerEvent("event1:derby:onPlayerArenaJoin", source)
                end,

                onArenaPlayerQuit = function()
                    triggerEvent("event1:derby:onPlayerArenaQuit", source)

                    derby.removePlayerAllElementDataSubscriptions(source)
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
                            if derby.getPlayerVehicle(player) then
                                triggerEvent("onPlayerWasted", player)
                            end
                        end
                    end
                end
            },

            localEventHandlers = {
                onArenaDeathmatchPlayerAllMapResourceElementsLoaded = function()
                    if source == client then
                        local data = derby.data

                        local stateData = derby.states[data.state]
    
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

                    local data = derby.data

                    local arenaPlayers = getElementChildren(eventData.arenaElement, "player")
                    
                    derby.spawnPlayerAtSpawnpoint(source, (#arenaPlayers + 1 - 1) % #data.mapSpawnpoints + 1)

                    local stateData = derby.states[data.state]

                    stateData:addPlayerToLoadQueue(source)

                    triggerEvent("event1:derby:onPlayerJoinSpawn", source)
                end,

                onArenaDeathmatchPlayerQuit = function()
                    local data = derby.data

                    local stateData = derby.states[data.state]
                    
                    stateData:removePlayerFromLoadQueue(source)
                    stateData:checkForCountdown()
                end,

                onArenaPlayerWasted = function()
                    local eventData = event1.data

                    local arenaElement = eventData.arenaElement

                    local data = derby.data

                    local stateData = derby.states[data.state]

                    local playersToLoad = stateData.playersToLoad
                    
                    if playersToLoad[source] then
                        local arenaPlayers = getElementChildren(arenaElement, "player")

                        derby.spawnPlayerAtSpawnpoint(source, (#arenaPlayers + 1 - 1) % #data.mapSpawnpoints + 1)
                    else
                        spawnPlayer(source, 0, 0, 0, 0, 0, 0, getElementDimension(arenaElement))
                        setElementFrozen(source, true)

                        if getElementData(source, "state", false) ~= "dead" then
                            setElementData(source, "state", "dead"--[[ , "subscribe" *]])
    
                            local playerVehicle = derby.getPlayerVehicle(source)

                            if isElement(playerVehicle) then
                                setElementPosition(playerVehicle, 0, 0, 0)
                                setElementRotation(playerVehicle, 0, 0, 0)
                                setElementFrozen(playerVehicle, true)
                                setVehicleDamageProof(playerVehicle, true)
                                setElementCollisionsEnabled(playerVehicle, false)
                            end

                            triggerClientResourceEvent(resource, arenaElement, "event1:derby:onClientPlayerWastedInternal", source)

                            triggerEvent("event1:derby:onPlayerWasted", source)

                            if not next(playersToLoad) then
                                derby.setState("ended")
                            end
                        end
                    end
                end
            },

            localTimers = {
                forcedCountdown = function()
                    local data = derby.data

                    local stateData = derby.states[data.state]

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

                        derby.setState("countdown starting")
                    else
                        derby.setState("ended")
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

                addEventHandler("event1:derby:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
                addEventHandler("event1:derby:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaDeathmatchPlayerQuit)

                addEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:derby:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
                removeEventHandler("event1:derby:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaDeathmatchPlayerQuit)

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

                    local mapLoadedStateData = derby.states["map loaded"]

                    local alivePlayers = mapLoadedStateData.alivePlayers

                    if alivePlayers[source] then
                        setElementData(source, "state", "dead"--[[ , "subscribe" *]])
    
                        local playerVehicle = derby.getPlayerVehicle(source)

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

                        triggerClientResourceEvent(resource, arenaElement, "event1:derby:onClientPlayerWastedInternal", source, alivePlayersCount)

                        triggerEvent("event1:derby:onPlayerWasted", source)
    
                        if not next(alivePlayers) then
                            derby.setState("ended")
                        end
                    end
                end
            },

            localTimers = {
                countdownStart = function()
                    derby.setState("countdown started")
                end
            }
        },

        ["countdown started"] = {
            onStateSet = function(stateData)
                stateData:startCountdownTimer()

                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                addEventHandler("event1:derby:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
                addEventHandler("event1:derby:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaDeathmatchPlayerQuit)

                addEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:derby:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
                removeEventHandler("event1:derby:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaDeathmatchPlayerQuit)

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

                    local mapLoadedStateData = derby.states["map loaded"]

                    local alivePlayers = mapLoadedStateData.alivePlayers

                    if alivePlayers[source] then
                        setElementData(source, "state", "dead"--[[ , "subscribe" *]])
    
                        local playerVehicle = derby.getPlayerVehicle(source)

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
    
                        triggerClientResourceEvent(resource, arenaElement, "event1:derby:onClientPlayerWastedInternal", source, alivePlayersCount)

                        triggerEvent("event1:derby:onPlayerWasted", source)
    
                        if not next(alivePlayers) then
                            derby.setState("ended")
                        end
                    end
                end
            },

            localTimers = {
                countdown = function()
                    local remaining, executesRemaining, timeInterval = getTimerDetails(sourceTimer)

                    local countdownValue = executesRemaining - 1

                    local eventData = event1.data

                    triggerClientResourceEvent(resource, eventData.arenaElement, "event1:derby:onClientArenaCountdownValueUpdate", eventData.sourceElement, countdownValue)

                    if countdownValue == 0 then
                        derby.setState("running")
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

                addEventHandler("event1:derby:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
                addEventHandler("event1:derby:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaDeathmatchPlayerQuit)

                addEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)

                addEventHandler("event1:derby:onPlayerAllMapResourceElementsLoaded", arenaElement, localEventHandlers.onArenaDeathmatchPlayerAllMapResourceElementsLoaded)
                addEventHandler("event1:derby:onPlayerUnfreeze", arenaElement, localEventHandlers.onArenaDeathmatchPlayerUnfreeze)
                addEventHandler("event1:derby:onPlayerKill", arenaElement, localEventHandlers.onArenaDeathmatchPlayerKill)
                addEventHandler("event1:derby:onPlayerPickupRacePickup", arenaElement, localEventHandlers.onArenaDeathmatchPlayerPickupRacePickup)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:derby:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
                removeEventHandler("event1:derby:onPlayerArenaQuit", arenaElement, localEventHandlers.onArenaDeathmatchPlayerQuit)

                removeEventHandler("onPlayerWasted", arenaElement, localEventHandlers.onArenaPlayerWasted)

                removeEventHandler("event1:derby:onPlayerAllMapResourceElementsLoaded", arenaElement, localEventHandlers.onArenaDeathmatchPlayerAllMapResourceElementsLoaded)
                removeEventHandler("event1:derby:onPlayerUnfreeze", arenaElement, localEventHandlers.onArenaDeathmatchPlayerUnfreeze)
                removeEventHandler("event1:derby:onPlayerKill", arenaElement, localEventHandlers.onArenaDeathmatchPlayerKill)
                removeEventHandler("event1:derby:onPlayerPickupRacePickup", arenaElement, localEventHandlers.onArenaDeathmatchPlayerPickupRacePickup)

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

                    local mapLoadedStateData = derby.states["map loaded"]

                    local alivePlayers = mapLoadedStateData.alivePlayers

                    if alivePlayers[source] then
                        setElementData(source, "state", "dead"--[[ , "subscribe" *]])
    
                        local playerVehicle = derby.getPlayerVehicle(source)

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

                        triggerClientResourceEvent(resource, arenaElement, "event1:derby:onClientPlayerWastedInternal", source, alivePlayersCount)

                        triggerEvent("event1:derby:onPlayerWasted", source)
    
                        if not next(alivePlayers) then
                            derby.setState("ended")
                        end
                    end
                end,

                onArenaDeathmatchPlayerAllMapResourceElementsLoaded = function()
                    if source == client then
                        local data = derby.data

                        local stateData = derby.states[data.state]

                        local unloadedRacePickupIDs = stateData.unloadedRacePickupIDs

                        if next(unloadedRacePickupIDs) then
                            triggerClientResourceEvent(resource, client, "event1:derby:onClientRacePickupsUnload", client, unloadedRacePickupIDs)
                        end
                    end
                end,

                onArenaDeathmatchPlayerUnfreeze = function()
                    if source == client then
                        if derby.states["map loaded"].alivePlayers[client] then
                            derby.unfreezePlayerSpawnpointVehicle(client)
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
                        local data = derby.data

                        local stateData = derby.states[data.state]

                        respawn = tonumber(respawn)

                        if respawn and respawn + 1 > 50 then
                            local eventData = event1.data

                            triggerClientResourceEvent(resource, eventData.arenaElement, "event1:derby:onClientPlayerRacePickupUnload", client, id)

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
                end
            },

            localTimers = {
                timeIsUp = function()
                    for player in pairs(derby.states["map loaded"].alivePlayers) do
                        triggerEvent("onPlayerWasted", player)
                    end

                    local eventData = event1.data

                    outputChatBox("#CCCCCCTime is up!", eventData.arenaElement, 255, 255, 255, true)
                end,

                loadPickup = function(player, id)
                    local eventData = event1.data

                    triggerClientResourceEvent(resource, eventData.arenaElement, "event1:derby:onClientPlayerRacePickupLoad", player, id)

                    local data = derby.data

                    local stateData = derby.states[data.state]

                    stateData.unloadedRacePickupIDs[id] = nil
                end
            },

            localRacePickupFunctions = {
                ["vehiclechange"] = function(player, id, vehicle)
                    local data = derby.data

                    local playerVehicle = derby.getPlayerVehicle(player)

                    if playerVehicle then
                        vehicle = tonumber(vehicle)
    
                        if vehicle then
                            local eventData = event1.data

                            triggerClientResourceEvent(resource, eventData.arenaElement, "event1:derby:onClientPlayerSyncFunction", player, "setElementModel", playerVehicle, vehicle)
                        end
                    end
                end,

                ["nitro"] = function(player)
                    local data = derby.data

                    local playerVehicle = derby.getPlayerVehicle(player)

                    if playerVehicle then
                        local eventData = event1.data

                        triggerClientResourceEvent(resource, eventData.arenaElement, "event1:derby:onClientPlayerSyncFunction", player, "addVehicleUpgrade", playerVehicle, 1010)
                    end
                end,

                ["repair"] = function(player)
                    local data = derby.data

                    local playerVehicle = derby.getPlayerVehicle(player)

                    if playerVehicle then
                        local eventData = event1.data

                        triggerClientResourceEvent(resource, eventData.arenaElement, "event1:derby:onClientPlayerSyncFunction", player, "fixVehicle", playerVehicle)
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

                addEventHandler("event1:derby:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)
            end,

            onStateChanging = function(stateData)
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local localEventHandlers = stateData.localEventHandlers

                removeEventHandler("event1:derby:onPlayerArenaJoin", arenaElement, localEventHandlers.onArenaDeathmatchPlayerJoin)

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

                local mapLoadedStateData = derby.states["map loaded"]

                local mapLoadedSharedEventHandlers = mapLoadedStateData.sharedEventHandlers

                removeEventHandler("event1:onPlayerArenaJoin", arenaElement, mapLoadedSharedEventHandlers.onArenaPlayerJoin)
                removeEventHandler("event1:onPlayerArenaQuit", arenaElement, mapLoadedSharedEventHandlers.onArenaPlayerQuit)

                removeEventHandler("onVehicleStartExit", arenaElement, mapLoadedSharedEventHandlers.onArenaVehicleStartExit)
                removeEventHandler("onVehicleExit", arenaElement, mapLoadedSharedEventHandlers.onArenaVehicleExit)
                removeEventHandler("onElementDestroy", arenaElement, mapLoadedSharedEventHandlers.onArenaElementDestroy)

                setElementData(arenaElement, "state", nil--[[ , "subscribe" *]])
                setElementData(arenaElement, "mapDuration", nil--[[ , "subscribe" *]])

                local arenaPlayers = getElementChildren(arenaElement, "player")

                local removePlayerAllElementDataSubscriptions = derby.removePlayerAllElementDataSubscriptions
                
                for i = 1, #arenaPlayers do
                    removePlayerAllElementDataSubscriptions(arenaPlayers[i])
                end

                derby.destroyAllPlayerSpawnpointVehicles()

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

            local eventHandlers = derby.eventHandlers

            addEventHandler("event1:dd:onArenaMapResourceLoaded", arenaElement, eventHandlers.onArenaDeathmatchMapResourceLoaded)
            addEventHandler("event1:dd:onArenaMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)
        end,

        onArenaDestroy = function()
            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = derby.eventHandlers

            removeEventHandler("event1:dd:onArenaMapResourceLoaded", arenaElement, eventHandlers.onArenaDeathmatchMapResourceLoaded)
            removeEventHandler("event1:dd:onArenaMapResourceUnloading", arenaElement, eventHandlers.onArenaDeathmatchMapResourceUnloading)

            derby.stop()
        end,

        ---

        onArenaDeathmatchMapResourceLoaded = function(mapResource)
            derby.start(mapResource)
        end,

        onArenaDeathmatchMapResourceUnloading = function(mapResource)
            derby.stop()
        end
    }
}

event1.managers.derby = derby

addEvent("event1:onArenaCreated")
addEvent("event1:onArenaDestroy")

addEvent("event1:dd:onArenaMapResourceLoaded")
addEvent("event1:dd:onArenaMapResourceUnloading")

addEvent("event1:onPlayerArenaJoin")
addEvent("event1:onPlayerArenaQuit")

addEvent("event1:derby:onPlayerArenaJoin")
addEvent("event1:derby:onPlayerArenaQuit")

addEvent("event1:derby:onPlayerAllMapResourceElementsLoaded", true)
addEvent("event1:derby:onPlayerUnfreeze", true)
addEvent("event1:derby:onPlayerKill", true)
addEvent("event1:derby:onPlayerPickupRacePickup", true)

do
    local eventHandlers = derby.eventHandlers

    addEventHandler("event1:onArenaCreated", resourceRoot, eventHandlers.onArenaCreated)
    addEventHandler("event1:onArenaDestroy", resourceRoot, eventHandlers.onArenaDestroy)
end