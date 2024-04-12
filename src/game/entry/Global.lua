-- stdlib global access point
---@diagnostic disable-next-line: lowercase-global
std = require "lib.std"

-- lume global access point
---@diagnostic disable-next-line: lowercase-global
lume = std.lume

-- make common types global
Vector = std.Vector
Bounds = std.Bounds

-- make common functions global
---@diagnostic disable-next-line: lowercase-global
inspect = std.inspect
---@diagnostic disable-next-line: lowercase-global
pretty = std.pretty

-- Extensions to the Love2D interface
require "src.engine.extensions"

-- `Game` object provides a global entry point for game-related state
local GameState = require "game.entry.GameState"
Game = GameState()

-- `Conf` contains global configuration options
Conf = require "game.entry.conf"

if Conf:loggingEnabled() then
    -- Bringup logging
    local Logger = require "engine.Logger"
    local logger = Logger(Conf:logFile())

    ---@diagnostic disable-next-line: lowercase-global
    function log(message, ...)
        logger:log(message, ...)
    end
else
    ---@diagnostic disable-next-line: lowercase-global
    function log(...)
        -- Do nothing
    end
end
