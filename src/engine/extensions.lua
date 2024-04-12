--
-- Extensions to Love
--

local std = require "lib.std"

-- love.graphics

function love.graphics.rectWithBounds(mode, bounds)
    love.graphics.rectangle(mode, bounds.x1, bounds.y1, bounds.x2 - bounds.x1, bounds.y2 - bounds.y1)
end

function love.graphics.setColorWithTable(table)
    love.graphics.setColor(table.red, table.green, table.blue, table.alpha)
end

function love.graphics.newPixelImage(filename)
    local image = love.graphics.newImage(filename, { mipmaps = true })
    image:setMipmapFilter("linear", 16)
    image:setFilter("nearest", "nearest")
    return image
end

function love.graphics.drawInBounds(image, bounds, keepAspect)
    if keepAspect == nil then
        keepAspect = false
    end

    local imageSize = Vector(image:getPixelDimensions())

    local renderPosition
    local renderScale

    if keepAspect then
        local imageAspect = imageSize:aspect()
        local boundsAspect = bounds:size():aspect()

        local scale
        if imageAspect >= boundsAspect then
            -- Image is wider than the bounds, make space around the top and bottom
            scale = bounds:width() / imageSize.x
            local scaledHeight = imageSize.y * scale
            local yOffset = (bounds:height() - scaledHeight) / 2
            renderPosition = Vector(bounds:left(), bounds:top() + yOffset)
        else
            -- Image is taller than the bounds, make space around the left and right
            scale = bounds:height() / imageSize.y
            local scaledWidth = imageSize.x * scale
            local xOffset = (bounds:width() - scaledWidth) / 2
            renderPosition = Vector(bounds:left() + xOffset, bounds:top())
        end

        renderScale = Vector(scale, scale)
    else
        renderPosition = bounds:topLeft()
        renderScale = bounds:size():perdiv(imageSize)
    end

    love.graphics.draw(image, renderPosition.x, renderPosition.y, nil, renderScale.x, renderScale.y)
end

-- love.math

function love.math.transformBounds(transform, bounds)
    local topLeft = bounds:topLeft()
    local bottomRight = bounds:bottomRight()
    return Bounds.from(
        Vector(transform:transformPoint(topLeft.x, topLeft.y)),
        Vector(transform:transformPoint(bottomRight.x, bottomRight.y))
    )
end

function love.math.randomColor(randomGenerator)
    if randomGenerator == nil then
        randomGenerator = love.math.newRandomGenerator()
    end

    return {
        randomGenerator:random(),
        randomGenerator:random(),
        randomGenerator:random(),
        1,
    }
end

function love.math.randomChoice(tbl, rng)
    std.assertArray(tbl)

    local index
    if rng == nil then
        index = love.math.random(1, #tbl)
    else
        index = rng:random(1, #tbl)
    end

    return tbl[index]
end
