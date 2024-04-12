local std = require "lib.std"

local Frame = std.Object:extend()

Frame.new = std.argcheck {
    std.InstanceMethod,
    -- Required
    "anchor", "size", "clipped",
    -- Optional
    {"scale", 1.0},
    {"anchorType", "topleft"},
    {"parent", std.Nil},

    function(self, t)
        if t.scale == nil then
            t.scale = 1.0
        end

        if t.anchorType == nil then
            t.anchorType = "topleft"
        end

        self.anchor = t.anchor
        self.size = t.size
        self.scale = t.scale
        self.anchorType = t.anchorType
        self.parent = t.parent
    end
}

function Frame:_getVirtualScaleFactor()
    local aspect = self.size.x / self.size.y
    local scale

    if aspect >= 1.0 then
        -- Screen is wider than it is tall
        local localHeight = self.size.y
        local screenHeight = 2.0

        scale = localHeight / screenHeight
    elseif aspect < 1.0 then
        -- Screen is taller than it is wide
        local localWidth = self.size.x
        local screenWidth = 2.0

        scale = localWidth / screenWidth
    end

    if self.anchorType == "topleft" then
        -- Adjust coordinate system to be [0, 1]x[0,1] instead of [-1, 1]x[-1, 1]
        -- when our anchor is in the top-left
        return scale * 2
    else
        return scale
    end
end

function Frame:getParentTransform()
    if self.parent ~= nil then
        std.notImplementedException()
    else
        return Game.screen:getTransform()
    end
end

function Frame:getBounds()
    if self.anchorType == "topleft" then
        return Bounds.fromCorners(self.anchor, self.anchor + self.size)
    elseif self.anchorType == "center" then
        local radius = self.size / 2.0
        return Bounds.fromCorners(self.anchor - radius, self.anchor + radius)
    else
        error()
    end
end

function Frame:fromPixelLength(pixels)
    local baseTransform = Game.screen:getTransform()
    local transform = baseTransform:apply(self:getTransform())
    local inverseTransform = transform:inverse()

    local origin = Vector(0, 0)
    local pixelsPoint = Vector(pixels, 0)

    local inverseOrigin = Vector(inverseTransform:transformPoint(origin.x, origin.y))
    local inversePixelsPoint = Vector(inverseTransform:transformPoint(pixelsPoint.x, pixelsPoint.y))

    return inverseOrigin:dist(inversePixelsPoint)
end

function Frame:asPixelLength(length)
    local baseTransform = Game.screen:getTransform()
    local transform = baseTransform:apply(self:getTransform())

    local origin = Vector(0, 0)
    local point = Vector(length, 0)

    local transformedOrigin = Vector(transform:transformPoint(origin.x, origin.y))
    local transformedPoint = Vector(transform:transformPoint(point.x, point.y))

    return transformedOrigin:dist(transformedPoint)
end

function Frame:getTransform()
    local scale = self:_getVirtualScaleFactor()
    return love.math.newTransform()
        :translate(self.anchor.x, self.anchor.y)
        :scale(scale, scale)
end

function Frame:getFullTransform()
    return self:getParentTransform()
        :apply(self:getTransform())
end

function Frame:getInverseTransform()
    return self:getTransform():inverse()
end

function Frame:push()
    if self.parent ~= nil then
        std.notImplementedException()
    end

    local localBounds = self:getBounds()
    local screenBounds = Bounds.fromCorners(
        Vector(love.graphics.transformPoint(localBounds.x1, localBounds.y1)),
        Vector(love.graphics.transformPoint(localBounds.x2, localBounds.y2))
    )

    if self.clipped then
        Game.screen:pushScissor(screenBounds)
    end

    -- std.pretty(self)
    -- print("transform (1, 0)x{0, 1} -> "..std.inspect({ Vector(love.graphics.transformPoint(1, 0)), Vector(love.graphics.transformPoint(0, 1)) }))

    love.graphics.push("all")
    love.graphics.applyTransform(self:getTransform())
end

function Frame:pop()
    love.graphics.pop()

    if self.clipped then
        Game.screen:popScissor()
    end

    if self.parent ~= nil then
        std.notImplementedException()
    end
end

function Frame:print(text, font, position)
    local screenTransform = Game.screen:getTransform()
    local transform = screenTransform:apply(self:getTransform())
    local transformedPosition = Vector(transform:transformPoint(position.x, position.y))

    love.graphics.push("all")

        love.graphics.origin()
        love.graphics.setFont(font)
        love.graphics.print(text, transformedPosition.x, transformedPosition.y)

    love.graphics.pop()
end

-- function Frame:printf(text, font, position, wrapAt)
--     local screenTransform = Game.screen:getTransform()
--     local transform = screenTransform:apply(self:getTransform())
--     local transformedPosition = Vector(transform:transformPoint(position.x, position.y))

--     love.graphics.push("all")

--         love.graphics.origin()
--         love.graphics.setFont(font)
--         love.graphics.printf(text, transformedPosition.x, transformedPosition.y, wrapAt)

--     love.graphics.pop()
-- end

function Frame:localBounds()
    local bounds = self:getBounds()
    local inverseTransform = self:getTransform():inverse()
    local left, top = inverseTransform:transformPoint(bounds.x1, bounds.y1)
    local right, bottom = inverseTransform:transformPoint(bounds.x2, bounds.y2)
    local localBounds = Bounds.fromPoints(left, top, right, bottom)
    return localBounds
end

function Frame:renderWith(func)
    self:push()
    func()
    self:pop()
end

function Frame:debugDrawBounds()
    local bounds = self:getBounds()
    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.setLineWidth(0.005)
    love.graphics.rectangle("line", bounds.x1, bounds.y1, bounds.x2 - bounds.x1, bounds.y2 - bounds.y1)
end

return Frame
