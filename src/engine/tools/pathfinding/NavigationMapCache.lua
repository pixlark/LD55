--
-- NavigationMap
--     This type holds a precalculated cost map that can be used for many pathfinds that
--   all have the same target and possible movements.
--     Navmaps are limited because they can only be precalculated out to a certain range, and
--   because they can't account for dynamic entities that might also be pathfinding on the map.
--     Therefore, a few checks needs to be performed on the results of a navmap before one can
--   use its results, and a backup full pathfinding routine still needs to happen in case the
--   results are non-existent or invalid.
local NavigationMap = std.Object:extend()

function NavigationMap:new()
    self.map = {}
end

function NavigationMap:_setMoveValue(pos, value)
    if self.map[pos.x] == nil then
        self.map[pos.x] = {}
    end

    self.map[pos.x][pos.y] = value
end

function NavigationMap:getMoveValue(move)
    if self.map[move.x] == nil then
        return nil
    end

    return self.map[move.x][move.y]
end

function NavigationMap:getBestMove(moves)
    local bestMove
    local bestMoveValue

    for _, move in ipairs(moves) do
        local moveValue = self:getMoveValue(move)

        if moveValue == nil then
            -- If any of the moves under consideration are not
            -- in this navmap, then we can't be sure that we know
            -- the best move
            return nil
        end

        if bestMove == nil or moveValue < bestMoveValue then
            bestMove = move
            bestMoveValue = moveValue
        end
    end

    return bestMove
end

function NavigationMap.generate(target, range, getMoves)
    local navMap = NavigationMap()

    local queue = {}
    table.insert(queue, { target = target, cost = 0 })

    local visited = { target:integerHash() }

    while #queue > 0 do
        local node = table.remove(queue, 1)
        navMap:_setMoveValue(node.target, node.cost)

        local moves = getMoves(node.target)
        for _, move in ipairs(moves) do
            if visited[move.pos:integerHash()] == nil and Vector.dist(move.pos, target) <= range then
                table.insert(queue, { target = move.pos, cost = node.cost + move.distance })
            end

            visited[move.pos:integerHash()] = true
        end
    end

    return navMap
end

--
-- NavigationMapCache
--   This type is the frontend for interacting with NavigationMap. It can placed statically somewhere
--   and then requested from many different places, and it will automatically take care of checking that
--   the navigation map is up-to-date.
--
local NavigationMapCache = std.Object:extend()

NavigationMapCache.new = std.argcheck {
    std.InstanceMethod,
    -- Required
    "range", "targetCallback", "movesetCallback",

    function(self, t)
        self.range = t.range
        self.targetCallback = t.targetCallback
        self.movesetCallback = t.movesetCallback

        -- TODO(brooke.tilley): Use an LRU cache with a small no. of entries,
        self.cachedMap = nil
        self.cachedTarget = nil
    end
}

function NavigationMapCache:request()
    -- Check if cache is up-to-date
    local newTarget = self.targetCallback()

    if newTarget == nil then
        return nil
    end

    if self.cachedTarget ~= nil and self.cachedTarget == newTarget then
        -- Can just return cached navmap
        assert(self.cachedMap ~= nil)
        return self.cachedMap
    end

    -- Otherwise, generate a new navmap
    return NavigationMap.generate(newTarget, self.range, self.movesetCallback)
end

return NavigationMapCache
