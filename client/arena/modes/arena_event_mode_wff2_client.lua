local deathmatch = event1.managers.deathmatch

local wff2

wff2 = {
    settings = {
        resultsFilePath = "client/arena/modes/wff2_results.txt",
        resultsJSONFilePath = "client/arena/modes/wff2_results.json"
    },

    start = function()
        if not wff2.data then
            local data = {}

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local coreElement = getElementData(arenaElement, "coreElement", false)

            local mainClanTeamElement = getElementData(coreElement, "mainClanTeamElement", false)
            local refereeClanTeamElement = getElementData(coreElement, "refereeClanTeamElement", false)
            local spectatorsClanTeamElement = getElementData(coreElement, "spectatorsClanTeamElement", false)

            local eventHandlers = wff2.eventHandlers

            addEventHandler("event1:deathmatch:onVehicleWeaponsUpdate", localPlayer, eventHandlers.onClientArenaDeathmatchVehicleWeaponsUpdate)

            addEventHandler("lobby:ui:onStateSet", localPlayer, eventHandlers.onClientLobbyUIStateSet)

            addEventHandler("event1:wff2:onClientArenaResultsSaved", arenaElement, eventHandlers.onArenaWFFResultsSaved)

            addEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)

            local commandHandlers = wff2.commandHandlers

            addCommandHandler("setlines", commandHandlers.setLines)

            data.coreElement = coreElement

            data.mainClanTeamElement = mainClanTeamElement
            data.refereeClanTeamElement = refereeClanTeamElement
            data.spectatorsClanTeamElement = spectatorsClanTeamElement

            wff2.data = data

            wff2.startUI()
            wff2.updateVehicleWeapons()
        end
    end,

    stop = function()
        local data = wff2.data

        if data then
            wff2.stopUI()

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = wff2.eventHandlers

            removeEventHandler("event1:deathmatch:onVehicleWeaponsUpdate", localPlayer, eventHandlers.onClientArenaDeathmatchVehicleWeaponsUpdate)

            removeEventHandler("lobby:ui:onStateSet", localPlayer, eventHandlers.onClientLobbyUIStateSet)

            removeEventHandler("event1:wff2:onClientArenaResultsSaved", arenaElement, eventHandlers.onArenaWFFResultsSaved)

            removeEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)

            local commandHandlers = wff2.commandHandlers

            removeCommandHandler("setlines", commandHandlers.setLines)

            toggleControl("vehicle_fire", true)
            toggleControl("vehicle_secondary_fire", true)

            deathmatch.updateVehicleWeapons()

            wff2.data = nil
        end
    end,

    addPlayersToUI = function()
        local eventData = event1.data

        local arenaElement = eventData.arenaElement

        local arenaPlayers = getElementChildren(arenaElement, "player")

        local data = wff2.data

        local mainClanTeamElement = data.mainClanTeamElement

        local wff2UIItemlistElement = wff2.ui.itemlistElement

        local wff2UIItemlistElementCustomAddPlayer = wff2UIItemlistElement.custom.addPlayer

        for i = 1, #arenaPlayers do
            local arenaPlayer = arenaPlayers[i]

            if getPlayerTeam(arenaPlayer) == mainClanTeamElement then
                wff2UIItemlistElementCustomAddPlayer(wff2UIItemlistElement, arenaPlayer)
            end
        end
    end,

    startUI = function()
        local wff2UI = wff2.ui

        wff2UI.create()

        local wff2UIItemlistElement = wff2UI.itemlistElement

        wff2.addPlayersToUI()

        wff2UIItemlistElement:setAnimationState(true)
    end,

    stopUI = function()
        local wff2UI = wff2.ui

        local wff2UIItemlistElement = wff2UI.itemlistElement

        wff2UIItemlistElement:setAnimationState(false)
        wff2UIItemlistElement:setAnimationProgress(0)

        wff2UI.destroy()
    end,

    updateVehicleWeapons = function()
        local vehicle = getPedOccupiedVehicle(localPlayer)

        if isElement(vehicle) then
            local model = getElementModel(vehicle)

            local controlsState = not wff2.armedVehicleIDs[model]

            toggleControl("vehicle_fire", controlsState)
            toggleControl("vehicle_secondary_fire", controlsState)
        end
    end,

    eventHandlers = {
        onClientArenaCreated = function()
            local eventHandlers = wff2.eventHandlers

            addEventHandler("event1:wff2:onClientEventModeStart", localPlayer, eventHandlers.onClientArenaEventModeStart)
            addEventHandler("event1:wff2:onClientEventModeStop", localPlayer, eventHandlers.onClientArenaEventModeStop)

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            addEventHandler("event1:wff2:onClientEventModeCreatedInternal", arenaElement, eventHandlers.onArenaEventModeCreated)
            addEventHandler("event1:wff2:onClientEventModeDestroyInternal", arenaElement, eventHandlers.onArenaEventModeDestroy)
        end,

        onClientArenaDestroy = function()
            local eventHandlers = wff2.eventHandlers

            removeEventHandler("event1:wff2:onClientEventModeStart", localPlayer, eventHandlers.onClientArenaEventModeStart)
            removeEventHandler("event1:wff2:onClientEventModeStop", localPlayer, eventHandlers.onClientArenaEventModeStop)

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            removeEventHandler("event1:wff2:onClientEventModeCreatedInternal", arenaElement, eventHandlers.onArenaEventModeCreated)
            removeEventHandler("event1:wff2:onClientEventModeDestroyInternal", arenaElement, eventHandlers.onArenaEventModeDestroy)

            wff2.stop()
        end,

        ---

        onClientArenaEventModeStart = function()
            wff2.start()
        end,

        onClientArenaEventModeStop = function()
            wff2.stop()
        end,

        onArenaEventModeCreated = function()
            wff2.start()
        end,

        onArenaEventModeDestroy = function()
            wff2.stop()
        end,

        ---

        onClientArenaDeathmatchVehicleWeaponsUpdate = function()
            wff2.updateVehicleWeapons()
        end,

        onClientLobbyUIStateSet = function(state)
            local wff2UIState = not state

            wff2.ui.itemlistElement:setAnimationState(wff2UIState)
        end,

        onArenaWFFResultsSaved = function(resultsString, resultsJSONString)
            local resultsFilePath = wff2.settings.resultsFilePath
            local resultsJSONFilePath = wff2.settings.resultsJSONFilePath

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
            local data = wff2.data

            local wff2UIItemlistElement = wff2.ui.itemlistElement

            if newTeam == data.mainClanTeamElement then
                wff2UIItemlistElement.custom.addPlayer(wff2UIItemlistElement, source)
            else
                wff2UIItemlistElement.custom.removePlayer(wff2UIItemlistElement, source)
            end
        end
    },

    commandHandlers = {
        setLines = function(commandName, lines)
            lines = tonumber(lines)

            if lines then
                local wff2UIItemlistElement = wff2.ui.itemlistElement

                wff2UIItemlistElement.custom.setMaxRows(wff2UIItemlistElement, lines)

                outputChatBox("#CCCCCCLines have been set to #FFFFFF" .. tostring(lines), 255, 255, 255, true)
            else
                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [lines]", 255, 255, 255, true)
            end
        end
    },

    armedVehicleIDs = { [425] = true, [447] = true, [520] = true, [430] = true, [464] = true, [432] = true }
}

event1.modes.wff2 = wff2

addEvent("event1:onClientArenaCreated")
addEvent("event1:onClientArenaDestroy")

addEvent("event1:wff2:onClientEventModeStart", true)
addEvent("event1:wff2:onClientEventModeStop", true)

addEvent("event1:wff2:onClientEventModeCreatedInternal", true)
addEvent("event1:wff2:onClientEventModeDestroyInternal", true)

addEvent("event1:deathmatch:onVehicleWeaponsUpdate")

addEvent("lobby:ui:onStateSet")

addEvent("onClientPlayerTeamChange")

addEvent("event1:wff2:onClientArenaResultsSaved", true)

do
    local eventHandlers = wff2.eventHandlers

    addEventHandler("event1:onClientArenaCreated", localPlayer, eventHandlers.onClientArenaCreated)
    addEventHandler("event1:onClientArenaDestroy", localPlayer, eventHandlers.onClientArenaDestroy)
end