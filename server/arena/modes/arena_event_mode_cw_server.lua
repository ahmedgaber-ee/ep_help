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

local cw

cw = {
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

        dataFilePath = "server/arena/modes/cw_data.json",
        resultsFilePath = "server/arena/modes/cw_results.txt",
        resultsJSONFilePath = "server/arena/modes/cw_results.json",

        teamsCount = 2
    },

    start = function()
        if not cw.data then
            local data = {}

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local arenaName = getElementData(arenaElement, "name", false)

            local refereeClan = clanNew(arenaName .. " Referee", 255, 0, 0)
            local spectatorsClan = clanNew(arenaName .. " Spectators", 255, 255, 255)

            local coreElement = createElement("core", "Event Name")

            local teamsCount = cw.settings.teamsCount

            setElementParent(coreElement, arenaElement)

            setElementData(arenaElement, "coreElement", coreElement)

            setElementData(coreElement, "refereeClanTeamElement", refereeClan.teamElement)
            setElementData(coreElement, "spectatorsClanTeamElement", spectatorsClan.teamElement)

            setElementData(coreElement, "teamsCount", teamsCount)
            setElementData(coreElement, "state", "free")
            setElementData(coreElement, "round", 1)
            setElementData(coreElement, "totalRounds", 20)

            local eventHandlers = cw.eventHandlers
            
            addEventHandler("event1:cw:onPlayerWasted", arenaElement, eventHandlers.onArenaCWPlayerWasted)
            addEventHandler("event1:cw:onPlayerHunterSpray", arenaElement, eventHandlers.onArenaCWPlayerHunterSpray)

            addEventHandler("event1:deathmatch:onArenaStateSet", arenaElement, eventHandlers.onArenaDeathmatchStateSet)
            addEventHandler("event1:deathmatch:onPlayerJoinSpawn", arenaElement, eventHandlers.onArenaDeathmatchPlayerJoinSpawn)
            addEventHandler("event1:deathmatch:onPlayerReachedHunter", arenaElement, eventHandlers.onArenaDeathmatchPlayerReachedHunter)

            addEventHandler("event1:onPlayerArenaJoin", arenaElement, eventHandlers.onArenaPlayerJoin)
            addEventHandler("event1:onPlayerArenaQuit", arenaElement, eventHandlers.onArenaPlayerQuit)

            addEventHandler("onPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)
            addEventHandler("onPlayerChangeNick", arenaElement, eventHandlers.onArenaPlayerChangeNick)
            addEventHandler("onPlayerLogin", arenaElement, eventHandlers.onArenaPlayerLogin)

            local commandHandlers = cw.commandHandlers

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
            addCommandHandler("setpingspikelimit", commandHandlers.setPingSpikeLimit)
            addCommandHandler("setplayerpoints", commandHandlers.setPlayerPoints)
            addCommandHandler("addplayerdata", commandHandlers.addPlayerData)
            addCommandHandler("getplayerdata", commandHandlers.getPlayerData)
            addCommandHandler("cd", commandHandlers.startCountdown)
            addCommandHandler("fixall", commandHandlers.fixAll)
            addCommandHandler("group", commandHandlers.group)
            addCommandHandler("randomkill", commandHandlers.randomKill)
            addCommandHandler("outputresultsforum", commandHandlers.outputResultsForum)
            addCommandHandler("resetmode", commandHandlers.resetMode)
            addCommandHandler("nhmap", commandHandlers.requestNoHunterMap)

            local timers = cw.timers

            local boundaryTimer = setTimer(timers.checkBoundary, 3000, 0)
            
            data.coreElement = coreElement
            
            data.refereeClan = refereeClan
            data.spectatorsClan = spectatorsClan

            data.boundaryTimer = boundaryTimer

            data.pingSpikeLimit = 50

            eventData.isNoHunterMapRequested = false
            eventData.countdownStarted = false
            eventData.hunterPlayers = {}
            eventData.hunterMapSet = false
            
            data.mapData = {}

            data.mapList = {}

            data.playerPings = {}

            cw.data = data

            cw.createEventClans()
            cw.loadData()
            cw.updatePlayersOnStart()

            local sourceElement = eventData.sourceElement

            triggerClientResourceEvent(resource, arenaElement, "event1:cw:onClientEventModeCreatedInternal", sourceElement, teamsCount)

            triggerEvent("event1:cw:onEventModeCreated", sourceElement)

            outputDebugString(debuggerPrepareString("Event cw mode created.", 1))
        end
    end,

    stop = function()
        local data = cw.data

        if data then
            outputDebugString(debuggerPrepareString("Destroying event1 cw mode.", 1))

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local sourceElement = eventData.sourceElement

            triggerEvent("event1:cw:onEventModeDestroy", sourceElement)

            triggerClientResourceEvent(resource, arenaElement, "event1:cw:onClientEventModeDestroyInternal", sourceElement)

            local eventHandlers = cw.eventHandlers

            removeEventHandler("event1:cw:onPlayerWasted", arenaElement, eventHandlers.onArenaCWPlayerWasted)
            removeEventHandler("event1:cw:onPlayerHunterSpray", arenaElement, eventHandlers.onArenaCWPlayerHunterSpray)

            removeEventHandler("event1:deathmatch:onArenaStateSet", arenaElement, eventHandlers.onArenaDeathmatchStateSet)
            removeEventHandler("event1:deathmatch:onPlayerJoinSpawn", arenaElement, eventHandlers.onArenaDeathmatchPlayerJoinSpawn)
            removeEventHandler("event1:deathmatch:onPlayerReachedHunter", arenaElement, eventHandlers.onArenaDeathmatchPlayerReachedHunter)

            removeEventHandler("event1:onPlayerArenaJoin", arenaElement, eventHandlers.onArenaPlayerJoin)
            removeEventHandler("event1:onPlayerArenaQuit", arenaElement, eventHandlers.onArenaPlayerQuit)

            removeEventHandler("onPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)
            removeEventHandler("onPlayerChangeNick", arenaElement, eventHandlers.onArenaPlayerChangeNick)
            removeEventHandler("onPlayerLogin", arenaElement, eventHandlers.onArenaPlayerLogin)

            local commandHandlers = cw.commandHandlers

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
            removeCommandHandler("setpingspikelimit", commandHandlers.setPingSpikeLimit)
            removeCommandHandler("setplayerpoints", commandHandlers.setPlayerPoints)
            removeCommandHandler("addplayerdata", commandHandlers.addPlayerData)
            removeCommandHandler("getplayerdata", commandHandlers.getPlayerData)
            removeCommandHandler("cd", commandHandlers.startCountdown)
            removeCommandHandler("fixall", commandHandlers.fixAll)
            removeCommandHandler("group", commandHandlers.group)
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

            cw.updatePlayersOnStop()
            cw.saveData()
            cw.destroyEventClans()

            local boundaryTimer = data.boundaryTimer

            if isTimer(boundaryTimer) then
                killTimer(boundaryTimer)
            end

            local countdownTimer = data.countdownTimer

            if isTimer(countdownTimer) then
                killTimer(countdownTimer)
            end

            local checkAlivePlayersTimer = data.checkAlivePlayersTimer

            if isTimer(checkAlivePlayersTimer) then
                killTimer(checkAlivePlayersTimer)
            end

            local checkAlivePlayersPingsTimer = data.checkAlivePlayersPingsTimer

            if isTimer(checkAlivePlayersPingsTimer) then
                killTimer(checkAlivePlayersPingsTimer)
            end

            if isElement(coreElement) then
                destroyElement(coreElement)
            end

            data.refereeClan:destroy()
            data.spectatorsClan:destroy()

            cw.data = nil
        end
    end,

    createEventClans = function()
        local teamsCount = cw.settings.teamsCount

        local eventData = event1.data

        local arenaName = getElementData(eventData.arenaElement, "name", false)
    
        local data = cw.data
    
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
        local data = cw.data

        local coreElement = data.coreElement
    
        local eventClans = data.eventClans
    
        for i = 1, #eventClans do
            local clan = eventClans[i]

            local id = getElementData(clan.teamElement, "id", false)

            setElementData(coreElement, "eventTeam" .. tostring(id), nil--[[ , "subscribe" *]])

            clan:destroy()
        end
    
        data.eventClans = nil
    end,
    
    addEventClansDataSubscriber = function(player)
        local data = cw.data
    
        local eventClans = data.eventClans
    
        for i = 1, #eventClans do
            local clan = eventClans[i]

            clan:addAllElementDataSubscriber(player)
        end
    end,
    
    removeEventClansDataSubscriber = function(player)
        local data = cw.data
    
        local eventClans = data.eventClans
    
        for i = 1, #eventClans do
            local clan = eventClans[i]

            clan:removeAllElementDataSubscriber(player)
        end
    end,

    updatePlayersOnStart = function()
        local data = cw.data

        local refereeClan = data.refereeClan
        local spectatorsClan = data.spectatorsClan

        local refereeClanTeamElement = refereeClan.teamElement
        local spectatorsClanTeamElement = spectatorsClan.teamElement

        local eventData = event1.data

        local arenaElement = eventData.arenaElement

        local arenaPlayers = getElementChildren(arenaElement, "player")

        local permissionString = "resource." .. resourceName .. ".mode_cw_referee"

        local addEventClansDataSubscriber = cw.addEventClansDataSubscriber

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
        local dataFilePath = cw.settings.dataFilePath

        if fileExists(dataFilePath) then
            fileDelete(dataFilePath)
        end

        local fileHandler = fileCreate(dataFilePath)

        if fileHandler then
            local data = cw.data

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
        local dataFilePath = cw.settings.dataFilePath

        if fileExists(dataFilePath) then
            local fileHandler = fileOpen(dataFilePath, true)

            if fileHandler then
                local loadedDataJSON = fileRead(fileHandler, fileGetSize(fileHandler))

                local loadedData = fromJSON(loadedDataJSON) or {}

                fileClose(fileHandler)

                local data = cw.data

                local coreID = loadedData.coreID

                if coreID then
                    setElementID(data.coreElement, coreID)
                end
                
                local eventClansData = loadedData.eventClansData
                
                if eventClansData then
                    local eventClans = data.eventClans

                    local getEventClanByID = cw.getEventClanByID

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
        local resultsFilePath = cw.settings.resultsFilePath

        if fileExists(resultsFilePath) then
            fileDelete(resultsFilePath)
        end

        local fileHandler = fileCreate(resultsFilePath)

        if fileHandler then
            local data = cw.data

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
                        local playerResult = { points = points }

                        local dataStrings = {}

                        local dataNames = { "killed", "survived", "passed" }

                        for i = 1, #dataNames do
                            local dataName = dataNames[i]

                            local dataValue = data[dataName] or 0

                            dataStrings[i] = dataName .. ": " .. tostring(dataValue)

                            playerResult[dataName] = dataValue
                        end

                        local nickNameString = tostring(data.nickName)

                        playerResult.nickName = nickNameString

                        playerResult.text = tostring(points) .. " " .. stringRemoveHex(nickNameString) .. " (" .. tableConcat(dataStrings, ", ") .. ")"

                        playerResults[#playerResults + 1] = playerResult
                    end
                end
            end

            local clanResultsString = tableConcat(clanResults, ", ")

            resultsStrings[#resultsStrings + 1] = stringRemoveHex(clanResultsString) .. "\n\n"

            resultsToJSONResults.clan = clanResultsString

            tableSortOnValuesDescending(playerResults, "points")

            for i = 1, #playerResults do
                local playerResult = playerResults[i]

                resultsStrings[#resultsStrings + 1] = playerResult.text .. "\n"

                resultsToJSONPlayerResults[#resultsToJSONPlayerResults + 1] = { playerResult.nickName, playerResult.points, playerResult.killed, playerResult.survived, playerResult.passed }
            end

            local firstPlayer = playerResults[1]

            if firstPlayer then
                local firstPlayerNickName = firstPlayer.nickName
                local firstPlayerPointsString = tostring(firstPlayer.points)

                resultsStrings[#resultsStrings + 1] = "\nMVP: " .. stringRemoveHex(firstPlayerNickName) .. " with " .. firstPlayerPointsString .. " points\n"

                resultsToJSONResults.mvp = firstPlayerNickName .. " #FFFFFF(" .. firstPlayerPointsString .. ")"
            end

            local resultsJSON = toJSON(resultsToJSON, false, "tabs")

            local resultsJSONFilePath = cw.settings.resultsJSONFilePath

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
        local data = cw.data

        local resultsToJSON = data.resultsToJSON

        if resultsToJSON then
            local resultsToJSONMapData = resultsToJSON.mapData
            local resultsToJSONResults = resultsToJSON.results
            local resultsToJSONPlayerResults = resultsToJSON.playerResults

            local clanResults = resultsToJSONResults.clan

            local settings = cw.settings

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
                        <th>Alive Players</th>
                    </tr>
            ]] }

            for i = 1, #resultsToJSONMapData do
                local mapData = resultsToJSONMapData[i]

                htmlStrings[#htmlStrings + 1] = [[
                    <tr>
                        <td>]] .. mapData[1] .. [[</td>
                        <td>]] .. convertStringToHTML(mapData[2]) .. [[</td>
                        <td>]] .. convertStringToHTML(mapData[3]) .. [[</td>
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
                        <th>Killed</th>
                        <th>Survived</th>
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
                        <td>]] .. playerResults[4] .. [[</td>
                        <td>]] .. playerResults[5] .. [[</td>
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

    getAliveClans = function()
        local data = cw.data

        local aliveClans = {}
        
        local alivePlayers = deathmatchMapLoadedStateData.alivePlayers
        
        if alivePlayers then
            local eventClans = data.eventClans

            for i = 1, #eventClans do
                local clan = eventClans[i]

                for player in pairs(clan.players) do
                    if alivePlayers[player] then
                        aliveClans[#aliveClans + 1] = clan

                        break
                    end
                end
            end
        end

        return aliveClans
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
        local data = cw.data

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
        local data = cw.data

        local eventClans = data.eventClans

        for i = 1, #eventClans do
            local clan = eventClans[i]

            if clan.teamElement == teamElement then
                return clan
            end
        end
    end,

    getPlayerEventClan = function(player)
        local data = cw.data

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
        
            local eventHandlers = cw.eventHandlers
        
            addEventHandler("event1:cw:onEventStateSet", arenaElement, eventHandlers.onArenaWFFEventStateSet)
        end,

        onArenaDestroy = function()
            local eventData = event1.data

            local arenaElement = eventData.arenaElement
        
            local eventHandlers = cw.eventHandlers
        
            removeEventHandler("event1:cw:onEventStateSet", arenaElement, eventHandlers.onArenaWFFEventStateSet)

            cw.stop()
        end,

        ---

        onArenaWFFEventStateSet = function(state)
            if state then
                cw.start()
            else
                cw.stop()
            end
        end,

        ---

        checkAndSetHunterMap = function()
            local eventData = event1.data
            local data = cw.data
            
            -- Only proceed if game is live, nhmap not requested, and hunter map not already set
            if getElementData(data.coreElement, "state", false) == "live" and
               not eventData.isNoHunterMapRequested and
               not eventData.hunterMapSet then
                
                local alivePlayers = deathmatchMapLoadedStateData.alivePlayers or {}
                local numAlivePlayers = 0
                for _ in pairs(alivePlayers) do numAlivePlayers = numAlivePlayers + 1 end
                
                -- Check if any alive players are in non-hunter vehicles
                local playersInNonHunterVehicles = false
                for player, _ in pairs(alivePlayers) do
                    local vehicle = getPedOccupiedVehicle(player)
                    if vehicle and getVehicleName(vehicle) ~= "Hunter" then
                        playersInNonHunterVehicles = true
                        break
                    end
                end
                
                -- Determine hunter counts per team
                local team1HunterCount = 0
                local team2HunterCount = 0
                if #eventData.hunterPlayers > 0 then
                    local clansToConsider = cw.getAliveClans()
                    if #clansToConsider < 2 then
                        clansToConsider = cw.data.eventClans
                    end
                    
                    if #clansToConsider >= 2 then
                        for _, hunterPlayerName in ipairs(eventData.hunterPlayers) do
                            local hunterPlayer = getPlayerFromName(hunterPlayerName)
                            if hunterPlayer then
                                local hunterPlayerClan = cw.getPlayerEventClan(hunterPlayer)
                                if hunterPlayerClan == clansToConsider[1] then
                                    team1HunterCount = team1HunterCount + 1
                                elseif hunterPlayerClan == clansToConsider[2] then
                                    team2HunterCount = team2HunterCount + 1
                                end
                            end
                        end
                    end
                end
                
                -- Scenario 1: Player reaches hunter
                -- Check if all alive players have reached hunter AND no one is driving non-hunter vehicles
                local allAliveReachedHunter = true
                if numAlivePlayers > 0 then
                    for player, _ in pairs(alivePlayers) do
                        local playerName = getPlayerName(player)
                        local hasReachedHunter = false
                        for _, hunterPlayerName in ipairs(eventData.hunterPlayers) do
                            if hunterPlayerName == playerName then
                                hasReachedHunter = true
                                break
                            end
                        end
                        if not hasReachedHunter then
                            allAliveReachedHunter = false
                            break
                        end
                    end
                else
                    -- If no alive players, then technically all (0) alive players have reached hunter
                    allAliveReachedHunter = true
                end
                
                if allAliveReachedHunter and not playersInNonHunterVehicles then
                    -- Display info and indicate map setting (without setNextMap)
                    eventData.hunterMapSet = true -- Mark as set to prevent re-triggering
                    local hunterPlayersList = table.concat(eventData.hunterPlayers, ", ")
                    outputChatBox("#CCCCCCPlayers who reached hunter: #FFFFFF" .. hunterPlayersList, eventData.arenaElement, 255, 255, 255, true)
                    outputChatBox("#CCCCCCHunter map selection triggered (not yet set)", eventData.arenaElement, 255, 255, 255, true)
                    -- No setNextMap here yet, as per user request
                    return -- Exit after this scenario
                end
                
                -- Scenario 2: Last person driving dies
                -- This should trigger if no players are in non-hunter vehicles AND both teams have reached hunter
                if not playersInNonHunterVehicles and team1HunterCount > 0 and team2HunterCount > 0 then
                    -- Determine which map to set based on hunter players per team
                    local selectedMap = ""
                    if team1HunterCount <= 2 and team2HunterCount <= 2 then
                        selectedMap = "[HUNTER] RoNNiE# - NO to Astronomy"
                    else
                        selectedMap = "[HUNTER] Elite Fight"
                    end
                    
                    -- Set the map
                    eventData.hunterMapSet = true
                    
                    -- Display hunter players
                    local hunterPlayersList = table.concat(eventData.hunterPlayers, ", ")
                    outputChatBox("#CCCCCCPlayers who reached hunter: #FFFFFF" .. hunterPlayersList, eventData.arenaElement, 255, 255, 255, true)
                    outputChatBox("#CCCCCCHunter map will be set to: #FFFFFF" .. selectedMap, eventData.arenaElement, 255, 255, 255, true)
                    -- setNextMap(selectedMap) -- Keep commented for now as per user request
                end
            end
        end,

        onArenaCWPlayerWasted = function(killer, killerPing)
            if source == client then
                local data = cw.data

                if getElementData(data.coreElement, "state", false) == "live" then
                    if killer then
                        local clientClan = cw.getPlayerEventClan(client)

                        local killerClan = cw.getPlayerEventClan(killer)

                        if clientClan and killerClan then
                            local eventData = event1.data

                            local arenaElement = eventData.arenaElement

                            if clientClan == killerClan then
                                outputChatBox(getPlayerName(client) .. " #CCCCCChas been killed by #FFFFFF" .. getPlayerName(killer) .. " #CCCCCC(ping: #FFFFFF" .. tostring(killerPing) .. "#CCCCCC) #FF0000(teamkill)", arenaElement, 255, 255, 255, true)
                            else
                                local oldPoints = getElementData(killer, "points", false) or 0

                                killerClan:setPlayerData(killer, "points", oldPoints + 1)
        
                                local oldKilled = getElementData(killer, "killed", false) or 0
        
                                killerClan:setPlayerData(killer, "killed", oldKilled + 1)

                                local oldMapPoints = getElementData(killer, "mapPoints", false) or 0

                                killerClan:setPlayerData(killer, "mapPoints", oldMapPoints + 1)

                                outputChatBox(getPlayerName(client) .. " #CCCCCChas been killed by #FFFFFF" .. getPlayerName(killer) .. " #CCCCCC(ping: #FFFFFF" .. tostring(killerPing) .. "#CCCCCC)", arenaElement, 255, 255, 255, true)
                            end
                        end
                    end

                    if not data.roundEnded then
                        local aliveClans = cw.getAliveClans()
    
                        if #aliveClans == 1 then
                            local clan = aliveClans[1]
    
                            local teamElement = clan.teamElement
    
                            local oldClanPoints = getElementData(teamElement, "points", false) or 0
    
                            setElementData(teamElement, "points", oldClanPoints + 1)
    
                            local eventData = event1.data

                            local arenaElement = eventData.arenaElement

                            local r, g, b = getTeamColor(teamElement)
    
                            local hexColor = "#" .. rgbToHex(r, g, b)
    
                            local teamName = getTeamName(teamElement)
    
                            outputChatBox(hexColor .. teamName .. " #CCCCCChas won this round. Alive players:", arenaElement, 255, 255, 255, true)
                            
                            local clanAlivePlayers = cw.getAlivePlayersInClan(clan)
                            
                            local playersStrings = {}
    
                            for i = 1, #clanAlivePlayers do
                                local alivePlayer = clanAlivePlayers[i]
    
                                local oldPoints = getElementData(alivePlayer, "points", false) or 0
    
                                clan:setPlayerData(alivePlayer, "points", oldPoints + 1)
    
                                local oldSurvived = getElementData(alivePlayer, "survived", false) or 0
    
                                clan:setPlayerData(alivePlayer, "survived", oldSurvived + 1)
    
                                local playerName = getPlayerName(alivePlayer)
    
                                playersStrings[#playersStrings + 1] = playerName
    
                                local mapPoints = getElementData(alivePlayer, "mapPoints", false) or 0
    
                                local pointsEarnedString = tostring(mapPoints + 1)
    
                                local pointsTotal = tostring(oldPoints + 1)
    
                                outputChatBox(playerName .. " #CCCCCCpoints earned: #FFFFFF" .. pointsEarnedString .. " #CCCCCCtotal: #FFFFFF" .. pointsTotal, arenaElement, 255, 255, 255, true)
                            end
    
                            local mapData = data.mapData
    
                            local thisMapID = #mapData + 1
    
                            local mapString = tostring(thisMapID) .. ". " .. (data.mapName or "")
    
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
    
                            local playersString = tableConcat(playersStrings, " #FFFFFF")
    
                            local thisMapData = { mapString, clansString, playersString }
                            
                            mapData[thisMapID] = thisMapData
    
                            local clanOutputString = tableConcat(clansOutputStrings, ", ")
    
                            outputChatBox("#CCCCCCCurrent result: " .. clanOutputString, arenaElement, 255, 255, 255, true)
    
                            data.roundEnded = true
                        end
                    end
                                        
                    -- Check if we should set hunter map after this death
                    --cw.eventHandlers.checkAndSetHunterMap()
                end
            end
        end,

        onArenaCWPlayerHunterSpray = function(hunterShotsCount)
            if source == client then
                local data = cw.data

                if getElementData(data.coreElement, "state", false) == "live" then
                    local alivePlayers = deathmatchMapLoadedStateData.alivePlayers

                    if alivePlayers and alivePlayers[client] then
                        hunterShotsCount = tonumber(hunterShotsCount)

                        if hunterShotsCount then
                            local eventData = event1.data

                            local arenaElement = eventData.arenaElement

                            local sprayWarnCount = getElementData(client, "sprayWarnCount", false) or 0

                            local newSprayWarnCount = sprayWarnCount + 1
                            
                            outputChatBox(getPlayerName(client) .. " #CCCCCChas just sprayed #FF0000(" .. tostring(hunterShotsCount) .. " shots, warnings: " .. tostring(newSprayWarnCount) .. ")", arenaElement, 255, 255, 255, true)

                            local clan = cw.getPlayerEventClan(client)
        
                            if clan then
                                clan:setPlayerData(client, "sprayWarnCount", newSprayWarnCount)
                                
                                if newSprayWarnCount >= 2 then
                                    blowVehicle(getPedOccupiedVehicle(client) or client)
                                    
                                    outputChatBox("#FF0000" .. getPlayerName(client) .. " #CCCCCChas been eliminated for excessive spraying! (#FF0000" .. tostring(newSprayWarnCount) .. " warnings#CCCCCC)", arenaElement, 255, 255, 255, true)
                                end
                            end
                        end
                    end
                end
            end
        end,

        onArenaDeathmatchStateSet = function(state)
            local arenaDeathmatchStateFunction = cw.arenaDeathmatchStateFunctions[state]

            if arenaDeathmatchStateFunction then
                arenaDeathmatchStateFunction()
            end
        end,

        onArenaDeathmatchPlayerJoinSpawn = function()
            deathmatchMapLoadedStateData:removePlayerFromLoadQueue(source)
        end,

        onArenaDeathmatchPlayerReachedHunter = function(timePassed)
            local eventData = event1.data

            outputChatBox(getPlayerName(source) .. " #CCCCCChas reached the hunter", eventData.arenaElement, 255, 255, 255, true)

            local data = cw.data

            if getElementData(data.coreElement, "state", false) == "live" then
                local eventClan = cw.getPlayerEventClan(source)

                if eventClan then
                    local oldPoints = getElementData(source, "points", false) or 0

                    eventClan:setPlayerData(source, "points", oldPoints + 1)

                    local oldPassed = getElementData(source, "passed", false) or 0

                    eventClan:setPlayerData(source, "passed", oldPassed + 1)

                    local oldMapPoints = getElementData(source, "mapPoints", false) or 0

                    eventClan:setPlayerData(source, "mapPoints", oldMapPoints + 1)
                end

                -- Add player to hunter players list
                table.insert(eventData.hunterPlayers, getPlayerName(source))

                -- Check if nhmap was requested (original logic)
                if eventData.isNoHunterMapRequested and not eventData.countdownStarted then
                    local arenaElement = eventData.arenaElement
                    
                    -- mark countdown as started to prevent multiple triggers
                    eventData.countdownStarted = true
                    
                    -- start countdown 3 seconds after hunter is reached
                    setTimer(function()
                        triggerClientResourceEvent(resource, eventData.arenaElement, "event1:cw:onClientArenaCountdownStarted", eventData.sourceElement, 3)
                        
                        -- set the countdown timer (4 seconds total, 1 second intervals)
                        local data = cw.data
                        data.countdownTimer = setTimer(cw.timers.countdown, 1000, 4)
                        
                        outputChatBox("#CCCCCCCountdown has been started by the system", arenaElement, 255, 255, 255, true)
                    end, 3000, 1)
                end
            end
        end,

        onArenaPlayerJoin = function()
            cw.addEventClansDataSubscriber(source)

            triggerClientResourceEvent(resource, source, "event1:cw:onClientEventModeStart", source, cw.settings.teamsCount)

            local data = cw.data
    
            if hasObjectPermissionTo(source, "resource." .. resourceName .. ".mode_cw_referee", false) then
                silentExport("ep_core", "setPlayerTeam", source, data.refereeClan.teamElement)
            else
                silentExport("ep_core", "setPlayerTeam", source, data.spectatorsClan.teamElement)
            end
        end,

        onArenaPlayerQuit = function()
            silentExport("ep_core", "setPlayerTeam", source, nil)
            
            triggerClientResourceEvent(resource, source, "event1:cw:onClientEventModeStop", source)
            
            cw.removeEventClansDataSubscriber(source)

            cw.data.playerPings[source] = nil
        end,

        onArenaPlayerTeamChange = function(oldTeam, newTeam)
            local data = cw.data
            
            local refereeClan = data.refereeClan
            local spectatorsClan = data.spectatorsClan

            refereeClan:removePlayer(source)
            spectatorsClan:removePlayer(source)

            local eventClans = data.eventClans

            for i = 1, #eventClans do
                local clan = eventClans[i]

                clan:setPlayerData(source, "mapPoints", nil)
                clan:setPlayerData(source, "sprayWarnCount", nil)

                clan:removePlayer(source)
            end

            if newTeam then
                local eventClan = cw.getEventClanByTeamElement(newTeam)

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
            local eventClan = cw.getPlayerEventClan(source)

            if eventClan then
                eventClan:setPlayerData(source, "nickName", newNick)
            end
        end,

        onArenaPlayerLogin = function()
            if hasObjectPermissionTo(source, "resource." .. resourceName .. ".mode_cw_referee", false) then
                silentExport("ep_core", "setPlayerTeam", source, cw.data.refereeClan.teamElement)
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
                    local eventClan = cw.getEventClanByTag(tag)

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
                local spectatorsClan = cw.data.spectatorsClan

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local arg = { ... }

                    if #arg > 0 then
                        local eventName = tableConcat(arg, " ")

                        setElementID(cw.data.coreElement, eventName)

                        outputChatBox("#CCCCCCEvent name has been set to #FFFFFF" .. eventName .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [name]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setTeamName = function(player, commandName, tag, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = cw.getEventClanByTag(tag)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = cw.getEventClanByTag(tag)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = cw.getEventClanByTag(tag)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = cw.getEventClanByTag(tag)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if state then
                        local stateData = cw.states[state]

                        if stateData then
                            setElementData(cw.data.coreElement, "state", state)
                            
                            -- Set map start time when state changes to "live"
                            if state == "live" then
                                eventData.mapStartTime = getTickCount()
                            end

                            local stateFunction = cw.stateFunctions[state]

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if round then
                        round = tonumber(round)

                        if round then
                            setElementData(cw.data.coreElement, "round", round)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if totalRounds then
                        totalRounds = tonumber(totalRounds)

                        if totalRounds then
                            setElementData(cw.data.coreElement, "totalRounds", totalRounds)

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

        setPingSpikeLimit = function(player, commandName, pingSpikeLimit)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    pingSpikeLimit = tonumber(pingSpikeLimit)

                    if pingSpikeLimit then
                        cw.data.pingSpikeLimit = pingSpikeLimit

                        outputChatBox("#CCCCCCPing spike limit has been set to #FFFFFF" .. tostring(pingSpikeLimit) .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [ping spike limit]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setPlayerPoints = function(player, commandName, playerPartialName, points)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
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
                                local eventClan = cw.getPlayerEventClan(targetPlayer)
    
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

        addPlayerData = function(player, commandName, playerPartialName, dataName, dataValue)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if playerPartialName then
                        local arenaPlayers = getElementChildren(arenaElement, "player")

                        local targetPlayer = getPlayerFromPartialName(arenaPlayers, playerPartialName)

                        if targetPlayer then
                            if dataName then
                                if dataValue then
                                    local eventClan = cw.getPlayerEventClan(targetPlayer)
    
                                    if eventClan then
                                        local oldDataValue = tonumber(getElementData(targetPlayer, dataName, false) or 0)

                                        if oldDataValue then
                                            local newDataValue = oldDataValue + dataValue

                                            eventClan:setPlayerData(targetPlayer, dataName, newDataValue)
        
                                            outputChatBox(getPlayerName(targetPlayer) .. " #FFFFFF" .. dataName .. " #CCCCCCvalue has been set to #FFFFFF" .. tostring(newDataValue) .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                                        end
                                    else
                                        outputChatBox("#CCCCCCPlayer #FFFFFF" .. getPlayerName(player) .. " #CCCCCCis not in a team", player, 255, 255, 255, true)
                                    end
                                else
                                    outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [player partial name] [data name] [data value]", player, 255, 255, 255, true)
                                end
                            else
                                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [player partial name] [data name] [data value]", player, 255, 255, 255, true)
                            end
                        else
                            outputChatBox("#CCCCCCPlayer not found", player, 255, 255, 255, true)
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [player partial name] [data name] [data value]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        getPlayerData = function(player, commandName, playerPartialName, dataName)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if playerPartialName then
                        local arenaPlayers = getElementChildren(arenaElement, "player")

                        local targetPlayer = getPlayerFromPartialName(arenaPlayers, playerPartialName)

                        if targetPlayer then
                            if dataName then
                                local eventClan = cw.getPlayerEventClan(targetPlayer)

                                if eventClan then
                                    local dataValue = getElementData(targetPlayer, dataName, false)

                                    outputChatBox(getPlayerName(targetPlayer) .. " #FFFFFF" .. dataName .. " #CCCCCCvalue: #FFFFFF" .. tostring(dataValue), player, 255, 255, 255, true)
                                else
                                    outputChatBox("#CCCCCCPlayer #FFFFFF" .. getPlayerName(player) .. " #CCCCCCis not in a team", player, 255, 255, 255, true)
                                end
                            else
                                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [player partial name] [data name]", player, 255, 255, 255, true)
                            end
                        else
                            outputChatBox("#CCCCCCPlayer not found", player, 255, 255, 255, true)
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [player partial name] [data name]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        startCountdown = function(player, commandName)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    triggerClientResourceEvent(resource, eventData.arenaElement, "event1:cw:onClientArenaCountdownStarted", eventData.sourceElement, 3)

                    local data = cw.data

                    data.countdownTimer = setTimer(cw.timers.countdown, 1000, 4)

                    outputChatBox("#CCCCCCCountdown has been started by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                end
            end
        end,

        requestNoHunterMap = function(player, commandName)
            if not commandName then
                commandName = "nhmap"
            end
            
            local eventData = event1.data
            local arenaElement = eventData.arenaElement
            local playerArenaElement = event1.getPlayerArenaElement(player)
            
            if playerArenaElement == arenaElement then
                local playerClan = cw.getPlayerEventClan(player)
                local isInPlayingTeam = false
                
                if playerClan then
                    local aliveClans = cw.getAliveClans()
                    for _, clan in ipairs(aliveClans) do
                        if clan == playerClan then
                            isInPlayingTeam = true
                            break
                        end
                    end
                end
                
                if not isInPlayingTeam then
                    return
                end
                
                local currentTime = getTickCount()
                local mapStartTime = eventData.mapStartTime
                
                -- If mapStartTime is not set, allow the command (map just started)
                if not mapStartTime then
                    eventData.isNoHunterMapRequested = true
                    outputChatBox("#CCCCCCNo Hunter map has been requested by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    return
                end
                
                local timeElapsed = (currentTime - mapStartTime) / 1000
                
                if timeElapsed <= 30 then
                    eventData.isNoHunterMapRequested = true
                    outputChatBox("#CCCCCCNo Hunter map has been requested by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                else
                    outputChatBox("#CCCCCCTime limit exceeded (30 seconds), you cannot request a hunter map.", player, 255, 255, 255, true)
                end
            end
        end,

        fixAll = function(player, commandName)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local alivePlayers = deathmatchMapLoadedStateData.alivePlayers

                    if alivePlayers and next(alivePlayers) then
                        local deathmatchData = deathmatch.data

                        local getPlayerVehicle = deathmatch.getPlayerVehicle

                        for player in pairs(alivePlayers) do
                            local vehicle = getPlayerVehicle(player)
                            
                            if isElement(vehicle) and getElementModel(vehicle) == 425 then
                                fixVehicle(vehicle)
                            end
                        end

                        outputChatBox("#CCCCCCPlayers have been fixed by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    end
                end
            end
        end,

        group = function(player, commandName)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local alivePlayers = deathmatchMapLoadedStateData.alivePlayers
        
                    if alivePlayers then
                        local getPlayerVehicle = deathmatch.getPlayerVehicle

                        local data = cw.data

                        local eventClans = data.eventClans

                        local position1, position2 = 0, 0

                        for i = 1, 2 do
                            local clan = eventClans[i]
                            
                            for player in pairs(clan.players) do
                                if alivePlayers[player] then
                                    local vehicle = getPlayerVehicle(player)

                                    if getElementModel(vehicle) == 425 then
                                        if i == 1 then
                                            setElementPosition(vehicle, 6010 + position1 * 50, -887, 100, true)
                                            setElementRotation(vehicle, 0, 0, 0)

                                            position1 = position1 + 1
                                        elseif i == 2 then
                                            setElementPosition(vehicle, 6010 + position2 * 50, -287, 100, true)
                                            setElementRotation(vehicle, 180, 180, 0)

                                            position2 = position2 + 1
                                        end
                                    end
                                end
                            end
                        end

                        outputChatBox("#CCCCCCPlayers have been grouped by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    end
                end
            end
        end,

        randomKill = function(player, commandName, tag)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = cw.getEventClanByTag(tag)

                        if eventClan then
                            local alivePlayers = cw.getAlivePlayersInClan(eventClan)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local forumID = tonumber(forumName)--cw.settings.forumNameIDs[forumName]

                    if forumID then
                        local isTopicHidden = true

                        if hiddenArg == "hidden" then
                            isTopicHidden = true
                        elseif hiddenArg == "visible" then
                            isTopicHidden = false
                        end

                        local arg = { ... }

                        cw.outputResultsOnForum(forumID, isTopicHidden, tableConcat({unpack(arg, 1, separatorOffset)}, " "), tableConcat({unpack(arg, separatorOffset + 1)}, " "),
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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_cw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    cw.stop()

                    local dataFilePath = cw.settings.dataFilePath

                    if fileExists(dataFilePath) then
                        fileDelete(dataFilePath)
                    end

                    -- bug fix
                    setTimer(
                        function()
                            cw.start()

                            outputChatBox("#CCCCCCEvent mode has been reset by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                        end,
                    100, 1)
                end
            end
        end
    },

    timers = {
        checkBoundary = function()
            local alivePlayers = deathmatchMapLoadedStateData.alivePlayers

            if alivePlayers and next(alivePlayers) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local deathmatchData = deathmatch.data

                local getPlayerVehicle = deathmatch.getPlayerVehicle

                for player in pairs(alivePlayers) do
                    local vehicle = getPlayerVehicle(player)

                    if isElement(vehicle) and getElementModel(vehicle) == 425 then
                        local x, y, z = getElementPosition(vehicle)

                        if x >= 8191 or x <= -8191 or y >= 8191 or y <= -8191 or z >= 8191 or z <= -8191 then
                            outputChatBox(getPlayerName(player) .. " #CCCCCCis out of the map", arenaElement, 255, 255, 255, true)
                        end
                    end
                end
            end
        end,

        countdown = function()
            local remaining, executesRemaining, timeInterval = getTimerDetails(sourceTimer)

            local countdownValue = executesRemaining - 1

            local eventData = event1.data

            triggerClientResourceEvent(resource, eventData.arenaElement, "event1:cw:onClientArenaCountdownValueUpdate", eventData.sourceElement, countdownValue)
        end,

        checkAlivePlayers = function()
            local data = cw.data

            local coreElement = data.coreElement
    
            if getElementData(coreElement, "state", false) == "live" then
                local arenaElement = event1.data.arenaElement

                local eventClans = data.eventClans

                local getAlivePlayersInClan = cw.getAlivePlayersInClan

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
        end,

        checkAlivePlayersPings = function()
            local data = cw.data

            local coreElement = data.coreElement
    
            if getElementData(coreElement, "state", false) == "live" then
                local arenaElement = event1.data.arenaElement

                local eventClans = data.eventClans

                local pingSpikeLimit = data.pingSpikeLimit

                local playerPings = data.playerPings

                local getAlivePlayersInClan = cw.getAlivePlayersInClan

                local getPlayerVehicle = deathmatch.getPlayerVehicle

                for i = 1, #eventClans do
                    local clan = eventClans[i]

                    local clanAlivePlayers = getAlivePlayersInClan(clan)

                    for j = 1, #clanAlivePlayers do
                        local player = clanAlivePlayers[j]

                        local vehicle = getPlayerVehicle(player)

                        if isElement(vehicle) and getElementModel(vehicle) == 425 then
                            local playerOldPing = playerPings[player]

                            local playerPing = getPlayerPing(player)

                            if playerOldPing then
                                local pingDiff = playerPing - playerOldPing

                                if pingDiff >= pingSpikeLimit then
                                    outputChatBox(getPlayerName(player) .. " #CCCCCCping has spiked #FF0000(+" .. tostring(pingDiff) .. " ms)", arenaElement, 255, 255, 255, true)
                                end
                            end

                            playerPings[player] = playerPing
                        end
                    end
                end
            end
        end
    },

    arenaDeathmatchStateFunctions = {
        ["map loaded"] = function()
            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local arenaPlayers = getElementChildren(arenaElement, "player")

            local getPlayerEventClan = cw.getPlayerEventClan

            local deathmatchData = deathmatch.data

            local getPlayerVehicle = deathmatch.getPlayerVehicle

            local mapInfo = getElementData(arenaElement, "mapInfo", false)

            local mapInfoDirectory = mapInfo.directory

            local teamSpawnpointIDs = {}

            for i = 1, #arenaPlayers do
                local arenaPlayer = arenaPlayers[i]

                local eventClan = getPlayerEventClan(arenaPlayer)

                if not eventClan then
                    deathmatchMapLoadedStateData:removePlayerFromLoadQueue(arenaPlayer)
                else
                    local vehicle = getPlayerVehicle(arenaPlayer)
                    
                    if isElement(vehicle) then
                        local teamElement = eventClan.teamElement

                        if mapInfoDirectory == "hunter" then
                            local teamSpawnpointID = teamSpawnpointIDs[teamElement]

                            if not teamSpawnpointID then
                                teamSpawnpointIDs[teamElement] = getElementData(vehicle, "spawnpointID", false)
                            else
                                deathmatchMapLoadedStateData:setPlayerSpawnpointID(arenaPlayer, teamSpawnpointID)
                            end
                        else
                            deathmatchMapLoadedStateData:setPlayerSpawnpointID(arenaPlayer, 1)

                            eventClan:setPlayerData(arenaPlayer, "sprayWarnCount", nil)
                        end

                        local r, g, b = getTeamColor(teamElement)

                        setVehicleColor(vehicle, r, g, b)
                    end

                    eventClan:setPlayerData(arenaPlayer, "mapPoints", nil)
                end
            end

            eventData.isNoHunterMapRequested = false
            eventData.countdownStarted = false
            eventData.hunterPlayers = {}
            eventData.hunterMapSet = false
            
            local data = cw.data
            
            if mapInfoDirectory ~= "hunter" then
                data.mapName = mapInfo.name

                local coreElement = data.coreElement
    
                if getElementData(coreElement, "state", false) == "live" then
                    local oldRound = getElementData(coreElement, "round", false) or 0
    
                    setElementData(coreElement, "round", oldRound + 1)
                end
            end

            data.roundEnded = nil

            deathmatchMapLoadedStateData:killForcedCountdownTimer()
        end,

        ["running"] = function()
            local data = cw.data

            local timers = cw.timers

            --data.checkAlivePlayersTimer = setTimer(timers.checkAlivePlayers, 4000, 0)
            data.checkAlivePlayersPingsTimer = setTimer(timers.checkAlivePlayersPings, 1000, 0)
        end,

        ["ended"] = function()
            deathmatchEndedStateData:killNextMapTimer()
        end,

        ["map unloading"] = function()
            local data = cw.data

            if isTimer(data.checkAlivePlayersTimer) then
                killTimer(data.checkAlivePlayersTimer)
            end

            if isTimer(data.checkAlivePlayersPingsTimer) then
                killTimer(data.checkAlivePlayersPingsTimer)
            end

            data.checkAlivePlayersTimer = nil
            data.checkAlivePlayersPingsTimer = nil
        end
    },

    stateFunctions = {
        ["ended"] = function()
            local resultsString, resultsJSONString = cw.saveResults()

            if resultsString then
                local eventData = event1.data

                local refereePlayers = {}

                local arenaPlayers = getElementChildren(eventData.arenaElement, "player")

                local permissionString = "resource." .. resourceName .. ".mode_cw_referee"

                for i = 1, #arenaPlayers do
                    local arenaPlayer = arenaPlayers[i]

                    if hasObjectPermissionTo(arenaPlayer, permissionString, false) then
                        refereePlayers[#refereePlayers + 1] = arenaPlayer
                    end
                end

                if #refereePlayers > 0 then
                    triggerClientResourceEvent(resource, refereePlayers, "event1:cw:onClientArenaResultsSaved", eventData.sourceElement, resultsString, resultsJSONString)
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

event1.modes.cw = cw

addEvent("event1:onArenaCreated")
addEvent("event1:onArenaDestroy")

addEvent("event1:onPlayerArenaJoin")
addEvent("event1:onPlayerArenaQuit")

addEvent("onPlayerTeamChange")

addEvent("event1:deathmatch:onArenaStateSet")
addEvent("event1:deathmatch:onPlayerJoinSpawn")
addEvent("event1:deathmatch:onPlayerReachedHunter")
addEvent("event1:deathmatch:onPlayerWasted")

addEvent("event1:cw:onEventStateSet")

addEvent("event1:cw:onPlayerWasted", true)
addEvent("event1:cw:onPlayerHunterSpray", true)

do
    local eventHandlers = cw.eventHandlers

    addEventHandler("event1:onArenaCreated", resourceRoot, eventHandlers.onArenaCreated)
    addEventHandler("event1:onArenaDestroy", resourceRoot, eventHandlers.onArenaDestroy)
end