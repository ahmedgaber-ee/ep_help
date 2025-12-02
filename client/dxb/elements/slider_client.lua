local utils = dxb.utils
local events = dxb.events
local point2D = dxb.point2D
local animation = dxb.animation

local addEvent = events.addEvent
local removeEvent = events.removeEvent

local scx, scy = utils.scx, utils.scy

local math = utils.math
local clamp = math.clamp
local isPointInRectangle = math.isPointInRectangle

local slider

slider = {
    new = function(x, y, sx, sy, animSpeed, animCubicbezier, type, startValue, endValue, barSize, events, custom, eventArg)
        local object = {}

        object.type = type or "vertical"
        object.startValue = startValue or 0
        object.endValue = endValue or 1
        object.barSize = barSize or 0

        object.events = events or {}
        object.custom = custom or {}
        object.eventArg = eventArg or object

        for i, v in pairs(slider.functions) do
            object[i] = v
        end

        object.position = point2D(x, y, nil, nil, object)
        object.size = point2D(sx, sy, nil, nil, object):setParent(object.position):setPositionRelative(sx, sy)
        object.animation = animation(false, animSpeed, animCubicbezier, 0, 255, slider.events.animation, nil, object)

        object.offset = 0
        object.progress = 0
        object.value = object.startValue
        
        object.pressed = false
        object.cursorOffset = 0
        object.endValueDiff = object.endValue - object.startValue
        object.maxOffset = slider.types[object.type].getMaxOffset(object)

        object:triggerEvent("onCreate")

        return object
    end,

    types = {
        vertical = {
            getMaxOffset = function(self)
                return self.size.ry - self.barSize
            end,

            getCursorOffset = function(self)
                local cx, cy = getCursorPosition()

                return cy*scy - (self.offset + self.position.y)
            end,

            getBarOffset = function(self)
                local cx, cy = getCursorPosition()

                return clamp(cy*scy - self.position.y - self.cursorOffset, 0, self.maxOffset)
            end,

            getClampedBarSize = function(self)
                return clamp(self.barSize, 0, self.size.ry)
            end,

            isPointInBar = function(self, x, y)
                local position = self.position

                return isPointInRectangle(x, y, position.x, position.y + self.offset, self.size.rx, self.barSize)
            end,

            updateOnSetSizeX = function(self)
                return self
            end,

            updateOnSetSizeY = function(self)
                return self:updateOffset()
            end
        },
    
        horizontal = {
            getMaxOffset = function(self)
                return self.size.rx - self.barSize
            end,

            getCursorOffset = function(self)
                local cx = getCursorPosition()

                return cx*scx - (self.offset + self.position.x)
            end,

            getBarOffset = function(self)
                local cx = getCursorPosition()

                return clamp(cx*scx - self.position.x - self.cursorOffset, 0, self.maxOffset)
            end,

            getClampedBarSize = function(self)
                return clamp(self.barSize, 0, self.size.rx)
            end,

            isPointInBar = function(self, x, y)
                local position = self.position

                return isPointInRectangle(x, y, position.x + self.offset, position.y, self.barSize, self.size.ry)
            end,

            updateOnSetSizeX = function(self)
                return self:updateOffset()
            end,

            updateOnSetSizeY = function(self)
                return self
            end
        }
    },

    eventHandlers = {
        onClick = function(self, mButton, mState, ax, ay, wx, wy, wz, clickedElement)
            if mButton == "left" then
                if mState == "down" then
                    if self:isPointInBar(ax, ay) then
                        local onClientRender = slider.eventHandlers.onClientRender

                        self.cursorOffset = slider.types[self.type].getCursorOffset(self)
                        self.pressed = true

                        addEvent("onClientRender", root, onClientRender, nil, nil, self)

                        self:triggerEvent("onBarPressed")

                        onClientRender(self)
                    end
                else
                    if self.pressed then
                        self.pressed = false
                        
                        removeEvent("onClientRender", root, slider.eventHandlers.onClientRender, self)

                        self:triggerEvent("onBarReleased")
                    end
                end
            end
        end,

        onClientRender = function(self, x, y, ax, ay, wx, wy, wz)
            local typeFunc = slider.types[self.type]

            local offset = typeFunc.getBarOffset(self)
            local progress = offset/self.maxOffset
            local value = progress*self.endValueDiff + self.startValue

            self.offset, self.progress, self.value = offset, progress, value

            self:triggerEvent("onCursorMoveBar", offset, progress, value)
        end
    },

    events = {
        animation = {
            onStartFadingIn = function(self)
                self:triggerEvent("onAnimationStartFadingIn")
            end,

            onStartFadingOut = function(self)
                self:triggerEvent("onAnimationStartFadingOut")
            end,

            onFadingIn = function(self)
                self:triggerEvent("onAnimationFadingIn")
            end,

            onFadingOut = function(self)
                self:triggerEvent("onAnimationFadingOut")
            end,

            onFadedIn = function(self)
                self:triggerEvent("onAnimationFadedIn")
            end,

            onFadedOut = function(self)
                self:triggerEvent("onAnimationFadedOut")
            end,

            onRender = function(self)
                self:triggerEvent("onAnimationRender")
            end
        }
    },

    functions = {
        setOffset = function(self, offset)
            offset = clamp(offset, 0, self.maxOffset)

            local progress = offset/self.maxOffset

            self.offset = offset
            self.progress = progress
            self.value = progress*self.endValueDiff + self.startValue

            return self
        end,

        setProgress = function(self, progress)
            progress = clamp(progress, 0, 1)

            self.offset = progress*self.maxOffset
            self.progress = progress
            self.value = progress*self.endValueDiff + self.startValue

            return self
        end,

        setValue = function(self, value)
            value = clamp(value, self.startValue, self.endValue)

            local progress = (value - self.startValue)/self.endValueDiff

            self.offset = progress*self.maxOffset
            self.progress = progress
            self.value = value

            return self
        end,

        setBarSize = function(self, size)
            local typeFunc = slider.types[self.type]

            self.barSize = size or self.barSize
            self.barSize = typeFunc.getClampedBarSize(self)

            local maxOffset = typeFunc.getMaxOffset(self)
            local progress = self.offset/maxOffset

            self.offset = progress*maxOffset
            self.progress = progress
            self.value = progress*self.endValueDiff + self.startValue

            self.maxOffset = maxOffset

            return self
        end,

        isPointIn = function(self, px, py)
            local size = self.size
            local position = self.position

            return isPointInRectangle(px, py, position.x, position.y, size.rx, size.ry)
        end,

        isPointInBar = function(self, px, py)
            return slider.types[self.type].isPointInBar(self, px, py)
        end,

        destroy = function(self)
            self:triggerEvent("onDestroy")

            self.size:destroy()
            self.position:destroy()
            self.animation:destroy()
        end,

        -- wrapper

        setPositionAbsoluteX = function(self, x)
            self.position:setPositionAbsoluteX(x)

            return self
        end,

        setPositionAbsoluteY = function(self, y)
            self.position:setPositionAbsoluteY(y)

            return self
        end,

        setPositionAbsolute = function(self, x, y)
            self.position:setPositionAbsolute(x, y)

            return self
        end,

        setPositionRelativeX = function(self, rx)
            self.position:setPositionRelativeX(rx)

            return self
        end,

        setPositionRelativeY = function(self, ry)
            self.position:setPositionRelativeY(ry)

            return self
        end,

        setPositionRelative = function(self, rx, ry)
            self.position:setPositionRelative(rx, ry)

            return self
        end,

        setPositionParent = function(self, parent)
            self.position:setParent(parent)

            return self
        end,

        removePositionParent = function(self)
            self.position:removeParent()

            return self
        end,

        setSizeAbsoluteX = function(self, x)
            self.size:setPositionAbsoluteX(x)

            return slider.types[self.type].updateOnSetSizeX(self)
        end,

        setSizeAbsoluteY = function(self, y)
            self.size:setPositionAbsoluteY(y)

            return slider.types[self.type].updateOnSetSizeY(self)
        end,

        setSizeAbsolute = function(self, x, y)
            self.size:setPositionAbsolute(x, y)

            local typeFunc = slider.types[self.type]

            typeFunc.updateOnSetSizeX(self)
            typeFunc.updateOnSetSizeY(self)

            return self
        end,

        setSizeRelativeX = function(self, rx)
            self.size:setPositionRelativeX(rx)

            return slider.types[self.type].updateOnSetSizeX(self)
        end,

        setSizeRelativeY = function(self, ry)
            self.size:setPositionRelativeY(ry)

            return slider.types[self.type].updateOnSetSizeY(self)
        end,

        setSizeRelative = function(self, rx, ry)
            self.size:setPositionRelative(rx, ry)

            local typeFunc = slider.types[self.type]

            typeFunc.updateOnSetSizeX(self)
            typeFunc.updateOnSetSizeY(self)

            return self
        end,

        setSizeParent = function(self, parent)
            self.size:setParent(parent)

            return self
        end,

        removeSizeParent = function(self)
            self.size:removeParent()

            return self
        end,

        setAnimationProgress = function(self, progress)
            self.animation:setProgress(progress)

            return self
        end,

        setAnimationState = function(self, state)
            self.animation:setState(state)

            return self
        end,

        setAnimationSpeed = function(self, speed)
            self.animation:setState(speed)
            
            return self
        end,

        setAnimationCubicbezier = function(self, cb)
            self.animation:setCubicbezier(cb)

            return self
        end,

        setAnimationParent = function(self, parent)
            self.animation:setParent(parent)

            return self
        end,

        removeAnimationParent = function(self)
            self.animation:removeParent()
            
            return self
        end,

        -- private

        updateOffset = function(self)
            local maxOffset = slider.types[self.type].getMaxOffset(self)
    
            self.offset = self.progress*maxOffset
            self.maxOffset = maxOffset

            return self
        end,

        triggerEvent = function(self, eventName, ...)
            local event = self.events[eventName]

            if event then
                event(self.eventArg, ...)
            end

            return self
        end
    }
}

setmetatable(slider, {
    __call = function(t, ...)
        return slider.new(...)        
    end
})

dxb.slider = slider