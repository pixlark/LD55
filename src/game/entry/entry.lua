require "game.entry.Global"

local EmptyScene = require "game.scenes.EmptyScene"

local profilerTimestamp = -math.huge
local profilerReport = nil

--
-- Hooks into Love2D
--

function love.load()
    if Conf:profilerEnabled() then
        if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") ~= nil then
            error("Cannot run the profiler and the debugger at the same time!")
        end

        log("Starting profiler...")
        std.profile.start()
        log("Profiler started")
    end

    Game:init()

    love.graphics.push("all")
    love.graphics.applyTransform(Game.screen:getTransform())

    -- WASD/DPad/Left stick
    Game.input:bindKeyStick("moveStick", "w", Vector(0, -1))
    Game.input:bindKeyStick("moveStick", "a", Vector(-1, 0))
    Game.input:bindKeyStick("moveStick", "s", Vector(0, 1))
    Game.input:bindKeyStick("moveStick", "d", Vector(1, 0))

    Game.input:bindControllerButtonToStick("moveStick", "dpup", Vector(0, -1))
    Game.input:bindControllerButtonToStick("moveStick", "dpleft", Vector(-1, 0))
    Game.input:bindControllerButtonToStick("moveStick", "dpdown", Vector(0, 1))
    Game.input:bindControllerButtonToStick("moveStick", "dpright", Vector(1, 0))

    Game.input:bindControllerStick("moveStick", "left")

    -- Debug controls
    Game.input:bindKeyButton("debugToggle", "`")
    Game.input:bindKeyButton("debugChangePos", "tab")

    Game.sceneManager:pushScene(EmptyScene())

    love.graphics.pop()
end

function love.update()
    if Conf:profilerEnabled() then
        local timestamp = love.timer.getTime()
        if timestamp - profilerTimestamp >= 5.0 then
            log("Generating profiler report...")
            profilerReport = std.profile.report(20)
            log("Profiler report:\n"..profilerReport)
            std.profile.reset()

            profilerTimestamp = timestamp
        end
    end

    love.graphics.push("all")
    love.graphics.applyTransform(Game.screen:getTransform())

        Game.debugger:log("fps", love.timer.getFPS())

        Game.input:update()
        Game.sceneManager:update()

        Game.debugger:update()

        if Conf:allRuntimeTests() then
            Game.sceneManager:executeRuntimeTests()
        end

    love.graphics.pop()
end

function love.draw()
    love.graphics.push("all")
    love.graphics.applyTransform(Game.screen:getTransform())

        Game.screen:startRender()

        Game.sceneManager:render()

        Game.debugger:render()

    love.graphics.pop()

    Game.screen:finishRender()

    if Conf:profilerEnabled() and profilerReport ~= nil then
        love.graphics.print(profilerReport)
    end
end

function love.resize()
    Game.screen:windowResized()
end
