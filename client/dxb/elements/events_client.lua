dxb.events = (
    function()
        local mathMin = math.min
        local mathMax = math.max

        local tableInsert = table.insert
        local tableRemove = table.remove

        local clamp = function(v, a, b)
            return mathMax(a, mathMin(v, b))
        end

        local addedEvents = {}

        local mainHandlerFunction

        mainHandlerFunction = function(...)
            local addedEvent = addedEvents[eventName][this]

            local i, addedEventLen = 1, #addedEvent

            repeat
                if addedEvent[i] == true then
                    tableRemove(addedEvent, i)

                    addedEventLen = addedEventLen - 1

                    if addedEventLen == 0 then
                        removeEventHandler(eventName, this, mainHandlerFunction)

                        addedEvents[eventName] = nil
                    end
                else
                    local addedEventData = addedEvent[i]

                    addedEventData[1](addedEventData[2], ...)

                    i = i + 1
                end
            until i > addedEventLen
        end

        local getEventIndex = function(eventName, attachedTo, handlerFunction, arg)
            local eventElements = addedEvents[eventName]

            if eventElements then
                local eventData = eventElements[attachedTo]

                if eventData then
                    for i = #eventData, 1, -1 do
                        local data = eventData[i]

                        if data ~= true and data[1] == handlerFunction and data[2] == arg then
                            return i
                        end
                    end
                end
            end
        end

        local addEvent = function(eventName, attachedTo, handlerFunction, propagate, priority, arg)
            local eventElements = addedEvents[eventName]

            if eventElements then
                local eventData = eventElements[attachedTo]

                if eventData then
                    local eventIndex = getEventIndex(eventName, attachedTo, handlerFunction, arg)
    
                    if not eventIndex then
                        eventData[#eventData + 1] = { handlerFunction, arg }
                    end
                else
                    eventElements[attachedTo] = { { handlerFunction, arg } }
                end
            else
                addedEvents[eventName] = { [attachedTo] = { { handlerFunction, arg } } }

                addEventHandler(eventName, attachedTo, mainHandlerFunction, propagate, priority)
            end
        end

        local removeEvent = function(eventName, attachedTo, handlerFunction, arg)
            local eventElements = addedEvents[eventName]

            if eventElements then
                local eventData = eventElements[attachedTo]

                if eventData then
                    local eventIndex = getEventIndex(eventName, attachedTo, handlerFunction, arg)
    
                    if eventIndex then
                        eventData[eventIndex] = true
                    end
                end
            end
        end

        local setEventLayer = function(eventName, attachedTo, handlerFunction, arg, layer)
            local eventElements = addedEvents[eventName]

            if eventElements then
                local eventData = eventElements[attachedTo]

                if eventData then
                    local eventIndex = getEventIndex(eventName, attachedTo, handlerFunction, arg)
    
                    if eventIndex then
                        local eventDataLen = #eventData

                        layer = clamp(layer, 1, addedEventLen)

                        local tmp = eventData[eventIndex]
            
                        tableRemove(eventData, eventIndex)
                        tableInsert(eventData, eventDataLen - layer + 1, tmp)
                    end
                end
            end
        end

        return { addEvent = addEvent, removeEvent = removeEvent, setEventLayer = setEventLayer }
    end
)()