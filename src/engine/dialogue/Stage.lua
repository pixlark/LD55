local std = require "lib.std"

local Stage = std.Object:extend()

function Stage.parse(source)
    local chunkIndices = { 1 }
    do
        local i = 1
        local endOfLastMatch
        while true do
            local start, end_ = string.find(source, "%[%d+|[^%]]+%]", i)
            endOfLastMatch = end_

            if start == nil then
                break
            end
            if start > chunkIndices[#chunkIndices] then
                table.insert(chunkIndices, start)
            end
            table.insert(chunkIndices, end_ + 1)
            i = end_ + 1
        end

        if #chunkIndices > 0 and chunkIndices[#chunkIndices] < #source then
            table.insert(chunkIndices, endOfLastMatch)
        end
    end

    local script = {}
    for index = 1, #chunkIndices do
        local i = chunkIndices[index]

        local j
        if index < #chunkIndices then
            j = chunkIndices[index + 1]
        else
            j = #source
        end

        local chunk = string.sub(source, i, j - 1)
        local chunkId, chunkText = string.match(chunk, "%[(%d+)|([^%]]+)%]")
        if chunkId ~= nil then
            table.insert(script, { chunkId, chunkText })
        else
            table.insert(script, chunk)
        end
    end

    return script
end

function Stage:new(scriptSource)
    self.script = Stage.parse(scriptSource)
end

function Stage:chunks()
    local chunks = {}
    for _, line in ipairs(self.script) do
        if type(line) == "string" then
            table.insert(chunks, line)
        else
            table.insert(chunks, line[2])
        end
    end
    return chunks
end

function Stage:getInteractIndex(chunkIndex)
    local line = self.script[chunkIndex]
    if type(line) == "table" then
        return line[1]
    else
        return nil
    end
end

return Stage
