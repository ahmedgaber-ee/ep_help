local mathRandom = math.random
local mathRandomseed = math.randomseed

local stringFind = string.find
local stringGsub = string.gsub
local stringLower = string.lower
local stringFormat = string.format

local tableConcat = table.concat
local tableRemove = table.remove

local debuggerPrepareString = debugger.prepareString

local stringRemoveHex = function(string)
    return stringGsub(string, "#%x%x%x%x%x%x", "")
end

local rgbToHex = function(r, g, b)
    return stringFormat("#%02x%02x%02x", r, g, b)
end

local isResource = function(resource)
    return resource and getUserdataType(resource) == "resource-data"
end

local triggerClientResourceEvent = function(resource, ...)
    if getResourceState(resource) == "running" then
        return triggerClientEvent(...)
    end
end

local getPlayerFromPartialName = function(players, name)
    local name = stringLower(stringRemoveHex(name))

    for i = 1, #players do
        local player = players[i]

        local playerName = stringLower(stringRemoveHex(getPlayerName(player)))

        if stringFind(playerName, name, 1, true) then
            return player
        end
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

local getArenaFreeDimension = function()
    local arenaElements = getElementsByType("arena")

    local arenaElementsLen = #arenaElements

    for dimension = 0, 0xFFFF do
        local dimensionFree = true

        for i = 1, arenaElementsLen do
            local arenaElement = arenaElements[i]
    
            if dimension == getElementDimension(arenaElement) then
                dimensionFree = false
                break
            end
        end

        if dimensionFree then
            return dimension
        end
    end
end

local resourceName = getResourceName(resource)

event1 = {
    settings = {
        chatMessageDelay = 250
    },

    create = function()
        if not event1.data then
            local data = {}

            local arenaID = "event1"
            local arenaName = "Event (1)"
            local arenaMaxPlayers = 128
            local arenaLocked = false
            local arenaPassword = false
            local arenaEventMode = "wff"
            local arenaEventState = false
            local arenaChatState = true

            local arenaAllowedMapDirectories = {
                ["dm"] = true,
                ["os"] = true,
                ["hdm"] = true,
                ["hunter"] = true,
                ["dd"] = true,
                ["race"] = true
            }
        
            local arenaAllowedEventModes = {
                ["wff"] = true,
                ["wff2"] = true,
                ["hdm"] = true,
                ["teamwff"] = true,
                ["teamwff2"] = true,
                ["teamhdm"] = true,
                ["cw"] = true,
                ["ddcw"] = true,
                ["draft"] = true,
            }

            local arenaDimension = getArenaFreeDimension()

            local arenaElement = createElement("arena", arenaID)
            local sourceElement = createElement("source")

            setElementParent(sourceElement, arenaElement)

            setElementData(arenaElement, "name", arenaName)
            setElementData(arenaElement, "maxPlayers", arenaMaxPlayers)
            setElementData(arenaElement, "locked", arenaLocked)
            setElementData(arenaElement, "password", arenaPassword)
            setElementData(arenaElement, "resourceName", resourceName, "local")

            setElementDimension(arenaElement, arenaDimension)

            local eventHandlers = event1.eventHandlers

            addEventHandler("event1:onPlayerThisResourceStart", root, eventHandlers.onPlayerThisResourceStart)
            addEventHandler("onPlayerQuit", root, eventHandlers.onPlayerQuit)

            addEventHandler("onResourceStart", root, eventHandlers.onResourceStart)
            addEventHandler("onResourceStop", root, eventHandlers.onResourceStop)

            addEventHandler("mapManager:onMapResourcesRefresh", root, eventHandlers.onMapResourcesRefresh)
            addEventHandler("mapManager:onMapResourceLoaded", root, eventHandlers.onMapResourceLoaded)
            addEventHandler("mapManager:onMapResourceUnloading", root, eventHandlers.onMapResourceUnloading)

            addEventHandler("mapManager:mapLoader:onMapResourceLoaded", arenaElement, eventHandlers.onArenaMapLoaderMapResourceLoaded)
            addEventHandler("onElementDataChange", arenaElement, eventHandlers.onArenaElementDataChange)
            addEventHandler("onPlayerChat", arenaElement, eventHandlers.onArenaPlayerChat)
            addEventHandler("onPlayerLogin", arenaElement, eventHandlers.onArenaPlayerLogin)
            addEventHandler("onPlayerLogout", arenaElement, eventHandlers.onArenaPlayerLogout)
            addEventHandler("onPlayerQuit", arenaElement, eventHandlers.onArenaPlayerQuit)

            addEventHandler("onResourceStop", resourceRoot, eventHandlers.onThisResourceStop)

            local commandHandlers = event1.commandHandlers

            addCommandHandler("redo", commandHandlers.redo)
            addCommandHandler("random", commandHandlers.random)
            addCommandHandler("nextmap", commandHandlers.nextmap)
            addCommandHandler("togglechat", commandHandlers.toggleChat)
            addCommandHandler("toggleplayerchat", commandHandlers.togglePlayerChat)
            addCommandHandler("toggleeventmode", commandHandlers.toggleEventMode)
            addCommandHandler("togglearenalock", commandHandlers.toggleArenaLock)
            addCommandHandler("setmap", commandHandlers.setMap)
            addCommandHandler("showmaplist", commandHandlers.showMaplist)
            
            data.arenaElement = arenaElement
            data.sourceElement = sourceElement

            data.eventMode = arenaEventMode
            data.eventState = arenaEventState
            data.chatState = arenaChatState

            data.arenaAllowedMapDirectories = arenaAllowedMapDirectories

            data.arenaAllowedEventModes = arenaAllowedEventModes

            data.chatPlayerMessageTicks = {}

            data.nextMapPlayerSearch = {}

            data.chatAllowedPlayers = {}

            data.mapResources = {}

            data.mapList = {}

            event1.data = data

            event1.cacheMapResources()

            triggerClientResourceEvent(resource, event1.loadedPlayers, "event1:onClientArenaCreatedInternal", sourceElement, arenaElement)

            triggerEvent("event1:onArenaCreated", sourceElement)

            outputDebugString(debuggerPrepareString("Arena created (id: " .. tostring(arenaID) .. ", name: " .. tostring(arenaName) .. ", max players: " .. tostring(arenaMaxPlayers) .. ", locked: " .. tostring(arenaLocked) .. ", password: " .. tostring(password) .. ", dimension: " .. tostring(arenaDimension) .. ").", 1))
        end
    end,

    destroy = function()
        local data = event1.data

        if data then
            local arenaElement = data.arenaElement

            outputDebugString(debuggerPrepareString("Destroying arena (id: " .. tostring(getElementID(arenaElement)) .. ").", 1))

            local sourceElement = data.sourceElement

            triggerEvent("event1:onArenaDestroy", sourceElement)

            triggerClientResourceEvent(resource, event1.loadedPlayers, "event1:onClientArenaDestroyInternal", sourceElement)

            local eventHandlers = event1.eventHandlers
            
            removeEventHandler("event1:onPlayerThisResourceStart", root, eventHandlers.onPlayerThisResourceStart)
            removeEventHandler("onPlayerQuit", root, eventHandlers.onPlayerQuit)

            removeEventHandler("onResourceStart", root, eventHandlers.onResourceStart)
            removeEventHandler("onResourceStop", root, eventHandlers.onResourceStop)

            removeEventHandler("mapManager:onMapResourcesRefresh", root, eventHandlers.onMapResourcesRefresh)
            removeEventHandler("mapManager:onMapResourceLoaded", root, eventHandlers.onMapResourceLoaded)
            removeEventHandler("mapManager:onMapResourceUnloading", root, eventHandlers.onMapResourceUnloading)
            
            removeEventHandler("mapManager:mapLoader:onMapResourceLoaded", arenaElement, eventHandlers.onArenaMapLoaderMapResourceLoaded)
            removeEventHandler("onElementDataChange", arenaElement, eventHandlers.onArenaElementDataChange)
            removeEventHandler("onPlayerChat", arenaElement, eventHandlers.onArenaPlayerChat)
            removeEventHandler("onPlayerLogin", arenaElement, eventHandlers.onArenaPlayerLogin)
            removeEventHandler("onPlayerLogout", arenaElement, eventHandlers.onArenaPlayerLogout)
            removeEventHandler("onPlayerQuit", arenaElement, eventHandlers.onArenaPlayerQuit)
            
            removeEventHandler("onResourceStop", resourceRoot, eventHandlers.onThisResourceStop)
            
            local commandHandlers = event1.commandHandlers
            
            removeCommandHandler("redo", commandHandlers.redo)
            removeCommandHandler("random", commandHandlers.random)
            removeCommandHandler("nextmap", commandHandlers.nextmap)
            removeCommandHandler("togglechat", commandHandlers.toggleChat)
            removeCommandHandler("toggleplayerchat", commandHandlers.togglePlayerChat)
            removeCommandHandler("toggleeventmode", commandHandlers.toggleEventMode)
            removeCommandHandler("togglearenalock", commandHandlers.toggleArenaLock)
            removeCommandHandler("setmap", commandHandlers.setMap)
            removeCommandHandler("showmaplist", commandHandlers.showMaplist)

            event1.movePlayersToLobby()
            
            if isElement(arenaElement) then
                destroyElement(arenaElement)
            end

            if isElement(sourceElement) then
                destroyElement(sourceElement)
            end

            event1.data = nil
        end
    end,

    addPlayerToArena = function(player, password)
        local data = event1.data

        local arenaElement = data.arenaElement

        local playerArenaElement = event1.getPlayerArenaElement(player)

        if playerArenaElement ~= arenaElement then
            local arenaElementPlayerCount = #getElementChildren(arenaElement, "player")

            local arenaElementMaxPlayers = getElementData(arenaElement, "maxPlayers", false)

            if arenaElementPlayerCount < arenaElementMaxPlayers then
                local allowJoinArena = false

                local arenaElementLocked = getElementData(arenaElement, "locked", false)

                if not arenaElementLocked then
                    allowJoinArena = true
                else
                    local arenaElementPassword = getElementData(arenaElement, "password", false)

                    if password == arenaElementPassword then
                        allowJoinArena = true
                    else
                        if hasObjectPermissionTo(player, "resource." .. resourceName .. ".allowJoinArenaWhenLocked", false) then
                            allowJoinArena = true
                        end
                    end
                end

                if allowJoinArena then
                    local arenaElementDimension = getElementDimension(arenaElement)

                    if playerArenaElement then
                        local playerArenaElementResourceName = getElementData(playerArenaElement, "resourceName", false)

                        if playerArenaElementResourceName then
                            silentExport(playerArenaElementResourceName, "removePlayerFromArena", player)
                        end
                    end
                    
                    setElementParent(player, arenaElement)
                    spawnPlayer(player, 0, 0, 0, 0, 0, 0, arenaElementDimension)
                    fadeCamera(player, true)
                    setCameraTarget(player, player)
                    setElementFrozen(player, true)

                    event1.addPlayerAllElementDataSubscriptions(player)

                    triggerClientResourceEvent(resource, event1.loadedPlayers, "event1:onClientPlayerArenaJoin", player)

                    triggerEvent("event1:onPlayerArenaJoin", player)

                    local mapResource = data.mapResource

                    if mapResource then
                        silentExport("ep_mapmanager", "sendMap", mapResource, player, 1)
                    else
                        event1.loadMap()
                    end
                end
            end
        end
    end,

    removePlayerFromArena = function(player, quitType)
        local data = event1.data

        local arenaElement = data.arenaElement

        local playerArenaElement = event1.getPlayerArenaElement(player)

        if playerArenaElement == arenaElement then
            local arenaPlayers = getElementChildren(data.arenaElement, "player")

            if #arenaPlayers < 2 then
                event1.unloadMap()
            else
                silentExport("ep_mapmanager", "unloadMap", data.mapResource, player, 1)
            end

            data.chatAllowedPlayers[player] = nil

            data.nextMapPlayerSearch[player] = nil

            data.chatPlayerMessageTicks[player] = nil

            triggerEvent("event1:onPlayerArenaQuit", player, quitType)

            triggerClientResourceEvent(resource, event1.loadedPlayers, "event1:onClientPlayerArenaQuit", player, quitType)

            event1.removePlayerAllElementDataSubscriptions(player)

            spawnPlayer(player, 0, 0, 0, 0, 0, 0, 0)
            fadeCamera(player, true)
            setCameraTarget(player, player)
            setElementFrozen(player, true)
            setElementParent(player, root)
        end
    end,

    movePlayersToLobby = function()
        local data = event1.data

        local arenaPlayers = getElementChildren(data.arenaElement, "player")

        local removePlayerFromArena = event1.removePlayerFromArena

        for i = 1, #arenaPlayers do
            local arenaPlayer = arenaPlayers[i]

            removePlayerFromArena(arenaPlayer)

            silentExport("ep_arena_lobby", "addPlayerToArena", arenaPlayer)
        end
    end,

    loadMap = function(mapResource)
        event1.unloadMap()

        local data = event1.data

        local mapResource = mapResource or data.nextMapResource or event1.getRandomMapResource()

        if mapResource then
            local arenaElement = data.arenaElement

            data.mapResource = mapResource
            data.mapTargetLoadCount = silentExport("ep_mapmanager", "getLoadCount") + 1
            
            if mapResource == data.nextMapResource then
                data.nextMapResource = nil
                
                setElementData(arenaElement, "nextMapName", nil)
            end

            silentExport("ep_mapmanager", "loadMap", mapResource, data.sourceElement)
        end
    end,

    unloadMap = function()
        local data = event1.data

        local mapResource = data.mapResource
    
        if mapResource then
            local arenaElement = data.arenaElement

            local mapInfo = getElementData(arenaElement, "mapInfo", false)

            if mapInfo then
                triggerEvent("event1:" .. tostring(mapInfo.directory) .. ":onArenaMapResourceUnloading", data.sourceElement, mapResource)
    
                silentExport("ep_mapmanager", "unloadMap", mapResource, arenaElement)
                
                setElementData(arenaElement, "mapInfo", nil)
            end

            data.mapResource = nil
            data.mapTargetLoadCount = nil
        end
    end,

    setNextMap = function(mapResource)
        local data = event1.data

        data.nextMapResource = mapResource

        local arenaElement = data.arenaElement

        local nextMapName = getResourceInfo(mapResource, "name") or "Unnamed"

        triggerClientResourceEvent(resource, arenaElement, "event1:onClientArenaNextMapSet", data.sourceElement, nextMapName)

        setElementData(arenaElement, "nextMapName", nextMapName)
    end,

    setEventModeState = function(state)
        local data = event1.data

        local oldEventState = data.eventState

        if state ~= oldEventState then
            data.eventState = state

            triggerEvent("event1:" .. tostring(data.eventMode) .. ":onEventStateSet", data.sourceElement, state)
        end
    end,

    setEventMode = function(mode)
        local data = event1.data

        local oldEventMode = data.eventMode

        if mode ~= oldEventMode then
            data.eventMode = mode

            local sourceElement = data.sourceElement

            if oldEventMode then
                triggerEvent("event1:" .. tostring(oldEventMode) .. ":onEventStateSet", sourceElement, false)
            end

            triggerEvent("event1:" .. tostring(mode) .. ":onEventStateSet", sourceElement, true)
        end
    end,

    setPlayerLoaded = function(player)
        local isLoaded = event1.isPlayerLoaded(player)

        if not isLoaded then
            local loadedPlayers = event1.loadedPlayers
    
            loadedPlayers[#loadedPlayers + 1] = player
        end
    end,

    setPlayerNotLoaded = function(player)
        local isLoaded, index = event1.isPlayerLoaded(player)

        if isLoaded then
            tableRemove(event1.loadedPlayers, index)
        end
    end,

    isPlayerLoaded = function(player)
        local loadedPlayers = event1.loadedPlayers

        for i = 1, #loadedPlayers do
            if loadedPlayers[i] == player then
                return true, i
            end
        end
    end,

    addPlayerAllElementDataSubscriptions = function(player)
        local data = event1.data

        local arenaPlayers = getElementChildren(data.arenaElement, "player")

        for i = 1, #arenaPlayers do
            local arenaPlayer = arenaPlayers[i]

            silentExport("ep_core", "addPlayerAllDataSubscriber", arenaPlayer, player)
            silentExport("ep_core", "addPlayerAllDataSubscriber", player, arenaPlayer)
        end
    end,

    removePlayerAllElementDataSubscriptions = function(player)
        local data = event1.data

        local arenaPlayers = getElementChildren(data.arenaElement, "player")

        for i = 1, #arenaPlayers do
            local arenaPlayer = arenaPlayers[i]

            silentExport("ep_core", "removePlayerAllDataSubscriber", arenaPlayer, player)
            silentExport("ep_core", "removePlayerAllDataSubscriber", player, arenaPlayer)
        end
    end,

    addMapResource = function(resource)
        local data = event1.data

        local mapResources = data.mapResources

        mapResources[#mapResources + 1] = { resource, getResourceInfo(resource, "name") or "Unnamed" }
    end,

    removeMapResource = function(resource)
        local data = event1.data

        local mapResources = data.mapResources

        for i = 1, #mapResources do
            local mapData = mapResources[i]

            if mapData[1] == resource then
                tableRemove(mapResources, i)
                
                break
            end
        end
    end,

    cacheMapResources = function()
        local data = event1.data

        local mapResources = {}

        for directory in pairs(data.arenaAllowedMapDirectories) do
            local directoryMaps = silentExport("ep_mapmanager", "getDirectoryMaps", directory)

            if directoryMaps then
                for i = 1, #directoryMaps do
                    local mapResource = directoryMaps[i]

                    if isResource(mapResource) then
                        mapResources[#mapResources + 1] = { mapResource, getResourceInfo(mapResource, "name") or "Unnamed" }
                    end
                end
            end
        end

        data.mapResources = mapResources
    end,

    getMapResourcesFromMapNamePart = function(mapNamePart)
        mapNamePart = stringLower(mapNamePart)

        local data = event1.data

        local mapResources = {}

        local cachedMapResources = data.mapResources

        for i = 1, #cachedMapResources do
            local mapResource, mapName = unpack(cachedMapResources[i])

            if stringFind(stringLower(mapName), mapNamePart, 1, true) then
                mapResources[#mapResources + 1] = { mapResource, mapName }
            end
        end

        return mapResources
    end,

    getRandomMapResource = function()
        local data = event1.data

        local mapResources = data.mapResources

        local mapResourcesLen = #mapResources

        if mapResourcesLen > 0 then
            mathRandomseed(getTickCount()^5)

            return mapResources[mathRandom(mapResourcesLen)][1]
        end
    end,

    getPlayerArenaElement = function(player)
        local parentElement = getElementParent(player)

        if getElementType(parentElement) == "arena" then
            return parentElement
        end
    end,

    eventHandlers = {
        onThisResourceStart = function()
            event1.create()
        end,

        ---
        
        onPlayerThisResourceStart = function()
            if source == client then
                local data = event1.data

                triggerClientResourceEvent(resource, client, "event1:onClientArenaStart", client, data.arenaElement)

                event1.setPlayerLoaded(client)
            end
        end,

        onPlayerQuit = function()
            event1.setPlayerNotLoaded(source)
        end,

        onResourceStart = function(startedResource)
            local resourceStartFunction = event1.resourceStartFunctions[getResourceName(startedResource)]

            if resourceStartFunction then
                resourceStartFunction(startedResource)
            end
        end,

        onResourceStop = function(stoppedResource)
            local resourceStopFunction = event1.resourceStopFunctions[getResourceName(stoppedResource)]

            if resourceStopFunction then
                resourceStopFunction(stoppedResource)
            end
        end,

        onMapResourcesRefresh = function()
            event1.cacheMapResources()

            local data = event1.data

            local mapResource = data.mapResource

            if type(mapResource) == "userdata" and not isResource(mapResource) then
                event1.removeMapResource(mapResource)

                event1.loadMap()
                
                outputChatBox("#CCCCCCCurrent map has been deleted", data.arenaElement, 255, 255, 255, true)
            end
        end,

        onMapResourceLoaded = function(resource)
            local data = event1.data

            local mapResourceDirectory = silentExport("ep_mapmanager", "getMapOrganizationalDirectory", mapResource)

            if data.arenaAllowedMapDirectories[mapResourceDirectory] then
                event1.addMapResource(resource)
            end
        end,

        onMapResourceUnloading = function(resource)
            local data = event1.data

            if resource == data.mapResource then
                event1.removeMapResource(resource)

                event1.loadMap()

                outputChatBox("#CCCCCCCurrent map has been deleted", data.arenaElement, 255, 255, 255, true)
            end
        end,

        onArenaMapLoaderMapResourceLoaded = function(mapResource, loadCount)
            local data = event1.data

            if mapResource == data.mapResource and loadCount == data.mapTargetLoadCount then
                local mapResourceDirectory = silentExport("ep_mapmanager", "getMapOrganizationalDirectory", mapResource)
                
                local mapName = getResourceInfo(mapResource, "name") or "Unnamed"

                local arenaElement = data.arenaElement

                setElementData(arenaElement, "mapInfo", { directory = mapResourceDirectory, name = mapName, resourceName = getResourceName(mapResource) })

                silentExport("ep_mapmanager", "sendMap", mapResource, arenaElement)

                triggerEvent("event1:" .. tostring(mapResourceDirectory) .. ":onArenaMapResourceLoaded", data.sourceElement, mapResource)
            end
        end,

        onArenaElementDataChange = function(key, oldValue, newValue)
            if client then
                local sourceType = getElementType(source)

                local msg = sourceType == "player" and "playerName: " .. getPlayerName(source) or "sourceID: " .. (getElementID(source) or "")
    
                outputDebugString(debuggerPrepareString("Possible rouge client (client: " .. getPlayerName(client) .. ", key: " .. tostring(key) .. ", oldValue: " .. tostring(oldValue) .. ", newValue: " .. tostring(newValue) .. ", sourceType: " .. sourceType .. ", " .. msg .. ").", 3))

                setElementData(source, key, oldValue)
            end
        end,

        onArenaPlayerChat = function(message, messageType)
            cancelEvent()

            local chatMessageTypeFunction = event1.chatMessageTypeFunctions[messageType]

            if chatMessageTypeFunction then
                chatMessageTypeFunction(source, message)
            end
        end,

        onArenaPlayerLogin = function()
            triggerClientResourceEvent(resource, event1.data.arenaElement, "event1:onClientPlayerLogin", source)
        end,

        onArenaPlayerLogout = function()
            triggerClientResourceEvent(resource, event1.data.arenaElement, "event1:onClientPlayerLogout", source)
        end,

        onArenaPlayerQuit = function(quitType)
            event1.removePlayerFromArena(source, quitType)
        end,

        onThisResourceStop = function()
            event1.destroy()
        end
    },

    commandHandlers = {
        redo = function(player, commandName)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".cmd_" .. commandName, false) then
                local data = event1.data

                local arenaElement = data.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local mapResource = data.mapResource
    
                    if mapResource then
                        event1.loadMap(mapResource)
    
                        outputChatBox("#CCCCCCMap restarted by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    end
                end
            end
        end,

        random = function(player, commandName)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".cmd_" .. commandName, false) then
                local data = event1.data

                local arenaElement = data.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    event1.loadMap()

                    outputChatBox("#CCCCCCMap randomized by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                end
            end
        end,

        nextmap = function(player, commandName, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".cmd_" .. commandName, false) then
                local data = event1.data

                local arenaElement = data.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local arg = { ... }

                    if #arg > 0 then
                        local mapID = tonumber(arg[1])

                        local playerSearch = data.nextMapPlayerSearch[player]
        
                        if mapID and playerSearch then
                            local search = playerSearch[mapID]
        
                            if search then
                                local resource, mapName = unpack(search)

                                if isResource(resource) then
                                    if data.nextMapResource ~= resource then
                                        event1.setNextMap(resource)

                                        data.nextMapPlayerSearch[player] = nil

                                        outputChatBox("#CCCCCCNext map set to #FFFFFF" .. mapName .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                                    else
                                        outputChatBox("#CCCCCCThis map is already set", player, 255, 255, 255, true)
                                    end
                                end
                            end
                        else
                            local mapNamePart = tableConcat(arg, " ")
                
                            local resources = event1.getMapResourcesFromMapNamePart(mapNamePart)

                            local resourcesLen = #resources
                
                            if resourcesLen == 0 or resourcesLen > 1 then
                                outputChatBox("#FFFFFF" .. resourcesLen .. " #CCCCCCmatches found", player, 255, 255, 255, true)
                
                                if resourcesLen < 6 then
                                    local playerSearch = {}
        
                                    for i = 1, resourcesLen do
                                        local resource, mapName = unpack(resources[i])
                                        
                                        playerSearch[i] = { resource, mapName }
        
                                        outputChatBox("/" .. commandName .. " " .. i .. " - " .. mapName, player, 255, 255, 255, true)
                                    end
        
                                    data.nextMapPlayerSearch[player] = playerSearch
                                end
                            else
                                local resource, mapName = unpack(resources[1])
                                
                                if isResource(resource) then
                                    if data.nextMapResource ~= resource then
                                        event1.setNextMap(resource)

                                        data.nextMapPlayerSearch[player] = nil

                                        outputChatBox("#CCCCCCNext map set to #FFFFFF" .. mapName .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                                    else
                                        outputChatBox("#CCCCCCThis map is already set", player, 255, 255, 255, true)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end,

        toggleChat = function(player, commandName)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".cmd_" .. commandName, false) then
                local data = event1.data

                local arenaElement = data.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local newChatState = not data.chatState

                    data.chatState = newChatState

                    if newChatState then
                        outputChatBox("#CCCCCCChat has been #00FF00enabled #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    else
                        outputChatBox("#CCCCCCChat has been #FF0000disabled #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    end
                end
            end
        end,

        togglePlayerChat = function(player, commandName, playerPartialName)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".cmd_" .. commandName, false) then
                local data = event1.data

                local arenaElement = data.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local arenaPlayers = getElementChildren(arenaElement, "player")

                    local targetPlayer = getPlayerFromPartialName(arenaPlayers, playerPartialName)

                    if targetPlayer then
                        local chatAllowedPlayers = data.chatAllowedPlayers

                        local playerChatState = (not chatAllowedPlayers[targetPlayer]) and true or nil

                        chatAllowedPlayers[targetPlayer] = playerChatState

                        if playerChatState then
                            outputChatBox(getPlayerName(targetPlayer) .. " #CCCCCChas been #00FF00allowed #CCCCCCto chat by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                        else
                            outputChatBox(getPlayerName(targetPlayer) .. " #CCCCCChas been #FF0000disallowed #CCCCCCto chat by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                        end
                    end
                end
            end
        end,

        toggleEventMode = function(player, commandName)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".cmd_" .. commandName, false) then
                local data = event1.data

                local arenaElement = data.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local newEventState = not data.eventState

                    event1.setEventModeState(newEventState)
                    
                    local commandHandlers = event1.commandHandlers

                    if newEventState then
                        addCommandHandler("seteventmode", commandHandlers.setEventMode)

                        outputChatBox("#CCCCCCEvent mode has been #00FF00enabled #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    else
                        removeCommandHandler("seteventmode", commandHandlers.setEventMode)

                        outputChatBox("#CCCCCCEvent mode has been #FF0000disabled #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    end
                end
            end
        end,

        toggleArenaLock = function(player, commandName)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".cmd_" .. commandName, false) then
                local data = event1.data

                local arenaElement = data.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local newLocked = not getElementData(arenaElement, "locked", false)

                    setElementData(arenaElement, "locked", newLocked)

                    if newLocked then
                        outputChatBox("#CCCCCCArena has been #FF0000locked #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    else
                        outputChatBox("#CCCCCCArena has been #00FF00unlocked #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    end
                end
            end
        end,

        setEventMode = function(player, commandName, mode)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".cmd_" .. commandName, false) then
                local data = event1.data

                local arenaElement = data.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    mode = tostring(mode)

                    if mode then
                        if data.arenaAllowedEventModes[mode] then
                            event1.setEventMode(mode)

                            outputChatBox("#CCCCCCEvent mode has been set to #FFFFFF" .. mode .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                        else
                            outputChatBox("#CCCCCCInvalid event1 mode specified", player, 255, 255, 255, true)
                        end
                    else
                        outputChatBox("#CCCCCCNo event1 mode specified", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setMap = function(player, commandName, mapID, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".cmd_" .. commandName, false) then
                local data = event1.data

                local arenaElement = data.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    mapID = tonumber(mapID)

                    if mapID then
                        local mapName = tableConcat({ ... }, " ")

                        if mapName then
                            data.mapList[mapID] = mapName

                            outputChatBox("#CCCCCCMap id: #FFFFFF" .. tostring(mapID) .. " #CCCCCCset to: #FFFFFF" .. mapName, player, 255, 255, 255, true)
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [map id] [map name]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        showMaplist = function(player, commandName)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".cmd_" .. commandName, false) then
                local data = event1.data

                local arenaElement = data.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    outputChatBox("#CCCCCCCurrent maplist:", player, 255, 255, 255, true)

                    for mapID, mapName in pairs(data.mapList) do
                        outputChatBox(tostring(mapID) .. ": " .. mapName, player, 255, 255, 255, true)
                    end
                end
            end
        end
    },

    chatMessageTypeFunctions = {
        [0] = function(player, message)
            local data = event1.data

            if data.chatState or data.chatAllowedPlayers[player] then
                local arenaElement = data.arenaElement

                local chatPlayerMessageTicks = data.chatPlayerMessageTicks

                local chatPlayerTick = chatPlayerMessageTicks[player]

                if chatPlayerTick and getTickCount() - chatPlayerTick < event1.settings.chatMessageDelay then
                    outputChatBox("Please refrain from spamming", player, 255, 0, 0)
                else
                    local r, g, b = 255, 255, 255
        
                    local team = getPlayerTeam(player)
        
                    if team then
                        r, g, b = getTeamColor(team)
                    end
        
                    local hex = rgbToHex(r, g, b)
        
                    local playerName = getPlayerName(player)
        
                    outputChatBox(hex .. playerName .. ": #EBDDB2" .. message, arenaElement, 255, 255, 255, true)
        
                    outputServerLog("(" .. getElementID(arenaElement) .. ") " .. playerName .. ": " .. message)
                end

                chatPlayerMessageTicks[player] = getTickCount()
            else
                outputChatBox("You are not allowed to use chat", player, 255, 0, 0)
            end
        end,

        [1] = function(player, message)

        end,

        [2] = function(player, message)
            local team = getPlayerTeam(player)

            if team then
                local data = event1.data

                local chatPlayerMessageTicks = data.chatPlayerMessageTicks

                local chatPlayerTick = chatPlayerMessageTicks[player]

                if chatPlayerTick and getTickCount() - chatPlayerTick < event1.settings.chatMessageDelay then
                    outputChatBox("Please refrain from spamming", player, 255, 0, 0)
                else
                    local playerName = getPlayerName(player)

                    local r, g, b = getTeamColor(team)
        
                    outputChatBox("(Team) " .. playerName .. ": #EBDDB2" .. message, getPlayersInTeam(team), r, g, b, true)
    
                    outputServerLog("(team) " .. playerName .. ": " .. message)
                end

                chatPlayerMessageTicks[player] = getTickCount()
            end
        end
    },

    resourceStartFunctions = {
        ["ep_mapmanager"] = function(resource)
            event1.cacheMapResources()

            local data = event1.data

            local arenaPlayers = getElementChildren(data.arenaElement, "player")

            if #arenaPlayers > 0 then
                event1.loadMap()
            end
        end
    },

    resourceStopFunctions = {
        ["ep_mapmanager"] = function(resource)
            event1.unloadMap()
        end
    },

    loadedPlayers = {},

    managers = {},

    addons = {},

    modes = {}
}

addEvent("event1:onPlayerThisResourceStart", true)

addEvent("mapManager:onMapResourcesRefresh")
addEvent("mapManager:onMapResourceLoaded")
addEvent("mapManager:onMapResourceUnloading")
addEvent("mapManager:mapLoader:onMapResourceLoaded")

do
    local eventHandlers = event1.eventHandlers

    addEventHandler("onResourceStart", resourceRoot, eventHandlers.onThisResourceStart)
end

do
    local exportedFunctionNames = {
        "addPlayerToArena",
        "removePlayerFromArena"
    }

    for i = 1, #exportedFunctionNames do
        local exportedFunctionName = exportedFunctionNames[i]

        do
            local exportedFunction = event1[exportedFunctionName]

            _G[exportedFunctionName] = function(...)
                return exportedFunction(...)
            end
        end
    end
end