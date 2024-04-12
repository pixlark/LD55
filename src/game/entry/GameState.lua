local std = require "lib.std"

local Input = require "engine.input.Input"
local ResourceManager = require "engine.resources.ResourceManager"
local SceneManager = require "engine.scenes.SceneManager"
local Screen = require "engine.graphics.Screen"
local Debugger = require "engine.debug.Debugger"

--[[
    GameState
     Global game management and state
]]--

local GameState = std.Object:extend()

function GameState:new()
end

function GameState:init()
    log("Initializing GameState...")

    self.input = Input()
    self.resources = ResourceManager()
    self.sceneManager = SceneManager()
    self.screen = Screen(1.0, { red = 0.2, green = 0.2, blue = 0.2, alpha = 1.0 })
    self.debugger = Debugger()

    self.services = {}

    log("GameState initialized")
end

-- TODO(brooke.tilley):
--   Connect the service provider to the SceneManager, so that
--   they can be automatically deregistered when their scenes die,
--   and so that scenes can override previous scene's registrations
--   temporarily.

function GameState:registerService(name, instance)
    if self.services[name] ~= nil then
        error("Service `"..name.."' is already registered with the GameState!")
    end

    self.services[name] = instance

    log("Registered new service: '%s'", name)
end

function GameState:unregisterService(name, instance)
    log("Unregistering service: '%s'", name)

    local found = self.services[name]
    if found ~= instance then
        return false
    else
        self.services[name] = nil
        return true
    end
end

function GameState:getOptionalService(name)
    return self.services[name]
end

function GameState:getService(name)
    local instance = self:getOptionalService(name)
    if instance == nil then
        error("Could not access service `"..name.."'!")
    end
    return instance
end

return GameState
