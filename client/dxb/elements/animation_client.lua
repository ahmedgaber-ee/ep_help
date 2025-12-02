local cubicbezierLinear = dxb.cubicbezier.linear()

local animation

animation = {
    new = function(state, speed, cubicbezier, min, max, events, custom, eventArg)
        local object = {}

        object.state = state or false
        object.speed = speed or 1000
        object.cubicbezier = cubicbezier or cubicbezierLinear
        object.min = min or 0
        object.max = max or 1

        object.events = events or {}
        object.custom = custom or {}
        object.eventArg = eventArg or object

        for i, v in pairs(animation.functions) do
            object[i] = v
        end

        object.progress = object.min
        object.tick = getTickCount()
        object.startValue = object.min
        object.endValue = object.state and object.max or object.min
        object.fadedIn = not object.state
        object.parent = nil
        object.children = {}
        object.hasChildren = false
        
        object:triggerEvent("onCreate")

        return object
    end,

    stateEvents = {
        [true] = "onStartFadingIn",
        [false] = "onStartFadingOut"
    },

    functions = {
        updateEasingStates = function(self)
            local progress = self.progress

            if progress > self.min then
                if not self.fadedIn then
                    if self.state then
                        self:triggerEvent("onFadingIn")
                    end
                    
                    if progress == self.max then
                        self:triggerEvent("onFadedIn")

                        self.fadedIn = true
                    end
                else
                    if not self.state then
                        self:triggerEvent("onFadingOut")
                    end
                end

                self:triggerEvent("onRender")
            else
                if self.fadedIn then
                    self:triggerEvent("onFadedOut")

                    self.fadedIn = false
                end
            end

            return self
        end,

        updateEasing = function(self)
            local progress = self.startValue + (self.endValue - self.startValue) * self.cubicbezier:ease((getTickCount() - self.tick)/self.speed)

            self.progress = progress

            return self:updateEasingStates()
        end,

        setProgress = function(self, progress)
            progress = progress or self.progress

            self.progress = progress

            self:updateEasingStates()

            if self.hasChildren then
                for child in pairs(self.children) do
                    child:setProgress(progress)
                end
            end

            return self
        end,

        setState = function(self, state)
            state = state and true or false

            if state ~= self.state then
                self.state = state
                self.tick = getTickCount()
                self.startValue = self.progress
                self.endValue = state and self.max or self.min
                self.fadedIn = not state
    
                self:triggerEvent(animation.stateEvents[state])
    
                if self.hasChildren then
                    for child in pairs(self.children) do
                        child:setState(state)
                    end
                end
            end

            return self
        end,

        setSpeed = function(self, speed)
            speed = speed or self.speed

            self.speed = speed

            return self
        end,

        setCubicbezier = function(self, cb)
            cb = cb or self.cubicbezier

            self.cubicbezier = cb

            return self
        end,

        setParent = function(self, parent)
            self.parent = parent

            parent.children[self] = true
            parent.hasChildren = true

            return self:setState(parent.state)
        end,

        removeParent = function(self)
            local parent = self.parent

            if parent then
                self.parent = nil
    
                parent.children[self] = nil
                parent.hasChildren = next(parent.children)
            end

            return self
        end,

        destroy = function(self)
            self:removeParent():triggerEvent("ondestroy")
        end,
        
        -- private

        triggerEvent = function(self, eventName, ...)
            local event = self.events[eventName]

            if event then
                event(self.eventArg, ...)
            end

            return self
        end
    },
}

setmetatable(animation, {
    __call = function(t, ...)
        return animation.new(...)        
    end
})

dxb.animation = animation