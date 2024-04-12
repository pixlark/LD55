-- http://lua-users.org/wiki/CopyTable
local function copy(x)
    if type(x) == "table" then
        local copied = {}
        for key, value in next, x, nil do
            copied[key] = value
        end

        if getmetatable(x) ~= nil then
            return setmetatable(copied, getmetatable(x))
        else
            return copied
        end
    else
        return x
    end
end

return copy
