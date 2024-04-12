local std = require "lib.std"

local FontBundle = std.Object:extend()

FontBundle.new = std.argcheck {
    std.InstanceMethod,
    "path", "scale", "yOffset",
    function(self, t)
        self.path = t.path
        self.scale = t.scale
        self.yOffset = t.yOffset
    end
}

FontBundle.DefaultUi = FontBundle {
    path = "res/Eczar-VariableFont_wght.ttf",
    scale = 1.25,
    yOffset = 2,
}

FontBundle.DefaultDialogue = FontBundle {
    path = "res/Eczar-VariableFont_wght.ttf",
    scale = 1.0,
    yOffset = 0,
}

return FontBundle
