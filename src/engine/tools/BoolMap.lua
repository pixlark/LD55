local BoolMap = std.Object:extend()

function BoolMap:new(inverted)
    self.map = {}
    self.inverted = inverted or false
end

function BoolMap.inverted()
    return BoolMap(true)
end

function BoolMap:set(pos)
    if self.map[pos.x] == nil then
        self.map[pos.x] = {}
    end

    self.map[pos.x][pos.y] = true
end

function BoolMap:unset(pos)
    if self.map[pos.x] == nil then
        return
    end

    self.map[pos.x][pos.y] = nil
end

function BoolMap:get(pos)
    local truthy = true
    if self.inverted then
        truthy = false
    end

    if self.map[pos.x] == nil then
        return not truthy
    end

    return (self.map[pos.x][pos.y] or false) == truthy
end

return BoolMap
