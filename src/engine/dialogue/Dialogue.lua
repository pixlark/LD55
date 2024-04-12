local std = require "lib.std"

local Dialogue = std.Object:extend()

Dialogue.new = std.argcheck {
    std.InstanceMethod,
    "stages",
    function (self, t)
        self.stages = t.stages
    end
}

return Dialogue
