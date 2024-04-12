local std = require "lib.std"
local Frame = require "engine.graphics.Frame"
local Ui = require "engine.graphics.Ui"

local Debugger = std.Object:extend()

local DebuggerPositions = {
    {
        anchor = Vector(-1, 0),
        size = Vector(1.25, 1.0),
    },
    {
        anchor = Vector(-0.25, -1),
        size = Vector(1.25, 0.5),
    }
}

function Debugger:new()
    self.ui = Ui(Frame {
        anchor = DebuggerPositions[1].anchor,
        size = DebuggerPositions[1].size,
        clipped = true,
    })

    self.enabled = false
    self.debuggerPosition = 1

    self.items = {}
end

function Debugger:log(nameOrItem, item)
    local name
    if item == nil then
        name = ""
        item = nameOrItem
    else
        name = nameOrItem
    end

    table.insert(self.items, { name, std.inspect(item) })
end

function Debugger:debugButtons()
    local toggledDebugGraphics = self.ui:button {
        bounds = Bounds.fromPoints(0, 0.95, 0.35, 1),
        text = "Toggle debug graphics",
    }

    if toggledDebugGraphics then
        Conf:toggleDebugGraphics()
    end
end

function Debugger:update()
    self.ui:clear()

    self.ui:renderWith(function()
        love.graphics.setColor(0.65, 0.65, 1.0, 0.55)
        local bounds = self.ui.frame:localBounds()
        love.graphics.rectangle("fill", bounds.x1, bounds.y1, bounds.x2 - bounds.x1, bounds.y2 - bounds.y1)
    end)

    local items = self.items
    self.items = {}
    for i, item in ipairs(items) do
        local name, text = unpack(item)
        self.ui:label {
            text = "["..name.."]: "..text,
            position = Vector(0, (i - 1) * 0.075),
            height = 0.075,
            color = {1, 1, 1, 1},
            shadowColor = {0, 0, 0, 1},
        }
    end

    self:debugButtons()

    if Game.input:buttonJustPressed("debugToggle") then
        self:toggle()
    end
    if self.enabled and Game.input:buttonJustPressed("debugChangePos") then
        self:changePosition()
    end
end

function Debugger:toggle()
    self.enabled = not self.enabled
end

function Debugger:changePosition()
    self.debuggerPosition = (self.debuggerPosition % #DebuggerPositions) + 1

    self.ui.frame.anchor = DebuggerPositions[self.debuggerPosition].anchor
    self.ui.frame.size = DebuggerPositions[self.debuggerPosition].size
end

function Debugger:render()
    if self.enabled then
        self.ui:render()
    end
end

return Debugger
