local mathFloor = math.floor

local stringLen = string.len
local stringRep = string.rep
local stringSub = string.sub
local stringFind = string.find
local stringGsub = string.gsub
local stringLower = string.lower
local stringFormat = string.format

local tableSort = table.sort
local tableConcat = table.concat

local debuggerPrepareString = debugger.prepareString

local addons = event1.addons

local clan = addons.clan

local clanNew = clan.new
local clanFunctions = clan.functions

local deathmatch = event1.managers.deathmatch

local deathmatchStates = deathmatch.states

local deathmatchMapLoadedStateData = deathmatchStates["map loaded"]
local deathmatchEndedStateData = deathmatchStates["ended"]

local stringRemoveHex = function(string)
    return stringGsub(string, "#%x%x%x%x%x%x", "")
end

local rgbToHex = function(r, g, b)
    return stringFormat("%02x%02x%02x", r, g, b)
end

local formatMS = function(ms)
    return stringFormat("%02d:%02d:%03d", tostring(mathFloor(ms/60000)), tostring(mathFloor((ms/1000) % 60)), tostring(mathFloor(ms % 1000)))
end

local triggerClientResourceEvent = function(resource, ...)
    if getResourceState(resource) == "running" then
        return triggerClientEvent(...)
    end
end

local getPlayerFromPartialName = function(players, name)
    local name = stringLower(stringRemoveHex(name))

    local eventData = event1.data

    for i = 1, #players do
        local player = players[i]

        local playerName = stringLower(stringRemoveHex(getPlayerName(player)))

        if stringFind(playerName, name, 1, true) then
            return player
        end
    end
end

local nth = function(value)
    if value > 3 and value < 21 then
        return "th"
    end

    local a = value % 10

    if a == 1 then
        return "st"
    elseif a == 2 then
        return "nd"
    elseif a == 3 then
        return "rd"
    else
        return "th"
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

local tableSortOnValuesDescending

do
    local args

    local sortingFunction = function(a, b)
        for i = 1, #args do
            local argValue = args[i]

            if a[argValue] > b[argValue] then 
                return true 
            end

            if a[argValue] < b[argValue] then 
                return false 
            end
        end
    end

    tableSortOnValuesDescending = function(table, ...)
        args = { ... }

        tableSort(table, sortingFunction)

        args = nil
    end
end

local resourceName = getResourceName(resource)

local teamhdm

teamhdm = {
    settings = {
        forumURL = "https://ep-mta.com/",
        forumAPIKey = "b7acbacc6cb8840ec9d111af35939952",
        forumAuthorID = 404,
        forumNameIDs = { 
            ["ef_dm"] = 24,
            ["ef_wff"] = 25,
            ["ef_hdm"] = 30,
            ["ef_os"] = 28,
            ["events"] = 9,
            ["community_clanwars"] = 31
        },

        dataFilePath = "server/arena/modes/teamhdm_data.json",
        resultsFilePath = "server/arena/modes/teamhdm_results.txt",
        resultsJSONFilePath = "server/arena/modes/teamhdm_results.json",

        pointsOrder = { 3, 2, 1, 1 },

        playerHunterTimesDelay = 2000,

        teamsCount = 2
    },

    start = function()
        if not teamhdm.data then
            local data = {}

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local arenaName = getElementData(arenaElement, "name", false)

            local refereeClan = clanNew(arenaName .. " Referee", 255, 0, 0)
            local spectatorsClan = clanNew(arenaName .. " Spectators", 255, 255, 255)

            local coreElement = createElement("core", "Event Name")

            local teamsCount = teamhdm.settings.teamsCount

            setElementParent(coreElement, arenaElement)

            setElementData(arenaElement, "coreElement", coreElement)

            setElementData(coreElement, "refereeClanTeamElement", refereeClan.teamElement)
            setElementData(coreElement, "spectatorsClanTeamElement", spectatorsClan.teamElement)

            setElementData(coreElement, "teamsCount", teamsCount)
            setElementData(coreElement, "state", "free")
            setElementData(coreElement, "round", 1)
            setElementData(coreElement, "totalRounds", 20)

            local eventHandlers = teamhdm.eventHandlers

            addEventHandler("event1:deathmatch:onArenaStateSet", arenaElement, eventHandlers.onArenaDeathmatchStateSet)
            addEventHandler("event1:deathmatch:onPlayerJoinSpawn", arenaElement, eventHandlers.onArenaDeathmatchPlayerJoinSpawn)
            addEventHandler("event1:deathmatch:onPlayerReachedHunter", arenaElement, eventHandlers.onArenaDeathmatchPlayerReachedHunter)

            addEventHandler("event1:onPlayerArenaJoin", arenaElement, eventHandlers.onArenaPlayerJoin)
            addEventHandler("event1:onPlayerArenaQuit", arenaElement, eventHandlers.onArenaPlayerQuit)

            addEventHandler("onPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)
            addEventHandler("onPlayerChangeNick", arenaElement, eventHandlers.onArenaPlayerChangeNick)
            addEventHandler("onPlayerLogin", arenaElement, eventHandlers.onArenaPlayerLogin)

            local commandHandlers = teamhdm.commandHandlers

            addCommandHandler("join", commandHandlers.join)
            addCommandHandler("spec", commandHandlers.spec)
            addCommandHandler("seteventname", commandHandlers.setEventName)
            addCommandHandler("setteamname", commandHandlers.setTeamName)
            addCommandHandler("setteamcolor", commandHandlers.setTeamColor)
            addCommandHandler("setteamtag", commandHandlers.setTeamTag)
            addCommandHandler("setteampoints", commandHandlers.setTeamPoints)
            addCommandHandler("setstate", commandHandlers.setState)
            addCommandHandler("setround", commandHandlers.setRound)
            addCommandHandler("settotalrounds", commandHandlers.setTotalRounds)
            addCommandHandler("setplayerpoints", commandHandlers.setPlayerPoints)
            addCommandHandler("setteamscount", commandHandlers.setTeamsCount)
            addCommandHandler("addpoints", commandHandlers.addPoints)
            addCommandHandler("randomkill", commandHandlers.randomKill)
            addCommandHandler("outputresultsforum", commandHandlers.outputResultsForum)
            addCommandHandler("resetmode", commandHandlers.resetMode)

            data.coreElement = coreElement

            data.refereeClan = refereeClan
            data.spectatorsClan = spectatorsClan

            data.playerHunterTimes = {}
            data.playerHunterLastPosition = 0

            data.mapData = {}

            teamhdm.data = data

            teamhdm.createEventClans()
            teamhdm.loadData()
            teamhdm.updatePlayersOnStart()

            local sourceElement = eventData.sourceElement

            triggerClientResourceEvent(resource, arenaElement, "event1:teamhdm:onClientEventModeCreatedInternal", sourceElement, teamsCount)

            triggerEvent("event1:teamhdm:onEventModeCreated", sourceElement)

            outputDebugString(debuggerPrepareString("Event team hdm mode created.", 1))
        end
    end,

    stop = function()
        local data = teamhdm.data

        if data then
            outputDebugString(debuggerPrepareString("Destroying event1 team hdm mode.", 1))

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local sourceElement = eventData.sourceElement

            triggerEvent("event1:teamhdm:onEventModeDestroy", sourceElement)

            triggerClientResourceEvent(resource, arenaElement, "event1:teamhdm:onClientEventModeDestroyInternal", sourceElement)

            local eventHandlers = teamhdm.eventHandlers

            removeEventHandler("event1:deathmatch:onArenaStateSet", arenaElement, eventHandlers.onArenaDeathmatchStateSet)
            removeEventHandler("event1:deathmatch:onPlayerJoinSpawn", arenaElement, eventHandlers.onArenaDeathmatchPlayerJoinSpawn)
            removeEventHandler("event1:deathmatch:onPlayerReachedHunter", arenaElement, eventHandlers.onArenaDeathmatchPlayerReachedHunter)

            removeEventHandler("event1:onPlayerArenaJoin", arenaElement, eventHandlers.onArenaPlayerJoin)
            removeEventHandler("event1:onPlayerArenaQuit", arenaElement, eventHandlers.onArenaPlayerQuit)

            removeEventHandler("onPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)
            removeEventHandler("onPlayerChangeNick", arenaElement, eventHandlers.onArenaPlayerChangeNick)
            removeEventHandler("onPlayerLogin", arenaElement, eventHandlers.onArenaPlayerLogin)

            local commandHandlers = teamhdm.commandHandlers

            removeCommandHandler("join", commandHandlers.join)
            removeCommandHandler("spec", commandHandlers.spec)
            removeCommandHandler("seteventname", commandHandlers.setEventName)
            removeCommandHandler("setteamname", commandHandlers.setTeamName)
            removeCommandHandler("setteamcolor", commandHandlers.setTeamColor)
            removeCommandHandler("setteamtag", commandHandlers.setTeamTag)
            removeCommandHandler("setteampoints", commandHandlers.setTeamPoints)
            removeCommandHandler("setstate", commandHandlers.setState)
            removeCommandHandler("setround", commandHandlers.setRound)
            removeCommandHandler("settotalrounds", commandHandlers.setTotalRounds)
            removeCommandHandler("setplayerpoints", commandHandlers.setPlayerPoints)
            removeCommandHandler("setteamscount", commandHandlers.setTeamsCount)
            removeCommandHandler("addpoints", commandHandlers.addPoints)
            removeCommandHandler("randomkill", commandHandlers.randomKill)
            removeCommandHandler("outputresultsforum", commandHandlers.outputResultsForum)
            removeCommandHandler("resetmode", commandHandlers.resetMode)

            setElementData(arenaElement, "coreElement", nil)

            local coreElement = data.coreElement

            setElementData(coreElement, "refereeClanTeamElement", nil)
            setElementData(coreElement, "spectatorsClanTeamElement", nil)

            setElementData(coreElement, "state", nil)
            setElementData(coreElement, "round", nil)
            setElementData(coreElement, "totalRounds", nil)

            teamhdm.updatePlayersOnStop()
            teamhdm.saveData()
            teamhdm.destroyEventClans()

            local playerHunterTimesTimer = data.playerHunterTimesTimer

            if isTimer(playerHunterTimesTimer) then
                killTimer(playerHunterTimesTimer)
            end

            local checkAlivePlayersTimer = data.checkAlivePlayersTimer

            if isTimer(checkAlivePlayersTimer) then
                killTimer(checkAlivePlayersTimer)
            end

            if isElement(coreElement) then
                destroyElement(coreElement)
            end

            data.refereeClan:destroy()
            data.spectatorsClan:destroy()

            teamhdm.data = nil
        end
    end,

    createEventClans = function()
        local teamsCount = teamhdm.settings.teamsCount

        local eventData = event1.data

        local arenaName = getElementData(eventData.arenaElement, "name", false)
    
        local data = teamhdm.data
    
        local coreElement = data.coreElement
    
        local eventClans = {}
    
        for i = 1, teamsCount do
            local iString = tostring(i)
    
            local teamName = arenaName .. " Team " .. iString
    
            local teamTag = "t" .. iString

            local clan = clanNew(teamName, 255, 255, 255)

            local teamElement = clan.teamElement
            
            setElementData(teamElement, "id", i)
            setElementData(teamElement, "tag", teamTag)
            setElementData(teamElement, "points", 0)

            setElementData(coreElement, "eventTeam" .. iString, teamElement)
    
            eventClans[i] = clan
        end
    
        data.eventClans = eventClans
    end,
    
    destroyEventClans = function()
        local data = teamhdm.data

        local coreElement = data.coreElement
    
        local eventClans = data.eventClans
    
        for i = 1, #eventClans do
            local clan = eventClans[i]

            local id = getElementData(clan.teamElement, "id", false)

            setElementData(coreElement, "eventTeam" .. tostring(id), nil)

            clan:destroy()
        end
    
        data.eventClans = nil
    end,
    
    addEventClansDataSubscriber = function(player)
        local data = teamhdm.data
    
        local eventClans = data.eventClans
    
        for i = 1, #eventClans do
            local clan = eventClans[i]

            clan:addAllElementDataSubscriber(player)
        end
    end,
    
    removeEventClansDataSubscriber = function(player)
        local data = teamhdm.data
    
        local eventClans = data.eventClans
    
        for i = 1, #eventClans do
            local clan = eventClans[i]

            clan:removeAllElementDataSubscriber(player)
        end
    end,

    updatePlayersOnStart = function()
        local data = teamhdm.data

        local refereeClan = data.refereeClan
        local spectatorsClan = data.spectatorsClan

        local refereeClanTeamElement = refereeClan.teamElement
        local spectatorsClanTeamElement = spectatorsClan.teamElement

        local eventData = event1.data

        local arenaElement = eventData.arenaElement

        local arenaPlayers = getElementChildren(arenaElement, "player")

        local permissionString = "resource." .. resourceName .. ".mode_teamhdm_referee"

        local addEventClansDataSubscriber = teamhdm.addEventClansDataSubscriber

        for i = 1, #arenaPlayers do
            local arenaPlayer = arenaPlayers[i]

            if hasObjectPermissionTo(arenaPlayer, permissionString, false) then
                silentExport("ep_core", "setPlayerTeam", arenaPlayer, refereeClanTeamElement)
            else
                silentExport("ep_core", "setPlayerTeam", arenaPlayer, spectatorsClanTeamElement)
            end

            addEventClansDataSubscriber(arenaPlayer)
        end
    end,

    updatePlayersOnStop = function()
        local eventData = event1.data

        local arenaElement = eventData.arenaElement

        local arenaPlayers = getElementChildren(arenaElement, "player")

        for i = 1, #arenaPlayers do
            local arenaPlayer = arenaPlayers[i]
                
            silentExport("ep_core", "setPlayerTeam", arenaPlayer, nil)
        end
    end,

    saveData = function()
        local dataFilePath = teamhdm.settings.dataFilePath

        if fileExists(dataFilePath) then
            fileDelete(dataFilePath)
        end

        local fileHandler = fileCreate(dataFilePath)

        if fileHandler then
            local data = teamhdm.data

            local eventClansData = {}

            local eventClans = data.eventClans
    
            for i = 1, #eventClans do
                local clan = eventClans[i]
    
                local teamElement = clan.teamElement

                local id = getElementData(teamElement, "id", false)

                eventClansData[id] = {
                    teamName = getTeamName(teamElement),

                    teamColor = { getTeamColor(teamElement) },

                    teamTag = getElementData(teamElement, "tag", false),

                    teamPoints = getElementData(teamElement, "points", false),

                    serialData = clan.serialData
                }
            end

            local dataToSave = {
                coreID = getElementID(data.coreElement),

                eventClansData = eventClansData,

                mapData = data.mapData
            }

            local dataJSON = toJSON(dataToSave, false, "tabs")

            fileWrite(fileHandler, dataJSON)
            fileClose(fileHandler)
        end
    end,

    loadData = function()
        local dataFilePath = teamhdm.settings.dataFilePath

        if fileExists(dataFilePath) then
            local fileHandler = fileOpen(dataFilePath, true)

            if fileHandler then
                local loadedDataJSON = fileRead(fileHandler, fileGetSize(fileHandler))

                local loadedData = fromJSON(loadedDataJSON) or {}

                fileClose(fileHandler)

                local data = teamhdm.data

                local coreID = loadedData.coreID

                if coreID then
                    setElementID(data.coreElement, coreID)
                end
                
                local eventClansData = loadedData.eventClansData
                
                if eventClansData then
                    local eventClans = data.eventClans

                    local getEventClanByID = teamhdm.getEventClanByID

                    for id, data in pairs(eventClansData) do
                        local id = tonumber(id)

                        local clan = eventClans[id]

                        if clan then
                            local teamElement = clan.teamElement

                            local teamName = data.teamName

                            if teamName then
                                setTeamName(teamElement, teamName)
                            end

                            local teamColor = data.teamColor

                            if teamColor then
                                setTeamColor(teamElement, unpack(teamColor))
                            end
                            
                            local teamTag = data.teamTag

                            if teamTag then
                                setElementData(teamElement, "tag", teamTag)
                            end

                            local teamPoints = data.teamPoints

                            if teamPoints then
                                setElementData(teamElement, "points", teamPoints)
                            end

                            local serialData = data.serialData

                            if serialData then
                                clan.serialData = serialData
                            end
                        end
                    end
                end

                local mapData = loadedData.mapData

                if mapData then
                    data.mapData = mapData
                end
            end
        end
    end,

    saveResults = function()
        local resultsFilePath = teamhdm.settings.resultsFilePath

        if fileExists(resultsFilePath) then
            fileDelete(resultsFilePath)
        end

        local fileHandler = fileCreate(resultsFilePath)

        if fileHandler then
            local data = teamhdm.data

            local mapData = data.mapData
            
            local mapDataCount = #mapData

            local columnMaxLengths = {}

            for i = 1, mapDataCount do
                local thisMapData = mapData[i]

                for j = 1, #thisMapData do
                    local dataValueString = thisMapData[j]

                    local stringLen = stringLen(dataValueString)

                    local oldKeyStringLength = columnMaxLengths[j] or 0
    
                    if stringLen > oldKeyStringLength then
                        columnMaxLengths[j] = stringLen
                    end
                end
            end

            local coreElementID = getElementID(data.coreElement)

            local resultsStrings = { coreElementID .. "\n\n" }

            local resultsToJSON = {
                mapData = {},
                results = {},
                playerResults = {},
                coreID = coreElementID
            }

            local resultsToJSONMapData = resultsToJSON.mapData
            local resultsToJSONResults = resultsToJSON.results
            local resultsToJSONPlayerResults = resultsToJSON.playerResults

            for i = 1, mapDataCount do
                local thisMapData = mapData[i]

                local dataValueStrings = {}

                local mapJSONData = {}
    
                for j = 1, #thisMapData do
                    local dataValueString = thisMapData[j]

                    local whitespacesCount = columnMaxLengths[j] - stringLen(dataValueString) + 5

                    local whitespaces = stringRep(" ", whitespacesCount)

                    dataValueStrings[j] = stringRemoveHex(dataValueString) .. whitespaces

                    mapJSONData[j] = dataValueString
                end
    
                resultsStrings[#resultsStrings + 1] = tableConcat(dataValueStrings) .. "\n"

                resultsToJSONMapData[#resultsToJSONMapData + 1] = mapJSONData
            end

            resultsStrings[#resultsStrings + 1] = "\n"

            local eventClans = data.eventClans

            local pointsOrder = teamhdm.settings.pointsOrder

            local pointsOrderCount = #pointsOrder

            local clanResults = {}

            local playerResults = {}

            for i = 1, #eventClans do
                local clan = eventClans[i]

                local teamElement = clan.teamElement

                local tag = getElementData(teamElement, "tag", false)
                local points = getElementData(teamElement, "points", false) or 0

                local r, g, b = getTeamColor(teamElement)

                local hexColor = "#" .. rgbToHex(r, g, b)

                clanResults[#clanResults + 1] = hexColor .. tag .. " #FFFFFF" .. tostring(points)

                for serial, data in pairs(clan.serialData) do
                    local points = data.points

                    if points and points > 0 then
                        local nickNameString = tostring(data.nickName)

                        local passed = data.passed or 0

                        local playerResult = { points = points, passed = passed }

                        local dataStrings = {}

                        for i = 1, pointsOrderCount do
                            local positionString = tostring(i) .. nth(i)

                            local positionData = data[positionString] or 0

                            playerResult[positionString] = positionData

                            dataStrings[i] = tostring(positionData) .. "x " .. positionString
                        end

                        dataStrings[#dataStrings + 1] = "passed: " .. tostring(passed)

                        playerResult.nickName = nickNameString

                        playerResult.text = tostring(points) .. " " .. stringRemoveHex(nickNameString) .. " (" .. tableConcat(dataStrings, ", ") .. ")"

                        playerResults[#playerResults + 1] = playerResult
                    end
                end
            end

            local clanResultsString = tableConcat(clanResults, ", ")

            resultsStrings[#resultsStrings + 1] = stringRemoveHex(clanResultsString) .. "\n\n"

            resultsToJSONResults.clan = clanResultsString

            local sortValues = { "points", "passed" }

            for i = 1, pointsOrderCount do
                local positionString = tostring(i) .. nth(i)

                sortValues[#sortValues + 1] = positionString
            end

            tableSortOnValuesDescending(playerResults, unpack(sortValues))

            for i = 1, #playerResults do
                local playerResult = playerResults[i]

                resultsStrings[#resultsStrings + 1] = playerResult.text .. "\n"

                resultsToJSONPlayerResults[#resultsToJSONPlayerResults + 1] = { playerResult.nickName, playerResult.points, playerResult.passed }
            end

            local firstPlayer = playerResults[1]

            if firstPlayer then
                local firstPlayerNickName = firstPlayer.nickName
                local firstPlayerPointsString = tostring(firstPlayer.points)

                resultsStrings[#resultsStrings + 1] = "\nMVP: " .. stringRemoveHex(firstPlayerNickName) .. " with " .. firstPlayerPointsString .. " points\n"

                resultsToJSONResults.mvp = firstPlayerNickName .. " #FFFFFF(" .. firstPlayerPointsString .. ")"
            end

            local resultsJSON = toJSON(resultsToJSON, false, "tabs")

            local resultsJSONFilePath = teamhdm.settings.resultsJSONFilePath

            if fileExists(resultsJSONFilePath) then
                fileDelete(resultsJSONFilePath)
            end
    
            local jsonFileHandler = fileCreate(resultsJSONFilePath)
    
            if jsonFileHandler then
                fileWrite(jsonFileHandler, resultsJSON)
                fileClose(jsonFileHandler)
            end

            local resultsString = tableConcat(resultsStrings)

            fileWrite(fileHandler, resultsString)
            fileClose(fileHandler)

            data.resultsToJSON = resultsToJSON

            return resultsString, resultsJSON
        end
    end,

    outputResultsOnForum = function(forumID, isTopicHidden, refereeName, streamerName, callbackFunction)
        local data = teamhdm.data

        local resultsToJSON = data.resultsToJSON

        if resultsToJSON then
            local resultsToJSONMapData = resultsToJSON.mapData
            local resultsToJSONResults = resultsToJSON.results
            local resultsToJSONPlayerResults = resultsToJSON.playerResults

            local clanResults = resultsToJSONResults.clan

            local settings = teamhdm.settings

            local pointsOrder = settings.pointsOrder

            local pointsOrderCount = #pointsOrder

            local convertStringToHTML = function(string)
                local htmlStrings = {[[
                    <p>
                ]]}
            
                local hexIndices = {}
            
                local currentStartIndex = 1
            
                while stringFind(string, "#%x%x%x%x%x%x", currentStartIndex) do
                    local startIndex, endIndex = stringFind(string, "#%x%x%x%x%x%x", currentStartIndex)
            
                    hexIndices[#hexIndices + 1] = {
                        startIndex = startIndex,
                        endIndex = endIndex
                    }
            
                    currentStartIndex = endIndex + 1
                end
            
                local hexIndicesCount = #hexIndices
            
                if hexIndicesCount > 0 then
                    local firstIndices = hexIndices[1]
            
                    local firstIndicesStartIndex = firstIndices.startIndex
            
                    if firstIndicesStartIndex > 1 then
                        --htmlStrings[#htmlStrings + 1] = [[<span style="color: #FFFFFF;">]] .. stringSub(string, 1, firstIndicesStartIndex - 1) .. [[</span>]]
                    end
            
                    for i = 1, hexIndicesCount do
                        local indices = hexIndices[i]
                        local nextIndices = hexIndices[i + 1]
            
                        local indicesEndIndex = indices.endIndex
            
                        if nextIndices then
                            --htmlStrings[#htmlStrings + 1] = [[<span style="color: ]] .. stringSub(string, indices.startIndex, indicesEndIndex) .. [[;">]] .. stringSub(string, indicesEndIndex + 1, nextIndices.startIndex - 1) .. [[</span>]]
                        else
                            --htmlStrings[#htmlStrings + 1] = [[<span style="color: ]] .. stringSub(string, indices.startIndex, indicesEndIndex) .. [[;">]] .. stringSub(string, indicesEndIndex + 1) .. [[</span>]]
                        end
                    end
                    
                    htmlStrings[#htmlStrings + 1] = [[<span>]] .. stringRemoveHex(string) .. [[</span>]]
                else
                    htmlStrings[#htmlStrings + 1] = [[<span>]] .. string .. [[</span>]]
                end
            
                htmlStrings[#htmlStrings + 1] = [[
                    </p>
                ]]
            
                return tableConcat(htmlStrings)
            end

            local htmlStrings = { [[
                <p style="text-align: center;">
                    <span style="color:#888b98; font-size:26px;">Map Results</span>
                </p>
                <table class="cEF_table">
                    <tr>
                        <th>Map</th>
                        <th>Result</th>
            ]] }

            for i = 1, pointsOrderCount do
                htmlStrings[#htmlStrings + 1] = [[
                    <th>]] .. tostring(i) .. nth(i) .. [[</th>
                ]]
            end

            htmlStrings[#htmlStrings + 1] = [[
                </tr>
            ]]

            for i = 1, #resultsToJSONMapData do
                local mapData = resultsToJSONMapData[i]

                local mapDataCount = #mapData

                htmlStrings[#htmlStrings + 1] = [[
                    <tr>
                        <td>]] .. mapData[1] .. [[</td>
                        <td>]] .. convertStringToHTML(mapData[2]) .. [[</td>
                ]]

                for j = 3, mapDataCount do
                    htmlStrings[#htmlStrings + 1] = [[
                        <td>]] .. convertStringToHTML(mapData[j]) .. [[</td>
                    ]]
                end

                htmlStrings[#htmlStrings + 1] = [[
                    </tr>
                ]]
            end

            htmlStrings[#htmlStrings + 1] = [[
                </table>
                <p style="text-align: center;">
                    <span style="color:#888b98; font-size:26px;">Rankingboard</span>
                </p>
                <table class="cEF_table">
                    <tr>
                        <th>Player</th>
                        <th>Points</th>
                        <th>Passed</th>
                    </tr>
            ]]
            
            for i = 1, #resultsToJSONPlayerResults do
                local playerResults = resultsToJSONPlayerResults[i]

                htmlStrings[#htmlStrings + 1] = [[
                    <tr>
                        <td>]] .. convertStringToHTML(playerResults[1]) .. [[</td>
                        <td>]] .. playerResults[2] .. [[</td>
                        <td>]] .. playerResults[3] .. [[</td>
                    </tr>
                ]]
            end

            htmlStrings[#htmlStrings + 1] = [[
                </table>
                <p style="text-align: center;">
                    <span style="color:#888b98; font-size:26px;">Result</span>
                </p>
                <table class="cEF_table">
                    <tr>
                        <th>MVP</th>
                        <th>Score</th>
                        <th>Referee</th>
                        <th>Streamer</th>
                    </tr>
                    <tr>
                        <td>]] .. convertStringToHTML(resultsToJSONResults.mvp or "") .. [[</td>
                        <td>]] .. convertStringToHTML(clanResults) .. [[</td>
                        <td>]] .. convertStringToHTML(refereeName or "") .. [[</td>
                        <td>]] .. convertStringToHTML(streamerName or "") .. [[</td>
                    </tr>
                </table>
            ]]

            fetchRemote(settings.forumURL .. "api/forums/topics?key=" .. settings.forumAPIKey, {
                queueName = "createResultsTopic",
                connectionAttempts = 1,
                connectTimeout = 5000,
                formFields = {
                    forum = forumID,
                    title = resultsToJSON.coreID .. " - " .. stringRemoveHex(clanResults),
                    post = tableConcat(htmlStrings),
                    author = settings.forumAuthorID,
                    author_name = "Bot",
                    locked = 1,
                    hidden = isTopicHidden and 1 or 0
                },
            }, function(responseData, responseInfo)
                if responseInfo.success then
                    callbackFunction(true, responseInfo.statusCode)
                else
                    callbackFunction(false, responseInfo.statusCode)
                end
            end)
        end
    end,

    getAlivePlayersInClan = function(clan)
        local clanAlivePlayers = {}

        local alivePlayers = deathmatchMapLoadedStateData.alivePlayers
        
        if alivePlayers then
            for player in pairs(clan.players) do
                if alivePlayers[player] then
                    clanAlivePlayers[#clanAlivePlayers + 1] = player
                end
            end
        end

        return clanAlivePlayers
    end,

    getEventClanByTag = function(tag)
        local data = teamhdm.data

        local eventClans = data.eventClans

        tag = stringLower(tag)

        for i = 1, #eventClans do
            local clan = eventClans[i]

            local clanTag = stringLower(getElementData(clan.teamElement, "tag", false))

            if clanTag == tag then
                return clan
            end
        end
    end,

    getEventClanByTeamElement = function(teamElement)
        local data = teamhdm.data

        local eventClans = data.eventClans

        for i = 1, #eventClans do
            local clan = eventClans[i]

            if clan.teamElement == teamElement then
                return clan
            end
        end
    end,

    getPlayerEventClan = function(player)
        local data = teamhdm.data

        local eventClans = data.eventClans

        for i = 1, #eventClans do
            local clan = eventClans[i]

            if clan.players[player] then
                return clan
            end
        end
    end,

    eventHandlers = {
        onArenaCreated = function()
            local eventData = event1.data

            local arenaElement = eventData.arenaElement
        
            local eventHandlers = teamhdm.eventHandlers
        
            addEventHandler("event1:teamhdm:onEventStateSet", arenaElement, eventHandlers.onArenaHDMEventStateSet)
        end,

        onArenaDestroy = function()
            local eventData = event1.data

            local arenaElement = eventData.arenaElement
        
            local eventHandlers = teamhdm.eventHandlers
        
            removeEventHandler("event1:teamhdm:onEventStateSet", arenaElement, eventHandlers.onArenaHDMEventStateSet)

            teamhdm.stop()
        end,

        ---

        onArenaHDMEventStateSet = function(state)
            if state then
                teamhdm.start()
            else
                teamhdm.stop()
            end
        end,

        ---

        onArenaDeathmatchStateSet = function(state)
            local arenaDeathmatchStateFunction = teamhdm.arenaDeathmatchStateFunctions[state]

            if arenaDeathmatchStateFunction then
                arenaDeathmatchStateFunction()
            end
        end,

        onArenaDeathmatchPlayerJoinSpawn = function()
            deathmatchMapLoadedStateData:removePlayerFromLoadQueue(source)
        end,

        onArenaDeathmatchPlayerReachedHunter = function(timePassed)
            local data = teamhdm.data

            local playerHunterTimes = data.playerHunterTimes

            playerHunterTimes[#playerHunterTimes + 1] = { player = source, timePassed = timePassed }

            if not isTimer(data.playerHunterTimesTimer) then
                data.playerHunterTimesTimer = setTimer(teamhdm.timers.hunterTimes, teamhdm.settings.playerHunterTimesDelay, 1)
            end

            if getElementData(data.coreElement, "state", false) == "live" then
                local eventClan = teamhdm.getPlayerEventClan(source)

                if eventClan then
                    local eventData = event1.data
                    local arenaElement = eventData.arenaElement
                    local teamElement = eventClan.teamElement

                    local oldPassed = getElementData(source, "passed", false) or 0
                    local oldPoints = getElementData(source, "points", false) or 0
                    local teamPoints = getElementData(teamElement, "points", false) or 0

                    outputChatBox("#CCCCCCAdding an additional point to #ffffff".. getPlayerName(source) .. "#CCCCCC for finishing the map.", arenaElement, 255, 255, 255, true)
                    --outputChatBox(getPlayerName(source) .. "#ffffff has finished the map. [" .. tostring(oldPoints) .. " -> " .. tostring(oldPoints + 1) .. "]", arenaElement, 255, 255, 255, true)

                    setElementData(teamElement, "points", teamPoints + 1)
                    eventClan:setPlayerData(source, "passed", oldPassed + 1)
                    eventClan:setPlayerData(source, "points", oldPoints + 1)
                    eventClan:setPlayerData(source, "mapHunterReached", true)
                    
                end
            end
        end,

        onArenaPlayerJoin = function()
            teamhdm.addEventClansDataSubscriber(source)

            triggerClientResourceEvent(resource, source, "event1:teamhdm:onClientEventModeStart", source, teamhdm.settings.teamsCount)

            local data = teamhdm.data
    
            if hasObjectPermissionTo(source, "resource." .. resourceName .. ".mode_teamhdm_referee", false) then
                silentExport("ep_core", "setPlayerTeam", source, data.refereeClan.teamElement)
            else
                silentExport("ep_core", "setPlayerTeam", source, data.spectatorsClan.teamElement)
            end
        end,

        onArenaPlayerQuit = function()
            silentExport("ep_core", "setPlayerTeam", source, nil)
            
            triggerClientResourceEvent(resource, source, "event1:teamhdm:onClientEventModeStop", source)
            
            teamhdm.removeEventClansDataSubscriber(source)
        end,

        onArenaPlayerTeamChange = function(oldTeam, newTeam)
            local data = teamhdm.data
            
            local refereeClan = data.refereeClan
            local spectatorsClan = data.spectatorsClan

            refereeClan:removePlayer(source)
            spectatorsClan:removePlayer(source)

            local eventClans = data.eventClans

            for i = 1, #eventClans do
                local clan = eventClans[i]

                clan:setPlayerData(source, "mapHunterReached", nil)

                clan:removePlayer(source)
            end

            if newTeam then
                local eventClan = teamhdm.getEventClanByTeamElement(newTeam)

                if eventClan then
                    eventClan:addPlayer(source)

                    eventClan:setPlayerData(source, "nickName", getPlayerName(source))

                    if not getElementData(source, "points", false) then
                        eventClan:setPlayerData(source, "points", 0)
                    end
                else
                    if newTeam == refereeClan.teamElement then
                        refereeClan:addPlayer(source)
                    elseif newTeam == spectatorsClan.teamElement then
                        spectatorsClan:addPlayer(source)
                    end
                end
            end
        end,

        onArenaPlayerChangeNick = function(oldNick, newNick)
            local eventClan = teamhdm.getPlayerEventClan(source)

            if eventClan then
                eventClan:setPlayerData(source, "nickName", newNick)
            end
        end,

        onArenaPlayerLogin = function()
            if hasObjectPermissionTo(source, "resource." .. resourceName .. ".mode_teamhdm_referee", false) then
                silentExport("ep_core", "setPlayerTeam", source, teamhdm.data.refereeClan.teamElement)
            end
        end
    },

    commandHandlers = {
        join = function(player, commandName, tag)
            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local playerArenaElement = event1.getPlayerArenaElement(player)

            if playerArenaElement == arenaElement then
                if tag then
                    local eventClan = teamhdm.getEventClanByTag(tag)

                    if eventClan then
                        if not eventClan.players[player] then
                            local playerName = stringLower(stringRemoveHex(getPlayerName(player)))

                            if stringFind(playerName, stringLower(tag), 1, true) then
                                local teamElement = eventClan.teamElement

                                silentExport("ep_core", "setPlayerTeam", player, teamElement)

                                local r, g, b = getTeamColor(teamElement)

                                local hexColor = "#" .. rgbToHex(r, g, b)

                                local tag = getElementData(teamElement, "tag", false)

                                outputChatBox(getPlayerName(player) .. " #CCCCCChas joined " .. hexColor .. tag, arenaElement, 255, 255, 255, true)
                            else
                                outputChatBox("#CCCCCCYou do not belong to this team", player, 255, 255, 255, true)
                            end
                        end
                    end
                else
                    outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [tag]", player, 255, 255, 255, true)
                end
            end
        end,

        spec = function(player, commandName)
            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local playerArenaElement = event1.getPlayerArenaElement(player)

            if playerArenaElement == arenaElement then
                local spectatorsClan = teamhdm.data.spectatorsClan

                if not spectatorsClan.players[player] then
                    local teamElement = spectatorsClan.teamElement

                    silentExport("ep_core", "setPlayerTeam", player, teamElement)

                    local r, g, b = getTeamColor(teamElement)

                    local hexColor = "#" .. rgbToHex(r, g, b)

                    outputChatBox(getPlayerName(player) .. " #CCCCCChas joined " .. hexColor .. getTeamName(teamElement), arenaElement, 255, 255, 255, true)
                end
            end
        end,

        setEventName = function(player, commandName, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamhdm_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local arg = { ... }

                    if #arg > 0 then
                        local eventName = tableConcat(arg, " ")

                        setElementID(teamhdm.data.coreElement, eventName)

                        outputChatBox("#CCCCCCEvent name has been set to #FFFFFF" .. eventName .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [name]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setTeamName = function(player, commandName, tag, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamhdm_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = teamhdm.getEventClanByTag(tag)

                        if eventClan then
                            local arg = { ... }

                            if #arg > 0 then
                                local teamName = tableConcat(arg, " ")

                                if not getTeamFromName(teamName) then
                                    local teamElement = eventClan.teamElement
            
                                    setTeamName(teamElement, teamName)
    
                                    local r, g, b = getTeamColor(teamElement)
    
                                    local hexColor = "#" .. rgbToHex(r, g, b)

                                    local tag = getElementData(teamElement, "tag", false)
            
                                    outputChatBox(hexColor .. tag .. " #CCCCCCname has been set to " .. hexColor .. teamName .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                                else
                                    outputChatBox("#CCCCCCTeam with this name already exists", player, 255, 255, 255, true)
                                end
                            else
                                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [name]", player, 255, 255, 255, true)
                            end
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [tag] [name]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setTeamColor = function(player, commandName, tag, hexColor)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamhdm_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = teamhdm.getEventClanByTag(tag)

                        if eventClan then
                            if hexColor then
                                local r, g, b = getColorFromString(hexColor)

                                if r then
                                    local teamElement = eventClan.teamElement

                                    local oldR, oldG, oldB = getTeamColor(teamElement)

                                    local oldHexColor = "#" .. rgbToHex(oldR, oldG, oldB)

                                    local tag = getElementData(teamElement, "tag", false)

                                    setTeamColor(teamElement, r, g, b)

                                    outputChatBox(oldHexColor .. tag .. " #CCCCCCcolor has been set to " .. hexColor .. stringGsub(hexColor, "#", "") .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                                else
                                    outputChatBox("#CCCCCCInvalid color specified", player, 255, 255, 255, true)
                                end
                            else
                                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [hex color]", player, 255, 255, 255, true)
                            end
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [tag] [hex color]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setTeamTag = function(player, commandName, tag, newTag)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamhdm_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = teamhdm.getEventClanByTag(tag)

                        if eventClan then
                            if newTag then
                                local teamElement = eventClan.teamElement

                                local tag = getElementData(teamElement, "tag", false)

                                setElementData(teamElement, "tag", newTag)

                                local r, g, b = getTeamColor(teamElement)

                                local hexColor = "#" .. rgbToHex(r, g, b)

                                outputChatBox(hexColor .. tag .. " #CCCCCCtag has been set to " .. hexColor .. newTag .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                            else
                                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [tag] [new tag]", player, 255, 255, 255, true)
                            end
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [tag] [new tag]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setTeamPoints = function(player, commandName, tag, points)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamhdm_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = teamhdm.getEventClanByTag(tag)

                        if eventClan then
                            points = tonumber(points)

                            if points then
                                local teamElement = eventClan.teamElement

                                setElementData(teamElement, "points", points)

                                local r, g, b = getTeamColor(teamElement)

                                local hexColor = "#" .. rgbToHex(r, g, b)

                                local tag = getElementData(teamElement, "tag", false)

                                outputChatBox(hexColor .. tag .. " #CCCCCCpoints have been set to #FFFFFF" .. tostring(points) .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                            else
                                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [tag] [points]", player, 255, 255, 255, true)
                            end
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [tag] [points]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setState = function(player, commandName, state)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamhdm_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if state then
                        local stateData = teamhdm.states[state]

                        if stateData then
                            setElementData(teamhdm.data.coreElement, "state", state)

                            local stateFunction = teamhdm.stateFunctions[state]

                            if stateFunction then
                                stateFunction()
                            end

                            local hexColor = "#" .. rgbToHex(unpack(stateData.color))

                            outputChatBox("#CCCCCCState has been set to " .. hexColor .. stateData.name .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                        else
                            outputChatBox("#CCCCCCInvalid state specified #FFFFFF(free/live/ended)", player, 255, 255, 255, true)
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [state]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setRound = function(player, commandName, round)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamhdm_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if round then
                        round = tonumber(round)

                        if round then
                            setElementData(teamhdm.data.coreElement, "round", round)

                            outputChatBox("#CCCCCCRound has been set to #FFFFFF" .. tostring(round) .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                        else
                            outputChatBox("#CCCCCCInvalid number specified", player, 255, 255, 255, true)
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [round]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setTotalRounds = function(player, commandName, totalRounds)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamhdm_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if totalRounds then
                        totalRounds = tonumber(totalRounds)

                        if totalRounds then
                            setElementData(teamhdm.data.coreElement, "totalRounds", totalRounds)

                            outputChatBox("#CCCCCCTotal rounds have been set to #FFFFFF" .. tostring(totalRounds) .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                        else
                            outputChatBox("#CCCCCCInvalid number specified", player, 255, 255, 255, true)
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [total rounds]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setPlayerPoints = function(player, commandName, playerPartialName, points)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamhdm_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if playerPartialName then
                        local arenaPlayers = getElementChildren(arenaElement, "player")

                        local targetPlayer = getPlayerFromPartialName(arenaPlayers, playerPartialName)

                        if targetPlayer then
                            points = tonumber(points)

                            if points then
                                local eventClan = teamhdm.getPlayerEventClan(targetPlayer)
    
                                if eventClan then
                                    eventClan:setPlayerData(targetPlayer, "points", points)

                                    outputChatBox(getPlayerName(targetPlayer) .. " #CCCCCCpoints have been set to #FFFFFF" .. tostring(points) .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                                else
                                    outputChatBox("#CCCCCCPlayer #FFFFFF" .. getPlayerName(player) .. " #CCCCCCis not in a team", player, 255, 255, 255, true)
                                end
                            else
                                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [player partial name] [points]", player, 255, 255, 255, true)
                            end
                        else
                            outputChatBox("#CCCCCCPlayer not found", player, 255, 255, 255, true)
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [player partial name] [points]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setTeamsCount = function(player, commandName, teamsCount)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamhdm_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    teamsCount = tonumber(teamsCount)

                    if teamsCount then
                        teamsCount = math.max(math.min(teamsCount, 5), 1)

                        teamhdm.stop()

                        teamhdm.settings.teamsCount = teamsCount
    
                        -- bug fix
                        setTimer(
                            function()
                                teamhdm.start()
    
                                outputChatBox("#CCCCCCTeams count has been set to #FFFFFF" .. tostring(teamsCount) .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                            end,
                        100, 1)
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [teams count]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        addPoints = function(player, commandName, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamhdm_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local players = { ... }

                    if #players > 0 then
                        local getPlayerEventClan = teamhdm.getPlayerEventClan

                        local pointsOrder = teamhdm.settings.pointsOrder
                        
                        local pointsOrderCount = #pointsOrder

                        local arenaPlayers = getElementChildren(arenaElement, "player")

                        local invalidPlayerPositions = {}

                        for i = 1, pointsOrderCount do
                            local playerPartialName = players[i]

                            local targetPlayer = getPlayerFromPartialName(arenaPlayers, playerPartialName or "")

                            if not playerPartialName or not targetPlayer or not getPlayerEventClan(targetPlayer) then
                                invalidPlayerPositions[#invalidPlayerPositions + 1] = i
                            end
                        end

                        if #invalidPlayerPositions == 0 then
                            outputChatBox("#CCCCCCPoints have been added by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)

                            local data = teamhdm.data

                            local playersStrings = {}

                            for i = 1, pointsOrderCount do
                                local positionString = tostring(i) .. nth(i)

                                local targetPlayer = getPlayerFromPartialName(arenaPlayers, players[i])

                                local eventClan = getPlayerEventClan(targetPlayer)
    
                                local targetPlayerOldPositionValue = getElementData(targetPlayer, positionString, false) or 0
                                local targetPlayerNewPositionValue = targetPlayerOldPositionValue + 1

                                local points = pointsOrder[i]
                                
                                local targetPlayerOldPoints = getElementData(targetPlayer, "points", false) or 0
                                local targetPlayerNewPoints = targetPlayerOldPoints + points
                                
                                eventClan:setPlayerData(targetPlayer, positionString, targetPlayerNewPositionValue)
                                eventClan:setPlayerData(targetPlayer, "points", targetPlayerNewPoints)

                                local teamElement = eventClan.teamElement

                                local teamElementOldPoints = getElementData(teamElement, "points", false) or 0

                                setElementData(teamElement, "points", teamElementOldPoints + points)

                                local pointsString = tostring(points)

                                local targetPlayerName = getPlayerName(targetPlayer)

                                local targetPlayerNewPointsString

                                if getElementData(targetPlayer, "mapHunterReached", false) then
                                    targetPlayerNewPointsString = tostring(targetPlayerNewPoints - 1) .. " + 1"
                                else
                                    targetPlayerNewPointsString = tostring(targetPlayerNewPoints)
                                end

                                --playersStrings[#playersStrings + 1] = positionString .. " (" .. pointsString .. ") " .. stringRemoveHex(targetPlayerName) .. " (" .. targetPlayerNewPointsString .. ")"
                                playersStrings[#playersStrings + 1] = targetPlayerName .. " #FFFFFF(" .. targetPlayerNewPointsString .. ")"

                                outputChatBox("#CCCCCC" .. positionString .. ": #FFFFFF" .. targetPlayerName .. " #CCCCCChas earned #FFFFFF" .. pointsString .. " #CCCCCCpoints and now has #FFFFFF" .. tostring(targetPlayerNewPoints) .. " #CCCCCCpoint" .. (targetPlayerNewPoints == 1 and "" or "s"), arenaElement, 255, 255, 255, true)
                            end

                            local mapData = data.mapData

                            local thisMapID = #mapData + 1

                            local mapInfo = getElementData(arenaElement, "mapInfo", false) or {}

                            local mapString = tostring(thisMapID) .. ". " .. (mapInfo.name or "")

                            local eventClans = data.eventClans

                            local clansStrings = {}

                            local clansOutputStrings = {}
        
                            for i = 1, #eventClans do
                                local clan = eventClans[i]
        
                                local teamElement = clan.teamElement

                                local r, g, b = getTeamColor(teamElement)

                                local hexColor = "#" .. rgbToHex(r, g, b)
        
                                local teamTag = getElementData(teamElement, "tag", false)
        
                                local teamPoints = getElementData(teamElement, "points", false) or 0
        
                                local clanString = hexColor .. teamTag .. " #FFFFFF" .. teamPoints
        
                                clansStrings[i] = clanString

                                local clanOutputString = hexColor .. teamTag .. " #FFFFFF" .. teamPoints
        
                                clansOutputStrings[i] = clanOutputString
                            end

                            local clansString = tableConcat(clansStrings, ", ")

                            local thisMapData = { mapString, clansString, unpack(playersStrings) }

                            mapData[thisMapID] = thisMapData

                            local clanOutputString = tableConcat(clansOutputStrings, ", ")
        
                            outputChatBox("#CCCCCCCurrent result: " .. clanOutputString, arenaElement, 255, 255, 255, true)
                        else
                            outputChatBox("#CCCCCCInvalid players specified at positions: #FFFFFF" .. tableConcat(invalidPlayerPositions, ", "), player, 255, 255, 255, true)
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [players]", player, 255, 255, 255, true)
                    end
                end
            end
        end,
        
        randomKill = function(player, commandName, tag)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamhdm_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = teamhdm.getEventClanByTag(tag)

                        if eventClan then
                            local alivePlayers = teamhdm.getAlivePlayersInClan(eventClan)

                            local alivePlayersLen = #alivePlayers

                            if alivePlayersLen > 0 then
                                local randomPlayer = alivePlayers[math.random(alivePlayersLen)]

                                if isElement(randomPlayer) then
                                    killPed(randomPlayer)

                                    outputChatBox(getPlayerName(randomPlayer) .. " #CCCCCChas been killed by #FFFFFF" .. getPlayerName(player) .. " #CCCCCC(random kill)", arenaElement, 255, 255, 255, true)
                                end
                            end
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [tag]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        outputResultsForum = function(player, commandName, forumName, hiddenArg, separatorOffset, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamhdm_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local forumID = tonumber(forumName)--teamhdm.settings.forumNameIDs[forumName]

                    if forumID then
                        local isTopicHidden = true

                        if hiddenArg == "hidden" then
                            isTopicHidden = true
                        elseif hiddenArg == "visible" then
                            isTopicHidden = false
                        end

                        local arg = { ... }

                        teamhdm.outputResultsOnForum(forumID, isTopicHidden, tableConcat({unpack(arg, 1, separatorOffset)}, " "), tableConcat({unpack(arg, separatorOffset + 1)}, " "),
                            function(success, errorCode)
                                if success then
                                    outputChatBox("#CCCCCCDone", player, 255, 255, 255, true)
                                else
                                    outputChatBox("#CCCCCCAn error occured: " .. tostring(errorCode), player, 255, 255, 255, true)
                                end
                            end
                        )
                    else
                        outputChatBox("#CCCCCCInvalid forum name", player, 255, 255, 255, true)
                    end
                end
            end
        end,
        
        resetMode = function(player, commandName, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamhdm_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    teamhdm.stop()

                    local dataFilePath = teamhdm.settings.dataFilePath

                    if fileExists(dataFilePath) then
                        fileDelete(dataFilePath)
                    end

                    -- bug fix
                    setTimer(
                        function()
                            teamhdm.start()

                            outputChatBox("#CCCCCCEvent mode has been reset by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                        end,
                    100, 1)
                end
            end
        end
    },

    timers = {
        hunterTimes = function()
            local data = teamhdm.data

            local playerHunterTimes = data.playerHunterTimes
            
            tableSort(playerHunterTimes,
                function(a, b)
                    return a.timePassed < b.timePassed
                end
            )

            local eventData = event1.data

            local arenaElement = eventData.arenaElement
            
            for i = 1, #playerHunterTimes do
                local hunterTime = playerHunterTimes[i]

                local position = data.playerHunterLastPosition + 1

                data.playerHunterLastPosition = position

                outputChatBox("#CCCCCC" .. tostring(position) .. nth(position) .. ": #FFFFFF" .. getPlayerName(hunterTime.player) .. "#CCCCCC, time: #FFFFFF" .. formatMS(hunterTime.timePassed), arenaElement, 255, 255, 255, true)
            end

            data.playerHunterTimes = {}
        end,

        checkAlivePlayers = function()
            local data = teamhdm.data

            local coreElement = data.coreElement
    
            if getElementData(coreElement, "state", false) == "live" then
                local arenaElement = event1.data.arenaElement

                local eventClans = data.eventClans

                local getAlivePlayersInClan = teamhdm.getAlivePlayersInClan

                for i = 1, #eventClans do
                    local clan = eventClans[i]

                    local clanAlivePlayersCount = #getAlivePlayersInClan(clan)

                    if clanAlivePlayersCount > 5 then
                        local teamElement = clan.teamElement

                        local r, g, b = getTeamColor(teamElement)

                        local hexColor = "#" .. rgbToHex(r, g, b)

                        local teamTag = getElementData(teamElement, "tag", false)

                        outputChatBox(hexColor .. teamTag .. " #CCCCCCis playing with #FFFFFF" .. tostring(clanAlivePlayersCount) .. " #CCCCCCplayers", arenaElement, 255, 255, 255, true)
                    end
                end
            end
        end
    },

    arenaDeathmatchStateFunctions = {
        ["map loaded"] = function()
            local eventData = event1.data

            local arenaPlayers = getElementChildren(eventData.arenaElement, "player")

            local getPlayerEventClan = teamhdm.getPlayerEventClan

            local deathmatchData = deathmatch.data

            local getPlayerVehicle = deathmatch.getPlayerVehicle

            for i = 1, #arenaPlayers do
                local arenaPlayer = arenaPlayers[i]

                local eventClan = getPlayerEventClan(arenaPlayer)

                if not eventClan then
                    deathmatchMapLoadedStateData:removePlayerFromLoadQueue(arenaPlayer)
                else
                    local vehicle = getPlayerVehicle(arenaPlayer)

                    if isElement(vehicle) then
                        deathmatchMapLoadedStateData:setPlayerSpawnpointID(arenaPlayer, 1)

                        local r, g, b = getTeamColor(eventClan.teamElement)

                        setVehicleColor(vehicle, r, g, b)
                    end

                    eventClan:setPlayerData(arenaPlayer, "mapHunterReached", nil)
                end
            end

            local data = teamhdm.data

            local coreElement = data.coreElement

            if getElementData(coreElement, "state", false) == "live" then
                local oldRound = getElementData(coreElement, "round", false) or 0

                setElementData(coreElement, "round", oldRound + 1)
            end

            deathmatchMapLoadedStateData:killForcedCountdownTimer()
        end,

        ["running"] = function()
            local data = teamhdm.data

            if isTimer(data.playerHunterTimesTimer) then
                killTimer(data.playerHunterTimesTimer)
            end

            data.playerHunterTimesTimer = nil

            data.playerHunterTimes = {}
            data.playerHunterLastPosition = 0

            --teamhdm.data.checkAlivePlayersTimer = setTimer(teamhdm.timers.checkAlivePlayers, 4000, 0)
        end,

        ["ended"] = function()
            deathmatchEndedStateData:killNextMapTimer()
        end,

        ["map unloading"] = function()
            local data = teamhdm.data

            if isTimer(data.checkAlivePlayersTimer) then
                killTimer(data.checkAlivePlayersTimer)
            end

            data.checkAlivePlayersTimer = nil
        end
    },

    stateFunctions = {
        ["ended"] = function()
            local resultsString, resultsJSONString = teamhdm.saveResults()

            if resultsString then
                local eventData = event1.data

                local refereePlayers = {}

                local arenaPlayers = getElementChildren(eventData.arenaElement, "player")

                local permissionString = "resource." .. resourceName .. ".mode_teamhdm_referee"

                for i = 1, #arenaPlayers do
                    local arenaPlayer = arenaPlayers[i]

                    if hasObjectPermissionTo(arenaPlayer, permissionString, false) then
                        refereePlayers[#refereePlayers + 1] = arenaPlayer
                    end
                end

                if #refereePlayers > 0 then
                    triggerClientResourceEvent(resource, refereePlayers, "event1:teamhdm:onClientArenaResultsSaved", eventData.sourceElement, resultsString, resultsJSONString)
                end
            end
        end
    },

    states = {
        ["free"] = { name = "Free", color = { 204, 150, 105 } },
        ["live"] = { name = "Live", color = { 105, 204, 150 } },
        ["ended"] = { name = "Ended", color = { 204, 105, 105 } }
    }
}

event1.modes.teamhdm = teamhdm

addEvent("event1:onArenaCreated")
addEvent("event1:onArenaDestroy")

addEvent("event1:onPlayerArenaJoin")
addEvent("event1:onPlayerArenaQuit")

addEvent("onPlayerTeamChange")

addEvent("event1:deathmatch:onArenaStateSet")
addEvent("event1:deathmatch:onPlayerJoinSpawn")
addEvent("event1:deathmatch:onPlayerReachedHunter")

addEvent("event1:teamhdm:onEventStateSet")

do
    local eventHandlers = teamhdm.eventHandlers

    addEventHandler("event1:onArenaCreated", resourceRoot, eventHandlers.onArenaCreated)
    addEventHandler("event1:onArenaDestroy", resourceRoot, eventHandlers.onArenaDestroy)
end