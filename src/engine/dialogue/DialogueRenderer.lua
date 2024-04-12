local std = require "lib.std"

local Ui = require "engine.graphics.Ui"
local FontBundle = require "engine.resources.FontBundle"

local DialogueRenderer = Ui:extend()

function DialogueRenderer:new(frame, dialogue)
    DialogueRenderer.super.new(self, frame)
    self.dialogue = dialogue
    self.currentDialogueStage = 1
end

function DialogueRenderer:currentStage()
    return self.dialogue.stages[self.currentDialogueStage]
end

DialogueRenderer.renderDialogue = std.argcheck {
    std.InstanceMethod,
    {"textColor", { 0.15, 0.15, 0.15, 1 }},
    {"shadowColor", { 0.8, 0.8, 0.8, 1 }},
    {"fontBundle", FontBundle.DefaultDialogue},
    {"padding", Vector(0.1, 0.1)},
    {"color", { 1, 0.756, 0.756, 1 }},
    {"hoverColor", { 0.9, 0.65, 0.65, 1 }},
    {"pressColor", { 0.85, 0.6, 0.6, 1 }},
    function (self, t)
        local dialogueText = self:currentStage():chunks()

        local frameBounds = self.frame:localBounds()
        frameBounds.x1 = frameBounds.x1 + t.padding.x
        frameBounds.x2 = frameBounds.x2 - t.padding.x
        frameBounds.y1 = frameBounds.y1 + t.padding.y
        frameBounds.y2 = frameBounds.y2 - t.padding.y

        local fontHeight = (frameBounds.y2 - frameBounds.y1) * 0.28

        local labelArgs = {
            text = dialogueText,
            position = Vector(frameBounds.x1, frameBounds.y1),
            height = fontHeight,
            color = t.textColor,
            shadowColor = t.shadowColor,
            wrapWidth = frameBounds.x2 - frameBounds.x1,
            fontBundle = t.fontBundle,
            centerInHeight = frameBounds.y2 - frameBounds.y1,
        }

        -- Before actually rendering, render once "mocked" (meaning not actually renderered)
        -- so that we can get the label bounds beforehand
        self:enableMocking()

            local allLabelBounds = self:label(labelArgs)

        self:disableMocking()

        -- Draw buttons underneath interactable script lines
        for chunkIndex, labelBoundsSet in ipairs(allLabelBounds) do
            local interactIndex = self:currentStage():getInteractIndex(chunkIndex)
            if interactIndex ~= nil then
                local buttonBounds = {}

                for _, labelBounds in ipairs(labelBoundsSet) do
                    table.insert(
                        buttonBounds,
                        Bounds.fromPoints(
                            labelBounds.x1 - 0.01,
                            labelBounds.y1 + 0.02,
                            labelBounds.x2 + 0.01,
                            labelBounds.y2 - 0.04))
                end

                self:dialogueButton {
                    boundsSet = buttonBounds,
                    color = t.color,
                    hoverColor = t.hoverColor,
                    pressColor = t.pressColor,
                }
            end
        end

        -- Do the actual render
        self:label(labelArgs)
    end
}

DialogueRenderer.dialogueButton = std.argcheck {
    std.InstanceMethod,
    "boundsSet",
    {"color", { 0.35, 0.35, 0.35, 1 }},
    {"hoverColor", { 0.3, 0.3, 0.3, 1 }},
    {"pressColor", { 0.2, 0.2, 0.2, 1 }},
    function(self, t)
        local returnPressed = false
        self.canvas:renderTo(function()
            self.frame:renderWith(function()
                local hover = false
                local justClicked = false

                for _, bounds in ipairs(t.boundsSet) do
                    local mpos = Vector(love.graphics.inverseTransformPoint(love.mouse.getPosition()))
                    hover = hover or bounds:contains(mpos)
                    justClicked = justClicked or Game.input:buttonJustPressed("leftClick")
                end

                for _, bounds in ipairs(t.boundsSet) do
                    if hover and justClicked then
                        returnPressed = true
                        love.graphics.setColor(unpack(t.pressColor))
                    elseif hover then
                        love.graphics.setColor(unpack(t.hoverColor))
                    else
                        love.graphics.setColor(unpack(t.color))
                    end
                    love.graphics.rectWithBounds("fill", bounds)
                end
            end)
        end)
        return returnPressed
    end
}

return DialogueRenderer
