local std = require "lib.std"

local ResourceManager = std.Object:extend()

function ResourceManager:new()
    self.images = {}
    self.fonts = {}

    self.emRatios = {}
end

function ResourceManager:image(filename)
    local image = self.images[filename]

    if image == nil then
        image = love.graphics.newPixelImage(filename)
        if image == nil then
            error("No such image resource")
        end
        self.images[filename] = image
    end

    return image
end

-- https://graphicdesign.stackexchange.com/a/4069
function ResourceManager:_getEmRatio(name)
    if self.emRatios[name] == nil then
        local emBoxSize = 10
        local font = love.graphics.newFont(name, emBoxSize)
        local fontHeight = font:getHeight()
        self.emRatios[name] = emBoxSize / fontHeight
    end

    return self.emRatios[name]
end

function ResourceManager:font(name, height)
    local emBoxSize = self:_getEmRatio(name) * height

    local key = name..";"..tostring(emBoxSize)

    if self.fonts[key] == nil then
        local font = love.graphics.newFont(name, emBoxSize)
        font:setFilter("nearest", "nearest")
        self.fonts[key] = font
    end

    return self.fonts[key]
end

return ResourceManager
