local clan

clan = {
    new = function(name, r, g, b, events, custom, eventArg)
        local clanObject = {}
        
        clanObject.events = events or {}
        clanObject.custom = custom or {}
        clanObject.eventArg = eventArg or clanObject
        
        for i, v in pairs(clan.functions) do
            clanObject[i] = v
        end

        local teamElement = createTeam(name, r, g, b) or getTeamFromName(name)

        clanObject.teamElement = teamElement

        clanObject.players = {}

        clanObject.elementData = {}
        clanObject.serialData = {}
        clanObject.subscribers = {}

        clanObject:triggerEvent("onCreate")
        
        return clanObject
    end,

    functions = {
        addPlayer = function(self, player)
            local players = self.players

            if not players[player] then
                players[player] = true

                local serial = getPlayerSerial(player)

                if serial then
                    local serialData = self.serialData

                    local data = serialData[serial]

                    if data then
                        local setElementData = self.setElementData

                        for dataName, value in pairs(data) do
                            setElementData(self, player, dataName, value)
                        end
                    else
                        serialData[serial] = {}
                    end
                end
            end
        end,

        removePlayer = function(self, player)
            local players = self.players
            
            if players[player] then
                local elementData = self.elementData

                local data = elementData[player]

                if data then
                    local setElementData = self.setElementData

                    for dataName in pairs(data) do
                        setElementData(self, player, dataName, nil)
                    end

                    elementData[player] = nil
                end

                players[player] = nil
            end
        end,

        setElementData = function(self, element, dataName, value)
            local elementData = self.elementData

            local thisElementData = elementData[element]

            if not thisElementData then
                local thisElementNewData = {}

                thisElementData = thisElementNewData

                elementData[element] = thisElementNewData
            end

            local oldData = getElementData(element, dataName, false)

            if oldData ~= value then
                setElementData(element, dataName, value--[[ , "subscribe" *]])

                if value then
                    if not oldData then
                        for subscriber in pairs(self.subscribers) do
                            addElementDataSubscriber(element, dataName, subscriber)
                        end
                    end
                    
                    thisElementData[dataName] = true
                else
                    for subscriber in pairs(self.subscribers) do
                        removeElementDataSubscriber(element, dataName, subscriber)
                    end
                    
                    thisElementData[dataName] = nil

                    if not next(thisElementData) then
                        elementData[element] = nil
                    end
                end
            end
        end,

        setPlayerData = function(self, player, dataName, value)
            local players = self.players
            
            if players[player] then
                self:setElementData(player, dataName, value)

                local serial = getPlayerSerial(player)

                if serial then
                    self.serialData[serial][dataName] = value
                end
            end
        end,

        addAllElementDataSubscriber = function(self, subscriber)
            for element, data in pairs(self.elementData) do
                for dataName in pairs(data) do
                    addElementDataSubscriber(element, dataName, subscriber)
                end
            end

            self.subscribers[subscriber] = true
        end,

        removeAllElementDataSubscriber = function(self, subscriber)
            for element, data in pairs(self.elementData) do
                for dataName in pairs(data) do
                    removeElementDataSubscriber(element, dataName, subscriber)
                end
            end

            self.subscribers[subscriber] = nil
        end,

        destroy = function(self)
            self:triggerEvent("onDestroy")

            local setElementData = self.setElementData
            
            for element, data in pairs(self.elementData) do
                for dataName in pairs(data) do
                    setElementData(self, element, dataName, nil)
                end
            end

            local teamElement = self.teamElement

            if isElement(teamElement) then
                destroyElement(teamElement)
            end
        end,

        -- private

        triggerEvent = function(self, eventName, ...)
            local event = self.events[eventName]

            if event then
                event(self.eventArg, ...)
            end

            return self
        end
    }
}

setmetatable(clan, {
    __call = function(t, ...)
        return clan.new(...)        
    end
})

event1.addons.clan = clan