local deathmatch = event1.managers.deathmatch

local wff

wff = {
    settings = {
        resultsFilePath = "client/arena/modes/wff_results.txt",
        resultsJSONFilePath = "client/arena/modes/wff_results.json"
    },

    start = function()
        if not wff.data then
            local data = {}

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local coreElement = getElementData(arenaElement, "coreElement", false)

            local mainClanTeamElement = getElementData(coreElement, "mainClanTeamElement", false)
            local refereeClanTeamElement = getElementData(coreElement, "refereeClanTeamElement", false)
            local spectatorsClanTeamElement = getElementData(coreElement, "spectatorsClanTeamElement", false)

            local eventHandlers = wff.eventHandlers

            addEventHandler("event1:deathmatch:onVehicleWeaponsUpdate", localPlayer, eventHandlers.onClientArenaDeathmatchVehicleWeaponsUpdate)

            addEventHandler("lobby:ui:onStateSet", localPlayer, eventHandlers.onClientLobbyUIStateSet)

            addEventHandler("event1:wff:onClientArenaResultsSaved", arenaElement, eventHandlers.onArenaWFFResultsSaved)

            addEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)

            local commandHandlers = wff.commandHandlers

            addCommandHandler("setlines", commandHandlers.setLines)

            data.coreElement = coreElement

            data.mainClanTeamElement = mainClanTeamElement
            data.refereeClanTeamElement = refereeClanTeamElement
            data.spectatorsClanTeamElement = spectatorsClanTeamElement

            wff.data = data

            wff.startUI()
            wff.updateVehicleWeapons()
        end
    end,

    stop = function()
        local data = wff.data

        if data then
            wff.stopUI()

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = wff.eventHandlers

            removeEventHandler("event1:deathmatch:onVehicleWeaponsUpdate", localPlayer, eventHandlers.onClientArenaDeathmatchVehicleWeaponsUpdate)

            removeEventHandler("lobby:ui:onStateSet", localPlayer, eventHandlers.onClientLobbyUIStateSet)

            removeEventHandler("event1:wff:onClientArenaResultsSaved", arenaElement, eventHandlers.onArenaWFFResultsSaved)

            removeEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)

            local commandHandlers = wff.commandHandlers

            removeCommandHandler("setlines", commandHandlers.setLines)

            toggleControl("vehicle_fire", true)
            toggleControl("vehicle_secondary_fire", true)

            deathmatch.updateVehicleWeapons()

            wff.data = nil
        end
    end,

    addPlayersToUI = function()
        local eventData = event1.data

        local arenaElement = eventData.arenaElement

        local arenaPlayers = getElementChildren(arenaElement, "player")

        local data = wff.data

        local mainClanTeamElement = data.mainClanTeamElement

        local wffUIItemlistElement = wff.ui.itemlistElement

        local wffUIItemlistElementCustomAddPlayer = wffUIItemlistElement.custom.addPlayer

        for i = 1, #arenaPlayers do
            local arenaPlayer = arenaPlayers[i]

            if getPlayerTeam(arenaPlayer) == mainClanTeamElement then
                wffUIItemlistElementCustomAddPlayer(wffUIItemlistElement, arenaPlayer)
            end
        end
    end,

    startUI = function()
        local wffUI = wff.ui

        wffUI.create()

        local wffUIItemlistElement = wffUI.itemlistElement

        wff.addPlayersToUI()

        wffUIItemlistElement:setAnimationState(true)
    end,

    stopUI = function()
        local wffUI = wff.ui

        local wffUIItemlistElement = wffUI.itemlistElement

        wffUIItemlistElement:setAnimationState(false)
        wffUIItemlistElement:setAnimationProgress(0)

        wffUI.destroy()
    end,

    updateVehicleWeapons = function()
        local vehicle = getPedOccupiedVehicle(localPlayer)

        if isElement(vehicle) then
            local model = getElementModel(vehicle)

            local controlsState = not wff.armedVehicleIDs[model]

            toggleControl("vehicle_fire", controlsState)
            toggleControl("vehicle_secondary_fire", controlsState)
        end
    end,

    eventHandlers = {
        onClientArenaCreated = function()
            local eventHandlers = wff.eventHandlers

            addEventHandler("event1:wff:onClientEventModeStart", localPlayer, eventHandlers.onClientArenaEventModeStart)
            addEventHandler("event1:wff:onClientEventModeStop", localPlayer, eventHandlers.onClientArenaEventModeStop)

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            addEventHandler("event1:wff:onClientEventModeCreatedInternal", arenaElement, eventHandlers.onArenaEventModeCreated)
            addEventHandler("event1:wff:onClientEventModeDestroyInternal", arenaElement, eventHandlers.onArenaEventModeDestroy)
        end,

        onClientArenaDestroy = function()
            local eventHandlers = wff.eventHandlers

            removeEventHandler("event1:wff:onClientEventModeStart", localPlayer, eventHandlers.onClientArenaEventModeStart)
            removeEventHandler("event1:wff:onClientEventModeStop", localPlayer, eventHandlers.onClientArenaEventModeStop)

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            removeEventHandler("event1:wff:onClientEventModeCreatedInternal", arenaElement, eventHandlers.onArenaEventModeCreated)
            removeEventHandler("event1:wff:onClientEventModeDestroyInternal", arenaElement, eventHandlers.onArenaEventModeDestroy)

            wff.stop()
        end,

        ---

        onClientArenaEventModeStart = function()
            wff.start()
        end,

        onClientArenaEventModeStop = function()
            wff.stop()
        end,

        onArenaEventModeCreated = function()
            wff.start()
        end,

        onArenaEventModeDestroy = function()
            wff.stop()
        end,

        ---

        onClientArenaDeathmatchVehicleWeaponsUpdate = function()
            wff.updateVehicleWeapons()
        end,

        onClientLobbyUIStateSet = function(state)
            local wffUIState = not state

            wff.ui.itemlistElement:setAnimationState(wffUIState)
        end,

        onArenaWFFResultsSaved = function(resultsString, resultsJSONString)
            local resultsFilePath = wff.settings.resultsFilePath
            local resultsJSONFilePath = wff.settings.resultsJSONFilePath

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

        onArenaPlayerTeamChange = function(oldTeam, newTeam)
            local data = wff.data

            local wffUIItemlistElement = wff.ui.itemlistElement

            if newTeam == data.mainClanTeamElement then
                wffUIItemlistElement.custom.addPlayer(wffUIItemlistElement, source)
            else
                wffUIItemlistElement.custom.removePlayer(wffUIItemlistElement, source)
            end
        end
    },

    commandHandlers = {
        setLines = function(commandName, lines)
            lines = tonumber(lines)

            if lines then
                local wffUIItemlistElement = wff.ui.itemlistElement

                wffUIItemlistElement.custom.setMaxRows(wffUIItemlistElement, lines)

                outputChatBox("#CCCCCCLines have been set to #FFFFFF" .. tostring(lines), 255, 255, 255, true)
            else
                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [lines]", 255, 255, 255, true)
            end
        end
    },

    armedVehicleIDs = { [425] = true, [447] = true, [520] = true, [430] = true, [464] = true, [432] = true }
}

event1.modes.wff = wff

addEvent("event1:onClientArenaCreated")
addEvent("event1:onClientArenaDestroy")

addEvent("event1:wff:onClientEventModeStart", true)
addEvent("event1:wff:onClientEventModeStop", true)

addEvent("event1:wff:onClientEventModeCreatedInternal", true)
addEvent("event1:wff:onClientEventModeDestroyInternal", true)

addEvent("event1:deathmatch:onVehicleWeaponsUpdate")

addEvent("lobby:ui:onStateSet")

addEvent("onClientPlayerTeamChange")

addEvent("event1:wff:onClientArenaResultsSaved", true)

do
    local eventHandlers = wff.eventHandlers

    addEventHandler("event1:onClientArenaCreated", localPlayer, eventHandlers.onClientArenaCreated)
    addEventHandler("event1:onClientArenaDestroy", localPlayer, eventHandlers.onClientArenaDestroy)
end