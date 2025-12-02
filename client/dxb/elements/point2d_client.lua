local point2D

point2D = {
    new = function(x, y, events, custom, eventArg)
        local object = {}

        object.x, object.y = x or 0, y or 0

        object.events = events or {}
        object.custom = custom or {}
        object.eventArg = eventArg or object

        for i, v in pairs(point2D.functions) do
            object[i] = v
        end

        object.parent = nil
        object.children = {}
        object.hasChildren = false
        object.rx, object.ry = object.x, object.y
        
        object:triggerEvent("onCreate")

        return object
    end,

    functions = {
        setPositionAbsoluteX = function(self, x)
            return self:updatePositionAbsolute("x", "rx", x)
        end,

        setPositionAbsoluteY = function(self, y)
            return self:updatePositionAbsolute("y", "ry", y)
        end,

        setPositionRelativeX = function(self, rx)
            return self:updatePositionRelative("x", "rx", rx)
        end,

        setPositionRelativeY = function(self, ry)
            return self:updatePositionRelative("y", "ry", ry)
        end,

        setPositionAbsolute = function(self, x, y)
            return self:updatePositionAbsolute("x", "rx", x):updatePositionAbsolute("y", "ry", y)
        end,

        setPositionRelative = function(self, rx, ry)
            return self:updatePositionRelative("x", "rx", rx):updatePositionRelative("y", "ry", ry)
        end,

        setParent = function(self, parent)
            self.parent = parent

            parent.children[self] = true
            parent.hasChildren = true

            return self
        end,

        removeParent = function(self)
            local parent = self.parent

            if parent then
                self.parent = nil
    
                parent.children[self] = nil
                parent.hasChildren = next(parent.children) and true or false
            end

            return self
        end,
        
        destroy = function(self)
            self:removeParent():triggerEvent("onDestroy")
        end,
        
        -- private

        updatePositionAbsolute = function(self, posAbs, posRel, v)
            v = v or self[posAbs]

            local parent = self.parent
            
            if self.hasChildren then
                local ov = self[posAbs]

                self[posAbs], self[posRel] = v, parent and v - parent[posAbs] or v
                
                for child in pairs(self.children) do
                    child:updatePositionAbsolute(posAbs, posRel, child[posAbs] + (v - ov))
                end
            else
                self[posAbs], self[posRel] = v, parent and v - parent[posAbs] or v
            end

            return self
        end,

        updatePositionRelative = function(self, posAbs, posRel, v)
            v = v or self[posRel]

            local parent = self.parent

            if self.hasChildren then
                local orv = self[posRel]
                
                self[posRel], self[posAbs] = v, parent and parent[posAbs] + v or v

                for child in pairs(self.children) do
                    child:updatePositionRelative(posAbs, posRel, child[posRel] + (v - orv))
                end
            else
                self[posRel], self[posAbs] = v, parent and parent[posAbs] + v or v
            end

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

setmetatable(point2D, {
    __call = function(t, ...)
        return point2D.new(...)        
    end
})

dxb.point2D = point2D
