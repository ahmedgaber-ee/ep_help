local mathMin = math.min
local mathMax = math.max

local tableInsert = table.insert
local tableRemove = table.remove

local utils = dxb.utils
local slider = dxb.slider
local point2D = dxb.point2D
local animation = dxb.animation

local math = utils.math
local clamp = math.clamp
local isPointInRectangle = math.isPointInRectangle

local cubicbezierLinear = dxb.cubicbezier.linear()

local itemlist

itemlist = {
    new = function(x, y, sx, sy, animSpeed, animCubicbezier, events, custom, eventArg)
        local object = {}

        object.events = events or {}
        object.custom = custom or {}
        object.eventArg = eventArg or object

        for i, v in pairs(itemlist.functions) do
            object[i] = v
        end

        object.position = point2D(x, y, nil, nil, object)
        object.size = point2D(sx, sy, nil, nil, object):setParent(object.position):setPositionRelative(sx, sy)
        object.animation = animation(false, animSpeed, animCubicbezier, 0, 255, itemlist.events.animation, nil, object)
        
        object.data = {
            horizontal = { up = {}, down = {}, upCellIndex = 1, downCellIndex = 1, offset = 0, maxOffset = 0, totalSize = 0, size = object.size.rx, pos = "x", posSize = "sx", counterpart = "vertical", type = "horizontal" },
            vertical = { up = {}, down = {}, upCellIndex = 1, downCellIndex = 1, offset = 0, maxOffset = 0, totalSize = 0, size = object.size.ry, pos = "y", posSize = "sy", counterpart = "horizontal", type = "vertical" }
        }
        
        object.activeCells = {}

        object:triggerEvent("onCreate")

        return object
    end,
    
    eventNames = {
        horizontal = {
            onCreate = "onSliderCreateHorizontal",
            onDestroy = "onSliderDestroyHorizontal",
            onScrollAnimationUpdate = "onScrollAnimationUpdateHorizontal",
            onScrollAnimationUpdateStart = "onScrollAnimationUpdateStartHorizontal",
            onScrollAnimationUpdateEnd = "onScrollAnimationUpdateEndHorizontal"
        },

        vertical = {
            onCreate = "onSliderCreateVertical",
            onDestroy = "onSliderDestroyVertical",
            onScrollAnimationUpdate = "onScrollAnimationUpdateVertical",
            onScrollAnimationUpdateStart = "onScrollAnimationUpdateStartVertical",
            onScrollAnimationUpdateEnd = "onScrollAnimationUpdateEndVertical"
        }
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
        },

        slider = {
            horizontal = {
                onAnimationStartFadingIn = function(self)
                    self:triggerEvent("onSliderAnimationStartFadingInHorizontal")
                end,
    
                onAnimationStartFadingOut = function(self)
                    self:triggerEvent("onSliderAnimationStartFadingOutHorizontal")
                end,

                onAnimationFadingIn = function(self)
                    self:triggerEvent("onSliderAnimationFadingInHorizontal")
                end,
    
                onAnimationFadingOut = function(self)
                    self:triggerEvent("onSliderAnimationFadingOutHorizontal")
                end,
    
                onAnimationFadedIn = function(self)
                    self:triggerEvent("onSliderAnimationFadedInHorizontal")
                end,
    
                onAnimationFadedOut = function(self)
                    self:triggerEvent("onSliderAnimationFadedOutHorizontal")
                end,

                onAnimationRender = function(self)
                    self:triggerEvent("onSliderAnimationRenderHorizontal")
                end,

                onBarPressed = function(self)
                    self:triggerEvent("onSliderPressedHorizontal")
                end,

                onBarReleased = function(self)
                    self:cancelScrollAnimation(self.data.vertical):triggerEvent("onSliderReleasedHorizontal")
                end,

                onCursorMoveBar = function(self, offset, progress, value)
                    local data = self.data.horizontal

                    self:cancelScrollAnimation(data):updateOffset(data):triggerEvent("onSliderCursorMoveHorizontal")
                end
            },

            vertical = {
                onAnimationStartFadingIn = function(self)
                    self:triggerEvent("onSliderAnimationStartFadingInVertical")
                end,
    
                onAnimationStartFadingOut = function(self)
                    self:triggerEvent("onSliderAnimationStartFadingOutVertical")
                end,

                onAnimationFadingIn = function(self)
                    self:triggerEvent("onSliderAnimationFadingInVertical")
                end,
    
                onAnimationFadingOut = function(self)
                    self:triggerEvent("onSliderAnimationFadingOutVertical")
                end,
    
                onAnimationFadedIn = function(self)
                    self:triggerEvent("onSliderAnimationFadedInVertical")
                end,
    
                onAnimationFadedOut = function(self)
                    self:triggerEvent("onSliderAnimationFadedOutVertical")
                end,

                onAnimationRender = function(self)
                    self:triggerEvent("onSliderAnimationRenderVertical")
                end,

                onBarPressed = function(self)
                    self:triggerEvent("onSliderPressedVertical")
                end,

                onBarReleased = function(self)
                    self:triggerEvent("onSliderReleasedVertical")
                end,

                onCursorMoveBar = function(self, offset, progress, value)
                    local data = self.data.vertical

                    self:cancelScrollAnimation(data):updateOffset(data):triggerEvent("onSliderCursorMoveVertical")
                end
            }
        }
    },

    functions = {
        setCellsHorizontal = function(self, up, down, totalSize)
            return self:setCells(self.data.horizontal, up, down, totalSize)
        end,

        setCellsVertical = function(self, up, down, totalSize)
            return self:setCells(self.data.vertical, up, down, totalSize)
        end,

        addCellHorizontal = function(self, cell, upIndex, downIndex)
            return self:addCell(self.data.horizontal, cell, upIndex, downIndex)
        end,

        addCellVertical = function(self, cell, upIndex, downIndex)
            return self:addCell(self.data.vertical, cell, upIndex, downIndex)
        end,

        removeCellHorizontal = function(self, upIndex, downIndex)
            return self:removeCell(self.data.horizontal, upIndex, downIndex)
        end,

        removeCellVertical = function(self, upIndex, downIndex)
            return self:removeCell(self.data.vertical, upIndex, downIndex)
        end,

        scrollHorizontal = function(self, direction)
            return self:scroll(self.data.horizontal, direction)
        end,

        scrollVertical = function(self, direction)
            return self:scroll(self.data.vertical, direction)
        end,

        scrollAnimatedHorizontal = function(self, direction)
            return self:scrollAnimated(self.data.horizontal, direction)
        end,

        scrollAnimatedVertical = function(self, direction)
            return self:scrollAnimated(self.data.vertical, direction)
        end,

        updateScrollAnimationHorizontal = function(self)
            return self:updateScrollAnimation(self.data.horizontal)
        end,

        updateScrollAnimationVertical = function(self)
            return self:updateScrollAnimation(self.data.vertical)
        end,

        cancelScrollAnimationHorizontal = function(self)
            return self:cancelScrollAnimation(self.data.horizontal)
        end,

        cancelScrollAnimationVertical = function(self)
            return self:cancelScrollAnimation(self.data.vertical)
        end,

        setProgressHorizontal = function(self, progress)
            return self:setProgress(self.data.horizontal, progress)
        end,

        setProgressVertical = function(self, progress)
            return self:setProgress(self.data.vertical, progress)
        end,

        setCellPositionHorizontal = function(self, upIndex, downIndex, position)
            return self:setCellPosition(self.data.horizontal, upIndex, downIndex, position)
        end,

        setCellPositionVertical = function(self, upIndex, downIndex, position)
            return self:setCellPosition(self.data.vertical, upIndex, downIndex, position)
        end,

        findCellIndexUpFromPositionHorizontal = function(self, position, upStart, upEnd)
            return self:findCellIndexUpFromPosition(self.data.horizontal, position, upStart, upEnd)
        end,

        findCellIndexUpFromPositionVertical = function(self, position, upStart, upEnd)
            return self:findCellIndexUpFromPosition(self.data.vertical, position, upStart, upEnd)
        end,
        
        findCellIndexDownFromPositionHorizontal = function(self, position, downStart, downEnd)
            return self:findCellIndexDownFromPosition(self.data.horizontal, position, downStart, downEnd)
        end,

        findCellIndexDownFromPositionVertical = function(self, position, downStart, downEnd)
            return self:findCellIndexDownFromPosition(self.data.vertical, position, downStart, downEnd)
        end,

        setSliderDataHorizontal = function(self, x, y, sx, sy, animSpeed, animCubicbezier, startValue, endValue, barSize, autoBarSize, scrollSpeed, scrollCubicbezier, scrollOffset)
            self.data.horizontal.sliderData = { x, y, sx, sy, animSpeed, animCubicbezier, "horizontal", startValue, endValue, barSize, itemlist.events.slider.horizontal, { eventNames = itemlist.eventNames.horizontal, autoBarSize = autoBarSize, scroll = { speed = scrollSpeed, cubicbezier = scrollCubicbezier, offset = scrollOffset } }, self }

            return self
        end,

        setSliderDataVertical = function(self, x, y, sx, sy, animSpeed, animCubicbezier, startValue, endValue, barSize, autoBarSize, scrollSpeed, scrollCubicbezier, scrollOffset)
            self.data.vertical.sliderData = { x, y, sx, sy, animSpeed, animCubicbezier, "vertical", startValue, endValue, barSize, itemlist.events.slider.vertical, { eventNames = itemlist.eventNames.vertical, autoBarSize = autoBarSize, scroll = { speed = scrollSpeed, cubicbezier = scrollCubicbezier, offset = scrollOffset } }, self }

            return self
        end,
        
        isPointIn = function(self, px, py)
            local size = self.size
            local position = self.position
            
            return isPointInRectangle(px, py, position.x, position.y, size.rx, size.ry)
        end,

        clear = function(self)
            local data = self.data
            local h, v = data.horizontal, data.vertical

            h.up, h.down, h.upCellIndex, h.downCellIndex, h.offset, h.maxOffset, h.totalSize = {}, {}, 1, 0, 0, 0, 0
            v.up, v.down, v.upCellIndex, v.downCellIndex, v.offset, v.maxOffset, v.totalSize = {}, {}, 1, 0, 0, 0, 0

            self.activeCells = {}

            return self:destroySlider(h):destroySlider(v)
        end,

        destroy = function(self)
            self:triggerEvent("onDestroy")

            self.size:destroy()
            self.position:destroy()
            self.animation:destroy()

            local data = self.data

            self:destroySlider(data.horizontal):destroySlider(data.vertical)
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

            return self:updateSize(self.data.horizontal, "rx")
        end,

        setSizeAbsoluteY = function(self, y)
            self.size:setPositionAbsoluteY(y)

            return self:updateSize(self.data.vertical, "ry")
        end,

        setSizeAbsolute = function(self, x, y)
            local data = self.data

            self.size:setPositionAbsolute(x, y)

            return self:updateSize(data.horizontal, "rx"):updateSize(data.vertical, "ry")
        end,

        setSizeRelativeX = function(self, rx)
            self.size:setPositionRelativeX(rx)

            return self:updateSize(self.data.horizontal, "rx")
        end,

        setSizeRelativeY = function(self, ry)
            self.size:setPositionRelativeY(ry)

            return self:updateSize(self.data.vertical, "ry")
        end,

        setSizeRelative = function(self, rx, ry)
            local data = self.data

            self.size:setPositionRelative(rx, ry)

            return self:updateSize(data.horizontal, "rx"):updateSize(data.vertical, "ry")
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

        setCells = function(self, data, up, down)
            data.up, data.down = up, down

            data.upCellIndex = clamp(data.upCellIndex, 1, #up)
            data.downCellIndex = clamp(data.downCellIndex, 1, #down)

            return self:updateTotalSize(data)
        end,

        addCell = function(self, data, cell, upIndex, downIndex)
            tableInsert(data.up, upIndex, cell)
            tableInsert(data.down, downIndex, cell)

            if upIndex < data.upCellIndex and downIndex < data.downCellIndex then
                self.activeCells[cell] = true
            end

            return self:updateTotalSize(data)
        end,

        removeCell = function(self, data, upIndex, downIndex)
            local up, down = data.up, data.down
            local cell = up[upIndex]
            
            tableRemove(up, upIndex)
            tableRemove(down, downIndex)

            data.upCellIndex = clamp(data.upCellIndex, 1, #up)
            data.downCellIndex = clamp(data.downCellIndex, 1, #down)

            self.activeCells[cell] = nil

            return self:updateTotalSize(data)
        end,

        setCellPosition = function(self, data, upIndex, downIndex, position)
            local up, down = data.up, data.down
            local upLen, downLen = #up, #down

            local pos = data.pos
            local cell = up[upIndex]

            local oldPos = cell[pos]

            local newUpIndex, newDownIndex

            print(position, oldPos)
            --[[ if position > oldPos then
                newUpIndex, newDownIndex = self:findCellIndexUpFromPosition(data, position, upIndex, upLen), self:findCellIndexDownFromPosition(data, position, downIndex, 1)
            elseif position < oldPos then
                newUpIndex, newDownIndex = self:findCellIndexUpFromPosition(data, position, upIndex, 1), self:findCellIndexDownFromPosition(data, position, downIndex, downLen)
            end ]]

            newUpIndex, newDownIndex = self:findCellIndexUpFromPosition(data, position), self:findCellIndexDownFromPosition(data, position)

            print(newUpIndex, newDownIndex)

            --cell[pos] = position

            return self
        end,

        scroll = function(self, data, direction)
            local slider = data.slider

            if slider then
                self:cancelScrollAnimation(data)
    
                local custom = slider.custom
    
                data.offset = clamp(data.offset + custom.scroll.offset*direction, 0, data.maxOffset)
    
                slider:setProgress(data.offset/data.maxOffset)
    
                if direction == 1 then
                    self:updateCellsUp(data)
                elseif direction == -1 then
                    self:updateCellsDown(data)
                end
            end

            return self
        end,

        scrollAnimated = function(self, data, direction)
            local slider = data.slider

            if slider then
                local custom = slider.custom
                local scroll = custom.scroll
    
                local offset = clamp(scroll.endOffset + scroll.offset*direction, 0, data.maxOffset)
    
                scroll.startOffset = data.offset
                scroll.endOffset = offset
                scroll.down = direction == 1
                scroll.tick = getTickCount()
    
                if not scroll.state then
                    self:triggerEvent(custom.eventNames.onScrollAnimationUpdateStart)
    
                    scroll.state = true
                end
            end

            return self
        end,

        updateScrollAnimation = function(self, data)
            local slider = data.slider

            if slider then
                local custom = slider.custom
                local scroll = custom.scroll
    
                if scroll.endOffset ~= data.offset then
                    data.offset = scroll.startOffset + (scroll.endOffset - scroll.startOffset) * scroll.cubicbezier:ease((getTickCount() - scroll.tick)/scroll.speed)
                    
                    slider:setProgress(data.offset/data.maxOffset)
        
                    if scroll.down then
                        self:updateCellsUp(data)
                    else
                        self:updateCellsDown(data)
                    end

                    self:triggerEvent(custom.eventNames.onScrollAnimationUpdate)
                else
                    self:cancelScrollAnimation(data)
                end
            else
                self:cancelScrollAnimation(data)
            end

            return self
        end,

        cancelScrollAnimation = function(self, data)
            local slider = data.slider

            if slider then
                local custom = slider.custom
                local scroll = custom.scroll
    
                if scroll.state then
                    self:triggerEvent(custom.eventNames.onScrollAnimationUpdateEnd)
                    
                    scroll.state = false
                end
    
                scroll.startOffset = data.offset
                scroll.endOffset = data.offset
                scroll.down = nil
            end

            return self
        end,

        setProgress = function(self, data, progress)
            local slider = data.slider

            if slider then
                slider:setProgress(progress)

                self:updateOffset(data):cancelScrollAnimation(data)
            end

            return self
        end,

        updateOffset = function(self, data)
            local slider = data.slider

            if slider then
                local custom = slider.custom
                local lastOffset = custom.lastOffset
                local offset = slider.progress*data.maxOffset
    
                data.offset = offset
    
                if offset > lastOffset then
                    self:updateCellsUp(data)
                elseif offset < lastOffset then
                    self:updateCellsDown(data)
                end
    
                custom.lastOffset = offset
            end

            return self
        end,

        updateSize = function(self, data, posRel)
            local rv = self.size[posRel]
            local oldSize = data.size

            data.size = rv
            data.maxOffset = mathMax(0, data.totalSize - rv)
            data.offset = mathMin(data.offset, data.maxOffset)

            return self:updateSlider(data):updateCellsUp(data):updateCellsDown(data)
        end,

        updateTotalSize = function(self, data)
            local downFirst = data.down[1]

            local totalSize = downFirst and downFirst[data.pos] + downFirst[data.posSize] or 0

            data.totalSize = totalSize
            data.maxOffset = mathMax(0, data.totalSize - data.size)
            data.offset = mathMin(data.offset, data.maxOffset)

            return self:updateSlider(data):updateCellsUp(data):updateCellsDown(data)
        end,

        createSlider = function(self, data)
            if not data.slider then
                local sliderData = data.sliderData
                
                if sliderData then
                    local slider = slider(unpack(sliderData))
        
                    local custom = slider.custom
                    local scroll = custom.scroll
        
                    custom.autoBarSize = custom.autoBarSize or false
                    
                    custom.data = data
                    custom.lastOffset = 0
                    
                    scroll.speed = scroll.speed or 1
                    scroll.offset = scroll.offset or 0
                    scroll.cubicbezier = scroll.cubicbezier or cubicbezierLinear
                    
                    scroll.startOffset = data.offset
                    scroll.endOffset = data.offset
                    
                    data.slider = slider
        
                    slider.position:setParent(self.position)
                    slider.animation:setParent(self.animation)

                    self:triggerEvent(custom.eventNames.onCreate)
                end
            end

            return self
        end,

        updateSlider = function(self, data)
            local size = data.size

            if data.totalSize > size then
                self:createSlider(data)

                local slider = data.slider

                if slider then
                    slider:setAnimationState(self.animation.state)
    
                    self:cancelScrollAnimation(data)
                    
                    if slider.custom.autoBarSize then
                        slider:setBarSize(size/data.totalSize*size)
                    end
    
                    slider:setProgress(data.offset/data.maxOffset)
                end
            else
                self:destroySlider(data)
            end

            return self
        end,

        destroySlider = function(self, data)
            local slider = data.slider

            if slider then
                self:triggerEvent(slider.custom.eventNames.onDestroy)
    
                slider:destroy()
    
                data.slider = nil
            end

            return self
        end,

        findCellIndexUpFromPosition = function(self, data, position, upStart, upEnd)
            local up = data.up

            local pos = data.pos

            upStart, upEnd = upStart or 1, upEnd or #up

            local cellIndex

            for i = upStart, upEnd do
                local other = up[i]
                
                if position < other[pos] + 1 then
                    cellIndex = i
                    break
                end
            end

            local upLast = up[upEnd]

            if not cellIndex and position > upLast[pos] - 1 then
                cellIndex = upEnd
            end

            return cellIndex
        end,

        findCellIndexDownFromPosition = function(self, data, position, downStart, downEnd)
            local down = data.down
            local pos, posSize = data.pos, data.posSize

            downStart, downEnd = downStart or 1, downEnd or #down

            local cellIndex

            for i = downStart, downEnd do
                local other = down[i]
                
                if position > other[pos] + other[posSize] - 1 then
                    cellIndex = i
                    break
                end
            end

            local downLast = down[downEnd]

            if not cellIndex and position < downLast[pos] + downLast[posSize] + 1 then
                cellIndex = downEnd
            end

            return cellIndex
        end,

        --[[ UpdateCellIndexUp = function(self, data, currentUpIndex, currentDownIndex)
            local activeCells = self.activeCells

            local offset = data.offset
            local up, down = data.up, data.down
            local pos, posSize = data.pos, data.posSize

            local cell = up[currentUpIndex]
            local cellPos, cellPosSize = cell[pos], cell[posSize]
            local cellSizePos = cellPos + cellPosSize

            local newUpIndex, newDownIndex

            for i = currentUpIndex - 1, 1, -1 do
                local other = up[i]

                if cellPos > other[pos] then
                    break
                end

                newUpIndex = i
            end

            for i = currentDownIndex + 1, #down do
                local other = down[i]

                if cellSizePos > other[pos] + other[posSize] then
                    break
                end

                newDownIndex = i
            end

            if newUpIndex then
                tableSetValueIndexLeft(up, currentUpIndex, newUpIndex)
            end
            
            if newDownIndex then
                tableSetValueIndexRight(down, currentDownIndex, newDownIndex)
            end
            
            if currentUpIndex > data.endCell and cellPos - offset < data.size then
                data.endCell = data.endCell + 1
                activeCells[cell] = true
            end

            if #down - currentDownIndex + 1 > data.startCell - 1 and cellSizePos - offset - 1 < 0 then
                data.startCell = data.startCell + 1
                activeCells[cell] = nil
            end

            return self
        end,

        UpdateCellIndexDown = function(self, data, currentUpIndex, currentDownIndex)
            local activeCells = self.activeCells

            local offset = data.offset
            local up, down = data.up, data.down
            local pos, posSize = data.pos, data.posSize

            local cell = up[currentUpIndex]
            local cellPos, cellPosSize = cell[pos], cell[posSize]
            local cellSizePos = cellPos + cellPosSize

            local newUpIndex, newDownIndex

            for i = currentUpIndex + 1, #up do
                local other = up[i]

                if cellPos < other[pos] then
                    break
                end

                newUpIndex = i
            end

            for i = currentDownIndex - 1, 1, -1 do
                local other = down[i]

                if cellSizePos < other[pos] + other[posSize] then
                    break
                end

                newDownIndex = i
            end

            if newUpIndex then
                tableSetValueIndexRight(up, currentUpIndex, newUpIndex)
            end
            
            if newDownIndex then
                tableSetValueIndexLeft(down, currentDownIndex, newDownIndex)
            end
            
            if currentUpIndex - 1 < data.endCell and cellPos - offset > data.size - 1 then
                data.endCell = data.endCell - 1
                activeCells[cell] = nil
            end

            if #down - currentDownIndex + 1 < data.startCell and cellSizePos - offset > 0 then
                data.startCell = data.startCell - 1
                activeCells[cell] = true
            end

            return self
        end, ]]

        updateCellsUp = function(self, data)
            local up, down = data.up, data.down
            local upLen, downLen = #up, #down

            if upLen > 0 and downLen > 0 then
                local activeCells = self.activeCells
                local cData = self.data[data.counterpart]
                
                local size, offset, pos, posSize = data.size - 1, data.offset, data.pos, data.posSize
                local cSize, cOffset, cPos, cPosSize = cData.size, cData.offset, cData.pos, cData.posSize
    
                for i = data.downCellIndex, 1, -1 do
                    local cell = down[i]
                    
                    local sizePosition = cell[pos] + cell[posSize] - offset
    
                    if sizePosition > 0 then
                        data.downCellIndex = i
                        break
                    end
    
                    activeCells[cell] = nil
                end
    
                for i = mathMax(data.upCellIndex, downLen - data.downCellIndex + 1), upLen do
                    local cell = up[i]
    
                    local position = cell[pos] - offset
                    
                    if position > size then
                        data.upCellIndex = i - 1
                        break
                    end
                    
                    local cPosition = cell[cPos] - cOffset
                    local cSizePosition = cPosition + cell[cPosSize]
    
                    if cSizePosition > 0 and cPosition < cSize then
                        activeCells[cell] = true
                    end
                end
    
                local lastCellOffset = data.maxOffset - down[1][posSize] + 1
    
                if offset > lastCellOffset then
                    data.upCellIndex = upLen
                end
            end

            return self
        end,

        updateCellsDown = function(self, data)
            local up, down = data.up, data.down
            local upLen, downLen = #up, #down
            
            if upLen > 0 and downLen > 0 then
                local activeCells = self.activeCells
                local cData = self.data[data.counterpart]

                local size, offset, pos, posSize = data.size, data.offset, data.pos, data.posSize
                local cSize, cOffset, cPos, cPosSize = cData.size, cData.offset, cData.pos, cData.posSize
    
                for i = data.upCellIndex, 1, -1 do
                    local cell = up[i]
    
                    local position = cell[pos] - offset
                    
                    if position < size then
                        data.upCellIndex = i
                        break
                    end
                    
                    activeCells[cell] = nil
                end
    
                for i = mathMax(data.downCellIndex, upLen - data.upCellIndex + 1), downLen do
                    local cell = down[i]
    
                    local sizePosition = cell[pos] + cell[posSize] - offset
                    
                    if sizePosition < 1 then
                        data.downCellIndex = i - 1
                        break
                    end
    
                    local cPosition = cell[cPos] - cOffset
                    local cSizePosition = cPosition + cell[cPosSize]
    
                    if cSizePosition > 0 and cPosition < cSize then
                        activeCells[cell] = true
                    end
                end
    
                local firstCellOffset = up[1][posSize] - 1
    
                if offset < firstCellOffset then
                    data.downCellIndex = downLen
                end
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

setmetatable(itemlist, {
    __call = function(t, ...)
        return itemlist.new(...)        
    end
})

dxb.itemlist = itemlist
