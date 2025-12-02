local mathMin = math.min
local mathMax = math.max
local mathFloor = math.floor

local stringLower = string.lower
local stringFormat = string.format

local tableSort = table.sort
local tableConcat = table.concat
local tableInsert = table.insert
local tableRemove = table.remove

local utils = dxb.utils
local events = dxb.events
local slider = dxb.slider
local itemlist = dxb.itemlist
local cubicbezier = dxb.cubicbezier

local math = utils.math

local clamp = math.clamp

local addEvent = events.addEvent
local removeEvent = events.removeEvent

local scx, scy = utils.scx, utils.scy
local rel = scx > scy and mathMax(mathMin(scx/1920, 1), 0.5) or mathMax(mathMin(scy/1080, 1), 0.5)

local rgbToHex = function(r, g, b)
    return stringFormat("%02x%02x%02x", r, g, b)
end

local silentExport

do
    local validStates = { ["running"] = true, ["starting"] = true, ["stopping"] = true }

    silentExport = function(resourceName, functionName, ...)
        local resource = getResourceFromName(resourceName)
        
        if resource and validStates[getResourceState(resource)] then
            return call(resource, functionName, ...)
        end
    end
end

local drawPreMultAlphaImage = function(x, y, sx, sy, texture, rotation, rotationCenterOx, rotationCenterOy, r, g, b, a, postGUI)
    local alphaFactor = a / 255

    local oldBlendMode = dxGetBlendMode()

    dxSetBlendMode("add")

    local rendered = dxDrawImage(x, y, sx, sy, texture, rotation, rotationCenterOx, rotationCenterOy, tocolor(r * alphaFactor, g * alphaFactor, b * alphaFactor, a), postGUI)

    dxSetBlendMode(oldBlendMode)

    return rendered
end

local drawRoundedRectangle = function(x, y, sx, sy, cImage, cSize, color, postGUI, subPixel)
    sx, sy = mathMax(sx, cSize), mathMax(sy, cSize)

    dxDrawImage(x, y, cSize, cSize, cImage, 0, 0, 0, color, postGUI)
    dxDrawRectangle(x + cSize, y, sx - cSize * 2, cSize, color, postGUI, subPixel)
    dxDrawImage(x + sx - cSize, y, cSize, cSize, cImage, 90, 0, 0, color, postGUI)

    dxDrawRectangle(x, y + cSize, sx, sy - cSize * 2, color, postGUI, subPixel)

    dxDrawImage(x, y + sy - cSize, cSize, cSize, cImage, 270, 0, 0, color, postGUI)
    dxDrawRectangle(x + cSize, y + sy - cSize, sx - cSize * 2, cSize, color, postGUI, subPixel)
    dxDrawImage(x + sx - cSize, y + sy - cSize, cSize, cSize, cImage, 180, 0, 0, color, postGUI)
end

local drawEmptyRoundedRectangle = function(x, y, sx, sy, cImage, cSize, lineSize, color, postGUI, subPixel)
    sx, sy = mathMax(sx, cSize), mathMax(sy, cSize)

    dxDrawImage(x, y, cSize, cSize, cImage, 0, 0, 0, color, postGUI)
    dxDrawRectangle(x + cSize, y, sx - cSize * 2, lineSize, color, postGUI, subPixel)

    dxDrawImage(x + sx - cSize, y, cSize, cSize, cImage, 90, 0, 0, color, postGUI)

    dxDrawRectangle(x, y + cSize, lineSize, sy - cSize * 2, color, postGUI, subPixel)

    dxDrawRectangle(x + sx - lineSize, y + cSize, lineSize, sy - cSize * 2, color, postGUI, subPixel)

    dxDrawImage(x, y + sy - cSize, cSize, cSize, cImage, 270, 0, 0, color, postGUI)
    dxDrawRectangle(x + cSize, y + sy - lineSize, sx - cSize * 2, lineSize, color, postGUI, subPixel)

    dxDrawImage(x + sx - cSize, y + sy - cSize, cSize, cSize, cImage, 180, 0, 0, color, postGUI)
end

local nth = function(value)
    if value > 3 and value < 21 then
        return "th"
    end

    local a = value % 10

    if a == 1 then
        return "st"
    elseif a == 2 then
        return "nd"
    elseif a == 3 then
        return "rd"
    else
        return "th"
    end
end

local cubicbezierLinear = cubicbezier.linear()
local cubicbezierOutQuad = cubicbezier.outQuad()

local wff2UI

wff2UI = {
    settings = {
        toggleKey = "F2",

        mode = 1,
        modes = 3,
        maxRows = 20,

        offsetX = mathFloor(25*rel),
        offsetY = mathFloor(0*rel),

        sizeX = mathFloor(275*rel),
        maxSizeY = mathFloor(500*rel),

        cellMarginX = mathFloor(0*rel),
        cellMarginY = mathFloor(0*rel),

        headerSize = mathFloor(70*rel),
        footerSize = mathFloor(10*rel),

        animSpeed = 500,
        animCubicbezier = cubicbezierLinear,

        animCustomSpeed = 500,
        animCustomCubicbezier = cubicbezierOutQuad,

        updateDelay = 3000,

        rowSizeY = {
            ["team"] = mathFloor(40*rel),
            ["player"] = mathFloor(30*rel),
        },

        slider = {
            sizeX = mathFloor(4*rel),

            animSpeed = 500,
            animCubicbezier = cubicbezierLinear,

            scrollSpeed = 200,
            scrollCubicbezier = cubicbezierOutQuad,
            scrollOffset = mathFloor(40*rel),
        }
    },

    create = function()
        if not wff2UI.itemlistElement then
            local itemlistData = wff2UI.itemlistData

            local itemlistElement = itemlist.new(itemlistData.x, itemlistData.y, itemlistData.sx, itemlistData.sy, itemlistData.animSpeed, itemlistData.animCubicbezier, itemlistData.events, itemlistData.custom)

            local slider = itemlistData.slider

            itemlistElement:setSliderDataVertical(slider.x, slider.y, slider.sx, slider.sy, slider.animSpeed, slider.animCubicbezier, slider.startValue, slider.endValue, slider.barSize, slider.autoBarSize, slider.scrollSpeed, slider.scrollCubicbezier, slider.scrollOffset)

            wff2UI.itemlistElement = itemlistElement

            local eventHandlers = wff2UI.eventHandlers

            addEventHandler("onClientResourceStart", root, eventHandlers.onClientResourceStart)
            addEventHandler("onClientElementDataChange", root, eventHandlers.onClientElementDataChange)
            addEventHandler("onClientRestore", root, eventHandlers.onClientRestore)

            local settings = wff2UI.settings

            local keyBinds = wff2UI.keyBinds

            bindKey(settings.toggleKey, "down", keyBinds.toggle)

            wff2UI.cacheFonts()
        end
    end,

    destroy = function()
        if wff2UI.itemlistElement then
            local eventHandlers = wff2UI.eventHandlers

            removeEventHandler("onClientResourceStart", root, eventHandlers.onClientResourceStart)
            removeEventHandler("onClientElementDataChange", root, eventHandlers.onClientElementDataChange)
            removeEventHandler("onClientRestore", root, eventHandlers.onClientRestore)

            local settings = wff2UI.settings

            local keyBinds = wff2UI.keyBinds

            unbindKey(settings.toggleKey, "down", keyBinds.toggle)

            wff2UI.itemlistElement:destroy()

            wff2UI.itemlistElement = nil

            wff2UI.itemlistData = nil

            wff2UI.prepareItemlistData()

            wff2UI.elementData = {}
            wff2UI.fonts = {}
        end
    end,

    cacheFonts = function()
        local fonts = wff2UI.fonts

        fonts["roboto-regular-10"] = silentExport("ep_core", "getFont", "roboto-regular-10")
    end,

    setElementData = function(element, key, data)
        local elementData = wff2UI.elementData

        if not elementData[element] then
            elementData[element] = {}
        end

        elementData[element][key] = data
    end,

    getElementData = function(element, key)
        local elementData = wff2UI.elementData

        local data

        if elementData[element] then
            data = elementData[element][key]
        end

        if not data then
            data = getElementData(element, key, false)

            if data then
                wff2UI.setElementData(element, key, data)
            end
        end

        return data
    end,

    prepareItemlistData = function()
        if not wff2UI.itemlistData then
            local settings = wff2UI.settings
            local fonts = wff2UI.fonts

            local offsetX = settings.offsetX
            local offsetY = settings.offsetY

            local sizeX = settings.sizeX
            local maxSizeY = settings.maxSizeY

            local headerSize = settings.headerSize
            local footerSize = settings.footerSize

            local cellMarginX = settings.cellMarginX
            local cellMarginY = settings.cellMarginY

            local updateDelay = settings.updateDelay

            local rowSizeY = settings.rowSizeY

            local sliderSettings = settings.slider

            local diffSizeY = (headerSize - footerSize)/2
            local itemlistMaxSizeY = maxSizeY - (headerSize + footerSize)
            
            local startX = scx - settings.sizeX - settings.offsetX
            local startY = scy/2

            local itemlistMaxY = startY - itemlistMaxSizeY/2

            local itemlistData = {
                x = startX,
                y = startY + diffSizeY,
                sx = sizeX,
                sy = 0,
                animSpeed = settings.animSpeed,
                animCubicbezier = settings.animCubicbezier,
                slider = {
                    x = startX + sizeX - sliderSettings.sizeX,
                    y = itemlistMaxY,
                    sx = sliderSettings.sizeX,
                    sy = itemlistMaxSizeY,
                    animSpeed = 1,--sliderSettings.animSpeed,
                    animCubicbezier = sliderSettings.animCubicbezier,
                    startValue = 0,
                    endValue = 1,
                    barSize = 0,
                    autoBarSize = true,
                    scrollSpeed = sliderSettings.scrollSpeed,
                    scrollCubicbezier = sliderSettings.scrollCubicbezier,
                    scrollOffset = sliderSettings.scrollOffset
                },
                events = {
                    onCreate = function(self)
                        local custom = self.custom

                        custom.createTextures(self)
                    end,

                    onDestroy = function(self)
                        local custom = self.custom

                        custom.destroyTextures(self)
                    end,

                    onAnimationStartFadingIn = function(self)
                        local animation = self.animation
                        local custom = self.custom
            
                        if animation.progress == animation.min then
                            addEvent("onClientRender", root, animation.updateEasing, nil, nil, animation)

                            custom.updateItems(self)
                            custom.sortPlayers(self)
                            custom.updateMaxRows(self)
                            custom.updateRenderTargetSize(self)

                            custom.updateTimer = setTimer(
                                function()
                                    custom.updateItems(self)
                                    custom.sortPlayers(self)
                                    custom.updateMaxRows(self)
                                    custom.updateRenderTargetSize(self)
                                    custom.updateRenderTarget(self)
                                end,
                                updateDelay, 0
                            )
                        end
                    end,
            
                    onAnimationStartFadingOut = function(self)

                    end,
            
                    onAnimationFadedOut = function(self)
                        local animation = self.animation
                        local custom = self.custom

                        removeEvent("onClientRender", root, animation.updateEasing, animation)

                        if isElement(custom.renderTarget) then
                            destroyElement(custom.renderTarget)
                        end

                        if isTimer(custom.updateTimer) then
                            killTimer(custom.updateTimer)
                        end
                        
                        custom.renderTarget = nil
                        custom.renderTargetSizeY = nil

                        custom.updateTimer = nil

                        custom.allowUpdateRenderTarget = nil
                    end,
            
                    onScrollAnimationUpdateStartVertical = function(self)
                        local custom = self.custom
            
                        addEvent("onClientRender", root, self.updateScrollAnimationVertical, nil, nil, self)

                        custom.subPixel = true
                        custom.allowUpdateRenderTarget = true
                    end,
            
                    onScrollAnimationUpdateEndVertical = function(self)
                        local custom = self.custom
            
                        custom.updateRenderTarget(self)

                        custom.subPixel = nil
                        custom.allowUpdateRenderTarget = nil

                        removeEvent("onClientRender", root, self.updateScrollAnimationVertical, self)
                    end,
            
                    onSliderAnimationStartFadingInVertical = function(self)
                        local eventHandlers = slider.eventHandlers
                        local vertical = self.data.vertical.slider
                        local animation = vertical.animation
                        
                        if animation.progress == animation.min then
                            addEvent("onClientRender", root, animation.updateEasing, nil, nil, animation)
                        end
            
                        addEvent("onClientClick", root, eventHandlers.onClick, nil, nil, vertical)
                        addEvent("onClientKey", root, self.custom.updateMouseScroll, nil, nil, self)
                    end,
            
                    onSliderAnimationStartFadingOutVertical = function(self)
                        local custom = self.custom
            
                        local eventHandlers = slider.eventHandlers
                        local vertical = self.data.vertical.slider
                
                        removeEvent("onClientClick", root, eventHandlers.onClick, vertical)
                        removeEvent("onClientKey", root, custom.updateMouseScroll, self)

                        if vertical.pressed then
                            removeEvent("onClientRender", root, eventHandlers.onClientRender, vertical)
            
                            vertical.pressed = false
                        end
                    end,
            
                    onSliderAnimationFadedOutVertical = function(self)
                        local vertical = self.data.vertical.slider
                        local animation = vertical.animation
            
                        removeEvent("onClientRender", root, animation.updateEasing, animation)
                    end,
            
                    onSliderPressedVertical = function(self)
                        self.custom.allowUpdateRenderTarget = true
                    end,
            
                    onSliderReleasedVertical = function(self)
                        self.custom.allowUpdateRenderTarget = nil
                    end,

                    onSliderAnimationRenderVertical = function(self)
                        local custom = self.custom
                        local vertical = self.data.vertical.slider
                
                        local position = vertical.position
                        local size = vertical.size
                        local animation = vertical.animation
                
                        local x, y = position.x, position.y
                        local sx, sy = size.rx, size.ry
                    
                        local animationProgress = animation.progress

                        local textures = custom.textures
            
                        do
                            local texture = textures["circle-4"]

                            local y = y + vertical.offset

                            if isElement(texture) then
                                dxDrawImage(mathFloor(x), mathFloor(y), mathFloor(sx), mathFloor(sx), texture, 0, 0, 0, tocolor(255, 255, 255, animationProgress))
                                dxDrawImage(mathFloor(x), mathFloor(y + mathMax(vertical.barSize - sx, 0)), mathFloor(sx), mathFloor(sx), texture, 0, 0, 0, tocolor(255, 255, 255, animationProgress))
                            end

                            dxDrawRectangle(mathFloor(x), mathFloor(y + sx/2), mathFloor(sx), mathFloor(mathMax(vertical.barSize - sx, 0)), tocolor(255, 255, 255, animationProgress))
                        end
                    end,

                    onSliderDestroyVertical = function(self)
                        local custom = self.custom
            
                        local vertical = self.data.vertical.slider
                        
                        local eventHandlers = slider.eventHandlers
                
                        removeEvent("onClientRender", root, vertical.animation.updateEasing, vertical.animation)
                        removeEvent("onClientClick", root, eventHandlers.onClick, vertical)
                        removeEvent("onClientKey", root, custom.updateMouseScroll, self)
                
                        if vertical.pressed then
                            removeEvent("onClientRender", root, eventHandlers.onClientRender, vertical)
                        end
                    end,
            
                    onAnimationRender = function(self)
                        local position = self.position
                        local size = self.size
                        local animation = self.animation
                        local custom = self.custom
                        
                        local x, y = position.x, position.y
                        local sx, sy = size.rx, size.ry
            
                        local animationProgress = animation.progress
            
                        local textures = custom.textures
                        local renderTarget = custom.renderTarget

                        local font = isElement(fonts["roboto-regular-10"]) and fonts["roboto-regular-10"] or "default"

                        do
                            local texture = textures["round-10"]

                            if isElement(texture) then
                                drawRoundedRectangle(mathFloor(x), mathFloor(y - headerSize), mathFloor(sx), mathFloor(sy + headerSize + footerSize), texture, 10*rel, tocolor(30, 30, 30, animationProgress*0.75))
                            end
                        end

                        do
                            local texture = textures["empty-round-10"]

                            if isElement(texture) then
                                drawEmptyRoundedRectangle(mathFloor(x), mathFloor(y - headerSize), mathFloor(sx), mathFloor(sy + headerSize + footerSize), texture, 10*rel, 1*rel, tocolor(255, 255, 255, animationProgress*0.05))
                            end
                        end

                        if #self.data.vertical.up > 0 then
                            dxDrawLine(x + 1*rel, y, x + sx - 2*rel, y, tocolor(255, 255, 255, animationProgress*0.05))
                        end

                        --[[ do
                            local y = y + sy

                            dxDrawLine(x + 1*rel, y, x + sx - 2*rel, y, tocolor(255, 255, 255, animationProgress*0.05))
                        end *]]

                        do
                            local coreElement = wff2UI.getElementData(event1.data.arenaElement, "coreElement", false)

                            if isElement(coreElement) then
                                do
                                    local x = x + sx/2
                                    local y = y - headerSize + 20*rel

                                    dxDrawText(getElementID(coreElement), x, y, x, y, tocolor(255, 255, 255, animationProgress), 1*rel, font, "center", "center", false, false, false, true)
                                end

                                do
                                    local y = y - 15*rel

                                    local state = wff2UI.getElementData(coreElement, "state", false)
                                                
                                    if state then
                                        local texture = textures[custom.stateImages[state] or ""]

                                        if isElement(texture) then
                                            local x = x + 15*rel
                                            local imgSx = 14*rel
                                            local imgSy = 15*rel

                                            local stateName = custom.stateNames[state] or state

                                            local r, g, b = unpack(custom.stateColors[state] or { 255, 255, 255 })

                                            do
                                                local y = y - imgSy/2

                                                dxDrawImage(mathFloor(x), mathFloor(y), mathFloor(imgSx), mathFloor(imgSy), texture, 0, 0, 0, tocolor(r, g, b, animationProgress))
                                            end

                                            do
                                                local x = x + imgSx + 5*rel

                                                dxDrawText(stateName, x, y, x, y, tocolor(r, g, b, animationProgress), 1*rel, font, "left", "center")
                                            end
                                        end
                                    end

                                    local round = wff2UI.getElementData(coreElement, "round", false)
        
                                    if round then
                                        local x = x + sx - 15*rel

                                        dxDrawText(tostring(round) .. nth(round) .. " round", x, y, x, y, tocolor(255, 255, 255, animationProgress*0.7), 1*rel, font, "right", "center")
                                    end
                                end
                            end
                        end

                        if isElement(renderTarget) then
                            --custom.allowUpdateRenderTarget = true

                            if custom.allowUpdateRenderTarget then
                                custom.updateRenderTarget(self)
                            end

                            --dxDrawRectangle(mathFloor(x), mathFloor(y), mathFloor(sx), mathFloor(sy), 0x55000000)
            
                            drawPreMultAlphaImage(mathFloor(x), mathFloor(y), mathFloor(sx), mathFloor(sy), renderTarget, 0, 0, 0, 255, 255, 255, animationProgress)
                        else
                            custom.drawItems(self)
                        end
                    end
                },
                custom = {
                    createTextures = function(self)
                        local custom = self.custom
            
                        local textures = custom.textures
                        local textureFormats = custom.textureFormats

                        local texturesData = {
                            ["round-3"] = "client/img/round-3.png",
                            ["round-10"] = "client/img/round-10.png",
                            ["empty-round-3"] = "client/img/empty-round-3.png",
                            ["empty-round-10"] = "client/img/empty-round-10.png",
                            ["play-14-15"] = "client/img/play-14-15.png",
                            ["pause-14-15"] = "client/img/pause-14-15.png",
                            ["stop-14-15"] = "client/img/stop-14-15.png",
                            ["heart-13"] = "client/img/heart-13.png",
                            ["circle-4"] = "client/img/circle-4.png",
                        }
            
                        for i, v in pairs(texturesData) do
                            textures[i] = dxCreateTexture(v, textureFormats[i] or "argb", true, "clamp")
                        end
                    end,

                    destroyTextures = function(self)
                        local custom = self.custom
            
                        for i, v in pairs(custom.textures) do
                            if isElement(v) then
                                destroyElement(v)
                            end
                        end
            
                        custom.textures = {}
                    end,

                    addPlayer = function(self, player)
                        local custom = self.custom

                        local players = custom.players

                        players[#players + 1] = player

                        if self.animation.state then
                            custom.updateItems(self)
                            custom.sortPlayers(self)
                            custom.updateMaxRows(self)
                            custom.updateRenderTargetSize(self)
                        end
                    end,

                    addTeam = function(self, team)
                        local custom = self.custom

                        local teams = custom.teams

                        teams[#teams + 1] = team

                        if self.animation.state then
                            custom.updateItems(self)
                            custom.sortPlayers(self)
                            custom.updateMaxRows(self)
                            custom.updateRenderTargetSize(self)
                        end
                    end,

                    removePlayer = function(self, player)
                        local custom = self.custom

                        local players = custom.players

                        local index

                        for i = 1, #players do
                            if players[i] == player then
                                index = i

                                break
                            end
                        end

                        if index then
                            tableRemove(players, index)

                            if self.animation.state then
                                custom.updateItems(self)
                                custom.sortPlayers(self)
                                custom.updateMaxRows(self)
                                custom.updateRenderTargetSize(self)
                            end
                        end
                    end,

                    removeTeam = function(self, team)
                        local custom = self.custom

                        local teams = custom.teams

                        local index

                        for i = 1, #teams do
                            if teams[i] == team then
                                index = i

                                break
                            end
                        end

                        if index then
                            tableRemove(teams, index)

                            if self.animation.state then
                                custom.updateItems(self)
                                custom.sortPlayers(self)
                                custom.updateMaxRows(self)
                                custom.updateRenderTargetSize(self)
                            end
                        end
                    end,

                    setMaxRows = function(self, maxRows)
                        local custom = self.custom

                        custom.maxRows = maxRows

                        custom.updateItems(self)
                        custom.sortPlayers(self)
                        custom.updateMaxRows(self)
                        custom.updateRenderTargetSize(self)
                    end,

                    drawItems = function(self, startX, startY, animationProgress)
                        local position = self.position
                        local size = self.size
                        local animation = self.animation
                        local custom = self.custom
                        
                        local x, y = startX or position.x, startY or position.y
                        local sx, sy = size.rx, size.ry
                        local vertical = self.data.vertical

                        local subPixel = custom.subPixel

                        local animationProgress = animationProgress or animation.progress
            
                        local verticalOffset = vertical.offset
            
                        for cell in pairs(self.activeCells) do
                            local cellX = x + cell.x
                            local cellY = y + cell.y - verticalOffset
                            local cellSx = cell.sx
                            local cellSy = cell.sy
            
                            local data = cell.data
            
                            local renderer = data.renderer

                            if renderer then
                                renderer(self, cell, cellX, cellY, cellSx, cellSy, animationProgress, subPixel)
                            end
                        end
                    end,

                    updateRenderTargetSize = function(self)
                        local custom = self.custom
            
                        local sizeY = self.size.ry
                        local oldSizeY = custom.renderTargetSizeY or 0
            
                        if oldSizeY ~= sizeY then
                            if isElement(custom.renderTarget) then
                                destroyElement(custom.renderTarget)
                            end
                
                            custom.renderTarget = dxCreateRenderTarget(sizeX, sizeY, true)
                            custom.renderTargetSizeY = sizeY

                            if isElement(custom.renderTarget) then
                                dxSetTextureEdge(custom.renderTarget, "clamp")
                            end
                
                            custom.updateRenderTarget(self)
                        end
                    end,

                    updateRenderTarget = function(self)
                        local custom = self.custom
            
                        local renderTarget = custom.renderTarget
            
                        if isElement(renderTarget) then
                            local position = self.position

                            dxSetRenderTarget(renderTarget, true)
                            dxSetBlendMode("modulate_add")
            
                            custom.drawItems(self, 0, 0, 255)
            
                            dxSetBlendMode("blend")
                            dxSetRenderTarget()
                        end
                    end,

                    updateItems = function(self)
                        local custom = self.custom

                        local players = custom.players
                        local teams = custom.teams

                        local rowRenderers = custom.rowRenderers

                        local items = {}

                        if #teams > 0 then
                            for i = 1, #teams do
                                tableInsert(items, #items + 1, { type = "team", team = teams[i], renderer = rowRenderers.team })
                            end
                        end

                        if #players > 0 then
                            for i = 1, #players do
                                local player = players[i]

                                --[[ local playerTeam = getPlayerTeam(player)

                                if playerTeam then
                                    local teamIndex = custom.findItem(self, items, "team", playerTeam)

                                    if teamIndex then
                                        local nextTeamIndex = custom.findItem(self, items, "type", "team", teamIndex + 1)

                                        tableInsert(items, nextTeamIndex or #items + 1, { type = "player", player = player, renderer = rowRenderers.player })
                                    else
                                        tableInsert(items, #items + 1, { type = "team", team = playerTeam, renderer = rowRenderers.team })
                                        tableInsert(items, #items + 1, { type = "player", player = player, renderer = rowRenderers.player })
                                    end
                                else
                                    local firstTeamIndex = custom.findItem(self, items, "type", "team")

                                    tableInsert(items, firstTeamIndex or #items + 1, { type = "player", player = player, renderer = rowRenderers.player })
                                end *]]

                                tableInsert(items, #items + 1, { type = "player", player = player, renderer = rowRenderers.player })
                            end
                        end

                        local itemsLen = #items

                        if itemsLen > 0 then
                            local up, down = {}, {}

                            local currentY = 0

                            for i = 1, itemsLen do
                                local item = items[i]
    
                                local sizeY = rowSizeY[item.type]

                                local cell = {
                                    x = cellMarginX,
                                    y = currentY,
                                    sx = sizeX - cellMarginX*2,
                                    sy = sizeY,
                                    data = item
                                }
    
                                currentY = currentY + sizeY + cellMarginY
    
                                up[i], down[itemsLen - i + 1] = cell, cell
                            end

                            local vertical = self.data.vertical

                            local offset = vertical.offset

                            local totalSize = currentY - cellMarginY

                            self:setSizeRelativeY(mathMin(totalSize, itemlistMaxSizeY))

                            local y = mathMax(startY - self.size.ry/2 + diffSizeY, itemlistMaxY)
    
                            self:setPositionAbsoluteY(y)

                            vertical.sliderData[2] = y

                            self:clear():setCellsVertical(up, down)
                            self:setProgressVertical(clamp(offset/vertical.maxOffset, 0, 1))
                        else
                            local y = startY + diffSizeY

                            self:setPositionAbsoluteY(y)
                            self:setSizeRelativeY(0)

                            self.data.vertical.sliderData[2] = y

                            self:clear()
                        end
                    end,

                    sortPlayers = function(self)
                        local vertical = self.data.vertical
            
                        local verticalUp, verticalDown = vertical.up, vertical.down
                        
                        local data = {}
            
                        local upLen = #verticalUp
            
                        for i = 1, upLen do
                            data[i] = verticalUp[i].data
                        end
            
                        tableSort(data,
                            function(a, b)
                                local aPlayer = a.player
                                local bPlayer = b.player
    
                                local aPoints = wff2UI.getElementData(aPlayer, "points", false) or 0
                                local bPoints = wff2UI.getElementData(bPlayer, "points", false) or 0
    
                                if aPoints > bPoints then
                                    return true
                                end
    
                                if aPoints < bPoints then
                                    return false
                                end
    
                                local aPlayerNameLower = stringLower(getPlayerName(aPlayer))
                                local bPlayerNameLower = stringLower(getPlayerName(bPlayer))
    
                                if aPlayerNameLower < bPlayerNameLower then
                                    return true
                                end
    
                                if aPlayerNameLower > bPlayerNameLower then
                                    return false
                                end
                            end
                        )
            
                        for i = 1, #data do
                            local dataItem = data[i]
            
                            verticalUp[i].data, verticalDown[upLen - i + 1].data = dataItem, dataItem
                        end
                    end,

                    updateMaxRows = function(self)
                        local custom = self.custom

                        local customMaxTeamRows = custom.maxRows

                        local vertical = self.data.vertical
            
                        local verticalUp = vertical.up

                        local verticalUpLen = #verticalUp

                        local items = {}

                        local count = 0

                        for i = 1, verticalUpLen do
                            local itemData = verticalUp[i].data
                            local teamElement = itemData.team

                            local allowAdd = false

                            count = count + 1

                            if count <= customMaxTeamRows then
                                allowAdd = true
                            end

                            if allowAdd then
                                tableInsert(items, #items + 1, itemData)
                            end
                        end

                        local itemsLen = #items

                        if itemsLen > 0 then
                            local up, down = {}, {}

                            local currentY = 0

                            for i = 1, itemsLen do
                                local item = items[i]
    
                                local sizeY = rowSizeY[item.type]

                                local cell = {
                                    x = cellMarginX,
                                    y = currentY,
                                    sx = sizeX - cellMarginX*2,
                                    sy = sizeY,
                                    data = item
                                }
    
                                currentY = currentY + sizeY + cellMarginY
    
                                up[i], down[itemsLen - i + 1] = cell, cell
                            end

                            local vertical = self.data.vertical

                            local offset = vertical.offset

                            local totalSize = currentY - cellMarginY

                            self:setSizeRelativeY(mathMin(totalSize, itemlistMaxSizeY))

                            local y = mathMax(startY - self.size.ry/2 + diffSizeY, itemlistMaxY)
    
                            self:setPositionAbsoluteY(y)

                            vertical.sliderData[2] = y

                            self:clear():setCellsVertical(up, down)
                            self:setProgressVertical(clamp(offset/vertical.maxOffset, 0, 1))
                        else
                            local y = startY + diffSizeY

                            self:setPositionAbsoluteY(y)
                            self:setSizeRelativeY(0)

                            self.data.vertical.sliderData[2] = y

                            self:clear()
                        end
                    end,

                    findItem = function(self, t, dataName, value, startIndex, stopIndex)
                        for i = startIndex or 1, stopIndex or #t do
                            if t[i][dataName] == value then
                                return i
                            end
                        end
                    end,

                    findItem2 = function(self, t, dataName, dataName2, value, startIndex, stopIndex)
                        for i = startIndex or 1, stopIndex or #t do
                            if t[i][dataName][dataName2] == value then
                                return i
                            end
                        end
                    end,

                    updateMouseScroll = function(self, button, state)
                        if not silentExport("ep_scoreboard", "getUIState") then
                            local direction = button == "mouse_wheel_up" and -1 or button == "mouse_wheel_down" and 1
                
                            if direction then
                                self:scrollAnimatedVertical(direction)
                            end
                        end
                    end,
            
                    eventHandlers = {

                    },

                    rowRenderers = (
                        function()
                            local playerRenderer = function(self, cell, cellX, cellY, cellSx, cellSy, animationProgress, subPixel)
                                local custom = self.custom

                                local data = cell.data

                                local player = data.player

                                local textures = custom.textures

                                do
                                    local y = cellY + cellSy/2

                                    local font = isElement(fonts["roboto-regular-10"]) and fonts["roboto-regular-10"] or "default"

                                    do
                                        local x = cellX + 25*rel

                                        dxDrawText(getPlayerName(player), x, y, x, y, tocolor(255, 255, 255, animationProgress), 1*rel, font, "left", "center", false, false, false, true)
                                    end

                                    do
                                        local x = cellX + cellSx - 15*rel

                                        dxDrawText(wff2UI.getElementData(player, "points", false) or "-", x, y, x, y, tocolor(255, 255, 255, animationProgress), 1*rel, font, "right", "center", false, false, false, true)
                                    end

                                    do
                                        local texture = textures["heart-13"]

                                        if isElement(texture) then
                                            local x = cellX + cellSx - 55*rel

                                            local imgSize = 13*rel

                                            dxDrawImage(mathFloor(x), mathFloor(y - imgSize/2), mathFloor(imgSize), mathFloor(imgSize), texture, 0, 0, 0, tocolor(204, 105, 105, animationProgress*(wff2UI.getElementData(player, "state", false) == "alive" and 1 or 0.5)))
                                        end
                                    end
                                end
                            end

                            local teamRenderer = function(self, cell, cellX, cellY, cellSx, cellSy, animationProgress, subPixel)
                                local custom = self.custom

                                local data = cell.data

                                local team = data.team

                                local textures = custom.textures

                                --[[ do
                                    local texture = textures["round-10"]
        
                                    if isElement(texture) then
                                        drawRoundedRectangle(mathFloor(cellX), mathFloor(cellY), mathFloor(cellSx), mathFloor(cellSy), texture, 10*rel, tocolor(30, 30, 30, animationProgress*0.25))
                                    end
                                end
        
                                do
                                    local texture = textures["empty-round-10"]
        
                                    if isElement(texture) then
                                        drawEmptyRoundedRectangle(mathFloor(cellX), mathFloor(cellY), mathFloor(cellSx), mathFloor(cellSy), texture, 10*rel, 1*rel, tocolor(255, 255, 255, animationProgress*0.05))
                                    end
                                end *]]

                                do
                                    dxDrawLine(cellX + 1*rel, cellY - 1*rel, cellX + cellSx - 2*rel, cellY - 1*rel, tocolor(255, 255, 255, animationProgress*0.05))
                                end

                                do
                                    local y = cellY + cellSy/2

                                    local font = isElement(fonts["roboto-regular-10"]) and fonts["roboto-regular-10"] or "default"

                                    do
                                        local x = cellX + 15*rel

                                        local r, g, b = getTeamColor(team)

                                        dxDrawText(getTeamName(team), x, y, x, y, tocolor(r, g, b, animationProgress), 1*rel, font, "left", "center")
                                    end

                                    do
                                        local count = 0

                                        for i, player in pairs(getPlayersInTeam(team)) do
                                            if wff2UI.getElementData(player, "state", false) == "alive" then
                                                count = count + 1
                                            end
                                        end

                                        local x = cellX + cellSx - 15*rel

                                        dxDrawText(tostring(count) .. " alive", x, y, x, y, tocolor(255, 255, 255, animationProgress*0.7), 1*rel, font, "right", "center")
                                    end
                                end
                            end

                            local rowRenderers = {
                                ["team"] = teamRenderer,
                                ["player"] = playerRenderer
                            }

                            return rowRenderers
                        end
                    )(),

                    stateNames = {
                        ["free"] = "Free",
                        ["live"] = "Live",
                        ["ended"] = "Ended"
                    },

                    stateColors = {
                        ["free"] = { 204, 150, 105 },
                        ["live"] = { 105, 204, 150 },
                        ["ended"] = { 204, 105, 105 }
                    },

                    stateImages = {
                        ["free"] = "pause-14-15",
                        ["live"] = "play-14-15",
                        ["ended"] = "stop-14-15"
                    },

                    maxRows = settings.maxRows,

                    toggleState = false,

                    textures = {},
                    textureFormats = {},

                    players = {},
                    teams = {}
                }
            }

            wff2UI.itemlistData = itemlistData
        end
    end,

    eventHandlers = {
        onClientResourceStart = function(startedResource)
            if getResourceName(startedResource) == "ep_core" then
                wff2UI.cacheFonts()
            end
        end,

        onClientElementDataChange = function(key, oldValue, newValue)
            wff2UI.setElementData(source, key, newValue)
        end,

        onClientRestore = function()
            wff2UI.itemlistElement.custom.updateRenderTarget(wff2UI.itemlistElement)
        end
    },

    keyBinds = {
        toggle = function(key, state)
            wff2UI.itemlistElement:setAnimationState(not wff2UI.itemlistElement.animation.state)

            --[[ local itemlistElement = wff2UI.itemlistElement

            local itemlistElementCustom = itemlistElement.custom

            local modeIndex = (itemlistElementCustom.mode + 1 - 1) % itemlistElementCustom.modes + 1

            itemlistElementCustom.modeFunctions[modeIndex](itemlistElement)

            itemlistElementCustom.mode = modeIndex *]]
        end
    },

    elementData = {},

    fonts = {}
}

event1.modes.wff2.ui = wff2UI

wff2UI.prepareItemlistData()