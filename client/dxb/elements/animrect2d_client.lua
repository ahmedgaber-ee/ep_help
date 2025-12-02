local utils = dxb.utils
local point2D = dxb.point2D
local animation = dxb.animation

local math = utils.math
local isPointInRectangle = math.isPointInRectangle

local animRect2D

animRect2D = {
    new = function(x, y, sx, sy, animSpeed, animCubicbezier, events, custom, eventArg)
        local object = {}

        object.events = events or {}
        object.custom = custom or {}
        object.eventArg = eventArg or object

        for i, v in pairs(animRect2D.functions) do
            object[i] = v
        end

        object.position = point2D(x, y, nil, nil, object)
        object.size = point2D(sx, sy, nil, nil, object):setParent(object.position):setPositionRelative(sx, sy)
        object.animation = animation(false, animSpeed, animCubicbezier, 0, 255, animRect2D.events.animation, nil, object)

        object:triggerEvent("onCreate")

        return object
    end,

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
        isPointIn = function(self, px, py)
            local size = self.size
            local position = self.position

            return isPointInRectangle(px, py, position.x, position.y, size.rx, size.ry)
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

            return self
        end,

        setSizeAbsoluteY = function(self, y)
            self.size:setPositionAbsoluteY(y)

            return self
        end,

        setSizeAbsolute = function(self, x, y)
            self.size:setPositionAbsolute(x, y)

            return self
        end,

        setSizeRelativeX = function(self, rx)
            self.size:setPositionRelativeX(rx)

            return self
        end,

        setSizeRelativeY = function(self, ry)
            self.size:setPositionRelativeY(ry)

            return self
        end,

        setSizeRelative = function(self, rx, ry)
            self.size:setPositionRelative(rx, ry)

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

        triggerEvent = function(self, eventName, ...)
            local event = self.events[eventName]

            if event then
                event(self.eventArg, ...)
            end

            return self
        end
    }
}

setmetatable(animRect2D, {
    __call = function(t, ...)
        return animRect2D.new(...)        
    end
})

dxb.animRect2D = animRect2D