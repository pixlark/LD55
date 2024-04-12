local std = require "lib.std"

local function uniqueInsert(tbl, x)
    if not std.any(function(y) return x == y end, tbl) then
        table.insert(tbl, x)
    end
end

local KeyTrigger = std.Object:extend()

function KeyTrigger:new(key, value)
    self.key = key
    self.value = value
end

local KeyStick = std.Object:extend()

function KeyStick:new(key, value)
    self.key = key
    self.value = value
end

local Input = std.Object:extend()

function Input:new()
    -- maps bindings -> controller buttons
    self.controllerButtons = {}
    -- maps bindings -> key buttons
    self.keyButtons = {}
    -- maps bindings -> controller triggers
    self.controllerTriggers = {}
    -- maps bindings -> array({ key button, value })
    self.keyTriggers = {}
    -- maps bindings -> array({ controller button, value })
    self.controllerButtonedTriggers = {}
    -- maps bindings -> controller sticks
    self.controllerSticks = {}
    -- maps bindings -> array({ key button, { x, y } })
    self.keySticks = {}
    -- maps bindings -> array({ controller button, { x, y } })
    self.controllerButtonedSticks = {}

    -- track all key/button bindings every frame
    self.allBoundKeyButtons = {}
    self.allBoundControllerButtons = {}

    self.keyButtonsLastFrame = {}
    self.controllerButtonsLastFrame = {}

    self.deadzones = {
        trigger = {
            left = 0.1,
            right = 0.1,
        },
        stick = {
            left = 0.25,
            right = 0.25,
        },
    }
end

function Input:update()
    self.keyButtonsLastFrame = std.copy(self.allBoundKeyButtons)
    self.controllerButtonsLastFrame = std.copy(self.allBoundControllerButtons)

    for key, _ in pairs(self.allBoundKeyButtons) do
        self.allBoundKeyButtons[key] = self:_keyDown(key)
    end

    for button, _ in pairs(self.allBoundControllerButtons) do
        self.allBoundControllerButtons[button] = false
        for _, joystick in ipairs(love.joystick.getJoysticks()) do
            if joystick:isGamepadDown(button) then
                self.allBoundControllerButtons[button] = true
            end
        end
    end
end

--
-- Create bindings
--

function Input:bindKeyButton(name, key)
    do
        assert(type(name) == "string")
        assert(type(key) == "string")
    end

    if self.keyButtons[name] == nil then
        self.keyButtons[name] = {}
    end

    uniqueInsert(self.keyButtons[name], key)
    if self.allBoundKeyButtons[key] == nil then
        self.allBoundKeyButtons[key] = false
        self.keyButtonsLastFrame[key] = false
    end
end

function Input:bindControllerButton(name, button)
    do
        assert(type(name) == "string")
        assert(type(button) == "string")
    end

    if self.controllerButtons[name] == nil then
        self.controllerButtons[name] = {}
    end

    uniqueInsert(self.controllerButtons[name], button)
    if self.allBoundControllerButtons[button] == nil then
        self.allBoundControllerButtons[button] = false
        self.controllerButtonsLastFrame[button] = false
    end
end

function Input:bindKeyTrigger(name, key, value)
    do
        assert(type(name) == "string")
        assert(type(key) == "string")
        assert(type(value) == "number")
    end

    if self.keyTriggers[name] == nil then
        self.keyTriggers[name] = {}
    end

    self.keyTriggers[name][key] = value
end

function Input:bindControllerButtonToTrigger(name, button, value)
    do
        assert(type(name) == "string")
        assert(type(button) == "string")
        assert(type(value) == "number")
    end

    if self.controllerButtonedTriggers[name] == nil then
        self.controllerButtonedTriggers[name] = {}
    end

    self.controllerButtonedTriggers[name][button] = value
end

function Input:bindControllerTrigger(name, trigger)
    do
        assert(type(name) == "string")
        assert(type(trigger) == "string")
        assert(trigger == "left" or trigger == "right")
    end

    if self.controllerTriggers[name] == nil then
        self.controllerTriggers[name] = {}
    end

    uniqueInsert(self.controllerTriggers[name], trigger)
end

function Input:bindKeyStick(name, key, value)
    do
        assert(type(name) == "string")
        assert(type(key) == "string")
        assert(type(value) == "table")
    end

    if self.keySticks[name] == nil then
        self.keySticks[name] = {}
    end

    self.keySticks[name][key] = value
end

function Input:bindControllerButtonToStick(name, button, value)
    do
        assert(type(name) == "string")
        assert(type(button) == "string")
        assert(type(value) == "table")
    end

    if self.controllerButtonedSticks[name] == nil then
        self.controllerButtonedSticks[name] = {}
    end

    self.controllerButtonedSticks[name][button] = value
end

function Input:bindControllerStick(name, stick)
    do
        assert(type(name) == "string")
        assert(type(stick) == "string")
        assert(stick == "left" or stick == "right")
    end

    if self.controllerSticks[name] == nil then
        self.controllerSticks[name] = {}
    end

    uniqueInsert(self.controllerSticks[name], stick)
end

--
-- Test bindings
--

local mouseKeys = {
    mouse1 = 1,
    mouse2 = 2,
    mouse3 = 3,
}

function Input:_keyDown(key)
    if mouseKeys[key] ~= nil then
        return love.mouse.isDown(mouseKeys[key])
    end

    return love.keyboard.isDown(key)
end

function Input:_keyJustPressed(key)
    return self.allBoundKeyButtons[key] and (not self.keyButtonsLastFrame[key])
end

function Input:_keyJustReleased(key)
    return (not self.allBoundKeyButtons[key]) and self.keyButtonsLastFrame[key]
end

function Input:_controllerButtonJustPressed(button)
    return self.allBoundControllerButtons[button] and (not self.controllerButtonsLastFrame[button])
end

function Input:_controllerButtonJustReleased(button)
    return (not self.allBoundControllerButtons[button]) and self.controllerButtonsLastFrame[button]
end

function Input:buttonDown(name)
    if self.keyButtons[name] ~= nil then
        for _, key in ipairs(self.keyButtons[name]) do
            if self:_keyDown(key) then
                return true
            end
        end
    end

    if self.controllerButtons[name] ~= nil then
        for _, joystick in ipairs(love.joystick.getJoysticks()) do
            if joystick:isGamepadDown(unpack(self.controllerButtons[name])) then
                return true
            end
        end
    end

    return false
end

function Input:buttonJustPressed(name)
    if self.keyButtons[name] ~= nil then
        for _, key in ipairs(self.keyButtons[name]) do
            if self:_keyJustPressed(key) then
                return true
            end
        end
    end

    if self.controllerButtons[name] ~= nil then
        for _, button in ipairs(self.controllerButtons[name]) do
            if self:_controllerButtonJustPressed(button) then
                return true
            end
        end
    end

    return false
end

function Input:buttonJustReleased(name)
    if self.keyButtons[name] ~= nil then
        for _, key in ipairs(self.keyButtons[name]) do
            if self:_keyJustReleased(key) then
                return true
            end
        end
    end

    if self.controllerButtons[name] ~= nil then
        for _, button in ipairs(self.controllerButtons[name]) do
            if self:_controllerButtonJustReleased(button) then
                return true
            end
        end
    end

    return false
end

function Input:trigger(name)
    if self.keyTriggers[name] ~= nil then
        for key, value in pairs(self.keyTriggers[name]) do
            if self:_keyDown(key) then
                return value
            end
        end
    end

    if self.controllerButtonedTriggers[name] ~= nil then
        for _, joystick in ipairs(love.joystick.getJoysticks()) do
            for button, value in pairs(self.controllerButtonedTriggers[name]) do
                if joystick:isGamepadDown(button) then
                    return value
                end
            end
        end
    end

    if self.controllerTriggers[name] ~= nil then
        for _, joystick in ipairs(love.joystick.getJoysticks()) do
            for _, trigger in ipairs(self.controllerTriggers[name]) do
                local triggerAxis
                if trigger == "left" then
                    triggerAxis = "triggerleft"
                elseif trigger == "right" then
                    triggerAxis = "triggerright"
                else
                    error()
                end

                local axisValue = joystick:getGamepadAxis(triggerAxis)
                if axisValue > self.deadzones.trigger[trigger] then
                    return axisValue
                end
            end
        end
    end

    return 0.0
end

function Input:stick(name)
    local dir = Vector(0, 0)

    if self.keySticks[name] ~= nil then
        for key, value in pairs(self.keySticks[name]) do
            if self:_keyDown(key) then
                dir = dir + value
            end
        end
    end

    if self.controllerButtonedSticks[name] ~= nil then
        for _, joystick in ipairs(love.joystick.getJoysticks()) do
            for button, value in pairs(self.controllerButtonedSticks[name]) do
                if joystick:isGamepadDown(button) then
                    dir = dir + value
                end
            end
        end
    end

    if self.controllerSticks[name] ~= nil then
        for _, joystick in ipairs(love.joystick.getJoysticks()) do
            for _, stick in ipairs(self.controllerSticks[name]) do
                local axes
                if stick == "left" then
                    axes = { "leftx", "lefty" }
                elseif stick == "right" then
                    axes = { "rightx", "righty" }
                else
                    error()
                end

                local axesValue = Vector(
                    joystick:getGamepadAxis(axes[1]),
                    joystick:getGamepadAxis(axes[2])
                )

                if axesValue:len() > self.deadzones.stick[stick] then
                    dir = dir + axesValue
                end
            end
        end
    end

    return dir:normalized()
end

return Input
