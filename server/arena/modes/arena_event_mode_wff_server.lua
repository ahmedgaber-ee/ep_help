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

local wff

wff = {
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

        dataFilePath = "server/arena/modes/wff_data.json",
        resultsFilePath = "server/arena/modes/wff_results.txt",
        resultsJSONFilePath = "server/arena/modes/wff_results.json",

        pointsOrder = { 3, 2, 1, 1 },

        playerHunterTimesDelay = 2000
    },

    start = function()
        if not wff.data then
            local data = {}

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local arenaName = getElementData(arenaElement, "name", false)

            local mainClan = clanNew(arenaName .. " Team", 255, 255, 255)
            local refereeClan = clanNew(arenaName .. " Referee", 255, 0, 0)
            local spectatorsClan = clanNew(arenaName .. " Spectators", 255, 255, 255)

            local coreElement = createElement("core", "Event Name")

            setElementParent(coreElement, arenaElement)

            setElementData(arenaElement, "coreElement", coreElement)

            setElementData(coreElement, "mainClanTeamElement", mainClan.teamElement)
            setElementData(coreElement, "refereeClanTeamElement", refereeClan.teamElement)
            setElementData(coreElement, "spectatorsClanTeamElement", spectatorsClan.teamElement)

            setElementData(coreElement, "state", "free")
            setElementData(coreElement, "round", 1)
            setElementData(coreElement, "totalRounds", 20)

            local eventHandlers = wff.eventHandlers

            addEventHandler("event1:deathmatch:onArenaStateSet", arenaElement, eventHandlers.onArenaDeathmatchStateSet)
            addEventHandler("event1:deathmatch:onPlayerJoinSpawn", arenaElement, eventHandlers.onArenaDeathmatchPlayerJoinSpawn)
            addEventHandler("event1:deathmatch:onPlayerReachedHunter", arenaElement, eventHandlers.onArenaDeathmatchPlayerReachedHunter)

            addEventHandler("event1:onPlayerArenaJoin", arenaElement, eventHandlers.onArenaPlayerJoin)
            addEventHandler("event1:onPlayerArenaQuit", arenaElement, eventHandlers.onArenaPlayerQuit)
            
            addEventHandler("onPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)
            addEventHandler("onPlayerChangeNick", arenaElement, eventHandlers.onArenaPlayerChangeNick)
            addEventHandler("onPlayerLogin", arenaElement, eventHandlers.onArenaPlayerLogin)

            local commandHandlers = wff.commandHandlers

            addCommandHandler("seteventname", commandHandlers.setEventName)
            addCommandHandler("setteamname", commandHandlers.setTeamName)
            addCommandHandler("setteamcolor", commandHandlers.setTeamColor)
            addCommandHandler("setstate", commandHandlers.setState)
            addCommandHandler("setround", commandHandlers.setRound)
            addCommandHandler("settotalrounds", commandHandlers.setTotalRounds)
            addCommandHandler("setplayerpoints", commandHandlers.setPlayerPoints)
            addCommandHandler("addpoints", commandHandlers.addPoints)
            addCommandHandler("outputresultsforum", commandHandlers.outputResultsForum)
            addCommandHandler("resetmode", commandHandlers.resetMode)
            addCommandHandler("join", commandHandlers.join)
            addCommandHandler("play", commandHandlers.join)

            data.coreElement = coreElement

            data.mainClan = mainClan
            data.refereeClan = refereeClan
            data.spectatorsClan = spectatorsClan

            data.playerHunterTimes = {}
            data.playerHunterLastPosition = 0

            data.mapData = {}

            wff.data = data

            wff.loadData()
            wff.updatePlayersOnStart()

            local sourceElement = eventData.sourceElement

            triggerClientResourceEvent(resource, arenaElement, "event1:wff:onClientEventModeCreatedInternal", sourceElement)

            triggerEvent("event1:wff:onEventModeCreated", sourceElement)

            outputDebugString(debuggerPrepareString("Event wff mode created.", 1))
        end
    end,

    stop = function()
        local data = wff.data

        if data then
            outputDebugString(debuggerPrepareString("Destroying event1 wff mode.", 1))

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local sourceElement = eventData.sourceElement

            triggerEvent("event1:wff:onEventModeDestroy", sourceElement)

            triggerClientResourceEvent(resource, arenaElement, "event1:wff:onClientEventModeDestroyInternal", sourceElement)

            local eventHandlers = wff.eventHandlers

            removeEventHandler("event1:deathmatch:onArenaStateSet", arenaElement, eventHandlers.onArenaDeathmatchStateSet)
            removeEventHandler("event1:deathmatch:onPlayerJoinSpawn", arenaElement, eventHandlers.onArenaDeathmatchPlayerJoinSpawn)
            removeEventHandler("event1:deathmatch:onPlayerReachedHunter", arenaElement, eventHandlers.onArenaDeathmatchPlayerReachedHunter)

            removeEventHandler("event1:onPlayerArenaJoin", arenaElement, eventHandlers.onArenaPlayerJoin)
            removeEventHandler("event1:onPlayerArenaQuit", arenaElement, eventHandlers.onArenaPlayerQuit)
            
            removeEventHandler("onPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)
            removeEventHandler("onPlayerChangeNick", arenaElement, eventHandlers.onArenaPlayerChangeNick)
            removeEventHandler("onPlayerLogin", arenaElement, eventHandlers.onArenaPlayerLogin)

            local commandHandlers = wff.commandHandlers

            removeCommandHandler("seteventname", commandHandlers.setEventName)
            removeCommandHandler("setteamname", commandHandlers.setTeamName)
            removeCommandHandler("setteamcolor", commandHandlers.setTeamColor)
            removeCommandHandler("setstate", commandHandlers.setState)
            removeCommandHandler("setround", commandHandlers.setRound)
            removeCommandHandler("settotalrounds", commandHandlers.setTotalRounds)
            removeCommandHandler("setplayerpoints", commandHandlers.setPlayerPoints)
            removeCommandHandler("addpoints", commandHandlers.addPoints)
            removeCommandHandler("outputresultsforum", commandHandlers.outputResultsForum)
            removeCommandHandler("resetmode", commandHandlers.resetMode)
            removeCommandHandler("join", commandHandlers.join)
            removeCommandHandler("play", commandHandlers.join)

            setElementData(arenaElement, "coreElement", nil)

            local coreElement = data.coreElement

            setElementData(coreElement, "mainClanTeamElement", nil)
            setElementData(coreElement, "refereeClanTeamElement", nil)
            setElementData(coreElement, "spectatorsClanTeamElement", nil)

            setElementData(coreElement, "state", nil)
            setElementData(coreElement, "round", nil)
            setElementData(coreElement, "totalRounds", nil)

            wff.saveData()
            wff.updatePlayersOnStop()

            local playerHunterTimesTimer = data.playerHunterTimesTimer

            if isTimer(playerHunterTimesTimer) then
                killTimer(playerHunterTimesTimer)
            end

            if isElement(coreElement) then
                destroyElement(coreElement)
            end

            data.mainClan:destroy()
            data.refereeClan:destroy()
            data.spectatorsClan:destroy()

            wff.data = nil
        end
    end,

    updatePlayersOnStart = function()
        local data = wff.data

        local mainClan = data.mainClan
        local refereeClan = data.refereeClan
        local spectatorsClan = data.spectatorsClan

        local refereeClanTeamElement = refereeClan.teamElement
        local spectatorsClanTeamElement = spectatorsClan.spectatorsClanTeamElement

        local eventData = event1.data

        local arenaElement = eventData.arenaElement

        local arenaPlayers = getElementChildren(arenaElement, "player")

        local permissionString = "resource." .. resourceName .. ".mode_wff_referee"

        for i = 1, #arenaPlayers do
            local arenaPlayer = arenaPlayers[i]

            if hasObjectPermissionTo(arenaPlayer, permissionString, false) then
                silentExport("ep_core", "setPlayerTeam", arenaPlayer, refereeClanTeamElement)
            else
                silentExport("ep_core", "setPlayerTeam", arenaPlayer, spectatorsClanTeamElement)
            end

            mainClan:addAllElementDataSubscriber(arenaPlayer)
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
        local dataFilePath = wff.settings.dataFilePath

        if fileExists(dataFilePath) then
            fileDelete(dataFilePath)
        end

        local fileHandler = fileCreate(dataFilePath)

        if fileHandler then
            local data = wff.data

            local mainClan = data.mainClan

            local mainClanTeamElement = mainClan.teamElement

            local dataToSave = {
                mainClanData = {
                    eventName = getElementID(data.coreElement),

                    teamName = getTeamName(mainClanTeamElement),

                    teamColor = { getTeamColor(mainClanTeamElement) },

                    serialData = mainClan.serialData
                },

                mapData = data.mapData
            }

            local dataJSON = toJSON(dataToSave, false, "tabs")

            fileWrite(fileHandler, dataJSON)
            fileClose(fileHandler)
        end
    end,

    loadData = function()
        local dataFilePath = wff.settings.dataFilePath

        if fileExists(dataFilePath) then
            local fileHandler = fileOpen(dataFilePath, true)

            if fileHandler then
                local loadedDataJSON = fileRead(fileHandler, fileGetSize(fileHandler))

                local loadedData = fromJSON(loadedDataJSON) or {}

                fileClose(fileHandler)

                local data = wff.data

                local mainClan = data.mainClan

                local mainClanTeamElement = mainClan.teamElement

                local mainClanData = loadedData.mainClanData

                local mainClanEventName = mainClanData.eventName
                
                if mainClanEventName then
                    setElementID(data.coreElement, mainClanEventName)
                end

                local mainClanTeamName = mainClanData.teamName

                if mainClanTeamName then
                    setTeamName(mainClanTeamElement, mainClanTeamName)
                end

                local mainClanTeamColor = mainClanData.mainTeamColor

                if mainClanTeamColor then
                    setTeamColor(mainClanTeamElement, unpack(mainClanTeamColor))
                end

                local mainClanSerialData = mainClanData.serialData

                if mainClanSerialData then
                    mainClan.serialData = mainClanSerialData
                end

                local mapData = loadedData.mapData

                if mapData then
                    data.mapData = mapData
                end
            end
        end
    end,

    saveResults = function()
        local resultsFilePath = wff.settings.resultsFilePath

        if fileExists(resultsFilePath) then
            fileDelete(resultsFilePath)
        end

        local fileHandler = fileCreate(resultsFilePath)

        if fileHandler then
            local data = wff.data

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

            local pointsOrder = wff.settings.pointsOrder

            local pointsOrderCount = #pointsOrder

            local playerResults = {}

            for serial, data in pairs(data.mainClan.serialData) do
                local points = data.points

                if points and points > 0 then
                    local playerResult = { points = points }

                    local dataStrings = {}

                    for i = 1, pointsOrderCount do
                        local positionString = tostring(i) .. nth(i)

                        local positionData = data[positionString] or 0

                        playerResult[positionString] = positionData

                        dataStrings[i] = tostring(positionData) .. "x " .. positionString
                    end

                    dataStrings[#dataStrings + 1] = "passed: " .. tostring(data.passed or 0)

                    local nickNameString = tostring(data.nickName)

                    playerResult.nickName = nickNameString

                    playerResult.text = tostring(points) .. " " .. stringRemoveHex(nickNameString) .. " (" .. tableConcat(dataStrings, ", ") .. ")"

                    playerResults[#playerResults + 1] = playerResult
                end
            end

            local sortValues = { "points" }

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

            local resultsJSONFilePath = wff.settings.resultsJSONFilePath

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
        local data = wff.data

        local resultsToJSON = data.resultsToJSON

        if resultsToJSON then
            local resultsToJSONMapData = resultsToJSON.mapData
            local resultsToJSONResults = resultsToJSON.results
            local resultsToJSONPlayerResults = resultsToJSON.playerResults

            local settings = wff.settings

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
                    </tr>
            ]]
            
            for i = 1, #resultsToJSONPlayerResults do
                local playerResults = resultsToJSONPlayerResults[i]

                htmlStrings[#htmlStrings + 1] = [[
                    <tr>
                        <td>]] .. convertStringToHTML(playerResults[1]) .. [[</td>
                        <td>]] .. playerResults[2] .. [[</td>
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
                        <th>Referee</th>
                        <th>Streamer</th>
                    </tr>
                    <tr>
                        <td>]] .. convertStringToHTML(resultsToJSONResults.mvp or "") .. [[</td>
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
                    title = stringRemoveHex(resultsToJSON.coreID),
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

    eventHandlers = {
        onArenaCreated = function()
            local eventData = event1.data

            local arenaElement = eventData.arenaElement
        
            local eventHandlers = wff.eventHandlers
        
            addEventHandler("event1:wff:onEventStateSet", arenaElement, eventHandlers.onArenaWFFEventStateSet)
        end,

        onArenaDestroy = function()
            local eventData = event1.data

            local arenaElement = eventData.arenaElement
        
            local eventHandlers = wff.eventHandlers
        
            removeEventHandler("event1:wff:onEventStateSet", arenaElement, eventHandlers.onArenaWFFEventStateSet)

            wff.stop()
        end,

        ---

        onArenaWFFEventStateSet = function(state)
            if state then
                wff.start()
            else
                wff.stop()
            end
        end,

        ---

        onArenaDeathmatchStateSet = function(state)
            local arenaDeathmatchStateFunction = wff.arenaDeathmatchStateFunctions[state]

            if arenaDeathmatchStateFunction then
                arenaDeathmatchStateFunction()
            end
        end,

        onArenaDeathmatchPlayerJoinSpawn = function()
            deathmatchMapLoadedStateData:removePlayerFromLoadQueue(source)
        end,

        onArenaDeathmatchPlayerReachedHunter = function(timePassed)
            local data = wff.data

            local playerHunterTimes = data.playerHunterTimes

            playerHunterTimes[#playerHunterTimes + 1] = { player = source, timePassed = timePassed }

            if not isTimer(data.playerHunterTimesTimer) then
                data.playerHunterTimesTimer = setTimer(wff.timers.hunterTimes, wff.settings.playerHunterTimesDelay, 1)
            end

            if getElementData(data.coreElement, "state", false) == "live" then
                local oldMapsPassed = getElementData(source, "passed", false) or 0

                wff.data.mainClan:setPlayerData(source, "passed", oldMapsPassed + 1)
            end
        end,

        onArenaPlayerJoin = function()
            local data = wff.data

            data.mainClan:addAllElementDataSubscriber(source)

            triggerClientResourceEvent(resource, source, "event1:wff:onClientEventModeStart", source)
    
            if hasObjectPermissionTo(source, "resource." .. resourceName .. ".mode_wff_referee", false) then
                silentExport("ep_core", "setPlayerTeam", source, data.refereeClan.teamElement)
            else
                silentExport("ep_core", "setPlayerTeam", source, data.spectatorsClan.teamElement)
            end

            -- join message
            outputChatBox("#CCCCCCUse #FFFFFF/play #CCCCCCor #FFFFFF/join #CCCCCCto participate in the event group.", source, 255, 255, 255, true)

        end,

        onArenaPlayerQuit = function()
            silentExport("ep_core", "setPlayerTeam", source, nil)

            triggerClientResourceEvent(resource, source, "event1:wff:onClientEventModeStop", source)

            local data = wff.data

            data.mainClan:removeAllElementDataSubscriber(source)
        end,

        onArenaPlayerTeamChange = function(oldTeam, newTeam)
            local data = wff.data
            
            local mainClan = data.mainClan
            local refereeClan = data.refereeClan
            local spectatorsClan = data.spectatorsClan

            mainClan:removePlayer(source)
            refereeClan:removePlayer(source)
            spectatorsClan:removePlayer(source)

            if newTeam then
                if newTeam == mainClan.teamElement then
                    mainClan:addPlayer(source)

                    mainClan:setPlayerData(source, "nickName", getPlayerName(source))

                    if not getElementData(source, "points", false) then
                        mainClan:setPlayerData(source, "points", 0)
                    end
                elseif newTeam == refereeClan.teamElement then
                    refereeClan:addPlayer(source)
                elseif newTeam == spectatorsClan.teamElement then
                    spectatorsClan:addPlayer(source)
                end
            end
        end,

        onArenaPlayerChangeNick = function(oldNick, newNick)
            wff.data.mainClan:setPlayerData(source, "nickName", newNick)
        end,

        onArenaPlayerLogin = function()
            if hasObjectPermissionTo(source, "resource." .. resourceName .. ".mode_wff_referee", false) then
                silentExport("ep_core", "setPlayerTeam", source, wff.data.refereeClan.teamElement)
            end
        end
    },

    commandHandlers = {
        join = function(player, commandName)
            local eventData = event1.data
            local arenaElement = eventData.arenaElement
            local playerArenaElement = event1.getPlayerArenaElement(player)

            if playerArenaElement == arenaElement then
                local eventClan = wff.data.mainClan

                if eventClan then
                    local teamElement = eventClan.teamElement
                    local playerTeam = getPlayerTeam(player)

                
                    if playerTeam == teamElement then 
                        return
                    end

                    silentExport("ep_core", "setPlayerTeam", player, teamElement)
                    local r, g, b = getTeamColor(teamElement)
                    local hexColor = "#" .. rgbToHex(r, g, b)
                    --local tag = getElementData(teamElement, "tag", false)
                    local teamName = getTeamName(teamElement)

                    outputChatBox(getPlayerName(player) .. " #CCCCCChas joined " .. hexColor .. teamName, arenaElement, 255, 255, 255, true)
                end
            end
        end, 
        
        setEventName = function(player, commandName, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_wff_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local arg = { ... }

                    if #arg > 0 then
                        local eventName = tableConcat(arg, " ")

                        setElementID(wff.data.coreElement, eventName)

                        outputChatBox("#CCCCCCEvent name has been set to #FFFFFF" .. eventName .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [name]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setTeamName = function(player, commandName, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_wff_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local arg = { ... }

                    if #arg > 0 then
                        local teamName = tableConcat(arg, " ")

                        if not getTeamFromName(teamName) then
                            setTeamName(wff.data.mainClan.teamElement, teamName)

                            outputChatBox("#CCCCCCTeam name has been set to #FFFFFF" .. teamName .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                        else
                            outputChatBox("#CCCCCCTeam with this name already exists", player, 255, 255, 255, true)
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [team name]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setTeamColor = function(player, commandName, colorString)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_wff_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if colorString then
                        local r, g, b = getColorFromString(colorString)

                        if r then
                            setTeamColor(wff.data.mainClan.teamElement, r, g, b)

                            outputChatBox("#CCCCCCTeam color has been set to " .. colorString .. stringGsub(colorString, "#", "") .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                        else
                            outputChatBox("#CCCCCCInvalid color specified", player, 255, 255, 255, true)
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [hex color]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setState = function(player, commandName, state)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_wff_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if state then
                        local stateData = wff.states[state]

                        if stateData then
                            setElementData(wff.data.coreElement, "state", state)

                            local stateFunction = wff.stateFunctions[state]

                            if stateFunction then
                                stateFunction()
                            end

                            local hex = "#" .. rgbToHex(unpack(stateData.color))

                            outputChatBox("#CCCCCCState has been set to " .. hex .. stateData.name .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_wff_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if round then
                        round = tonumber(round)

                        if round then
                            setElementData(wff.data.coreElement, "round", round)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_wff_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if totalRounds then
                        totalRounds = tonumber(totalRounds)

                        if totalRounds then
                            setElementData(wff.data.coreElement, "totalRounds", totalRounds)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_wff_cmd_" .. commandName, false) then
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
                                local mainClan = wff.data.mainClan

                                if mainClan.players[targetPlayer] then
                                    mainClan:setPlayerData(targetPlayer, "points", points)
    
                                    outputChatBox(getPlayerName(targetPlayer) .. " #CCCCCCpoints have been set to #FFFFFF" .. tostring(points) .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                                else
                                    outputChatBox("#CCCCCCPlayer #FFFFFF" .. getPlayerName(player) .. " #CCCCCCis not in the team", player, 255, 255, 255, true)
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

        addPoints = function(player, commandName, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_wff_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local players = { ... }

                    if #players > 0 then
                        local data = wff.data

                        local pointsOrder = wff.settings.pointsOrder

                        local pointsOrderCount = #pointsOrder

                        local arenaPlayers = getElementChildren(arenaElement, "player")

                        local mainClan = data.mainClan
                        
                        local mainClanPlayers = mainClan.players

                        local invalidPlayerPositions = {}

                        for i = 1, pointsOrderCount do
                            local playerPartialName = players[i]

                            local targetPlayer = getPlayerFromPartialName(arenaPlayers, playerPartialName or "")

                            if not playerPartialName or not targetPlayer or not mainClanPlayers[targetPlayer] then
                                invalidPlayerPositions[#invalidPlayerPositions + 1] = i
                            end
                        end

                        if #invalidPlayerPositions == 0 then
                            outputChatBox("#CCCCCCPoints have been added by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)

                            local playersStrings = {}

                            for i = 1, pointsOrderCount do
                                local positionString = tostring(i) .. nth(i)

                                local targetPlayer = getPlayerFromPartialName(arenaPlayers, players[i])
    
                                local targetPlayerOldPositionValue = getElementData(targetPlayer, positionString, false) or 0
                                local targetPlayerNewPositionValue = targetPlayerOldPositionValue + 1

                                local points = pointsOrder[i]
                                
                                local targetPlayerOldPoints = getElementData(targetPlayer, "points", false) or 0
                                local targetPlayerNewPoints = targetPlayerOldPoints + points
                                
                                mainClan:setPlayerData(targetPlayer, positionString, targetPlayerNewPositionValue)
                                mainClan:setPlayerData(targetPlayer, "points", targetPlayerNewPoints)

                                local pointsString = tostring(points)

                                local targetPlayerName = getPlayerName(targetPlayer)

                                local targetPlayerNewPointsString = tostring(targetPlayerNewPoints)

                                --playersStrings[#playersStrings + 1] = positionString .. " (" .. pointsString .. ") " .. stringRemoveHex(targetPlayerName) .. " (" .. targetPlayerNewPointsString .. ")"
                                playersStrings[#playersStrings + 1] = targetPlayerName .. " #FFFFFF(" .. targetPlayerNewPointsString .. ")"

                                outputChatBox("#CCCCCC" .. positionString .. ": #FFFFFF" .. targetPlayerName .. " #CCCCCChas earned #FFFFFF" .. pointsString .. " #CCCCCCpoints and now has #FFFFFF" .. targetPlayerNewPointsString .. " #CCCCCCpoint" .. (targetPlayerNewPoints == 1 and "" or "s"), arenaElement, 255, 255, 255, true)
                            end

                            local mapData = data.mapData

                            local thisMapID = #mapData + 1
    
                            local mapInfo = getElementData(arenaElement, "mapInfo", false) or {}
    
                            local mapString = tostring(thisMapID) .. ". " .. (mapInfo.name or "")
    
                            local thisMapData = { mapString, unpack(playersStrings) }
    
                            mapData[thisMapID] = thisMapData
                        else
                            outputChatBox("#CCCCCCInvalid players specified at positions: #FFFFFF" .. tableConcat(invalidPlayerPositions, ", "), player, 255, 255, 255, true)
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [players]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        outputResultsForum = function(player, commandName, forumName, hiddenArg, separatorOffset, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_wff_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local forumID = tonumber(forumName)--wff.settings.forumNameIDs[forumName]

                    if forumID then
                        local isTopicHidden = true

                        if hiddenArg == "hidden" then
                            isTopicHidden = true
                        elseif hiddenArg == "visible" then
                            isTopicHidden = false
                        end

                        local arg = { ... }

                        wff.outputResultsOnForum(forumID, isTopicHidden, tableConcat({unpack(arg, 1, separatorOffset)}, " "), tableConcat({unpack(arg, separatorOffset + 1)}, " "),
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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_wff_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    wff.stop()

                    local dataFilePath = wff.settings.dataFilePath

                    if fileExists(dataFilePath) then
                        fileDelete(dataFilePath)
                    end

                    -- bug fix
                    setTimer(
                        function()
                            wff.start()

                            outputChatBox("#CCCCCCEvent mode has been reset by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                        end,
                    100, 1)
                end
            end
        end
    },

    timers = {
        hunterTimes = function()
            local data = wff.data

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
        end
    },

    arenaDeathmatchStateFunctions = {
        ["map loaded"] = function()
            local eventData = event1.data

            local arenaPlayers = getElementChildren(eventData.arenaElement, "player")

            local data = wff.data

            local mainClan = data.mainClan

            local mainClanPlayers = mainClan.players

            local r, g, b = getTeamColor(mainClan.teamElement)

            local deathmatchData = deathmatch.data

            local getPlayerVehicle = deathmatch.getPlayerVehicle

            for i = 1, #arenaPlayers do
                local arenaPlayer = arenaPlayers[i]

                if not mainClanPlayers[arenaPlayer] then
                    deathmatchMapLoadedStateData:removePlayerFromLoadQueue(arenaPlayer)
                else
                    local vehicle = getPlayerVehicle(arenaPlayer)

                    if isElement(vehicle) then
                        deathmatchMapLoadedStateData:setPlayerSpawnpointID(arenaPlayer, 1)

                        setVehicleColor(vehicle, r, g, b)
                    end
                end
            end

            local coreElement = data.coreElement

            if getElementData(coreElement, "state", false) == "live" then
                local oldRound = getElementData(coreElement, "round", false) or 0

                setElementData(coreElement, "round", oldRound + 1)
            end

            deathmatchMapLoadedStateData:killForcedCountdownTimer()
        end,

        ["running"] = function()
            local data = wff.data

            if isTimer(data.playerHunterTimesTimer) then
                killTimer(data.playerHunterTimesTimer)
            end

            data.playerHunterTimesTimer = nil

            data.playerHunterTimes = {}
            data.playerHunterLastPosition = 0
        end,

        ["ended"] = function()
            deathmatchEndedStateData:killNextMapTimer()
        end,

        ["map unloading"] = function()

        end
    },

    stateFunctions = {
        ["ended"] = function()
            local resultsString, resultsJSONString = wff.saveResults()

            if resultsString then
                local eventData = event1.data

                local refereePlayers = {}

                local arenaPlayers = getElementChildren(eventData.arenaElement, "player")

                local permissionString = "resource." .. resourceName .. ".mode_wff_referee"

                for i = 1, #arenaPlayers do
                    local arenaPlayer = arenaPlayers[i]

                    if hasObjectPermissionTo(arenaPlayer, permissionString, false) then
                        refereePlayers[#refereePlayers + 1] = arenaPlayer
                    end
                end

                if #refereePlayers > 0 then
                    triggerClientResourceEvent(resource, refereePlayers, "event1:wff:onClientArenaResultsSaved", eventData.sourceElement, resultsString, resultsJSONString)
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

event1.modes.wff = wff

addEvent("event1:onArenaCreated")
addEvent("event1:onArenaDestroy")

addEvent("event1:onPlayerArenaJoin")
addEvent("event1:onPlayerArenaQuit")

addEvent("onPlayerTeamChange")

addEvent("event1:deathmatch:onArenaStateSet")
addEvent("event1:deathmatch:onPlayerJoinSpawn")
addEvent("event1:deathmatch:onPlayerArenaJoin")
addEvent("event1:deathmatch:onPlayerArenaQuit")
addEvent("event1:deathmatch:onPlayerReachedHunter")

addEvent("event1:wff:onEventStateSet")

do
    local eventHandlers = wff.eventHandlers

    addEventHandler("event1:onArenaCreated", resourceRoot, eventHandlers.onArenaCreated)
    addEventHandler("event1:onArenaDestroy", resourceRoot, eventHandlers.onArenaDestroy)
end