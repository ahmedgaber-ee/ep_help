local scx, scy = guiGetScreenSize()

local mathMin = math.min
local mathMax = math.max

local clamp = function(v, a, b)
    return mathMax(a, mathMin(v, b))
end

local isPointInRectangle = function(px, py, x, y, sx, sy)
    return (px + 1 > x and px - 1 < x + sx) and (py + 1 > y and py - 1 < y + sy)
end

local isCursorInRectangle = function(x, y, sx, sy)
    if not isCursorShowing() then
        return
    end

    local cx, cy = getCursorPosition()

    return isPointInRectangle(cx*scx, cy*scy, x, y, sx, sy)
end

local tableInsertValues = function(table, startPos, values)
    local valuesLen = #values

    for i = #table, startPos, -1 do
        table[i + valuesLen] = table[i]
    end

    for i = 1, valuesLen do
        table[startPos + (i - 1)] = values[i]
    end
end

local tableRemoveValues = function(table, startPos, endPos)
    local tableLen = #table
    local count = endPos - startPos + 1

    for i = endPos + 1, tableLen do
        table[i - count] = table[i]
    end

    for i = tableLen, tableLen - count + 1, -1 do
        table[i] = nil
    end
end

local tableSetValueIndexLeft = function(table, index, newIndex)
    local tmp = table[index]

    table[index] = nil

    for i = index - 1, newIndex, -1 do
        table[i + 1] = table[i]
    end

    table[newIndex] = tmp
end

local tableSetValueIndexRight = function(table, index, newIndex)
    local tmp = table[index]

    table[index] = nil

    for i = index + 1, newIndex do
        table[i - 1] = table[i]
    end

    table[newIndex] = tmp
end

local tableCopy

tableCopy = function(table)
    local copy = {}

    for i, v in pairs(table) do
        copy[i] = type(v) == "table" and tableCopy(v) or v
    end

    setmetatable(copy, getmetatable(table))

    return copy
end

local tableShallowCopy = function(table)
    local copy = {}

    for i, v in pairs(table) do
        copy[i] = v
    end

    return copy
end

dxb.utils = { 
    scx = scx, scy = scy,
    
    math = {
        clamp = clamp, 
        isPointInRectangle = isPointInRectangle, 
        isCursorInRectangle = isCursorInRectangle
    },

    table = {
        copy = tableCopy, 
        shallowCopy = tableShallowCopy,
        insertValues = tableInsertValues,
        setValueIndexLeft = tableSetValueIndexLeft,
        setValueIndexRight = tableSetValueIndexRight
    }
}