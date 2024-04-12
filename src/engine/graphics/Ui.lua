local std = require "lib.std"
local FontBundle = require "engine.resources.FontBundle"

local Ui = std.Object:extend()

local wordwrap = require "engine.tools.wordwrap"
local wrapTextToLines = wordwrap.wrapTextToLines
local wrapAnnotatedTextToLines = wordwrap.wrapAnnotatedTextToLines

function Ui:new(frame)
    self.frame = frame
    self.mocking = false

    love.graphics.push("all")
        love.graphics.origin()
        self.canvas = love.graphics.newCanvas()
    love.graphics.pop()

    Game.screen:windowResizedSubscribe(function ()
        self.canvas = love.graphics.newCanvas()
    end)
end

function Ui:enableMocking()
    assert(not self.mocking)
    self.mocking = true
    self.savedCanvas = self.canvas
    self.canvas = love.graphics.newCanvas()
end

function Ui:disableMocking()
    assert(self.mocking)
    self.mocking = false
    self.canvas = self.savedCanvas
end

Ui.label = std.argcheck {
    std.InstanceMethod,
    "text", "position", "height",
    {"color", {1, 1, 1, 1}},
    {"shadowColor", nil},
    {"fontBundle", FontBundle.DefaultUi},
    {"wrapWidth", nil},
    {"centerInHeight", nil},
    {"chunkSpacing", 0.5},
    function(self, t)
        local fontHeight = self.frame:asPixelLength(t.height * t.fontBundle.scale)
        local font = Game.resources:font(t.fontBundle.path, fontHeight)
        local chunkSpacing = t.chunkSpacing * t.height * t.fontBundle.scale

        local annotatedLines
        if type(t.text) == "table" then
            -- Annotated text
            assert(t.wrapWidth ~= nil)
            local pixelWrapWidth = self.frame:asPixelLength(t.wrapWidth)
            annotatedLines = wrapAnnotatedTextToLines(t.text, font, pixelWrapWidth)
        elseif t.wrapWidth ~= nil then
            local pixelWrapWidth = self.frame:asPixelLength(t.wrapWidth)
            local lines = wrapTextToLines(t.text, font, pixelWrapWidth)
            annotatedLines = std.iterate(lines)
                :map(function (line) return { spans = { text = line, index = 1 } } end)
                :collect()
        else
            annotatedLines = { { spans = { { text = t.text, index = 1 } } } }
        end

        local centeringOffset = 0
        if t.centerInHeight ~= nil then
            local lineHeight = t.height * t.fontBundle.scale
            local textHeight = #annotatedLines * lineHeight
            local differenceInContainer = t.centerInHeight - textHeight
            centeringOffset = differenceInContainer / 2
        end

        local finalRenderedBounds = {}
        local function markRenderedBounds(bounds, chunkIndex)
            if finalRenderedBounds[chunkIndex] == nil then
                finalRenderedBounds[chunkIndex] = { bounds }
            else
                table.insert(finalRenderedBounds[chunkIndex], bounds)
            end
        end

        for lineIndex, annotatedLine in ipairs(annotatedLines) do
            local xOffset = 0
            for _, span in ipairs(annotatedLine.spans) do
                local yOffset = (lineIndex - 1) * t.height * t.fontBundle.scale

                self.canvas:renderTo(function()
                    local text = span.text
                    local chunkIndex = span.index

                    local fontBundleOffset = self.frame:fromPixelLength(t.fontBundle.yOffset)
                    local pos = t.position + Vector(xOffset, yOffset + centeringOffset + fontBundleOffset)

                    if t.shadowColor ~= nil then
                        local onePixel = self.frame:fromPixelLength(2)
                        love.graphics.setColor(unpack(t.shadowColor))
                        self.frame:print(text, font, pos + Vector(onePixel, onePixel))
                    end

                    love.graphics.setColor(unpack(t.color))
                    self.frame:print(text, font, pos)

                    local chunkWidthPixels = font:getWidth(text)
                    local chunkWidth = self.frame:fromPixelLength(chunkWidthPixels)
                    xOffset = xOffset + chunkWidth

                    markRenderedBounds(Bounds.fromRect(pos, Vector(chunkWidth, t.height)), chunkIndex)
                end)
            end
        end

        return finalRenderedBounds
    end
}

local ButtonRenderTypes = {
    FilledRect = 1,
    Image = 2,
}

Ui.button = std.argcheck {
    std.InstanceMethod,
    "bounds",
    {"text", nil},
    {"textColor", { 0.95, 0.95, 0.95, 1 }},
    {"fontBundle", FontBundle.DefaultUi},

    {"color", nil},
    {"hoverColor", nil},
    {"pressColor", nil},

    {"image", nil},
    {"maintainImageAspect", true},
    {"imageScale",      1.0 },
    {"imageHoverScale", 1.1 },
    {"imagePressScale", 1.15},

    function(self, t)
        -- Determine the type of button that we're rendering
        local buttonRenderType = ButtonRenderTypes.FilledRect
        if t.image ~= nil then
            buttonRenderType = ButtonRenderTypes.Image
        end

        -- Set default colors based on button render type
        if buttonRenderType == ButtonRenderTypes.FilledRect then
            t.color      = t.color      or { 0.35, 0.35, 0.35, 1 }
            t.hoverColor = t.hoverColor or { 0.3,  0.3,  0.3,  1 }
            t.pressColor = t.pressColor or { 0.2,  0.2,  0.2,  1 }
        elseif buttonRenderType == ButtonRenderTypes.Image then
            t.color      = t.color      or { 0.85, 0.85, 0.85, 1 }
            t.hoverColor = t.hoverColor or { 0.95, 0.95, 0.95, 1 }
            t.pressColor = t.pressColor or { 1.0,  1.0,  1.0,  1 }
        else
            std.unreachableException()
        end

        local returnPressed = false
        self.canvas:renderTo(function()
            self.frame:renderWith(function()
                -- Get interaction information
                local mpos = Vector(love.graphics.inverseTransformPoint(love.mouse.getPosition()))
                local hover = t.bounds:contains(mpos)
                local justClicked = Game.input:buttonJustPressed("leftClick")

                if hover and justClicked then
                    returnPressed = true
                end

                -- Render button background
                if hover and justClicked then
                    love.graphics.setColor(unpack(t.pressColor))
                elseif hover then
                    love.graphics.setColor(unpack(t.hoverColor))
                else
                    love.graphics.setColor(unpack(t.color))
                end

                if buttonRenderType == ButtonRenderTypes.FilledRect then
                    -- Background is a simple rectangle
                    love.graphics.rectWithBounds("fill", t.bounds)
                elseif buttonRenderType == ButtonRenderTypes.Image then
                    -- Background is a custom image
                    local imageScale
                    if hover and justClicked then
                        imageScale = t.imagePressScale
                    elseif hover then
                        imageScale = t.imageHoverScale
                    else
                        imageScale = t.imageScale
                    end

                    love.graphics.drawInBounds(t.image, t.bounds:scaleAroundCenter(imageScale), t.maintainImageAspect)
                else
                    std.unreachableException()
                end

                -- Draw text
                if t.text ~= nil then
                    local boundsHeight = t.bounds.y2 - t.bounds.y1
                    local textHeight = boundsHeight * t.fontBundle.scale
                    local textHeightPixels = self.frame:asPixelLength(textHeight)

                    local font = Game.resources:font(t.fontBundle.path, textHeightPixels)
                    local textWidthPixels = font:getWidth(t.text)
                    local textWidth = self.frame:fromPixelLength(textWidthPixels)

                    local centerX, centerY = (t.bounds.x1 + t.bounds.x2) / 2, (t.bounds.y1 + t.bounds.y2) / 2
                    local position = Vector(
                        centerX - textWidth / 2,
                        centerY - textHeight / 2 + self.frame:fromPixelLength(t.fontBundle.yOffset)
                    )

                    love.graphics.setColor(unpack(t.textColor))
                    self.frame:print(t.text, font, position)
                end
            end)
        end)
        return returnPressed
    end
}

function Ui:renderWith(func)
    self.canvas:renderTo(function()
        self.frame:renderWith(function()
            func()
        end)
    end)
end

function Ui:clear()
    self.canvas:renderTo(function()
        love.graphics.clear(0, 0, 0, 0)
    end)
end

function Ui:render()
    love.graphics.push("all")
        love.graphics.origin()
        love.graphics.setColor(1, 1, 1, 1)
        local prevBlendMode = { love.graphics.getBlendMode() }
        love.graphics.setBlendMode("alpha", "premultiplied")
            love.graphics.draw(self.canvas)
        love.graphics.setBlendMode(unpack(prevBlendMode))
    love.graphics.pop()
end

return Ui
