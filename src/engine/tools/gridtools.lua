local gridtools = {}

function gridtools.getSquaresInRange(origin, range)
    local squares = {}
    for x = origin.x - math.floor(range), origin.x + math.ceil(range) do
        for y = origin.y - math.floor(range), origin.y + math.ceil(range) do
            local square = Vector(x, y)
            if Vector.dist(origin, square) <= range then
                table.insert(squares, square)
            end
        end
    end
    return squares
end

function gridtools.getRangeCircle(origin, range)
    local squares = {}
end

return gridtools
