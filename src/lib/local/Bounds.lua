local Vector = require "lib.forked.vector"

local Object = require "lib.forked.classic"
local decorators = require "lib.local.decorators"

local argcheck = decorators.argcheck
local InstanceMethod = decorators.InstanceMethod

local Bounds = Object:extend()

Bounds.new = argcheck {
    InstanceMethod,
    "x1", "y1", "x2", "y2",
    function (self, t)
        self.x1 = t.x1
        self.y1 = t.y1
        self.x2 = t.x2
        self.y2 = t.y2
    end
}

function Bounds.fromPoints(x1, y1, x2, y2)
    return Bounds { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end

function Bounds.fromCorners(topLeft, bottomRight)
    return Bounds { x1 = topLeft.x, y1 = topLeft.y, x2 = bottomRight.x, y2 = bottomRight.y }
end

function Bounds.fromRect(topLeft, size)
    return Bounds { x1 = topLeft.x, y1 = topLeft.y, x2 = topLeft.x + size.x, y2 = topLeft.y + size.y }
end

function Bounds:contains(point)
    return point.x >= self.x1 and point.x <= self.x2 and point.y >= self.y1 and point.y <= self.y2
end

function Bounds:topLeft()
    return Vector(self.x1, self.y1)
end

function Bounds:bottomRight()
    return Vector(self.x2, self.y2)
end

function Bounds:left()
    return self.x1
end

function Bounds:top()
    return self.y1
end

function Bounds:right()
    return self.x2
end

function Bounds:bottom()
    return self.y2
end

function Bounds:width()
    return self.x2 - self.x1
end

function Bounds:height()
    return self.y2 - self.y1
end

function Bounds:size()
    return Vector(self:width(), self:height())
end

function Bounds:center()
    return self:topLeft() + self:size() / 2
end

function Bounds:scaleAroundCenter(scaleFactor)
    local radius = self:size() / 2
    local center = self:center()

    local scaledTopLeft = center - radius * scaleFactor
    local scaledBottomRight = center + radius * scaleFactor

    return Bounds.fromCorners(scaledTopLeft, scaledBottomRight)
end

function Bounds.__pretty(_, self)
    return "Bounds{ ("..self.x1..", "..self.y1..") x ("..self.x2..", "..self.y2..") }"
end

return Bounds
