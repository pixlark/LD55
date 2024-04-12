local lume = require "lib.vendored.lume"
local copy = require "lib.forked.copy"

local InstanceMethod = {}
local Nil = {}

local function argcheck(t)
    if not (lume.isarray(t)) then
        error("Passed non-table to argcheck")
    end

    local instanceMethod = #t > 0 and t[1] == InstanceMethod
    if instanceMethod then
        t = lume.slice(t, 2, #t)
    end

    local params = lume.slice(t, 1, #t - 1)
    local func = t[#t]

    return function(...)
        local allArgs = { ... }

        local args
        if instanceMethod then
            if #allArgs ~= 2 and type(allArgs[2]) ~= "table" then
                error("Expected argument table (something like: obj:function { key = value, ... })")
            end

            args = allArgs[2]
        else
            if #allArgs ~= 1 and type(allArgs[1]) ~= "table" then
                error("Expected argument table (something like: function { key = value, ... })")
            end

            args = allArgs[1]
        end

        for _, param in ipairs(params) do
            if type(param) == "string" then
                -- Required argument
                if args[param] == nil then
                    error("Expected argument table to have key \""..param.."\"")
                end
            elseif type(param) == "table" and lume.isarray(param) then
                -- Optional argument
                local paramName = param[1]
                local defaultValue = param[2]
                if args[paramName] == nil and defaultValue ~= Nil then
                    args[paramName] = defaultValue
                end
            else
                error("argcheck parameter list is malformed (expected entries like \"foo\" or {\"foo\", bar})")
            end
        end

        return func(unpack(allArgs))
    end
end

local function enum(t)
    local enumTable = {}
    for _, variant in ipairs(t) do
        enumTable[variant] = setmetatable({}, {
            __tostring = function (v)
                return variant
            end,
            __pretty = function (v)
                return variant
            end,
        })
    end
    return enumTable
end

local function overload(list)
    local overloads = {}
    local currentOverload = {}

    local assumeSelf = #list > 0 and list[1] == InstanceMethod
    if assumeSelf then
        list = lume.slice(list, 2, #list)
    end

    for _, value in ipairs(list) do
        if type(value) == "function" then
            local params
            if assumeSelf then
                -- Instance methods automatically take self as the first parameter
                params = lume.concat({ "table" }, currentOverload)
            else
                params = currentOverload
            end

            table.insert(overloads, { params = params, func = value })
            currentOverload = {}
        else
            table.insert(currentOverload, value)
        end
    end

    return function(...)
        local args = { ... }

        local function argsString()
            local argTypes = lume.map(args, function(arg) return type(arg) end)
            return table.concat(argTypes, ", ")
        end

        local possibleOverloads = copy(overloads)
        for argIndex, arg in ipairs(args) do
            -- Rule out overloads based on this argument's type
            local argType = type(arg)
            if argType ~= "nil" then
                local narrowedOverloads = {}

                for _, thisOverload in ipairs(possibleOverloads) do
                    if argIndex <= #thisOverload.params then
                        -- local overloadParamType = thisOverload.params[argIndex]
                        -- if type(overloadParamType) == "table" and Object.isObject(arg) and arg:is(overloadParamType) then
                        --     table.insert(narrowedOverloads, thisOverload)
                        -- else
                        if thisOverload.params[argIndex] == argType then
                            table.insert(narrowedOverloads, thisOverload)
                        end
                        -- end
                    end
                end

                possibleOverloads = narrowedOverloads
            end

            -- Check whether we've narrowed it down to one solution
            if #possibleOverloads == 0 then
                error("Arguments ("..argsString()..") do not match any defined overload")
            elseif #possibleOverloads == 1 then
                return possibleOverloads[1].func(unpack(args))
            end
        end

        error("Arguments ("..argsString()..") matched multiple defined overloads")
    end
end

return {
    argcheck = argcheck,
    enum = enum,
    overload = overload,
    InstanceMethod = InstanceMethod,
    Nil = Nil,
}
