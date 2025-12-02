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

local teamwff2

teamwff2 = {
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

        dataFilePath = "server/arena/modes/teamwff2_data.json",
        resultsFilePath = "server/arena/modes/teamwff2_results.txt",
        resultsJSONFilePath = "server/arena/modes/teamwff2_results.json",

        autoPointsOrder = { 10, 8, 6, 4, 3, 2, 1, 1 },
        defaultPointsOrder = { 4, 3, 2, 1 },
        pointsOrder = { 4, 3, 2, 1 },

        playerHunterTimesDelay = 3000,

        teamsCount = 4,
        teamMapPicks = 3,
        teamMapBans = 2,
        setPoints = 13,
    },

    start = function()
        if not teamwff2.data then
            local data = {}

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local arenaName = getElementData(arenaElement, "name", false)

            local refereeClan = clanNew(arenaName .. " Referee", 255, 0, 0)
            local spectatorsClan = clanNew(arenaName .. " Spectators", 255, 255, 255)

            local coreElement = createElement("core", "Event Name")

            local teamsCount = teamwff2.settings.teamsCount

            setElementParent(coreElement, arenaElement)

            setElementData(arenaElement, "coreElement", coreElement)

            setElementData(coreElement, "refereeClanTeamElement", refereeClan.teamElement)
            setElementData(coreElement, "spectatorsClanTeamElement", spectatorsClan.teamElement)

            setElementData(coreElement, "teamsCount", teamsCount)
            setElementData(coreElement, "state", "free")
            setElementData(coreElement, "round", 1)
            setElementData(coreElement, "totalRounds", 20)

            local eventHandlers = teamwff2.eventHandlers

            addEventHandler("event1:deathmatch:onArenaStateSet", arenaElement, eventHandlers.onArenaDeathmatchStateSet)
            addEventHandler("event1:deathmatch:onPlayerJoinSpawn", arenaElement, eventHandlers.onArenaDeathmatchPlayerJoinSpawn)
            addEventHandler("event1:deathmatch:onPlayerReachedHunter", arenaElement, eventHandlers.onArenaDeathmatchPlayerReachedHunter)

            addEventHandler("event1:onPlayerArenaJoin", arenaElement, eventHandlers.onArenaPlayerJoin)
            addEventHandler("event1:onPlayerArenaQuit", arenaElement, eventHandlers.onArenaPlayerQuit)

            addEventHandler("onPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)
            addEventHandler("onPlayerChangeNick", arenaElement, eventHandlers.onArenaPlayerChangeNick)
            addEventHandler("onPlayerLogin", arenaElement, eventHandlers.onArenaPlayerLogin)

            local commandHandlers = teamwff2.commandHandlers

            --mode_teamwff2_cmd_
            addCommandHandler("join", commandHandlers.join)
            addCommandHandler("spec", commandHandlers.spec)
            addCommandHandler("seteventname", commandHandlers.setEventName)
            addCommandHandler("setteamname", commandHandlers.setTeamName)
            addCommandHandler("setteamcolor", commandHandlers.setTeamColor)
            addCommandHandler("setteamtag", commandHandlers.setTeamTag)
            addCommandHandler("setteampoints", commandHandlers.setTeamPoints)
            addCommandHandler("setteamsets", commandHandlers.setTeamSets)
            addCommandHandler("setstate", commandHandlers.setState)
            addCommandHandler("setround", commandHandlers.setRound)
            addCommandHandler("settotalrounds", commandHandlers.setTotalRounds)
            addCommandHandler("setplayerpoints", commandHandlers.setPlayerPoints)
            addCommandHandler("setteamscount", commandHandlers.setTeamsCount)
            addCommandHandler("setmapid", commandHandlers.setMapID)
            addCommandHandler("showmaps", commandHandlers.showMaps)
            addCommandHandler("showpicks", commandHandlers.showPicks)
            addCommandHandler("reshufflepicks", commandHandlers.reshufflePicks)
            addCommandHandler("pickmap", commandHandlers.pickMap)
            addCommandHandler("banmap", commandHandlers.banMap)
            addCommandHandler("toggleautopoints", commandHandlers.toggleAutoPoints)
            addCommandHandler("addpoints", commandHandlers.addPoints)
            addCommandHandler("randomkill", commandHandlers.randomKill)
            addCommandHandler("outputresultsforum", commandHandlers.outputResultsForum)
            addCommandHandler("resetallteampoints", commandHandlers.resetAllTeamPoints)
            addCommandHandler("resetmode", commandHandlers.resetMode)

            data.coreElement = coreElement

            data.refereeClan = refereeClan
            data.spectatorsClan = spectatorsClan

            data.playerHunterTimes = {}
            data.playerHunterLastPosition = 0

            data.mapData = {}

            data.autoPointsState = false
            data.autoPointsPlayers = {}

            data.maplist = {}
            data.picks = {}
            data.bans = {}

            data.setMapIDPlayerSearch = {}

            teamwff2.data = data

            teamwff2.createEventClans()
            teamwff2.loadData()
            teamwff2.updatePlayersOnStart()

            local sourceElement = eventData.sourceElement

            triggerClientResourceEvent(resource, arenaElement, "event1:teamwff2:onClientEventModeCreatedInternal", sourceElement, teamsCount)

            triggerEvent("event1:teamwff2:onEventModeCreated", sourceElement)

            outputDebugString(debuggerPrepareString("Event team wff mode created.", 1))
        end
    end,

    stop = function()
        local data = teamwff2.data

        if data then
            outputDebugString(debuggerPrepareString("Destroying event1 team wff mode.", 1))

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local sourceElement = eventData.sourceElement

            triggerEvent("event1:teamwff2:onEventModeDestroy", sourceElement)

            triggerClientResourceEvent(resource, arenaElement, "event1:teamwff2:onClientEventModeDestroyInternal", sourceElement)

            local eventHandlers = teamwff2.eventHandlers

            removeEventHandler("event1:deathmatch:onArenaStateSet", arenaElement, eventHandlers.onArenaDeathmatchStateSet)
            removeEventHandler("event1:deathmatch:onPlayerJoinSpawn", arenaElement, eventHandlers.onArenaDeathmatchPlayerJoinSpawn)
            removeEventHandler("event1:deathmatch:onPlayerReachedHunter", arenaElement, eventHandlers.onArenaDeathmatchPlayerReachedHunter)

            removeEventHandler("event1:onPlayerArenaJoin", arenaElement, eventHandlers.onArenaPlayerJoin)
            removeEventHandler("event1:onPlayerArenaQuit", arenaElement, eventHandlers.onArenaPlayerQuit)

            removeEventHandler("onPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)
            removeEventHandler("onPlayerChangeNick", arenaElement, eventHandlers.onArenaPlayerChangeNick)
            removeEventHandler("onPlayerLogin", arenaElement, eventHandlers.onArenaPlayerLogin)

            local commandHandlers = teamwff2.commandHandlers

            removeCommandHandler("join", commandHandlers.join)
            removeCommandHandler("spec", commandHandlers.spec)
            removeCommandHandler("seteventname", commandHandlers.setEventName)
            removeCommandHandler("setteamname", commandHandlers.setTeamName)
            removeCommandHandler("setteamcolor", commandHandlers.setTeamColor)
            removeCommandHandler("setteamtag", commandHandlers.setTeamTag)
            removeCommandHandler("setteampoints", commandHandlers.setTeamPoints)
            removeCommandHandler("setteamsets", commandHandlers.setTeamSets)
            removeCommandHandler("setstate", commandHandlers.setState)
            removeCommandHandler("setround", commandHandlers.setRound)
            removeCommandHandler("settotalrounds", commandHandlers.setTotalRounds)
            removeCommandHandler("setplayerpoints", commandHandlers.setPlayerPoints)
            removeCommandHandler("setteamscount", commandHandlers.setTeamsCount)
            removeCommandHandler("setmapid", commandHandlers.setMapID)
            removeCommandHandler("showmaps", commandHandlers.showMaps)
            removeCommandHandler("showpicks", commandHandlers.showPicks)
            removeCommandHandler("reshufflepicks", commandHandlers.reshufflePicks)
            removeCommandHandler("pickmap", commandHandlers.pickMap)
            removeCommandHandler("banmap", commandHandlers.banMap)
            removeCommandHandler("toggleautopoints", commandHandlers.toggleAutoPoints)
            removeCommandHandler("addpoints", commandHandlers.addPoints)
            removeCommandHandler("randomkill", commandHandlers.randomKill)
            removeCommandHandler("outputresultsforum", commandHandlers.outputResultsForum)
            removeCommandHandler("resetallteampoints", commandHandlers.resetAllTeamPoints)
            removeCommandHandler("resetmode", commandHandlers.resetMode)

            setElementData(arenaElement, "coreElement", nil)

            local coreElement = data.coreElement

            setElementData(coreElement, "refereeClanTeamElement", nil)
            setElementData(coreElement, "spectatorsClanTeamElement", nil)

            setElementData(coreElement, "state", nil)
            setElementData(coreElement, "round", nil)
            setElementData(coreElement, "totalRounds", nil)

            teamwff2.updatePlayersOnStop()
            teamwff2.saveData()
            teamwff2.destroyEventClans()

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

            teamwff2.settings.pointsOrder = teamwff2.settings.defaultPointsOrder
            
            teamwff2.data = nil
        end
    end,

    createEventClans = function()
        local teamsCount = teamwff2.settings.teamsCount

        local eventData = event1.data

        local arenaName = getElementData(eventData.arenaElement, "name", false)
    
        local data = teamwff2.data
    
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
            setElementData(teamElement, "sets", 0)
            setElementData(teamElement, "picks", 0)
            setElementData(teamElement, "bans", 0)
            setElementData(teamElement, "action", "pick")

            setElementData(coreElement, "eventTeam" .. iString, teamElement)
    
            eventClans[i] = clan
        end
    
        data.eventClans = eventClans
    end,
    
    destroyEventClans = function()
        local data = teamwff2.data

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
        local data = teamwff2.data
    
        local eventClans = data.eventClans
    
        for i = 1, #eventClans do
            local clan = eventClans[i]

            clan:addAllElementDataSubscriber(player)
        end
    end,
    
    removeEventClansDataSubscriber = function(player)
        local data = teamwff2.data
    
        local eventClans = data.eventClans
    
        for i = 1, #eventClans do
            local clan = eventClans[i]

            clan:removeAllElementDataSubscriber(player)
        end
    end,

    updatePlayersOnStart = function()
        local data = teamwff2.data

        local refereeClan = data.refereeClan
        local spectatorsClan = data.spectatorsClan

        local refereeClanTeamElement = refereeClan.teamElement
        local spectatorsClanTeamElement = spectatorsClan.teamElement

        local eventData = event1.data

        local arenaElement = eventData.arenaElement

        local arenaPlayers = getElementChildren(arenaElement, "player")

        local permissionString = "resource." .. resourceName .. ".mode_teamwff2_referee"

        local addEventClansDataSubscriber = teamwff2.addEventClansDataSubscriber

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
        local dataFilePath = teamwff2.settings.dataFilePath

        if fileExists(dataFilePath) then
            fileDelete(dataFilePath)
        end

        local fileHandler = fileCreate(dataFilePath)

        if fileHandler then
            local data = teamwff2.data

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

                    teamSets = getElementData(teamElement, "sets", false),

                    teamPicks = getElementData(teamElement, "picks", false),

                    teamBans = getElementData(teamElement, "bans", false),

                    teamAction = getElementData(teamElement, "action", false),

                    serialData = clan.serialData
                }
            end

            local dataToSave = {
                coreID = getElementID(data.coreElement),

                eventClansData = eventClansData,

                mapData = data.mapData,

                maplist = data.maplist,

                picks = data.picks,

                bans = data.bans,
            }

            local dataJSON = toJSON(dataToSave, false, "tabs")

            fileWrite(fileHandler, dataJSON)
            fileClose(fileHandler)
        end
    end,

    loadData = function()
        local dataFilePath = teamwff2.settings.dataFilePath

        if fileExists(dataFilePath) then
            local fileHandler = fileOpen(dataFilePath, true)

            if fileHandler then
                local loadedDataJSON = fileRead(fileHandler, fileGetSize(fileHandler))

                local loadedData = fromJSON(loadedDataJSON) or {}

                fileClose(fileHandler)

                local data = teamwff2.data

                local coreID = loadedData.coreID

                if coreID then
                    setElementID(data.coreElement, coreID)
                end
                
                local eventClansData = loadedData.eventClansData
                
                if eventClansData then
                    local eventClans = data.eventClans

                    local getEventClanByID = teamwff2.getEventClanByID

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

                            local teamSets = data.teamSets

                            if teamSets then
                                setElementData(teamElement, "sets", teamSets)
                            end
                            
                            local teamPicks = data.teamPicks

                            if teamPicks then
                                setElementData(teamElement, "picks", teamPicks)
                            end

                            local teamBans = data.teamBans

                            if teamBans then
                                setElementData(teamElement, "bans", teamBans)
                            end

                            local teamAction = data.teamAction

                            if teamAction then
                                setElementData(teamElement, "action", teamAction)
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

                local maplist = loadedData.maplist

                if maplist then
                    data.maplist = maplist
                end
                
                local picks = loadedData.picks

                if picks then
                    data.picks = picks
                end

                local bans = loadedData.bans

                if bans then
                    data.bans = bans
                end
            end
        end
    end,

    saveResults = function()
        local resultsFilePath = teamwff2.settings.resultsFilePath

        if fileExists(resultsFilePath) then
            fileDelete(resultsFilePath)
        end

        local fileHandler = fileCreate(resultsFilePath)

        if fileHandler then
            local data = teamwff2.data

            local coreElement = data.coreElement

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

            local coreElementID = getElementID(coreElement)

            local resultsStrings = { coreElementID .. "\n\n" }

            local resultsToJSON = {
                mapData = {},
                results = {},
                playerResults = {},
                bans = {},
                coreID = coreElementID
            }

            local resultsToJSONMapData = resultsToJSON.mapData
            local resultsToJSONResults = resultsToJSON.results
            local resultsToJSONPlayerResults = resultsToJSON.playerResults
            local resultsToJSONBans = resultsToJSON.bans

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

            local pointsOrder = teamwff2.settings.pointsOrder

            local pointsOrderCount = #pointsOrder

            local clanResults = {}

            local playerResults = {}

            for i = 1, #eventClans do
                local clan = eventClans[i]

                local teamElement = clan.teamElement

                local tag = getElementData(teamElement, "tag", false)
                local points = getElementData(teamElement, "points", false) or 0
                local sets = getElementData(teamElement, "sets", false) or 0

                local r, g, b = getTeamColor(teamElement)

                local hexColor = "#" .. rgbToHex(r, g, b)

                clanResults[#clanResults + 1] = hexColor .. tag .. " #FFFFFF" .. tostring(sets) .. ":" .. tostring(points)

                for serial, data in pairs(clan.serialData) do
                    local points = data.points

                    if points and points > 0 then
                        local nickNameString = tostring(data.nickName)

                        local playerResult = { points = points }

                        local dataStrings = {}

                        for i = 1, pointsOrderCount do
                            local positionString = tostring(i) .. nth(i)

                            local positionData = data[positionString] or 0

                            playerResult[positionString] = positionData

                            dataStrings[i] = tostring(positionData) .. "x " .. positionString
                        end

                        dataStrings[#dataStrings + 1] = "passed: " .. tostring(data.passed or 0)

                        playerResult.nickName = nickNameString

                        playerResult.text = tostring(points) .. " " .. stringRemoveHex(nickNameString) .. " (" .. tableConcat(dataStrings, ", ") .. ")"

                        playerResults[#playerResults + 1] = playerResult
                    end
                end
            end

            local clanResultsString = tableConcat(clanResults, ", ")

            resultsStrings[#resultsStrings + 1] = stringRemoveHex(clanResultsString) .. "\n\n"

            resultsToJSONResults.clan = clanResultsString

            local sortValues = { "points" }

            for i = 1, pointsOrderCount do
                local positionString = tostring(i) .. nth(i)

                sortValues[#sortValues + 1] = positionString
            end

            tableSortOnValuesDescending(playerResults, unpack(sortValues))

            for i = 1, #playerResults do
                local playerResult = playerResults[i]

                resultsStrings[#resultsStrings + 1] = playerResult.text .. "\n"

                resultsToJSONPlayerResults[#resultsToJSONPlayerResults + 1] = { playerResult.nickName, playerResult.points }
            end

            local firstPlayer = playerResults[1]

            if firstPlayer then
                local firstPlayerNickName = firstPlayer.nickName
                local firstPlayerPointsString = tostring(firstPlayer.points)

                resultsStrings[#resultsStrings + 1] = "\nMVP: " .. stringRemoveHex(firstPlayerNickName) .. " with " .. firstPlayerPointsString .. " points\n"

                resultsToJSONResults.mvp = firstPlayerNickName .. " #FFFFFF(" .. firstPlayerPointsString .. ")"
            end

            resultsStrings[#resultsStrings + 1] = "\nBanned maps\n"

            for i, data in ipairs(data.bans) do
                local teamElement = getElementData(coreElement, "eventTeam" .. data.teamID, false)

                if isElement(teamElement) then
                    local r, g, b = getTeamColor(teamElement)

                    local hexColor = "#" .. rgbToHex(r, g, b)

                    local tag = getElementData(teamElement, "tag", false)

                    resultsStrings[#resultsStrings + 1] = data.name .. " (" .. tag .. ")"

                    resultsToJSONBans[#resultsToJSONBans + 1] = data.name .. " (" .. hexColor .. tag .. "#FFFFFF)"
                end
            end

            local resultsJSON = toJSON(resultsToJSON, false, "tabs")

            local resultsJSONFilePath = teamwff2.settings.resultsJSONFilePath

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
        local data = teamwff2.data

        local resultsToJSON = data.resultsToJSON

        if resultsToJSON then
            local resultsToJSONMapData = resultsToJSON.mapData
            local resultsToJSONResults = resultsToJSON.results
            local resultsToJSONPlayerResults = resultsToJSON.playerResults
            local resultsToJSONBans = resultsToJSON.bans

            local clanResults = resultsToJSONResults.clan

            local settings = teamwff2.settings

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

            htmlStrings[#htmlStrings + 1] = [[
                </table>
                <p style="text-align: center;">
                    <span style="color:#888b98; font-size:26px;">Banned maps</span>
                </p>
                <table class="cEF_table">
                    <tr>
                        <th>Name</th>
                    </tr>
            ]]
            
            for i = 1, #resultsToJSONBans do
                htmlStrings[#htmlStrings + 1] = [[
                    <tr>
                        <td>]] .. convertStringToHTML(resultsToJSONBans[i]) .. [[</td>
                    </tr>
                ]]
            end

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

    addPoints = function(addedBy, players)
        local eventData = event1.data

        local arenaElement = eventData.arenaElement

        local pointsOrder = teamwff2.settings.pointsOrder
                        
        local pointsOrderCount = #pointsOrder

        local getPlayerEventClan = teamwff2.getPlayerEventClan

        local arenaPlayers = getElementChildren(arenaElement, "player")

        if isElement(addedBy) then
            outputChatBox("#CCCCCCPoints have been added by #FFFFFF" .. getPlayerName(addedBy), arenaElement, 255, 255, 255, true)
        end

        local data = teamwff2.data

        local playersStrings = {}

        for i = 1, pointsOrderCount do
            if players[i] then
                local positionString = tostring(i) .. nth(i)

                local targetPlayer = getPlayerFromPartialName(arenaPlayers, players[i])

                if isElement(targetPlayer) then
                    local eventClan = getPlayerEventClan(targetPlayer)

                    local targetPlayerOldPositionValue = getElementData(targetPlayer, positionString, false) or 0
                    local targetPlayerNewPositionValue = targetPlayerOldPositionValue + 1

                    local points = pointsOrder[i]
                    
                    local targetPlayerOldPoints = getElementData(targetPlayer, "points", false) or 0
                    local targetPlayerNewPoints = targetPlayerOldPoints + points
                    
                    eventClan:setPlayerData(targetPlayer, positionString, targetPlayerNewPositionValue)
                    eventClan:setPlayerData(targetPlayer, "points", targetPlayerNewPoints)

                    local teamElement = eventClan.teamElement

                    setElementData(teamElement, "points", (getElementData(teamElement, "points", false) or 0) + points)

                    local pointsString = tostring(points)

                    local targetPlayerName = getPlayerName(targetPlayer)

                    local targetPlayerNewPointsString = tostring(targetPlayerNewPoints)

                    --playersStrings[#playersStrings + 1] = positionString .. " (" .. pointsString .. ") " .. stringRemoveHex(targetPlayerName) .. " (" .. targetPlayerNewPointsString .. ")"
                    playersStrings[#playersStrings + 1] = targetPlayerName .. " #FFFFFF(" .. targetPlayerNewPointsString .. ")"

                    outputChatBox("#CCCCCC" .. positionString .. ": #FFFFFF" .. targetPlayerName .. " #CCCCCChas earned #FFFFFF" .. pointsString .. " #CCCCCCpoints and now has #FFFFFF" .. targetPlayerNewPointsString .. " #CCCCCCpoint" .. (targetPlayerNewPoints == 1 and "" or "s"), arenaElement, 255, 255, 255, true)
                end
            end
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
            local teamSets = getElementData(teamElement, "sets", false) or 0

            local clanString = hexColor .. teamTag .. " #FFFFFF" .. teamSets .. ":" .. teamPoints

            clansStrings[i] = clanString

            local clanOutputString = hexColor .. teamTag .. " #FFFFFF" .. teamSets .. ":" .. teamPoints

            clansOutputStrings[i] = clanOutputString
        end

        local clansString = tableConcat(clansStrings, ", ")

        local thisMapData = { mapString, clansString, unpack(playersStrings) }

        mapData[thisMapID] = thisMapData

        local clanOutputString = tableConcat(clansOutputStrings, ", ")

        outputChatBox("#CCCCCCCurrent result: " .. clanOutputString, arenaElement, 255, 255, 255, true)
    end,

    didAllClansPickBanMaps = function()
        local data = teamwff2.data

        local eventClans = data.eventClans

        local teamMapPicks = teamwff2.settings.teamMapPicks
        local teamMapBans = teamwff2.settings.teamMapBans

        for i = 1, #eventClans do
            local teamElement = data.teamElement

            if getElementData(teamElement, "picks", false) ~= teamMapPicks or getElementData(teamElement, "bans", false) ~= teamMapBans then
                return false
            end
        end

        return true
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
        local data = teamwff2.data

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
        local data = teamwff2.data

        local eventClans = data.eventClans

        for i = 1, #eventClans do
            local clan = eventClans[i]

            if clan.teamElement == teamElement then
                return clan
            end
        end
    end,

    getPlayerEventClan = function(player)
        local data = teamwff2.data

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
        
            local eventHandlers = teamwff2.eventHandlers
        
            addEventHandler("event1:teamwff2:onEventStateSet", arenaElement, eventHandlers.onArenaWFFEventStateSet)
        end,

        onArenaDestroy = function()
            local eventData = event1.data

            local arenaElement = eventData.arenaElement
        
            local eventHandlers = teamwff2.eventHandlers
        
            removeEventHandler("event1:teamwff2:onEventStateSet", arenaElement, eventHandlers.onArenaWFFEventStateSet)

            teamwff2.stop()
        end,

        ---

        onArenaWFFEventStateSet = function(state)
            if state then
                teamwff2.start()
            else
                teamwff2.stop()
            end
        end,

        ---

        onArenaDeathmatchStateSet = function(state)
            local arenaDeathmatchStateFunction = teamwff2.arenaDeathmatchStateFunctions[state]

            if arenaDeathmatchStateFunction then
                arenaDeathmatchStateFunction()
            end
        end,

        onArenaDeathmatchPlayerJoinSpawn = function()
            deathmatchMapLoadedStateData:removePlayerFromLoadQueue(source)
        end,

        onArenaDeathmatchPlayerReachedHunter = function(timePassed)
            local data = teamwff2.data

            local playerHunterTimes = data.playerHunterTimes

            playerHunterTimes[#playerHunterTimes + 1] = { player = source, timePassed = timePassed }

            if not isTimer(data.playerHunterTimesTimer) then
                data.playerHunterTimesTimer = setTimer(teamwff2.timers.hunterTimes, teamwff2.settings.playerHunterTimesDelay, 1)
            end

            if getElementData(data.coreElement, "state", false) == "live" then
                local eventClan = teamwff2.getPlayerEventClan(source)

                if eventClan then
                    local oldPassed = getElementData(source, "passed", false) or 0

                    eventClan:setPlayerData(source, "passed", oldPassed + 1)
                end
            end
        end,

        onArenaPlayerJoin = function()
            teamwff2.addEventClansDataSubscriber(source)

            triggerClientResourceEvent(resource, source, "event1:teamwff2:onClientEventModeStart", source, teamwff2.settings.teamsCount)

            local data = teamwff2.data
    
            if hasObjectPermissionTo(source, "resource." .. resourceName .. ".mode_teamwff2_referee", false) then
                silentExport("ep_core", "setPlayerTeam", source, data.refereeClan.teamElement)
            else
                silentExport("ep_core", "setPlayerTeam", source, data.spectatorsClan.teamElement)
            end
        end,

        onArenaPlayerQuit = function()
            silentExport("ep_core", "setPlayerTeam", source, nil)
            
            triggerClientResourceEvent(resource, source, "event1:teamwff2:onClientEventModeStop", source)
            
            teamwff2.removeEventClansDataSubscriber(source)
        end,

        onArenaPlayerTeamChange = function(oldTeam, newTeam)
            local data = teamwff2.data
            
            local refereeClan = data.refereeClan
            local spectatorsClan = data.spectatorsClan

            refereeClan:removePlayer(source)
            spectatorsClan:removePlayer(source)

            local eventClans = data.eventClans

            for i = 1, #eventClans do
                local clan = eventClans[i]

                clan:removePlayer(source)
            end

            if newTeam then
                local eventClan = teamwff2.getEventClanByTeamElement(newTeam)

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
            local eventClan = teamwff2.getPlayerEventClan(source)

            if eventClan then
                eventClan:setPlayerData(source, "nickName", newNick)
            end
        end,

        onArenaPlayerLogin = function()
            if hasObjectPermissionTo(source, "resource." .. resourceName .. ".mode_teamwff2_referee", false) then
                silentExport("ep_core", "setPlayerTeam", source, teamwff2.data.refereeClan.teamElement)
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
                    local eventClan = teamwff2.getEventClanByTag(tag)

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
                local spectatorsClan = teamwff2.data.spectatorsClan

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local arg = { ... }

                    if #arg > 0 then
                        local eventName = tableConcat(arg, " ")

                        setElementID(teamwff2.data.coreElement, eventName)

                        outputChatBox("#CCCCCCEvent name has been set to #FFFFFF" .. eventName .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [name]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setTeamName = function(player, commandName, tag, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = teamwff2.getEventClanByTag(tag)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = teamwff2.getEventClanByTag(tag)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = teamwff2.getEventClanByTag(tag)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = teamwff2.getEventClanByTag(tag)

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

        setTeamSets = function(player, commandName, tag, sets)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = teamwff2.getEventClanByTag(tag)

                        if eventClan then
                            sets = tonumber(sets)

                            if sets then
                                local teamElement = eventClan.teamElement

                                setElementData(teamElement, "sets", sets)

                                local r, g, b = getTeamColor(teamElement)

                                local hexColor = "#" .. rgbToHex(r, g, b)

                                local tag = getElementData(teamElement, "tag", false)

                                outputChatBox(hexColor .. tag .. " #CCCCCCsets have been set to #FFFFFF" .. tostring(sets) .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                            else
                                outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [tag] [sets]", player, 255, 255, 255, true)
                            end
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [tag] [sets]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setState = function(player, commandName, state)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if state then
                        local stateData = teamwff2.states[state]

                        if stateData then
                            setElementData(teamwff2.data.coreElement, "state", state)

                            local stateFunction = teamwff2.stateFunctions[state]

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if round then
                        round = tonumber(round)

                        if round then
                            setElementData(teamwff2.data.coreElement, "round", round)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if totalRounds then
                        totalRounds = tonumber(totalRounds)

                        if totalRounds then
                            setElementData(teamwff2.data.coreElement, "totalRounds", totalRounds)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
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
                                local eventClan = teamwff2.getPlayerEventClan(targetPlayer)
    
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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    teamsCount = tonumber(teamsCount)

                    if teamsCount then
                        teamsCount = math.max(math.min(teamsCount, 5), 1)

                        teamwff2.stop()

                        teamwff2.settings.teamsCount = teamsCount
    
                        -- bug fix
                        setTimer(
                            function()
                                teamwff2.start()
    
                                outputChatBox("#CCCCCCTeams count has been set to #FFFFFF" .. tostring(teamsCount) .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                            end,
                        100, 1)
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [teams count]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setMapID = function(player, commandName, index, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    index = tonumber(index)

                    if index then
                        local data = teamwff2.data

                        index = mathFloor(index)

                        if index >= 1 and index <= #data.maplist + 1 then
                            local arg = { ... }

                            if #arg > 0 then
                                local mapID = tonumber(arg[1])
        
                                local playerSearch = data.setMapIDPlayerSearch[player]
                
                                if mapID and playerSearch then
                                    local search = playerSearch[mapID]
                
                                    if search then
                                        local resource, mapName = unpack(search)
        
                                        data.maplist[index] = {name = mapName, resourceName = getResourceName(resource)}

                                        data.setMapIDPlayerSearch[player] = nil

                                        outputChatBox("#CCCCCCMap #FFFFFF#" .. index .. " #CCCCCChas been set to #FFFFFF" .. mapName, player, 255, 255, 255, true)
                                    end
                                else
                                    local mapNamePart = tableConcat(arg, " ")
                        
                                    local resources = event1.getMapResourcesFromMapNamePart(mapNamePart)
        
                                    local resourcesLen = #resources
                        
                                    if resourcesLen == 0 or resourcesLen > 1 then
                                        outputChatBox("#FFFFFF" .. resourcesLen .. " #CCCCCCmatches found", player, 255, 255, 255, true)
                        
                                        if resourcesLen < 6 then
                                            local playerSearch = {}
                
                                            for i = 1, resourcesLen do
                                                local resource, mapName = unpack(resources[i])
                                                
                                                playerSearch[i] = { resource, mapName }
                
                                                outputChatBox("/" .. commandName .. " [index] " .. i .. " - " .. mapName, player, 255, 255, 255, true)
                                            end
                
                                            data.setMapIDPlayerSearch[player] = playerSearch
                                        end
                                    else
                                        local resource, mapName = unpack(resources[1])
                                        
                                        data.maplist[index] = {name = mapName, resourceName = getResourceName(resource)}

                                        data.setMapIDPlayerSearch[player] = nil

                                        outputChatBox("#CCCCCCMap #FFFFFF#" .. index .. " #CCCCCChas been set to #FFFFFF" .. mapName, player, 255, 255, 255, true)
                                    end
                                end
                            end
                        else
                            outputChatBox("#CCCCCCIndex has to be in the range of #FFFFFF1-" .. #data.maplist + 1, player, 255, 255, 255, true)
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [index] [map name]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        showMaps = function(player, commandName)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local data = teamwff2.data

                    local getPlayerEventClan = teamwff2.getPlayerEventClan

                    outputChatBox("#CCCCCCMaplist:", arenaElement, 255, 255, 255, true)

                    for i, data in ipairs(data.maplist) do
                        outputChatBox("#" .. i .. " - " .. data.name, arenaElement, 255, 255, 255, true)
                    end

                    for i, player in ipairs(getElementChildren(arenaElement, "player")) do
                        if getPlayerEventClan(player) then
                            outputChatBox("#CCCCCCUse #FFFFFF/pickmap [index] #CCCCCCor #FFFFFF/banmap [index] #CCCCCCto pick/ban maps", player, 255, 255, 255, true)
                        end
                    end
                end
            end
        end,

        showPicks = function(player, commandName)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local data = teamwff2.data

                    local coreElement = data.coreElement

                    local getPlayerEventClan = teamwff2.getPlayerEventClan

                    outputChatBox("#CCCCCCPicks:", player, 255, 255, 255, true)

                    for i, data in ipairs(data.picks) do
                        local teamElement = getElementData(coreElement, "eventTeam" .. data.teamID, false)

                        if isElement(teamElement) then
                            local r, g, b = getTeamColor(teamElement)

                            local hexColor = "#" .. rgbToHex(r, g, b)

                            local tag = getElementData(teamElement, "tag", false)

                            outputChatBox("#" .. i .. " - " .. data.name .. " (" .. hexColor .. tag .. "#FFFFFF)", player, 255, 255, 255, true)
                        end
                    end
                end
            end
        end,

        reshufflePicks = function(player, commandName)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local data = teamwff2.data

                    local sortPicks = function(picks, numPieces)
                        local function shuffle(tbl)
                            for i = #tbl, 2, -1 do
                                local j = math.random(i)

                                tbl[i], tbl[j] = tbl[j], tbl[i]
                            end
                        end
                    
                        shuffle(picks)
                    
                        local result = {}

                        for i = 1, numPieces do
                            result[i] = {}
                        end
                    
                        local teamUsed = {}

                        for i = 1, numPieces do
                            teamUsed[i] = {}
                        end
                    
                        for _, pick in ipairs(picks) do
                            local teamID = pick.teamID
                            local placed = false
                    
                            for pieceIndex = 1, numPieces do
                                if not teamUsed[pieceIndex][teamID] then
                                    table.insert(result[pieceIndex], pick)

                                    teamUsed[pieceIndex][teamID] = true

                                    placed = true

                                    break
                                end
                            end
                    
                            if not placed then
                                return outputChatBox("#CCCCCCAn error occured", player, 255, 255, 255, true)
                            end
                        end
                    
                        for i, piece in ipairs(result) do
                            shuffle(piece)
                        end

                        local newPicks = {}

                        for i, piece in ipairs(result) do
                            for j, pick in ipairs(piece) do
                                table.insert(newPicks, pick)
                            end
                        end
                    
                        return newPicks
                    end
                    
                    data.picks = sortPicks(data.picks, math.ceil(#data.picks / teamwff2.settings.teamsCount))
                    
                    outputChatBox("#CCCCCCPicks have been reshuffled", player, 255, 255, 255, true)
                end
            end
        end,

        pickMap = function(player, commandName, index)
            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local playerArenaElement = event1.getPlayerArenaElement(player)

            if playerArenaElement == arenaElement then
                local eventClan = teamwff2.getPlayerEventClan(player)

                if eventClan then
                    index = tonumber(index)

                    if index then
                        local data = teamwff2.data

                        local map = data.maplist[index]

                        if map then
                            if not map.banned then
                                if not map.picked then
                                    local teamElement = eventClan.teamElement

                                    local picks = getElementData(teamElement, "picks", false) or 0

                                    local teamMapPicks = teamwff2.settings.teamMapPicks

                                    if picks < teamMapPicks then
                                        if getElementData(teamElement, "action", false) == "pick" then
                                            setElementData(teamElement, "picks", picks + 1)
                                            setElementData(teamElement, "action", "ban")

                                            map.picked = true

                                            table.insert(data.picks, {name = map.name, resourceName = map.resourceName, teamID = getElementData(teamElement, "id", false)})

                                            local r, g, b = getTeamColor(teamElement)

                                            local hexColor = "#" .. rgbToHex(r, g, b)

                                            local tag = getElementData(teamElement, "tag", false)

                                            outputChatBox(hexColor .. tag .. " #CCCCCChas picked #FFFFFF" .. map.name, arenaElement, 255, 255, 255, true)
                                        else
                                            outputChatBox("#CCCCCCYour team has to ban a map first", player, 255, 255, 255, true)
                                        end
                                    else
                                        outputChatBox("#CCCCCCYou can pick a max of #FFFFFF" .. teamMapPicks .. " #CCCCCCmaps", player, 255, 255, 255, true)
                                    end
                                else
                                    outputChatBox("#CCCCCCThis map is already picked", player, 255, 255, 255, true)
                                end
                            else
                                outputChatBox("#CCCCCCThis map is banned", player, 255, 255, 255, true)
                            end
                        else
                            outputChatBox("#CCCCCCInvalid index provided", player, 255, 255, 255, true)
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [index]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        banMap = function(player, commandName, index)
            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local playerArenaElement = event1.getPlayerArenaElement(player)

            if playerArenaElement == arenaElement then
                local eventClan = teamwff2.getPlayerEventClan(player)

                if eventClan then
                    index = tonumber(index)

                    if index then
                        local data = teamwff2.data

                        local map = data.maplist[index]

                        if map then
                            if not map.banned then
                                local teamElement = eventClan.teamElement

                                local bans = getElementData(teamElement, "bans", false) or 0

                                local teamMapBans = teamwff2.settings.teamMapBans

                                if bans < teamMapBans then
                                    if getElementData(teamElement, "action", false) == "ban" then
                                        setElementData(teamElement, "bans", bans + 1)
                                        setElementData(teamElement, "action", "pick")

                                        map.banned = true

                                        table.insert(data.bans, {name = map.name, resourceName = map.resourceName, teamID = getElementData(teamElement, "id", false)})

                                        local r, g, b = getTeamColor(teamElement)

                                        local hexColor = "#" .. rgbToHex(r, g, b)

                                        local tag = getElementData(teamElement, "tag", false)

                                        outputChatBox(hexColor .. tag .. " #CCCCCChas banned #FFFFFF" .. map.name, arenaElement, 255, 255, 255, true)
                                    else
                                        outputChatBox("#CCCCCCYour team has to pick a map first", player, 255, 255, 255, true)
                                    end
                                else
                                    outputChatBox("#CCCCCCYou can ban a max of #FFFFFF" .. teamMapBans .. " #CCCCCCmaps", player, 255, 255, 255, true)
                                end
                            else
                                outputChatBox("#CCCCCCThis map is banned", player, 255, 255, 255, true)
                            end
                        else
                            outputChatBox("#CCCCCCInvalid index provided", player, 255, 255, 255, true)
                        end
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [index]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        toggleAutoPoints = function(player, commandName)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local data = teamwff2.data

                    local newState = not data.autoPointsState

                    data.autoPointsState = newState

                    if newState then
                        teamwff2.settings.pointsOrder = teamwff2.settings.autoPointsOrder

                        outputChatBox("#CCCCCCAuto points have been #00FF00enabled #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    else
                        teamwff2.settings.pointsOrder = teamwff2.settings.defaultPointsOrder

                        outputChatBox("#CCCCCCAuto points have been #FF0000disabled #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    end
                end
            end
        end,

        addPoints = function(player, commandName, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local players = { ... }

                    if #players > 0 then
                        local getPlayerEventClan = teamwff2.getPlayerEventClan

                        local pointsOrder = teamwff2.settings.pointsOrder
                        
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
                            teamwff2.addPoints(player, players)
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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = teamwff2.getEventClanByTag(tag)

                        if eventClan then
                            local alivePlayers = teamwff2.getAlivePlayersInClan(eventClan)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local forumID = tonumber(forumName)--teamwff2.settings.forumNameIDs[forumName]

                    if forumID then
                        local isTopicHidden = true

                        if hiddenArg == "hidden" then
                            isTopicHidden = true
                        elseif hiddenArg == "visible" then
                            isTopicHidden = false
                        end

                        local arg = { ... }

                        teamwff2.outputResultsOnForum(forumID, isTopicHidden, tableConcat({unpack(arg, 1, separatorOffset)}, " "), tableConcat({unpack(arg, separatorOffset + 1)}, " "),
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

        resetAllTeamPoints = function(player, commandName)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local data = teamwff2.data

                    local eventClans = data.eventClans

                    for i = 1, #eventClans do
                        local clan = eventClans[i]
            
                        setElementData(clan.teamElement, "points", 0)
                    end

                    outputChatBox("#CCCCCCAll team points have been reset by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                end
            end
        end,
        
        resetMode = function(player, commandName, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_teamwff2_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    teamwff2.stop()

                    local dataFilePath = teamwff2.settings.dataFilePath

                    if fileExists(dataFilePath) then
                        fileDelete(dataFilePath)
                    end

                    -- bug fix
                    setTimer(
                        function()
                            teamwff2.start()

                            outputChatBox("#CCCCCCEvent mode has been reset by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                        end,
                    100, 1)
                end
            end
        end
    },

    timers = {
        hunterTimes = function()
            local data = teamwff2.data

            local playerHunterTimes = data.playerHunterTimes
            
            tableSort(playerHunterTimes,
                function(a, b)
                    return a.timePassed < b.timePassed
                end
            )

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local didPlayerFinish = function(player)
                for i, v in ipairs(data.autoPointsPlayers) do
                    if v.player == player then
                        return true
                    end
                end
            end
            
            for i = 1, #playerHunterTimes do
                local hunterTime = playerHunterTimes[i]

                local player = hunterTime.player

                if not didPlayerFinish(player) then
                    local position = data.playerHunterLastPosition + 1

                    data.playerHunterLastPosition = position

                    table.insert(data.autoPointsPlayers, {player = player, time = hunterTime.timePassed})

                    outputChatBox("#CCCCCC" .. tostring(position) .. nth(position) .. ": #FFFFFF" .. getPlayerName(player) .. "#CCCCCC, time: #FFFFFF" .. formatMS(hunterTime.timePassed), arenaElement, 255, 255, 255, true)
                end
            end

            data.playerHunterTimes = {}
        end,

        checkAlivePlayers = function()
            local data = teamwff2.data

            local coreElement = data.coreElement
    
            if getElementData(coreElement, "state", false) == "live" then
                local arenaElement = event1.data.arenaElement

                local eventClans = data.eventClans

                local getAlivePlayersInClan = teamwff2.getAlivePlayersInClan

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

            local getPlayerEventClan = teamwff2.getPlayerEventClan

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
                end
            end

            local data = teamwff2.data

            local coreElement = data.coreElement

            if getElementData(coreElement, "state", false) == "live" then
                local oldRound = getElementData(coreElement, "round", false) or 0

                local round = oldRound + 1

                setElementData(coreElement, "round", round)

                local pick = data.picks[round % #data.picks + 1]

                if pick then
                    local resource = getResourceFromName(pick.resourceName)

                    if resource then
                        event1.setNextMap(resource)
                    end
                end
            end

            deathmatchMapLoadedStateData:killForcedCountdownTimer()
        end,

        ["running"] = function()
            local data = teamwff2.data

            if isTimer(data.playerHunterTimesTimer) then
                killTimer(data.playerHunterTimesTimer)
            end

            data.playerHunterTimesTimer = nil

            data.playerHunterTimes = {}
            data.playerHunterLastPosition = 0

            data.autoPointsPlayers = {}

            --teamwff2.data.checkAlivePlayersTimer = setTimer(teamwff2.timers.checkAlivePlayers, 4000, 0)
        end,

        ["ended"] = function()
            deathmatchEndedStateData:killNextMapTimer()
        end,

        ["map unloading"] = function()
            local data = teamwff2.data

            if data.autoPointsState and getElementData(data.coreElement, "state", false) == "live" then
                tableSort(data.autoPointsPlayers,
                    function(a, b)
                        return a.time < b.time
                    end
                )

                local playerNames = {}

                for i, v in ipairs(data.autoPointsPlayers) do
                    if isElement(v.player) then
                        table.insert(playerNames, getPlayerName(v.player))
                    end
                end

                if #playerNames > 0 then
                    teamwff2.addPoints(nil, playerNames)
                end
            end

            data.autoPointsPlayers = {}

            if isTimer(data.checkAlivePlayersTimer) then
                killTimer(data.checkAlivePlayersTimer)
            end

            data.checkAlivePlayersTimer = nil
        end
    },

    stateFunctions = {
        ["ended"] = function()
            local resultsString, resultsJSONString = teamwff2.saveResults()

            if resultsString then
                local eventData = event1.data

                local refereePlayers = {}

                local arenaPlayers = getElementChildren(eventData.arenaElement, "player")

                local permissionString = "resource." .. resourceName .. ".mode_teamwff2_referee"

                for i = 1, #arenaPlayers do
                    local arenaPlayer = arenaPlayers[i]

                    if hasObjectPermissionTo(arenaPlayer, permissionString, false) then
                        refereePlayers[#refereePlayers + 1] = arenaPlayer
                    end
                end

                if #refereePlayers > 0 then
                    triggerClientResourceEvent(resource, refereePlayers, "event1:teamwff2:onClientArenaResultsSaved", eventData.sourceElement, resultsString, resultsJSONString)
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

event1.modes.teamwff2 = teamwff2

addEvent("event1:onArenaCreated")
addEvent("event1:onArenaDestroy")

addEvent("event1:onPlayerArenaJoin")
addEvent("event1:onPlayerArenaQuit")

addEvent("onPlayerTeamChange")

addEvent("event1:deathmatch:onArenaStateSet")
addEvent("event1:deathmatch:onPlayerJoinSpawn")
addEvent("event1:deathmatch:onPlayerReachedHunter")

addEvent("event1:teamwff2:onEventStateSet")

do
    local eventHandlers = teamwff2.eventHandlers

    addEventHandler("event1:onArenaCreated", resourceRoot, eventHandlers.onArenaCreated)
    addEventHandler("event1:onArenaDestroy", resourceRoot, eventHandlers.onArenaDestroy)
end