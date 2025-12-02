local stringFind = string.find

local deathmatch = event1.managers.deathmatch

local draft

draft = {
    settings = {
        resultsFilePath = "client/arena/modes/draft_results.txt",
        resultsJSONFilePath = "client/arena/modes/draft_results.json"
    },

    start = function(teamsCount)
        if not draft.data then
            local data = {}

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local coreElement = getElementData(arenaElement, "coreElement", false)

            local refereeClanTeamElement = getElementData(coreElement, "refereeClanTeamElement", false)
            local spectatorsClanTeamElement = getElementData(coreElement, "spectatorsClanTeamElement", false)

            local eventHandlers = draft.eventHandlers

            addEventHandler("event1:deathmatch:onVehicleWeaponsUpdate", localPlayer, eventHandlers.onClientArenaDeathmatchVehicleWeaponsUpdate)
            
            addEventHandler("lobby:ui:onStateSet", localPlayer, eventHandlers.onClientLobbyUIStateSet)

            addEventHandler("mapManager:mapLoader:onClientMapResourceUnloaded", localPlayer, eventHandlers.onClientMapResourceUnloaded)

            addEventHandler("event1:draft:onClientArenaResultsSaved", arenaElement, eventHandlers.onArenaDraftResultsSaved)
            addEventHandler("event1:draft:onClientArenaCheckpointsReceive", arenaElement, eventHandlers.onArenaDraftCheckpointsReceive)

            addEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)

            addEventHandler("onClientMarkerHit", root, eventHandlers.onClientMarkerHit)

            local commandHandlers = draft.commandHandlers

            addCommandHandler("w", commandHandlers.w)
            addCommandHandler("st", commandHandlers.st)
            addCommandHandler("setlines", commandHandlers.setLines)

            data.coreElement = coreElement

            data.refereeClanTeamElement = refereeClanTeamElement
            data.spectatorsClanTeamElement = spectatorsClanTeamElement

            data.teamsCount = teamsCount

            data.checkpoints = {}

            draft.data = data

            draft.getEventClansTeamElements()
            draft.startUI()
            draft.updateVehicleWeapons()
        end
    end,

    stop = function()
        local data = draft.data

        if data then
            draft.stopUI()

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = draft.eventHandlers

            removeEventHandler("event1:deathmatch:onVehicleWeaponsUpdate", localPlayer, eventHandlers.onClientArenaDeathmatchVehicleWeaponsUpdate)

            removeEventHandler("lobby:ui:onStateSet", localPlayer, eventHandlers.onClientLobbyUIStateSet)

            removeEventHandler("mapManager:mapLoader:onClientMapResourceUnloaded", localPlayer, eventHandlers.onClientMapResourceUnloaded)

            removeEventHandler("event1:draft:onClientArenaResultsSaved", arenaElement, eventHandlers.onArenaDraftResultsSaved)
            removeEventHandler("event1:draft:onClientArenaCheckpointsReceive", arenaElement, eventHandlers.onArenaDraftCheckpointsReceive)

            removeEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)

            removeEventHandler("onClientMarkerHit", root, eventHandlers.onClientMarkerHit)

            setElementData(localPlayer, "draftMarkersCount", nil, false)

            local commandHandlers = draft.commandHandlers

            removeCommandHandler("w", commandHandlers.w)
            removeCommandHandler("st", commandHandlers.st)
            removeCommandHandler("setlines", commandHandlers.setLines)

            toggleControl("vehicle_fire", true)
            toggleControl("vehicle_secondary_fire", true)

            deathmatch.updateVehicleWeapons()

            draft.data = nil
        end
    end,

    getEventClansTeamElements = function()
        local data = draft.data

        local teamsCount = data.teamsCount

        local coreElement = data.coreElement

        local eventClansTeamElements = {}

        for i = 1, teamsCount do
            eventClansTeamElements[i] = getElementData(coreElement, "eventTeam" .. tostring(i), false)
        end

        data.eventClansTeamElements = eventClansTeamElements
    end,

    addEventClansDataToUI = function()
        local data = draft.data

        local eventClansTeamElements = data.eventClansTeamElements

        local draftUIItemlistElement = draft.ui.itemlistElement

        local draftUIItemlistElementCustomAddPlayer = draftUIItemlistElement.custom.addPlayer
        local draftUIItemlistElementCustomAddTeam = draftUIItemlistElement.custom.addTeam

        for i = 1, #eventClansTeamElements do
            local teamElement = eventClansTeamElements[i]

            draftUIItemlistElementCustomAddTeam(draftUIItemlistElement, teamElement)

            local teamElementPlayers = getPlayersInTeam(teamElement)

            for i = 1, #teamElementPlayers do
                local player = teamElementPlayers[i]

                draftUIItemlistElementCustomAddPlayer(draftUIItemlistElement, player)
            end
        end
    end,

    startUI = function()
        local draftUI = draft.ui

        draftUI.create()

        local data = draft.data

        local draftUIItemlistElement = draftUI.itemlistElement

        local draftUIItemlistElementCustom = draftUIItemlistElement.custom

        draftUIItemlistElementCustom.eventClansTeamElements = data.eventClansTeamElements

        draft.addEventClansDataToUI()

        draftUIItemlistElement:setAnimationState(true)
    end,

    stopUI = function()
        local draftUI = draft.ui

        local draftUIItemlistElement = draftUI.itemlistElement

        draftUIItemlistElement:setAnimationState(false)
        draftUIItemlistElement:setAnimationProgress(0)

        draftUI.destroy()
    end,

    isEventTeamElement = function(teamElement)
        local data = draft.data

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

            local controlsState = not draft.armedVehicleIDs[model]

            toggleControl("vehicle_fire", controlsState)
            toggleControl("vehicle_secondary_fire", controlsState)
        end
    end,

    destroyCheckpoints = function()
        local data = draft.data

        for marker in pairs(data.checkpoints) do
            if isElement(marker) then
                destroyElement(marker)
            end
        end

        data.checkpoints = {}
    end,
    
    eventHandlers = {
        onClientArenaCreated = function()
            local eventHandlers = draft.eventHandlers

            addEventHandler("event1:draft:onClientEventModeStart", localPlayer, eventHandlers.onClientArenaEventModeStart)
            addEventHandler("event1:draft:onClientEventModeStop", localPlayer, eventHandlers.onClientArenaEventModeStop)

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            addEventHandler("event1:draft:onClientEventModeCreatedInternal", arenaElement, eventHandlers.onArenaEventModeCreated)
            addEventHandler("event1:draft:onClientEventModeDestroyInternal", arenaElement, eventHandlers.onArenaEventModeDestroy)
        end,

        onClientArenaDestroy = function()
            local eventHandlers = draft.eventHandlers

            removeEventHandler("event1:draft:onClientEventModeStart", localPlayer, eventHandlers.onClientArenaEventModeStart)
            removeEventHandler("event1:draft:onClientEventModeStop", localPlayer, eventHandlers.onClientArenaEventModeStop)

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            removeEventHandler("event1:draft:onClientEventModeCreatedInternal", arenaElement, eventHandlers.onArenaEventModeCreated)
            removeEventHandler("event1:draft:onClientEventModeDestroyInternal", arenaElement, eventHandlers.onArenaEventModeDestroy)

            draft.stop()
        end,

        ---

        onClientArenaEventModeStart = function(teamsCount)
            draft.start(teamsCount)
        end,

        onClientArenaEventModeStop = function()
            draft.stop()
        end,

        onArenaEventModeCreated = function(teamsCount)
            draft.start(teamsCount)
        end,

        onArenaEventModeDestroy = function()
            draft.stop()
        end,

        ---

        onClientArenaDeathmatchVehicleWeaponsUpdate = function()
            draft.updateVehicleWeapons()
        end,

        onClientLobbyUIStateSet = function(state)
            local draftUIState = not state

            draft.ui.itemlistElement:setAnimationState(draftUIState)
        end,

        onClientMapResourceUnloaded = function()
            draft.destroyCheckpoints()
        end,

        onArenaDraftResultsSaved = function(resultsString, resultsJSONString)
            local resultsFilePath = draft.settings.resultsFilePath
            local resultsJSONFilePath = draft.settings.resultsJSONFilePath

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

        onArenaDraftCheckpointsReceive = function(serverCheckpoints)
            draft.destroyCheckpoints()

            local data = draft.data

            local checkpoints = data.checkpoints

            local dimension = getElementDimension(localPlayer)
            local interior = getElementInterior(localPlayer)

            for i, checkpoint in ipairs(serverCheckpoints) do
                local marker = createMarker(checkpoint.x, checkpoint.y, checkpoint.z, "corona", checkpoint.size, 255, 255, 255, 64)

                setElementDimension(marker, dimension)
                setElementInterior(marker, interior)

                checkpoints[marker] = true
            end

            setElementData(localPlayer, "draftMarkersCount", #serverCheckpoints, false)
        end,

        onArenaPlayerTeamChange = function(oldTeam, newTeam)
            local data = draft.data

            local draftUIItemlistElement = draft.ui.itemlistElement

            draftUIItemlistElement.custom.removePlayer(draftUIItemlistElement, source)

            if draft.isEventTeamElement(newTeam) then
                draftUIItemlistElement.custom.addPlayer(draftUIItemlistElement, source)
            end
        end,

        onClientMarkerHit = function(hitPlayer, matchingDimension)
            if hitPlayer == localPlayer and matchingDimension and draft.data.checkpoints[source] and not getElementData(source, "markerHit", false) then
                triggerServerEvent("event1:draft:onDraftMarkerHit", localPlayer)

                setElementData(source, "markerHit", true, false)
            end
        end
    },

    commandHandlers = {
        w = function(commandName, weatherID)
            --setWeather(tonumber(weatherID) or 0)
        end,

        st = function(commandName, hour, minute)
            setTime(tonumber(hour) or 0, tonumber(minute) or 0)
        end,

        setLines = function(commandName, lines)
            lines = tonumber(lines)

            if lines then
                local draftUIItemlistElement = draft.ui.itemlistElement

                draftUIItemlistElement.custom.setMaxTeamRows(draftUIItemlistElement, lines)

                outputChatBox("#CCCCCCLines have been set to #FFFFFF" .. tostring(lines), 255, 255, 255, true)
            else
                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [lines]", 255, 255, 255, true)
            end
        end
    },

    armedVehicleIDs = { [425] = true, [447] = true, [520] = true, [430] = true, [464] = true, [432] = true }
}

event1.modes.draft = draft

addEvent("event1:onClientArenaCreated")
addEvent("event1:onClientArenaDestroy")

addEvent("event1:draft:onClientEventModeStart", true)
addEvent("event1:draft:onClientEventModeStop", true)

addEvent("event1:draft:onClientEventModeCreatedInternal", true)
addEvent("event1:draft:onClientEventModeDestroyInternal", true)

addEvent("event1:draft:onClientArenaCheckpointsReceive", true)

addEvent("event1:deathmatch:onVehicleWeaponsUpdate")

addEvent("mapManager:mapLoader:onClientMapResourceUnloaded")

addEvent("lobby:ui:onStateSet")

addEvent("onClientPlayerTeamChange")

addEvent("event1:draft:onClientArenaResultsSaved", true)

do
    local eventHandlers = draft.eventHandlers

    addEventHandler("event1:onClientArenaCreated", localPlayer, eventHandlers.onClientArenaCreated)
    addEventHandler("event1:onClientArenaDestroy", localPlayer, eventHandlers.onClientArenaDestroy)
end