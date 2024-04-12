local Scene = require "engine.scenes.Scene"

local EmptyScene = Scene:extend()

function EmptyScene:new()
    self.player = std.Vector(0, 0)
end

function EmptyScene:update()
    local moveDir = Game.input:stick("moveStick")
    local dt = love.timer.getDelta()
    self.player = self.player + moveDir * dt
end

function EmptyScene:render()
    love.graphics.clear(0.1, 0.1, 0.1)

    love.graphics.setColor(0.9, 0.9, 0.9)
    love.graphics.circle("fill", self.player.x, self.player.y, 0.05)
end

return EmptyScene
