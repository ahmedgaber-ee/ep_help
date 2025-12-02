local mathAbs = math.abs

local epsilon = 1e-5

local cubicbezier

cubicbezier = {
    new = function(p1x, p1y, p2x, p2y)
        local object = {}

        for i, v in pairs(cubicbezier.functions) do
            object[i] = v
        end

        object.cx = 3 * p1x
        object.bx = 3 * (p2x - p1x) - object.cx
        object.ax = 1 - object.cx - object.bx
        object.cy = 3 * p1y
        object.by = 3 * (p2y - p1y) - object.cy
        object.ay = 1 - object.cy - object.by

        return object
    end,

    functions = {
        getCurveX = function(self, t)
            return ((self.ax * t + self.bx) * t + self.cx) * t
        end,

        getCurveY = function(self, t)
            return ((self.ay * t + self.by) * t + self.cy) * t
        end,

        getCurveDerivativeX = function(self, t)
            return (3 * self.ax * t + 2 * self.bx) * t + self.cx
        end,

        calculateCurveX = function(self, x) 
            local t0, t1, t2, x2, d2

            t2 = x

            for i = 1, 32 do
                x2 = self:getCurveX(t2) - x

                if (mathAbs(x2) < epsilon) then
                    return t2
                end

                d2 = self:getCurveDerivativeX(t2)

                if (mathAbs(d2) < epsilon) then
                    break
                end

                t2 = t2 - x2 / d2
            end
            
            t0, t1, t2 = 0, 1, x

            if (t2 < t0) then return t0 end
            if (t2 > t1) then return t1 end

            while (t0 < t1) do
                x2 = self:getCurveX(t2)

                if (mathAbs(x2 - x) < epsilon) then
                    return t2
                end

                if (x > x2) then
                    t0 = t2
                else 
                    t1 = t2
                end

                t2 = (t1 - t0) * 0.5 + t0
            end

            return t2
        end,

        ease = function(self, t)
            if t < 0 then return 0 end
            if t > 1 then return 1 end
            
            return self:getCurveY(self:calculateCurveX(t))
        end
    },

    linear = function() return cubicbezier.new(0.25, 0.25, 0.75, 0.75) end,
    inSine = function() return cubicbezier.new(0.47, 0, 0.745, 0.715) end,
    outSine = function() return cubicbezier.new(0.39, 0.575, 0.565, 1) end,
    inOutSine = function() return cubicbezier.new(0.445, 0.05, 0.55, 0.95) end,
    inQuad = function() return cubicbezier.new(0.55, 0.085, 0.68, 0.53) end,
    outQuad = function() return cubicbezier.new(0.25, 0.46, 0.45, 0.94) end,
    inOutQuad = function() return cubicbezier.new(0.455, 0.03, 0.515, 0.955) end,
    inCubic = function() return cubicbezier.new(0.55, 0.055, 0.675, 0.19) end,
    outCubic = function() return cubicbezier.new(0.215, 0.61, 0.355, 1) end,
    inOutCubic = function() return cubicbezier.new(0.645, 0.045, 0.355, 1) end,
    inQuart = function() return cubicbezier.new(0.895, 0.03, 0.685, 0.22) end,
    outQuart = function() return cubicbezier.new(0.165, 0.84, 0.44, 1) end,
    inOutQuart = function() return cubicbezier.new(0.77, 0, 0.175, 1) end,
    inQuint = function() return cubicbezier.new(0.755, 0.05, 0.855, 0.06) end,
    outQuint = function() return cubicbezier.new(0.23, 1, 0.32, 1) end,
    inOutQuint = function() return cubicbezier.new(0.86, 0, 0.07, 1) end,
    inExpo = function() return cubicbezier.new(0.95, 0.05, 0.795, 0.035) end,
    outExpo = function() return cubicbezier.new(0.19, 1, 0.22, 1) end,
    inOutExpo = function() return cubicbezier.new(1, 0, 0, 1) end,
    inCirc = function() return cubicbezier.new(0.6, 0.04, 0.98, 0.335) end,
    outCirc = function() return cubicbezier.new(0.075, 0.82, 0.165, 1) end,
    inOutCirc = function() return cubicbezier.new(0.785, 0.135, 0.15, 0.86) end,
    inBack = function() return cubicbezier.new(0.6, -0.28, 0.735, 0.045) end,
    outBack = function() return cubicbezier.new(0.175, 0.885, 0.32, 1.275) end,
    inOutBack = function() return cubicbezier.new(0.68, -0.55, 0.265, 1.55) end
}

setmetatable(cubicbezier, {
    __call = function(t, ...)
        return cubicbezier.new(...)        
    end
})

dxb.cubicbezier = cubicbezier