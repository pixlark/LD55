local pathfinding = {}

local Node = std.Object:extend()

Node.new = std.argcheck {
    std.InstanceMethod,
    -- Required
    "pos", "distance",
    -- Optional
    { "priors", {} },
    { "cost", nil },

    function(self, t)
        self.pos = t.pos
        self.priors = t.priors
        self.distance = t.distance
        self.cost = t.cost
    end
}

function Node:getCost()
    if self.cost then
        return self.cost
    else
        return self.distance
    end
end

function Node.__lt(a, b)
    return a:getCost() < b:getCost()
end

function Node.__le(a, b)
    return a:getCost() <= b:getCost()
end

pathfinding.grid = std.argcheck {
    -- Required
    "startPos", "endPos", "getMoves",
    -- Optional
    { "heuristic", nil },
    { "iterationLimit", 250 },
    function(t)
        local queue = std.PriorityQueue(std.PriorityQueueDirection.Ascending)

        if t.heuristic == nil then
            queue:push(Node {
                pos = t.startPos,
                distance = 0,
            })
        else
            queue:push(Node {
                pos = t.startPos,
                distance = 0,
                cost = 0,
            })
        end

        local visited = { t.startPos:integerHash() }
        local iterations = 0

        local bestGuess
        local bestGuessCost = math.huge

        while not queue:isEmpty() and iterations < t.iterationLimit do
            iterations = iterations + 1

            local node = queue:pop()

            if t.heuristic ~= nil then
                local cost = t.heuristic(node.pos, t.endPos)
                if cost < bestGuessCost then
                    bestGuess, bestGuessCost = node, cost
                end
            end

            if node.pos == t.endPos then
                local priors = std.copy(node.priors)
                table.insert(priors, node.pos)
                return priors
            end

            local validMoves = t.getMoves(node.pos)
            for _, move in ipairs(validMoves) do
                if not visited[move.pos:integerHash()] then
                    local distance = node.distance + move.distance

                    local priors = std.copy(node.priors)
                    table.insert(priors, node.pos)

                    if t.heuristic == nil then
                        queue:push(Node {
                            pos = move.pos,
                            distance = distance,
                            priors = priors
                        })
                    else
                        -- In A* mode, introduce heuristic
                        local cost = distance + t.heuristic(move.pos, t.endPos)
                        queue:push(Node {
                            pos = move.pos,
                            distance = distance,
                            priors = priors,
                            cost = cost,
                        })
                    end

                    visited[move.pos:integerHash()] = true
                end
            end
        end

        -- If the pathfinding times out, and we're using A*, use a best guess
        if bestGuess ~= nil then
            local priors = std.copy(bestGuess.priors)
            table.insert(priors, bestGuess.pos)
            return priors
        end
    end
}

return pathfinding
