local std = require "lib.std"

local Screen = std.Object:extend()

function Screen:new(aspect, backgroundColor)
    self.aspect = aspect
    self.backgroundColor = backgroundColor
    self.scissorStack = {}

    self.windowResizeSubscriptions = {}
end

function Screen:windowResized()
    for _, func in ipairs(self.windowResizeSubscriptions) do
        func()
    end
end

function Screen:windowResizedSubscribe(func)
    table.insert(self.windowResizeSubscriptions, func)
end

function Screen:width()
    local width, _, _ = love.window.getMode()
    return width
end

function Screen:height()
    local _, height, _ = love.window.getMode()
    return height
end

function Screen:_getVirtualScaleFactor()
    local screenWidth, screenHeight = self:width(), self:height()

    local aspect = screenWidth / screenHeight
    if aspect >= 1.0 then
        -- Screen is wider than it is tall
        return screenHeight / 2.0
    elseif aspect < 1.0 then
        -- Screen is taller than it is wide
        return screenWidth / 2.0
    end
end

function Screen:_getVirtualOffset()
    local screenWidth, screenHeight = self:width(), self:height()
    return screenWidth / 2.0, screenHeight / 2.0
end

function Screen:getTransform()
    local scaleFactor = self:_getVirtualScaleFactor()
    local offsetX, offsetY = self:_getVirtualOffset()
    return love.math.newTransform()
        :translate(offsetX, offsetY)
        :scale(scaleFactor, scaleFactor)
end

function Screen:globalToScreenSpace(vec)
    return Vector(self:getTransform():transformPoint(vec.x, vec.y))
end

function Screen:screenToGlobalSpace(vec)
    return Vector(self:getTransform():inverseTransformPoint(vec.x, vec.y))
end

function Screen:startRender()
    love.graphics.clear(self.backgroundColor)
end

function Screen:finishRender()
    local screenWidth, screenHeight = self:width(), self:height()
    local realAspect = screenWidth / screenHeight

    local bars = {}

    if realAspect == self.aspect then
        return
    elseif realAspect > self.aspect then
        local barAspect = (realAspect - self.aspect) / 2.0
        local barWidth = barAspect * screenHeight

        -- Left-side bar
        table.insert(bars, { x1 = 0.0, y1 = 0.0, x2 = barWidth, y2 = screenHeight })

        -- Right-side bar
        table.insert(bars, { x1 = screenWidth - barWidth, y1 = 0.0, x2 = screenWidth, y2 = screenHeight })
    else
        local barAspect = ((1.0 / realAspect) - (1.0 / self.aspect)) / 2.0
        local barHeight = barAspect * screenWidth

        -- Top bar
        table.insert(bars, { x1 = 0.0, y1 = 0.0, x2 = screenWidth, y2 = barHeight })

        -- Bottom bar
        table.insert(bars, { x1 = 0.0, y1 = screenHeight - barHeight, x2 = screenWidth, y2 = screenHeight })
    end

    love.graphics.setColorWithTable(self.backgroundColor)
    for _, bar in ipairs(bars) do
        love.graphics.rectangle("fill", bar.x1, bar.y1, bar.x2 - bar.x1, bar.y2 - bar.y1)
    end
end

function Screen:pushScissor(bounds)
    table.insert(self.scissorStack, bounds)
    love.graphics.setScissor(bounds.x1, bounds.y1, bounds.x2 - bounds.x1, bounds.y2 - bounds.y1)
end

function Screen:popScissor()
    table.remove(self.scissorStack)
    if #self.scissorStack == 0 then
        love.graphics.setScissor(0, 0, self:width(), self:height())
    else
        local newScissor = self.scissorStack[#self.scissorStack]
        love.graphics.setScissor(newScissor.x1, newScissor.y1, newScissor.x2 - newScissor.x1, newScissor.y2 - newScissor.y1)
    end
end

return Screen
