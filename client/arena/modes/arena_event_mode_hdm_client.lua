local deathmatch = event1.managers.deathmatch

local hdm

hdm = {
    settings = {
        resultsFilePath = "client/arena/modes/hdm_results.txt",
        resultsJSONFilePath = "client/arena/modes/hdm_results.json"
    },

    start = function()
        if not hdm.data then
            local data = {}

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local coreElement = getElementData(arenaElement, "coreElement", false)

            local mainClanTeamElement = getElementData(coreElement, "mainClanTeamElement", false)
            local refereeClanTeamElement = getElementData(coreElement, "refereeClanTeamElement", false)
            local spectatorsClanTeamElement = getElementData(coreElement, "spectatorsClanTeamElement", false)

            local eventHandlers = hdm.eventHandlers

            addEventHandler("event1:deathmatch:onVehicleWeaponsUpdate", localPlayer, eventHandlers.onClientArenaDeathmatchVehicleWeaponsUpdate)

            addEventHandler("lobby:ui:onStateSet", localPlayer, eventHandlers.onClientLobbyUIStateSet)

            addEventHandler("event1:hdm:onClientArenaResultsSaved", arenaElement, eventHandlers.onArenaHDMResultsSaved)

            addEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)

            local commandHandlers = hdm.commandHandlers

            addCommandHandler("setlines", commandHandlers.setLines)

            data.coreElement = coreElement

            data.mainClanTeamElement = mainClanTeamElement
            data.refereeClanTeamElement = refereeClanTeamElement
            data.spectatorsClanTeamElement = spectatorsClanTeamElement

            hdm.data = data

            hdm.startUI()
            hdm.updateVehicleWeapons()
        end
    end,

    stop = function()
        local data = hdm.data

        if data then
            hdm.stopUI()

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = hdm.eventHandlers

            removeEventHandler("event1:deathmatch:onVehicleWeaponsUpdate", localPlayer, eventHandlers.onClientArenaDeathmatchVehicleWeaponsUpdate)

            removeEventHandler("lobby:ui:onStateSet", localPlayer, eventHandlers.onClientLobbyUIStateSet)

            removeEventHandler("event1:hdm:onClientArenaResultsSaved", arenaElement, eventHandlers.onArenaHDMResultsSaved)

            removeEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)

            local commandHandlers = hdm.commandHandlers

            removeCommandHandler("setlines", commandHandlers.setLines)

            toggleControl("vehicle_fire", true)
            toggleControl("vehicle_secondary_fire", true)

            deathmatch.updateVehicleWeapons()

            hdm.data = nil
        end
    end,

    addPlayersToUI = function()
        local eventData = event1.data

        local arenaElement = eventData.arenaElement

        local arenaPlayers = getElementChildren(arenaElement, "player")

        local data = hdm.data

        local mainClanTeamElement = data.mainClanTeamElement

        local hdmUIItemlistElement = hdm.ui.itemlistElement

        local hdmUIItemlistElementCustomAddPlayer = hdmUIItemlistElement.custom.addPlayer

        for i = 1, #arenaPlayers do
            local arenaPlayer = arenaPlayers[i]

            if getPlayerTeam(arenaPlayer) == mainClanTeamElement then
                hdmUIItemlistElementCustomAddPlayer(hdmUIItemlistElement, arenaPlayer)
            end
        end
    end,

    startUI = function()
        local hdmUI = hdm.ui

        hdmUI.create()

        local hdmUIItemlistElement = hdmUI.itemlistElement

        hdm.addPlayersToUI()

        hdmUIItemlistElement:setAnimationState(true)
    end,

    stopUI = function()
        local hdmUI = hdm.ui

        local hdmUIItemlistElement = hdmUI.itemlistElement

        hdmUIItemlistElement:setAnimationState(false)
        hdmUIItemlistElement:setAnimationProgress(0)

        hdmUI.destroy()
    end,

    updateVehicleWeapons = function()
        local vehicle = getPedOccupiedVehicle(localPlayer)

        if isElement(vehicle) then
            local model = getElementModel(vehicle)

            local controlsState = not hdm.armedVehicleIDs[model]

            toggleControl("vehicle_fire", controlsState)
            toggleControl("vehicle_secondary_fire", controlsState)
        end
    end,

    eventHandlers = {
        onClientArenaCreated = function()
            local eventHandlers = hdm.eventHandlers

            addEventHandler("event1:hdm:onClientEventModeStart", localPlayer, eventHandlers.onClientArenaEventModeStart)
            addEventHandler("event1:hdm:onClientEventModeStop", localPlayer, eventHandlers.onClientArenaEventModeStop)

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            addEventHandler("event1:hdm:onClientEventModeCreatedInternal", arenaElement, eventHandlers.onArenaEventModeCreated)
            addEventHandler("event1:hdm:onClientEventModeDestroyInternal", arenaElement, eventHandlers.onArenaEventModeDestroy)
        end,

        onClientArenaDestroy = function()
            local eventHandlers = hdm.eventHandlers

            removeEventHandler("event1:hdm:onClientEventModeStart", localPlayer, eventHandlers.onClientArenaEventModeStart)
            removeEventHandler("event1:hdm:onClientEventModeStop", localPlayer, eventHandlers.onClientArenaEventModeStop)

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            removeEventHandler("event1:hdm:onClientEventModeCreatedInternal", arenaElement, eventHandlers.onArenaEventModeCreated)
            removeEventHandler("event1:hdm:onClientEventModeDestroyInternal", arenaElement, eventHandlers.onArenaEventModeDestroy)

            hdm.stop()
        end,

        ---

        onClientArenaEventModeStart = function()
            hdm.start()
        end,

        onClientArenaEventModeStop = function()
            hdm.stop()
        end,

        onArenaEventModeCreated = function()
            hdm.start()
        end,

        onArenaEventModeDestroy = function()
            hdm.stop()
        end,

        ---

        onClientArenaDeathmatchVehicleWeaponsUpdate = function()
            hdm.updateVehicleWeapons()
        end,

        onClientLobbyUIStateSet = function(state)
            local hdmUIState = not state

            hdm.ui.itemlistElement:setAnimationState(hdmUIState)
        end,

        onArenaHDMResultsSaved = function(resultsString, resultsJSONString)
            local resultsFilePath = hdm.settings.resultsFilePath
            local resultsJSONFilePath = hdm.settings.resultsJSONFilePath

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
            local data = hdm.data

            local hdmUIItemlistElement = hdm.ui.itemlistElement

            if newTeam == data.mainClanTeamElement then
                hdmUIItemlistElement.custom.addPlayer(hdmUIItemlistElement, source)
            else
                hdmUIItemlistElement.custom.removePlayer(hdmUIItemlistElement, source)
            end
        end
    },

    commandHandlers = {
        setLines = function(commandName, lines)
            lines = tonumber(lines)

            if lines then
                local hdmUIItemlistElement = hdm.ui.itemlistElement

                hdmUIItemlistElement.custom.setMaxRows(hdmUIItemlistElement, lines)

                outputChatBox("#CCCCCCLines have been set to #FFFFFF" .. tostring(lines), 255, 255, 255, true)
            else
                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [lines]", 255, 255, 255, true)
            end
        end
    },

    armedVehicleIDs = { [425] = true, [447] = true, [520] = true, [430] = true, [464] = true, [432] = true }
}

event1.modes.hdm = hdm

addEvent("event1:onClientArenaCreated")
addEvent("event1:onClientArenaDestroy")

addEvent("event1:hdm:onClientEventModeStart", true)
addEvent("event1:hdm:onClientEventModeStop", true)

addEvent("event1:hdm:onClientEventModeCreatedInternal", true)
addEvent("event1:hdm:onClientEventModeDestroyInternal", true)

addEvent("event1:deathmatch:onVehicleWeaponsUpdate")

addEvent("lobby:ui:onStateSet")

addEvent("onClientPlayerTeamChange")

addEvent("event1:hdm:onClientArenaResultsSaved", true)

do
    local eventHandlers = hdm.eventHandlers

    addEventHandler("event1:onClientArenaCreated", localPlayer, eventHandlers.onClientArenaCreated)
    addEventHandler("event1:onClientArenaDestroy", localPlayer, eventHandlers.onClientArenaDestroy)
end