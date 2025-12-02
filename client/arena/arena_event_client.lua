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

event1 = {
    create = function(arenaElement)
        if not event1.data then
            local data = {}

            local arenaLobbyOrdering = 1
            local arenaScoreboardOrdering = 1

            local eventHandlers = event1.eventHandlers

            addEventHandler("event1:onClientPlayerArenaJoin", localPlayer, eventHandlers.onClientArenaJoin)
            addEventHandler("event1:onClientPlayerArenaQuit", localPlayer, eventHandlers.onClientArenaQuit)

            addEventHandler("lobby:onClientArenaCreated", localPlayer, eventHandlers.onClientLobbyArenaCreated)

            addEventHandler("onClientResourceStart", root, eventHandlers.onClientResourceStart)

            addEventHandler("onClientResourceStop", resourceRoot, eventHandlers.onClientThisResourceStop)

            addEventHandler("event1:onClientPlayerArenaJoin", arenaElement, eventHandlers.onArenaPlayerJoin)
            addEventHandler("event1:onClientPlayerArenaQuit", arenaElement, eventHandlers.onArenaPlayerQuit)

            addEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)

            data.arenaLobbyOrdering = arenaLobbyOrdering
            data.arenaScoreboardOrdering = arenaScoreboardOrdering

            data.arenaElement = arenaElement

            event1.data = data

            event1.addArenaDataToScoreboard()

            silentExport("ep_arena_lobby", "addUIArena", arenaElement, arenaLobbyOrdering)

            triggerEvent("event1:onClientArenaCreated", localPlayer)
        end
    end,

    destroy = function()
        local data = event1.data

        if data then
            triggerEvent("event1:onClientArenaDestroy", localPlayer)
            
            local arenaElement = data.arenaElement

            silentExport("ep_arena_lobby", "removeUIArena", arenaElement)
            silentExport("ep_scoreboard", "removeUIArena", arenaElement)

            local eventHandlers = event1.eventHandlers

            removeEventHandler("event1:onClientPlayerArenaJoin", localPlayer, eventHandlers.onClientArenaJoin)
            removeEventHandler("event1:onClientPlayerArenaQuit", localPlayer, eventHandlers.onClientArenaQuit)

            removeEventHandler("lobby:onClientArenaCreated", localPlayer, eventHandlers.onClientLobbyArenaCreated)

            removeEventHandler("onClientResourceStart", root, eventHandlers.onClientResourceStart)

            removeEventHandler("onClientResourceStop", resourceRoot, eventHandlers.onClientThisResourceStop)

            removeEventHandler("event1:onClientPlayerArenaJoin", arenaElement, eventHandlers.onArenaPlayerJoin)
            removeEventHandler("event1:onClientPlayerArenaQuit", arenaElement, eventHandlers.onArenaPlayerQuit)
            
            removeEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)

            event1.data = nil
        end
    end,

    addArenaDataToScoreboard = function()
        local data = event1.data

        local arenaElement = data.arenaElement

        local arenaPlayers = getElementChildren(arenaElement, "player")

        silentExport("ep_scoreboard", "addUIArena", arenaElement, data.arenaScoreboardOrdering)

        for i = 1, #arenaPlayers do
            local arenaPlayer = arenaPlayers[i]

            silentExport("ep_scoreboard", "addUIPlayer", arenaPlayer, arenaElement)
        end
    end,

    updateRequestLabelPosition = function()
        local downloadUIState = silentExport("ep_download", "getUIState")

        if downloadUIState then
            local posX = silentExport("ep_raceui", "getRequestLabelSetting", "downloadPosX")
            local posY = silentExport("ep_raceui", "getRequestLabelSetting", "downloadPosY")

            silentExport("ep_raceui", "animateRequestLabelPosition", posX, posY)
        else
            local posX = silentExport("ep_raceui", "getRequestLabelSetting", "posX")
            local posY = silentExport("ep_raceui", "getRequestLabelSetting", "posY")

            silentExport("ep_raceui", "animateRequestLabelPosition", posX, posY)
        end
    end,

    getArenaVehicles = function()
        local eventData = event1.data

        local arenaElement = eventData.arenaElement

        local arenaVehicles = getElementChildren(arenaElement, "vehicle")

        local mapManagerResource = getResourceFromName("ep_mapmanager")

        if mapManagerResource and getResourceState(mapManagerResource) == "running" then
            local mapmanagerVehicles = getElementsByType("vehicle", getResourceRootElement(mapManagerResource))

            for i = 1, #mapmanagerVehicles do
                arenaVehicles[#arenaVehicles + 1] = mapmanagerVehicles[i]
            end
        end

        return arenaVehicles
    end,

    eventHandlers = {
        onClientThisResourceStart = function()
            triggerServerEvent("event1:onPlayerThisResourceStart", localPlayer)
        end,

        onClientArenaStart = function(arenaElement)
            event1.create(arenaElement)
        end,

        onArenaCreated = function(arenaElement)
            event1.create(arenaElement)
        end,

        onArenaDestroy = function()
            event1.destroy()
        end,

        ---

        onClientArenaJoin = function()
            setFPSLimit(51)

            setRadioChannel(0)
    
            setCameraClip(true, false)
    
            setPlayerHudComponentVisible("all", false)
            setPlayerHudComponentVisible("crosshair", true)
    
            engineSetAsynchronousLoading(true, true)

            local data = event1.data

            local arenaElement = data.arenaElement

            silentExport("ep_scoreboard", "setUIToggleState", true)
            silentExport("ep_scoreboard", "selectUIArena", arenaElement)

            local eventHandlers = event1.eventHandlers

            addEventHandler("mapManager:mapLoader:onClientMapResourceStarting", localPlayer, eventHandlers.onClientMapLoaderMapResourceStarting)
            addEventHandler("mapManager:mapLoader:onClientMapResourceUnloading", localPlayer, eventHandlers.onClientMapLoaderMapResourceUnloading)

            addEventHandler("onClientPlayerRadioSwitch", localPlayer, eventHandlers.onClientPlayerRadioSwitch)

            addEventHandler("onClientResourceStart", root, eventHandlers.onClientArenaResourceStart)

            addEventHandler("event1:onClientThisResourceStop", localPlayer, eventHandlers.onClientArenaThisResourceStop)

            addEventHandler("event1:onClientPlayerArenaJoin", arenaElement, eventHandlers.onArenaPlayerClientArenaJoin)
            addEventHandler("event1:onClientPlayerArenaQuit", arenaElement, eventHandlers.onArenaPlayerClientArenaQuit)
            addEventHandler("event1:onClientPlayerLogin", arenaElement, eventHandlers.onArenaPlayerClientArenaLogin)
            addEventHandler("event1:onClientPlayerLogout", arenaElement, eventHandlers.onArenaPlayerClientArenaLogout)
        end,

        onClientArenaQuit = function()
            local eventHandlers = event1.eventHandlers

            removeEventHandler("mapManager:mapLoader:onClientMapResourceStarting", localPlayer, eventHandlers.onClientMapLoaderMapResourceStarting)
            removeEventHandler("mapManager:mapLoader:onClientMapResourceUnloading", localPlayer, eventHandlers.onClientMapLoaderMapResourceUnloading)

            removeEventHandler("onClientPlayerRadioSwitch", localPlayer, eventHandlers.onClientPlayerRadioSwitch)

            removeEventHandler("onClientResourceStart", root, eventHandlers.onClientArenaResourceStart)

            removeEventHandler("event1:onClientThisResourceStop", localPlayer, eventHandlers.onClientArenaThisResourceStop)

            local data = event1.data

            local arenaElement = data.arenaElement

            removeEventHandler("event1:onClientPlayerArenaJoin", arenaElement, eventHandlers.onArenaPlayerClientArenaJoin)
            removeEventHandler("event1:onClientPlayerArenaQuit", arenaElement, eventHandlers.onArenaPlayerClientArenaQuit)
            removeEventHandler("event1:onClientPlayerLogin", arenaElement, eventHandlers.onArenaPlayerClientArenaLogin)
            removeEventHandler("event1:onClientPlayerLogout", arenaElement, eventHandlers.onArenaPlayerClientArenaLogout)

            silentExport("ep_arena_lobby", "setUIState", false)

            silentExport("ep_scoreboard", "setUIToggleState", false)
            silentExport("ep_scoreboard", "setUIState", false)
            
            setFPSLimit(51)

            setCameraClip()

            setPlayerHudComponentVisible("all", true)

            engineSetAsynchronousLoading(false, false)
        end,

        onClientLobbyArenaCreated = function()
            local data = event1.data

            silentExport("ep_arena_lobby", "addUIArena", data.arenaElement, data.arenaLobbyOrdering)
        end,

        onClientResourceStart = function(startedResource)
            local resourceStartFunction = event1.resourceStartFunctions[getResourceName(startedResource)]

            if resourceStartFunction then
                resourceStartFunction(startedResource)
            end
        end,

        onClientThisResourceStop = function()
            triggerEvent("event1:onClientThisResourceStop", localPlayer)

            event1.destroy()
        end,

        onArenaPlayerJoin = function()
            local data = event1.data

            local arenaElement = data.arenaElement

            silentExport("ep_scoreboard", "addUIPlayer", source, arenaElement)
        end,

        onArenaPlayerQuit = function(quitType)
            local data = event1.data

            local arenaElement = data.arenaElement

            silentExport("ep_scoreboard", "removeUIPlayer", source, arenaElement)
        end,

        onArenaPlayerTeamChange = function(oldTeam, newTeam)
            local data = event1.data

            local arenaElement = data.arenaElement

            --silentExport("ep_scoreboard", "removeUIPlayer", source, arenaElement)
            --silentExport("ep_scoreboard", "addUIPlayer", source, arenaElement) 
        end,

        ---

        onClientMapLoaderMapResourceStarting = function(resourceName)
            local data = event1.data

            local mapInfo = getElementData(data.arenaElement, "mapInfo", false)

            triggerEvent("event1:" .. tostring(mapInfo.directory) .. ":onClientMapResourceStarting", localPlayer)

            createTrayNotification("Starting map: " .. tostring(mapInfo.name or "Unnamed"))

            local eventHandlers = event1.eventHandlers

            addEventHandler("mapManager:mapLoader:onClientMapResourceElementFileDownloadStarted", localPlayer, eventHandlers.onClientMapLoaderMapResourceElementFileDownloadStarted)
            addEventHandler("mapManager:mapLoader:onClientMapResourceElementFilesDownloadStarted", localPlayer, eventHandlers.onClientMapLoaderMapResourceElementFilesDownloadStarted)
            addEventHandler("mapManager:mapLoader:onClientMapResourceElementFilesDownloadCompleted", localPlayer, eventHandlers.onClientMapLoaderMapResourceElementFilesDownloadCompleted)
            addEventHandler("mapManager:mapLoader:onClientMapResourceFileDownloadStarted", localPlayer, eventHandlers.onClientMapLoaderMapResourceFileDownloadStarted)
            addEventHandler("mapManager:mapLoader:onClientMapResourceFilesDownloadStarted", localPlayer, eventHandlers.onClientMapLoaderMapResourceFilesDownloadStarted)
            addEventHandler("mapManager:mapLoader:onClientMapResourceFilesDownloadCompleted", localPlayer, eventHandlers.onClientMapLoaderMapResourceFilesDownloadCompleted)

            addEventHandler("download:ui:onStateSet", localPlayer, eventHandlers.onClientDownloadUIStateSet)
        end,

        onClientMapLoaderMapResourceUnloading = function()
            local eventHandlers = event1.eventHandlers

            removeEventHandler("mapManager:mapLoader:onClientMapResourceElementFileDownloadStarted", localPlayer, eventHandlers.onClientMapLoaderMapResourceElementFileDownloadStarted)
            removeEventHandler("mapManager:mapLoader:onClientMapResourceElementFilesDownloadStarted", localPlayer, eventHandlers.onClientMapLoaderMapResourceElementFilesDownloadStarted)
            removeEventHandler("mapManager:mapLoader:onClientMapResourceElementFilesDownloadCompleted", localPlayer, eventHandlers.onClientMapLoaderMapResourceElementFilesDownloadCompleted)
            removeEventHandler("mapManager:mapLoader:onClientMapResourceFileDownloadStarted", localPlayer, eventHandlers.onClientMapLoaderMapResourceFileDownloadStarted)
            removeEventHandler("mapManager:mapLoader:onClientMapResourceFilesDownloadStarted", localPlayer, eventHandlers.onClientMapLoaderMapResourceFilesDownloadStarted)
            removeEventHandler("mapManager:mapLoader:onClientMapResourceFilesDownloadCompleted", localPlayer, eventHandlers.onClientMapLoaderMapResourceFilesDownloadCompleted)

            removeEventHandler("download:ui:onStateSet", localPlayer, eventHandlers.onClientDownloadUIStateSet)

            local data = event1.data

            local mapInfo = getElementData(data.arenaElement, "mapInfo", false)

            triggerEvent("event1:" .. tostring(mapInfo.directory) .. ":onClientMapResourceUnloading", localPlayer)

            silentExport("ep_raceui", "setRequestLabelState", false)

            data.mapLoaderDownloading = nil
        end,

        onClientPlayerRadioSwitch = function()
            cancelEvent()
        end,

        onClientArenaResourceStart = function(startedResource)
            local resourceStartFunction = event1.arenaResourceStartFunctions[getResourceName(startedResource)]

            if resourceStartFunction then
                resourceStartFunction(startedResource)
            end
        end,

        onClientArenaThisResourceStop = function()
            local data = event1.data

            local eventHandlers = event1.eventHandlers

            if getElementData(data.arenaElement, "mapInfo", false) then
                eventHandlers.onClientMapLoaderMapResourceUnloading()
            end
            
            eventHandlers.onClientArenaQuit()
        end,

        onArenaPlayerClientArenaJoin = function()
            silentExport("ep_raceui", "addNotification", getPlayerName(source) .. " #C6C6C6has joined", "user-plus-16-13")
        end,

        onArenaPlayerClientArenaQuit = function(quitType)
            if player ~= localPlayer then
                if quitType then
                    silentExport("ep_raceui", "addNotification", getPlayerName(source) .. " #C6C6C6has left - " .. quitType, "user-cross-16-13")
                else
                    silentExport("ep_raceui", "addNotification", getPlayerName(source) .. " #C6C6C6has left", "user-minus-16-13")
                end
            end
        end,

        onArenaPlayerClientArenaLogin = function()
            silentExport("ep_raceui", "addNotification", getPlayerName(source) .. " #C6C6C6has logged in", "user-lock-16-13")
        end,

        onArenaPlayerClientArenaLogout = function()
            silentExport("ep_raceui", "addNotification", getPlayerName(source) .. " #C6C6C6has logged out", "user-unlock-16-13")
        end,

        onClientMapLoaderMapResourceElementFileDownloadStarted = function(resourceName, mapSrc, fileSize, request)
            silentExport("ep_raceui", "addRequestLabelRemoteRequest", request, fileSize)
        end,

        onClientMapLoaderMapResourceElementFilesDownloadStarted = function(resourceName, elementsTotalSize)
            --silentExport("ep_raceui", "setRequestLabelPrefixText", "Map download progress: ")
            silentExport("ep_raceui", "resetRequestLabelRemoteRequests")
            silentExport("ep_raceui", "setRequestLabelState", true)

            event1.updateRequestLabelPosition()

            local data = event1.data

            data.mapLoaderDownloading = true
        end,

        onClientMapLoaderMapResourceElementFilesDownloadCompleted = function(resourceName, elementsTotalSize)
            silentExport("ep_raceui", "setRequestLabelState", false)

            local data = event1.data

            data.mapLoaderDownloading = nil
        end,

        onClientMapLoaderMapResourceFileDownloadStarted = function(resourceName, fileSrc, fileSize, request)
            silentExport("ep_raceui", "addRequestLabelRemoteRequest", request, fileSize)
        end,

        onClientMapLoaderMapResourceFilesDownloadStarted = function(resourceName, resourcesTotalSize)
            --silentExport("ep_raceui", "setRequestLabelPrefixText", "Download progress: ")
            silentExport("ep_raceui", "resetRequestLabelRemoteRequests")
            silentExport("ep_raceui", "setRequestLabelState", true)

            event1.updateRequestLabelPosition()

            local data = event1.data

            data.mapLoaderDownloading = true
        end,

        onClientMapLoaderMapResourceFilesDownloadCompleted = function(resourceName, resourcesTotalSize)
            silentExport("ep_raceui", "setRequestLabelState", false)

            local data = event1.data

            data.mapLoaderDownloading = nil
        end,

        onClientDownloadUIStateSet = function(state)
            event1.updateRequestLabelPosition()
        end
    },

    resourceStartFunctions = {
        ["ep_scoreboard"] = function(resource)
            event1.addArenaDataToScoreboard()
        end
    },

    arenaResourceStartFunctions = {
        ["ep_scoreboard"] = function(resource)
            local data = event1.data

            silentExport("ep_scoreboard", "setUIToggleState", true)
            silentExport("ep_scoreboard", "selectUIArena", data.arenaElement)
        end
    },

    managers = {},

    modes = {}
}

addEvent("event1:onClientArenaStart", true)

addEvent("event1:onClientArenaCreatedInternal", true)
addEvent("event1:onClientArenaDestroyInternal", true)

addEvent("event1:onClientPlayerArenaJoin", true)
addEvent("event1:onClientPlayerArenaQuit", true)
addEvent("event1:onClientPlayerLogin", true)
addEvent("event1:onClientPlayerLogout", true)

addEvent("event1:onClientThisResourceStop")

addEvent("onClientPlayerTeamChange")

addEvent("lobby:onClientArenaCreated")

addEvent("mapManager:mapLoader:onClientMapResourceStarting")
addEvent("mapManager:mapLoader:onClientMapResourceUnloading")

addEvent("mapManager:mapLoader:onClientMapResourceElementFileDownloadStarted")
addEvent("mapManager:mapLoader:onClientMapResourceElementFilesDownloadStarted")
addEvent("mapManager:mapLoader:onClientMapResourceElementFilesDownloadCompleted")
addEvent("mapManager:mapLoader:onClientMapResourceFileDownloadStarted")
addEvent("mapManager:mapLoader:onClientMapResourceFilesDownloadStarted")
addEvent("mapManager:mapLoader:onClientMapResourceFilesDownloadCompleted")

addEvent("download:ui:onStateSet")

do
    local eventHandlers = event1.eventHandlers

    addEventHandler("onClientResourceStart", resourceRoot, eventHandlers.onClientThisResourceStart)

    addEventHandler("event1:onClientArenaStart", localPlayer, eventHandlers.onClientArenaStart)

    addEventHandler("event1:onClientArenaCreatedInternal", resourceRoot, eventHandlers.onArenaCreated)
    addEventHandler("event1:onClientArenaDestroyInternal", resourceRoot, eventHandlers.onArenaDestroy)
end