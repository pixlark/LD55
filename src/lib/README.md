Lua libraries depended on by the game.

Almost everything is re-exported in `std.lua`, so at game boot, simply define `std = require "lib.std"` to set a global project reference for these libraries.
