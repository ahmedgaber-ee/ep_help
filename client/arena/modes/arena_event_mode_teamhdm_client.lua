local deathmatch = event1.managers.deathmatch

local teamhdm

teamhdm = {
    settings = {
        resultsFilePath = "client/arena/modes/teamhdm_results.txt",
        resultsJSONFilePath = "client/arena/modes/teamhdm_results.json"
    },

    start = function(teamsCount)
        if not teamhdm.data then
            local data = {}

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local coreElement = getElementData(arenaElement, "coreElement", false)

            local refereeClanTeamElement = getElementData(coreElement, "refereeClanTeamElement", false)
            local spectatorsClanTeamElement = getElementData(coreElement, "spectatorsClanTeamElement", false)

            local eventHandlers = teamhdm.eventHandlers

            addEventHandler("event1:deathmatch:onVehicleWeaponsUpdate", localPlayer, eventHandlers.onClientArenaDeathmatchVehicleWeaponsUpdate)
            
            addEventHandler("lobby:ui:onStateSet", localPlayer, eventHandlers.onClientLobbyUIStateSet)

            addEventHandler("event1:teamhdm:onClientArenaResultsSaved", arenaElement, eventHandlers.onArenateamhdmResultsSaved)

            addEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)

            local commandHandlers = teamhdm.commandHandlers

            addCommandHandler("w", commandHandlers.w)
            addCommandHandler("st", commandHandlers.st)
            addCommandHandler("setlines", commandHandlers.setLines)

            data.coreElement = coreElement

            data.refereeClanTeamElement = refereeClanTeamElement
            data.spectatorsClanTeamElement = spectatorsClanTeamElement

            data.teamsCount = teamsCount

            teamhdm.data = data

            teamhdm.getEventClansTeamElements()
            teamhdm.startUI()
            teamhdm.updateVehicleWeapons()
        end
    end,

    stop = function()
        local data = teamhdm.data

        if data then
            teamhdm.stopUI()

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = teamhdm.eventHandlers

            removeEventHandler("event1:deathmatch:onVehicleWeaponsUpdate", localPlayer, eventHandlers.onClientArenaDeathmatchVehicleWeaponsUpdate)

            removeEventHandler("lobby:ui:onStateSet", localPlayer, eventHandlers.onClientLobbyUIStateSet)

            removeEventHandler("event1:teamhdm:onClientArenaResultsSaved", arenaElement, eventHandlers.onArenateamhdmResultsSaved)

            removeEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)

            local commandHandlers = teamhdm.commandHandlers

            removeCommandHandler("w", commandHandlers.w)
            removeCommandHandler("st", commandHandlers.st)
            removeCommandHandler("setlines", commandHandlers.setLines)

            toggleControl("vehicle_fire", true)
            toggleControl("vehicle_secondary_fire", true)

            deathmatch.updateVehicleWeapons()

            teamhdm.data = nil
        end
    end,

    getEventClansTeamElements = function()
        local data = teamhdm.data

        local teamsCount = data.teamsCount

        local coreElement = data.coreElement

        local eventClansTeamElements = {}

        for i = 1, teamsCount do
            eventClansTeamElements[i] = getElementData(coreElement, "eventTeam" .. tostring(i), false)
        end

        data.eventClansTeamElements = eventClansTeamElements
    end,

    addEventClansDataToUI = function()
        local data = teamhdm.data

        local eventClansTeamElements = data.eventClansTeamElements

        local teamhdmUIItemlistElement = teamhdm.ui.itemlistElement

        local teamhdmUIItemlistElementCustomAddPlayer = teamhdmUIItemlistElement.custom.addPlayer
        local teamhdmUIItemlistElementCustomAddTeam = teamhdmUIItemlistElement.custom.addTeam

        for i = 1, #eventClansTeamElements do
            local teamElement = eventClansTeamElements[i]

            teamhdmUIItemlistElementCustomAddTeam(teamhdmUIItemlistElement, teamElement)

            local teamElementPlayers = getPlayersInTeam(teamElement)

            for i = 1, #teamElementPlayers do
                local player = teamElementPlayers[i]

                teamhdmUIItemlistElementCustomAddPlayer(teamhdmUIItemlistElement, player)
            end
        end
    end,

    startUI = function()
        local teamhdmUI = teamhdm.ui

        teamhdmUI.create()

        local data = teamhdm.data

        local teamhdmUIItemlistElement = teamhdmUI.itemlistElement

        local teamhdmUIItemlistElementCustom = teamhdmUIItemlistElement.custom

        teamhdmUIItemlistElementCustom.eventClansTeamElements = data.eventClansTeamElements

        teamhdm.addEventClansDataToUI()

        teamhdmUIItemlistElement:setAnimationState(true)
    end,

    stopUI = function()
        local teamhdmUI = teamhdm.ui

        local teamhdmUIItemlistElement = teamhdmUI.itemlistElement

        teamhdmUIItemlistElement:setAnimationState(false)
        teamhdmUIItemlistElement:setAnimationProgress(0)

        teamhdmUI.destroy()
    end,

    isEventTeamElement = function(teamElement)
        local data = teamhdm.data

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

            local controlsState = not teamhdm.armedVehicleIDs[model]

            toggleControl("vehicle_fire", controlsState)
            toggleControl("vehicle_secondary_fire", controlsState)
        end
    end,
    
    eventHandlers = {
        onClientArenaCreated = function()
            local eventHandlers = teamhdm.eventHandlers

            addEventHandler("event1:teamhdm:onClientEventModeStart", localPlayer, eventHandlers.onClientArenaEventModeStart)
            addEventHandler("event1:teamhdm:onClientEventModeStop", localPlayer, eventHandlers.onClientArenaEventModeStop)

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            addEventHandler("event1:teamhdm:onClientEventModeCreatedInternal", arenaElement, eventHandlers.onArenaEventModeCreated)
            addEventHandler("event1:teamhdm:onClientEventModeDestroyInternal", arenaElement, eventHandlers.onArenaEventModeDestroy)
        end,

        onClientArenaDestroy = function()
            local eventHandlers = teamhdm.eventHandlers

            removeEventHandler("event1:teamhdm:onClientEventModeStart", localPlayer, eventHandlers.onClientArenaEventModeStart)
            removeEventHandler("event1:teamhdm:onClientEventModeStop", localPlayer, eventHandlers.onClientArenaEventModeStop)

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            removeEventHandler("event1:teamhdm:onClientEventModeCreatedInternal", arenaElement, eventHandlers.onArenaEventModeCreated)
            removeEventHandler("event1:teamhdm:onClientEventModeDestroyInternal", arenaElement, eventHandlers.onArenaEventModeDestroy)

            teamhdm.stop()
        end,

        ---

        onClientArenaEventModeStart = function(teamsCount)
            teamhdm.start(teamsCount)
        end,

        onClientArenaEventModeStop = function()
            teamhdm.stop()
        end,

        onArenaEventModeCreated = function(teamsCount)
            teamhdm.start(teamsCount)
        end,

        onArenaEventModeDestroy = function()
            teamhdm.stop()
        end,

        ---

        onClientArenaDeathmatchVehicleWeaponsUpdate = function()
            teamhdm.updateVehicleWeapons()
        end,

        onClientLobbyUIStateSet = function(state)
            local teamhdmUIState = not state

            teamhdm.ui.itemlistElement:setAnimationState(teamhdmUIState)
        end,

        onArenateamhdmResultsSaved = function(resultsString, resultsJSONString)
            local resultsFilePath = teamhdm.settings.resultsFilePath
            local resultsJSONFilePath = teamhdm.settings.resultsJSONFilePath

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
            local data = teamhdm.data

            local teamhdmUIItemlistElement = teamhdm.ui.itemlistElement

            teamhdmUIItemlistElement.custom.removePlayer(teamhdmUIItemlistElement, source)

            if teamhdm.isEventTeamElement(newTeam) then
                teamhdmUIItemlistElement.custom.addPlayer(teamhdmUIItemlistElement, source)
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
                local teamhdmUIItemlistElement = teamhdm.ui.itemlistElement

                teamhdmUIItemlistElement.custom.setMaxTeamRows(teamhdmUIItemlistElement, lines)

                outputChatBox("#CCCCCCLines have been set to #FFFFFF" .. tostring(lines), 255, 255, 255, true)
            else
                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [lines]", 255, 255, 255, true)
            end
        end
    },

    armedVehicleIDs = { [425] = true, [447] = true, [520] = true, [430] = true, [464] = true, [432] = true }
}

event1.modes.teamhdm = teamhdm

addEvent("event1:onClientArenaCreated")
addEvent("event1:onClientArenaDestroy")

addEvent("event1:teamhdm:onClientEventModeStart", true)
addEvent("event1:teamhdm:onClientEventModeStop", true)

addEvent("event1:teamhdm:onClientEventModeCreatedInternal", true)
addEvent("event1:teamhdm:onClientEventModeDestroyInternal", true)

addEvent("event1:deathmatch:onVehicleWeaponsUpdate")

addEvent("lobby:ui:onStateSet")

addEvent("onClientPlayerTeamChange")

addEvent("event1:teamhdm:onClientArenaResultsSaved", true)

do
    local eventHandlers = teamhdm.eventHandlers

    addEventHandler("event1:onClientArenaCreated", localPlayer, eventHandlers.onClientArenaCreated)
    addEventHandler("event1:onClientArenaDestroy", localPlayer, eventHandlers.onClientArenaDestroy)
end