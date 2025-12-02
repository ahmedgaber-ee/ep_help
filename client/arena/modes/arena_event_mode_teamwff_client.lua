local deathmatch = event1.managers.deathmatch

local teamwff

teamwff = {
    settings = {
        resultsFilePath = "client/arena/modes/teamwff_results.txt",
        resultsJSONFilePath = "client/arena/modes/teamwff_results.json"
    },

    start = function(teamsCount)
        if not teamwff.data then
            local data = {}

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local coreElement = getElementData(arenaElement, "coreElement", false)

            local refereeClanTeamElement = getElementData(coreElement, "refereeClanTeamElement", false)
            local spectatorsClanTeamElement = getElementData(coreElement, "spectatorsClanTeamElement", false)

            local eventHandlers = teamwff.eventHandlers

            addEventHandler("event1:deathmatch:onVehicleWeaponsUpdate", localPlayer, eventHandlers.onClientArenaDeathmatchVehicleWeaponsUpdate)
            
            addEventHandler("lobby:ui:onStateSet", localPlayer, eventHandlers.onClientLobbyUIStateSet)

            addEventHandler("event1:teamwff:onClientArenaResultsSaved", arenaElement, eventHandlers.onArenaTeamWFFResultsSaved)

            addEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)

            local commandHandlers = teamwff.commandHandlers

            addCommandHandler("w", commandHandlers.w)
            addCommandHandler("st", commandHandlers.st)
            addCommandHandler("setlines", commandHandlers.setLines)

            data.coreElement = coreElement

            data.refereeClanTeamElement = refereeClanTeamElement
            data.spectatorsClanTeamElement = spectatorsClanTeamElement

            data.teamsCount = teamsCount

            teamwff.data = data

            teamwff.getEventClansTeamElements()
            teamwff.startUI()
            teamwff.updateVehicleWeapons()
        end
    end,

    stop = function()
        local data = teamwff.data

        if data then
            teamwff.stopUI()

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local eventHandlers = teamwff.eventHandlers

            removeEventHandler("event1:deathmatch:onVehicleWeaponsUpdate", localPlayer, eventHandlers.onClientArenaDeathmatchVehicleWeaponsUpdate)

            removeEventHandler("lobby:ui:onStateSet", localPlayer, eventHandlers.onClientLobbyUIStateSet)

            removeEventHandler("event1:teamwff:onClientArenaResultsSaved", arenaElement, eventHandlers.onArenaTeamWFFResultsSaved)

            removeEventHandler("onClientPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)

            local commandHandlers = teamwff.commandHandlers

            removeCommandHandler("w", commandHandlers.w)
            removeCommandHandler("st", commandHandlers.st)
            removeCommandHandler("setlines", commandHandlers.setLines)

            toggleControl("vehicle_fire", true)
            toggleControl("vehicle_secondary_fire", true)

            deathmatch.updateVehicleWeapons()

            teamwff.data = nil
        end
    end,

    getEventClansTeamElements = function()
        local data = teamwff.data

        local teamsCount = data.teamsCount

        local coreElement = data.coreElement

        local eventClansTeamElements = {}

        for i = 1, teamsCount do
            eventClansTeamElements[i] = getElementData(coreElement, "eventTeam" .. tostring(i), false)
        end

        data.eventClansTeamElements = eventClansTeamElements
    end,

    addEventClansDataToUI = function()
        local data = teamwff.data

        local eventClansTeamElements = data.eventClansTeamElements

        local teamwffUIItemlistElement = teamwff.ui.itemlistElement

        local teamwffUIItemlistElementCustomAddPlayer = teamwffUIItemlistElement.custom.addPlayer
        local teamwffUIItemlistElementCustomAddTeam = teamwffUIItemlistElement.custom.addTeam

        for i = 1, #eventClansTeamElements do
            local teamElement = eventClansTeamElements[i]

            teamwffUIItemlistElementCustomAddTeam(teamwffUIItemlistElement, teamElement)

            local teamElementPlayers = getPlayersInTeam(teamElement)

            for i = 1, #teamElementPlayers do
                local player = teamElementPlayers[i]

                teamwffUIItemlistElementCustomAddPlayer(teamwffUIItemlistElement, player)
            end
        end
    end,

    startUI = function()
        local teamwffUI = teamwff.ui

        teamwffUI.create()

        local data = teamwff.data

        local teamwffUIItemlistElement = teamwffUI.itemlistElement

        local teamwffUIItemlistElementCustom = teamwffUIItemlistElement.custom

        teamwffUIItemlistElementCustom.eventClansTeamElements = data.eventClansTeamElements

        teamwff.addEventClansDataToUI()

        teamwffUIItemlistElement:setAnimationState(true)
    end,

    stopUI = function()
        local teamwffUI = teamwff.ui

        local teamwffUIItemlistElement = teamwffUI.itemlistElement

        teamwffUIItemlistElement:setAnimationState(false)
        teamwffUIItemlistElement:setAnimationProgress(0)

        teamwffUI.destroy()
    end,

    isEventTeamElement = function(teamElement)
        local data = teamwff.data

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

            local controlsState = not teamwff.armedVehicleIDs[model]

            toggleControl("vehicle_fire", controlsState)
            toggleControl("vehicle_secondary_fire", controlsState)
        end
    end,
    
    eventHandlers = {
        onClientArenaCreated = function()
            local eventHandlers = teamwff.eventHandlers

            addEventHandler("event1:teamwff:onClientEventModeStart", localPlayer, eventHandlers.onClientArenaEventModeStart)
            addEventHandler("event1:teamwff:onClientEventModeStop", localPlayer, eventHandlers.onClientArenaEventModeStop)

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            addEventHandler("event1:teamwff:onClientEventModeCreatedInternal", arenaElement, eventHandlers.onArenaEventModeCreated)
            addEventHandler("event1:teamwff:onClientEventModeDestroyInternal", arenaElement, eventHandlers.onArenaEventModeDestroy)
        end,

        onClientArenaDestroy = function()
            local eventHandlers = teamwff.eventHandlers

            removeEventHandler("event1:teamwff:onClientEventModeStart", localPlayer, eventHandlers.onClientArenaEventModeStart)
            removeEventHandler("event1:teamwff:onClientEventModeStop", localPlayer, eventHandlers.onClientArenaEventModeStop)

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            removeEventHandler("event1:teamwff:onClientEventModeCreatedInternal", arenaElement, eventHandlers.onArenaEventModeCreated)
            removeEventHandler("event1:teamwff:onClientEventModeDestroyInternal", arenaElement, eventHandlers.onArenaEventModeDestroy)

            teamwff.stop()
        end,

        ---

        onClientArenaEventModeStart = function(teamsCount)
            teamwff.start(teamsCount)
        end,

        onClientArenaEventModeStop = function()
            teamwff.stop()
        end,

        onArenaEventModeCreated = function(teamsCount)
            teamwff.start(teamsCount)
        end,

        onArenaEventModeDestroy = function()
            teamwff.stop()
        end,

        ---

        onClientArenaDeathmatchVehicleWeaponsUpdate = function()
            teamwff.updateVehicleWeapons()
        end,

        onClientLobbyUIStateSet = function(state)
            local teamwffUIState = not state

            teamwff.ui.itemlistElement:setAnimationState(teamwffUIState)
        end,

        onArenaTeamWFFResultsSaved = function(resultsString, resultsJSONString)
            local resultsFilePath = teamwff.settings.resultsFilePath
            local resultsJSONFilePath = teamwff.settings.resultsJSONFilePath

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
            local data = teamwff.data

            local teamwffUIItemlistElement = teamwff.ui.itemlistElement

            teamwffUIItemlistElement.custom.removePlayer(teamwffUIItemlistElement, source)

            if teamwff.isEventTeamElement(newTeam) then
                teamwffUIItemlistElement.custom.addPlayer(teamwffUIItemlistElement, source)
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
                local teamwffUIItemlistElement = teamwff.ui.itemlistElement

                teamwffUIItemlistElement.custom.setMaxTeamRows(teamwffUIItemlistElement, lines)

                outputChatBox("#CCCCCCLines have been set to #FFFFFF" .. tostring(lines), 255, 255, 255, true)
            else
                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [lines]", 255, 255, 255, true)
            end
        end
    },

    armedVehicleIDs = { [425] = true, [447] = true, [520] = true, [430] = true, [464] = true, [432] = true }
}

event1.modes.teamwff = teamwff

addEvent("event1:onClientArenaCreated")
addEvent("event1:onClientArenaDestroy")

addEvent("event1:teamwff:onClientEventModeStart", true)
addEvent("event1:teamwff:onClientEventModeStop", true)

addEvent("event1:teamwff:onClientEventModeCreatedInternal", true)
addEvent("event1:teamwff:onClientEventModeDestroyInternal", true)

addEvent("event1:deathmatch:onVehicleWeaponsUpdate")

addEvent("lobby:ui:onStateSet")

addEvent("onClientPlayerTeamChange")

addEvent("event1:teamwff:onClientArenaResultsSaved", true)

do
    local eventHandlers = teamwff.eventHandlers

    addEventHandler("event1:onClientArenaCreated", localPlayer, eventHandlers.onClientArenaCreated)
    addEventHandler("event1:onClientArenaDestroy", localPlayer, eventHandlers.onClientArenaDestroy)
end