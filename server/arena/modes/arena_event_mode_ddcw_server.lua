local stringLen = string.len
local stringRep = string.rep
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

local derby = event1.managers.derby

local derbyStates = derby.states

local derbyMapLoadedStateData = derbyStates["map loaded"]
local derbyEndedStateData = derbyStates["ended"]

local stringRemoveHex = function(string)
    return stringGsub(string, "#%x%x%x%x%x%x", "")
end

local rgbToHex = function(r, g, b)
    return stringFormat("%02x%02x%02x", r, g, b)
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

local ddcw

ddcw = {
    settings = {
        dataFilePath = "server/arena/modes/ddcw_data.json",
        resultsFilePath = "server/arena/modes/ddcw_results.txt",

        teamsCount = 2
    },

    start = function()
        if not ddcw.data then
            local data = {}

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local arenaName = getElementData(arenaElement, "name", false)

            local refereeClan = clanNew(arenaName .. " Referee", 255, 0, 0)
            local spectatorsClan = clanNew(arenaName .. " Spectators", 255, 255, 255)

            local coreElement = createElement("core", "Event Name")

            local teamsCount = ddcw.settings.teamsCount

            setElementParent(coreElement, arenaElement)

            setElementData(arenaElement, "coreElement", coreElement)

            setElementData(coreElement, "refereeClanTeamElement", refereeClan.teamElement)
            setElementData(coreElement, "spectatorsClanTeamElement", spectatorsClan.teamElement)

            setElementData(coreElement, "teamsCount", teamsCount)
            setElementData(coreElement, "state", "free")
            setElementData(coreElement, "round", 1)
            setElementData(coreElement, "totalRounds", 20)

            local eventHandlers = ddcw.eventHandlers
            
            addEventHandler("event1:ddcw:onPlayerWasted", arenaElement, eventHandlers.onArenaDDCWPlayerWasted)

            addEventHandler("event1:derby:onArenaStateSet", arenaElement, eventHandlers.onArenaDerbyStateSet)
            addEventHandler("event1:derby:onPlayerJoinSpawn", arenaElement, eventHandlers.onArenaDerbyPlayerJoinSpawn)

            addEventHandler("event1:onPlayerArenaJoin", arenaElement, eventHandlers.onArenaPlayerJoin)
            addEventHandler("event1:onPlayerArenaQuit", arenaElement, eventHandlers.onArenaPlayerQuit)

            addEventHandler("onPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)
            addEventHandler("onPlayerChangeNick", arenaElement, eventHandlers.onArenaPlayerChangeNick)
            addEventHandler("onPlayerLogin", arenaElement, eventHandlers.onArenaPlayerLogin)

            local commandHandlers = ddcw.commandHandlers

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
            addCommandHandler("setplayerdata", commandHandlers.setPlayerData)
            addCommandHandler("getplayerdata", commandHandlers.getPlayerData)
            addCommandHandler("resetmode", commandHandlers.resetMode)

            data.coreElement = coreElement
            
            data.refereeClan = refereeClan
            data.spectatorsClan = spectatorsClan

            data.mapData = {}

            ddcw.data = data

            ddcw.createEventClans()
            ddcw.loadData()
            ddcw.updatePlayersOnStart()

            local sourceElement = eventData.sourceElement

            triggerClientResourceEvent(resource, arenaElement, "event1:ddcw:onClientEventModeCreatedInternal", sourceElement, teamsCount)

            triggerEvent("event1:ddcw:onEventModeCreated", sourceElement)

            outputDebugString(debuggerPrepareString("Event dd cw mode created.", 1))
        end
    end,

    stop = function()
        local data = ddcw.data

        if data then
            outputDebugString(debuggerPrepareString("Destroying event1 dd cw mode.", 1))

            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local sourceElement = eventData.sourceElement

            triggerEvent("event1:ddcw:onEventModeDestroy", sourceElement)

            triggerClientResourceEvent(resource, arenaElement, "event1:ddcw:onClientEventModeDestroyInternal", sourceElement)

            local eventHandlers = ddcw.eventHandlers

            removeEventHandler("event1:ddcw:onPlayerWasted", arenaElement, eventHandlers.onArenaDDCWPlayerWasted)

            removeEventHandler("event1:derby:onArenaStateSet", arenaElement, eventHandlers.onArenaDerbyStateSet)
            removeEventHandler("event1:derby:onPlayerJoinSpawn", arenaElement, eventHandlers.onArenaDerbyPlayerJoinSpawn)

            removeEventHandler("event1:onPlayerArenaJoin", arenaElement, eventHandlers.onArenaPlayerJoin)
            removeEventHandler("event1:onPlayerArenaQuit", arenaElement, eventHandlers.onArenaPlayerQuit)

            removeEventHandler("onPlayerTeamChange", arenaElement, eventHandlers.onArenaPlayerTeamChange)
            removeEventHandler("onPlayerChangeNick", arenaElement, eventHandlers.onArenaPlayerChangeNick)
            removeEventHandler("onPlayerLogin", arenaElement, eventHandlers.onArenaPlayerLogin)

            local commandHandlers = ddcw.commandHandlers

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
            removeCommandHandler("setplayerdata", commandHandlers.setPlayerData)
            removeCommandHandler("getplayerdata", commandHandlers.getPlayerData)
            removeCommandHandler("resetmode", commandHandlers.resetMode)

            setElementData(arenaElement, "coreElement", nil)

            local coreElement = data.coreElement

            setElementData(coreElement, "refereeClanTeamElement", nil)
            setElementData(coreElement, "spectatorsClanTeamElement", nil)

            setElementData(coreElement, "state", nil)
            setElementData(coreElement, "round", nil)
            setElementData(coreElement, "totalRounds", nil)

            ddcw.updatePlayersOnStop()
            ddcw.saveData()
            ddcw.destroyEventClans()

            local checkAlivePlayersTimer = data.checkAlivePlayersTimer

            if isTimer(checkAlivePlayersTimer) then
                killTimer(checkAlivePlayersTimer)
            end

            if isElement(coreElement) then
                destroyElement(coreElement)
            end

            data.refereeClan:destroy()
            data.spectatorsClan:destroy()

            ddcw.data = nil
        end
    end,

    createEventClans = function()
        local teamsCount = ddcw.settings.teamsCount

        local eventData = event1.data

        local arenaName = getElementData(eventData.arenaElement, "name", false)
    
        local data = ddcw.data
    
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
        local data = ddcw.data

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
        local data = ddcw.data
    
        local eventClans = data.eventClans
    
        for i = 1, #eventClans do
            local clan = eventClans[i]

            clan:addAllElementDataSubscriber(player)
        end
    end,
    
    removeEventClansDataSubscriber = function(player)
        local data = ddcw.data
    
        local eventClans = data.eventClans
    
        for i = 1, #eventClans do
            local clan = eventClans[i]

            clan:removeAllElementDataSubscriber(player)
        end
    end,

    updatePlayersOnStart = function()
        local data = ddcw.data

        local refereeClan = data.refereeClan
        local spectatorsClan = data.spectatorsClan

        local refereeClanTeamElement = refereeClan.teamElement
        local spectatorsClanTeamElement = spectatorsClan.teamElement

        local eventData = event1.data

        local arenaElement = eventData.arenaElement

        local arenaPlayers = getElementChildren(arenaElement, "player")

        local permissionString = "resource." .. resourceName .. ".mode_ddcw_referee"

        local addEventClansDataSubscriber = ddcw.addEventClansDataSubscriber

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
        local dataFilePath = ddcw.settings.dataFilePath

        if fileExists(dataFilePath) then
            fileDelete(dataFilePath)
        end

        local fileHandler = fileCreate(dataFilePath)

        if fileHandler then
            local data = ddcw.data

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
        local dataFilePath = ddcw.settings.dataFilePath

        if fileExists(dataFilePath) then
            local fileHandler = fileOpen(dataFilePath, true)

            if fileHandler then
                local loadedDataJSON = fileRead(fileHandler, fileGetSize(fileHandler))

                local loadedData = fromJSON(loadedDataJSON) or {}

                fileClose(fileHandler)

                local data = ddcw.data

                local coreID = loadedData.coreID

                if coreID then
                    setElementID(data.coreElement, coreID)
                end
                
                local eventClansData = loadedData.eventClansData
                
                if eventClansData then
                    local eventClans = data.eventClans

                    local getEventClanByID = ddcw.getEventClanByID

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
        local resultsFilePath = ddcw.settings.resultsFilePath

        if fileExists(resultsFilePath) then
            fileDelete(resultsFilePath)
        end

        local fileHandler = fileCreate(resultsFilePath)

        if fileHandler then
            local data = ddcw.data

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

            for i = 1, mapDataCount do
                local thisMapData = mapData[i]

                local dataValueStrings = {}
    
                for j = 1, #thisMapData do
                    local dataValueString = thisMapData[j]

                    local whitespacesCount = columnMaxLengths[j] - stringLen(dataValueString) + 5

                    local whitespaces = stringRep(" ", whitespacesCount)

                    dataValueStrings[j] = dataValueString .. whitespaces
                end
    
                resultsStrings[#resultsStrings + 1] = tableConcat(dataValueStrings) .. "\n"
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

                clanResults[#clanResults + 1] = tag .. " " .. tostring(points)

                for serial, data in pairs(clan.serialData) do
                    local points = data.points

                    if points and points > 0 then
                        local playerResult = { points = points }

                        local dataStrings = {}

                        local dataNames = { "killed", "survived" }

                        for i = 1, #dataNames do
                            local dataName = dataNames[i]

                            local dataValue = data[dataName] or 0

                            dataStrings[i] = dataName .. ": " .. tostring(dataValue)
                        end

                        local nickNameString = tostring(data.nickName)

                        playerResult.nickName = nickNameString

                        playerResult.text = tostring(points) .. " " .. nickNameString .. " (" .. tableConcat(dataStrings, ", ") .. ")"

                        playerResults[#playerResults + 1] = playerResult
                    end
                end
            end

            resultsStrings[#resultsStrings + 1] = tableConcat(clanResults, ", ") .. "\n\n"

            tableSortOnValuesDescending(playerResults, "points")

            for i = 1, #playerResults do
                resultsStrings[#resultsStrings + 1] = playerResults[i].text .. "\n"
            end

            local firstPlayer = playerResults[1]

            if firstPlayer then
                resultsStrings[#resultsStrings + 1] = "\nMVP: " .. firstPlayer.nickName .. " with " .. tostring(firstPlayer.points) .. " points\n"
            end

            local resultsString = tableConcat(resultsStrings)

            fileWrite(fileHandler, resultsString)
            fileClose(fileHandler)

            return resultsString
        end
    end,

    getAliveClans = function()
        local data = ddcw.data

        local aliveClans = {}
        
        local alivePlayers = derbyMapLoadedStateData.alivePlayers
        
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

        local alivePlayers = derbyMapLoadedStateData.alivePlayers
        
        if alivePlayers then
            for player in pairs(clan.players) do
                if alivePlayers[player] then
                    clanAlivePlayers[#clanAlivePlayers + 1] = player
                end
            end
        end

        return clanAlivePlayers
    end,

    getAlivePlayersCount = function()
        local alivePlayersCount = 0

        local alivePlayers = derbyMapLoadedStateData.alivePlayers
        
        if alivePlayers then
            for player in pairs(alivePlayers) do
                alivePlayersCount = alivePlayersCount + 1
            end
        end

        return alivePlayersCount
    end,

    getEventClanByTag = function(tag)
        local data = ddcw.data

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
        local data = ddcw.data

        local eventClans = data.eventClans

        for i = 1, #eventClans do
            local clan = eventClans[i]

            if clan.teamElement == teamElement then
                return clan
            end
        end
    end,

    getPlayerEventClan = function(player)
        local data = ddcw.data

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
        
            local eventHandlers = ddcw.eventHandlers
        
            addEventHandler("event1:ddcw:onEventStateSet", arenaElement, eventHandlers.onArenaDDCWEventStateSet)
        end,

        onArenaDestroy = function()
            local eventData = event1.data

            local arenaElement = eventData.arenaElement
        
            local eventHandlers = ddcw.eventHandlers
        
            removeEventHandler("event1:ddcw:onEventStateSet", arenaElement, eventHandlers.onArenaDDCWEventStateSet)

            ddcw.stop()
        end,

        ---

        onArenaDDCWEventStateSet = function(state)
            if state then
                ddcw.start()
            else
                ddcw.stop()
            end
        end,

        ---

        onArenaDDCWPlayerWasted = function(killer)
            if source == client then
                local data = ddcw.data

                if getElementData(data.coreElement, "state", false) == "live" then
                    if killer then
                        local clientClan = ddcw.getPlayerEventClan(client)

                        local killerClan = ddcw.getPlayerEventClan(killer)

                        if clientClan and killerClan then
                            local eventData = event1.data

                            local arenaElement = eventData.arenaElement

                            local pointsToChange

                            if clientClan == killerClan then
                                outputChatBox(getPlayerName(client) .. " #CCCCCChas been killed by #FFFFFF" .. getPlayerName(killer) .. " #FF0000(teamkill)", arenaElement, 255, 255, 255, true)

                                pointsToChange = -1
                            else
                                outputChatBox(getPlayerName(client) .. " #CCCCCChas been killed by #FFFFFF" .. getPlayerName(killer), arenaElement, 255, 255, 255, true)
                                
                                pointsToChange = 1
                            end

                            local oldPoints = getElementData(killer, "points", false) or 0

                            killerClan:setPlayerData(killer, "points", oldPoints + pointsToChange)
    
                            local oldKilled = getElementData(killer, "killed", false) or 0
    
                            killerClan:setPlayerData(killer, "killed", oldKilled + pointsToChange)

                            local oldMapPoints = getElementData(killer, "mapPoints", false) or 0

                            killerClan:setPlayerData(killer, "mapPoints", oldMapPoints + pointsToChange)
                        end
                    end

                    if not data.repairRacePickupsUnloaded then
                        local alivePlayersCount = ddcw.getAlivePlayersCount()

                        if alivePlayersCount == 2 then
                            local eventData = event1.data

                            triggerClientResourceEvent(resource, eventData.arenaElement, "event1:ddcw:onClientUnloadRepairRacePickups", eventData.sourceElement)

                            data.repairRacePickupsUnloaded = true
                        end
                    end

                    if not data.roundEnded then
                        local aliveClans = ddcw.getAliveClans()
    
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
                            
                            local clanAlivePlayers = ddcw.getAlivePlayersInClan(clan)
                            
                            local playersStrings = {}
    
                            for i = 1, #clanAlivePlayers do
                                local alivePlayer = clanAlivePlayers[i]
    
                                local oldPoints = getElementData(alivePlayer, "points", false) or 0
    
                                clan:setPlayerData(alivePlayer, "points", oldPoints + 1)
    
                                local oldSurvived = getElementData(alivePlayer, "survived", false) or 0
    
                                clan:setPlayerData(alivePlayer, "survived", oldSurvived + 1)
    
                                local playerName = getPlayerName(alivePlayer)
    
                                playersStrings[#playersStrings + 1] = stringRemoveHex(playerName)
    
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
    
                                local clanString = teamTag .. " " .. teamPoints
    
                                clansStrings[i] = clanString
    
                                local clanOutputString = hexColor .. teamTag .. " #FFFFFF" .. teamPoints
    
                                clansOutputStrings[i] = clanOutputString
                            end
    
                            local clansString = tableConcat(clansStrings, ", ")
    
                            local playersString = tableConcat(playersStrings, " ")
    
                            local thisMapData = { mapString, clansString, playersString }
                            
                            mapData[thisMapID] = thisMapData
    
                            local clanOutputString = tableConcat(clansOutputStrings, ", ")
    
                            outputChatBox("#CCCCCCCurrent result: " .. clanOutputString, arenaElement, 255, 255, 255, true)
    
                            data.roundEnded = true
                        end
                    end
                end
            end
        end,

        onArenaDerbyStateSet = function(state)
            local arenaDerbyStateFunction = ddcw.arenaDerbyStateFunctions[state]

            if arenaDerbyStateFunction then
                arenaDerbyStateFunction()
            end
        end,

        onArenaDerbyPlayerJoinSpawn = function()
            derbyMapLoadedStateData:removePlayerFromLoadQueue(source)
        end,

        onArenaPlayerJoin = function()
            ddcw.addEventClansDataSubscriber(source)

            triggerClientResourceEvent(resource, source, "event1:ddcw:onClientEventModeStart", source, ddcw.settings.teamsCount)

            local data = ddcw.data
    
            if hasObjectPermissionTo(source, "resource." .. resourceName .. ".mode_ddcw_referee", false) then
                silentExport("ep_core", "setPlayerTeam", source, data.refereeClan.teamElement)
            else
                silentExport("ep_core", "setPlayerTeam", source, data.spectatorsClan.teamElement)
            end
        end,

        onArenaPlayerQuit = function()
            silentExport("ep_core", "setPlayerTeam", source, nil)
            
            triggerClientResourceEvent(resource, source, "event1:ddcw:onClientEventModeStop", source)
            
            ddcw.removeEventClansDataSubscriber(source)
        end,

        onArenaPlayerTeamChange = function(oldTeam, newTeam)
            local data = ddcw.data
            
            local refereeClan = data.refereeClan
            local spectatorsClan = data.spectatorsClan

            refereeClan:removePlayer(source)
            spectatorsClan:removePlayer(source)

            local eventClans = data.eventClans

            for i = 1, #eventClans do
                local clan = eventClans[i]

                clan:setPlayerData(source, "mapPoints", nil)

                clan:removePlayer(source)
            end

            if newTeam then
                local eventClan = ddcw.getEventClanByTeamElement(newTeam)

                if eventClan then
                    eventClan:addPlayer(source)

                    eventClan:setPlayerData(source, "nickName", stringRemoveHex(getPlayerName(source)))

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
            local eventClan = ddcw.getPlayerEventClan(source)

            if eventClan then
                eventClan:setPlayerData(source, "nickName", stringRemoveHex(newNick))
            end
        end,

        onArenaPlayerLogin = function()
            if hasObjectPermissionTo(source, "resource." .. resourceName .. ".mode_ddcw_referee", false) then
                silentExport("ep_core", "setPlayerTeam", source, ddcw.data.refereeClan.teamElement)
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
                    local eventClan = ddcw.getEventClanByTag(tag)

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
                local spectatorsClan = ddcw.data.spectatorsClan

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_ddcw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    local arg = { ... }

                    if #arg > 0 then
                        local eventName = tableConcat(arg, " ")

                        setElementID(ddcw.data.coreElement, eventName)

                        outputChatBox("#CCCCCCEvent name has been set to #FFFFFF" .. eventName .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                    else
                        outputChatBox("#CCCCCCSyntax: #FFFFFF/" .. commandName .. " [name]", player, 255, 255, 255, true)
                    end
                end
            end
        end,

        setTeamName = function(player, commandName, tag, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_ddcw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = ddcw.getEventClanByTag(tag)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_ddcw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = ddcw.getEventClanByTag(tag)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_ddcw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = ddcw.getEventClanByTag(tag)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_ddcw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if tag then
                        local eventClan = ddcw.getEventClanByTag(tag)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_ddcw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if state then
                        local stateData = ddcw.states[state]

                        if stateData then
                            setElementData(ddcw.data.coreElement, "state", state)

                            local stateFunction = ddcw.stateFunctions[state]

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_ddcw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if round then
                        round = tonumber(round)

                        if round then
                            setElementData(ddcw.data.coreElement, "round", round)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_ddcw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if totalRounds then
                        totalRounds = tonumber(totalRounds)

                        if totalRounds then
                            setElementData(ddcw.data.coreElement, "totalRounds", totalRounds)

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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_ddcw_cmd_" .. commandName, false) then
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
                                local eventClan = ddcw.getPlayerEventClan(targetPlayer)
    
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

        setPlayerData = function(player, commandName, playerPartialName, dataName, dataValue)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_ddcw_cmd_" .. commandName, false) then
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
                                    local eventClan = ddcw.getPlayerEventClan(targetPlayer)
    
                                    if eventClan then
                                        eventClan:setPlayerData(targetPlayer, dataName, dataValue)
    
                                        outputChatBox(getPlayerName(targetPlayer) .. " #FFFFFF" .. dataName .. " #CCCCCCvalue has been set to #FFFFFF" .. tostring(dataValue) .. " #CCCCCCby #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
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
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_ddcw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    if playerPartialName then
                        local arenaPlayers = getElementChildren(arenaElement, "player")

                        local targetPlayer = getPlayerFromPartialName(arenaPlayers, playerPartialName)

                        if targetPlayer then
                            if dataName then
                                local eventClan = ddcw.getPlayerEventClan(targetPlayer)

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

        resetMode = function(player, commandName, ...)
            if hasObjectPermissionTo(player, "resource." .. resourceName .. ".mode_ddcw_cmd_" .. commandName, false) then
                local eventData = event1.data

                local arenaElement = eventData.arenaElement

                local playerArenaElement = event1.getPlayerArenaElement(player)

                if playerArenaElement == arenaElement then
                    ddcw.stop()

                    local dataFilePath = ddcw.settings.dataFilePath

                    if fileExists(dataFilePath) then
                        fileDelete(dataFilePath)
                    end

                    ddcw.start()

                    outputChatBox("#CCCCCCEvent mode has been reset by #FFFFFF" .. getPlayerName(player), arenaElement, 255, 255, 255, true)
                end
            end
        end
    },

    timers = {
        checkAlivePlayers = function()
            local data = ddcw.data

            local coreElement = data.coreElement
    
            if getElementData(coreElement, "state", false) == "live" then
                local arenaElement = event1.data.arenaElement

                local eventClans = data.eventClans

                local getAlivePlayersInClan = ddcw.getAlivePlayersInClan

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

    arenaDerbyStateFunctions = {
        ["map loaded"] = function()
            local eventData = event1.data

            local arenaElement = eventData.arenaElement

            local arenaPlayers = getElementChildren(arenaElement, "player")

            local getPlayerEventClan = ddcw.getPlayerEventClan

            local getPlayerVehicle = derby.getPlayerVehicle

            for i = 1, #arenaPlayers do
                local arenaPlayer = arenaPlayers[i]

                local eventClan = getPlayerEventClan(arenaPlayer)

                if not eventClan then
                    derbyMapLoadedStateData:removePlayerFromLoadQueue(arenaPlayer)
                else
                    local vehicle = getPlayerVehicle(arenaPlayer)

                    if isElement(vehicle) then
                        local r, g, b = getTeamColor(eventClan.teamElement)

                        setVehicleColor(vehicle, r, g, b)
                    end

                    eventClan:setPlayerData(arenaPlayer, "mapPoints", nil)
                end
            end

            local data = ddcw.data

            data.mapName = getElementData(arenaElement, "mapInfo", false).name

            local coreElement = data.coreElement

            if getElementData(coreElement, "state", false) == "live" then
                local oldRound = getElementData(coreElement, "round", false) or 0

                setElementData(coreElement, "round", oldRound + 1)
            end

            data.roundEnded = nil

            data.repairRacePickupsUnloaded = nil

            derbyMapLoadedStateData:killForcedCountdownTimer()
        end,

        ["running"] = function()
            --ddcw.data.checkAlivePlayersTimer = setTimer(ddcw.timers.checkAlivePlayers, 4000, 0)
        end,

        ["ended"] = function()
            derbyEndedStateData:killNextMapTimer()
        end,

        ["map unloading"] = function()
            local data = ddcw.data

            if isTimer(data.checkAlivePlayersTimer) then
                killTimer(data.checkAlivePlayersTimer)
            end

            data.checkAlivePlayersTimer = nil
        end
    },

    stateFunctions = {
        ["ended"] = function()
            local resultsString = ddcw.saveResults()

            if resultsString then
                local eventData = event1.data

                local refereePlayers = {}

                local arenaPlayers = getElementChildren(eventData.arenaElement, "player")

                local permissionString = "resource." .. resourceName .. ".mode_ddcw_referee"

                for i = 1, #arenaPlayers do
                    local arenaPlayer = arenaPlayers[i]

                    if hasObjectPermissionTo(arenaPlayer, permissionString, false) then
                        refereePlayers[#refereePlayers + 1] = arenaPlayer
                    end
                end

                if #refereePlayers > 0 then
                    triggerClientResourceEvent(resource, refereePlayers, "event1:ddcw:onClientArenaResultsSaved", eventData.sourceElement, resultsString)
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

event1.modes.ddcw = ddcw

addEvent("event1:onArenaCreated")
addEvent("event1:onArenaDestroy")

addEvent("event1:onPlayerArenaJoin")
addEvent("event1:onPlayerArenaQuit")

addEvent("onPlayerTeamChange")

addEvent("event1:derby:onArenaStateSet")
addEvent("event1:derby:onPlayerJoinSpawn")
addEvent("event1:derby:onPlayerReachedHunter")
addEvent("event1:derby:onPlayerWasted")

addEvent("event1:ddcw:onEventStateSet")

addEvent("event1:ddcw:onPlayerWasted", true)

do
    local eventHandlers = ddcw.eventHandlers

    addEventHandler("event1:onArenaCreated", resourceRoot, eventHandlers.onArenaCreated)
    addEventHandler("event1:onArenaDestroy", resourceRoot, eventHandlers.onArenaDestroy)
end