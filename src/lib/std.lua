local std = {}

--
-- Libraries
--

-- Forked
std.copy         = require "lib.forked.copy"
local inspect    = require "lib.forked.inspect"
std.Object       = require "lib.forked.classic"
std.Vector       = require "lib.forked.vector"

-- Local
std.Bounds       = require "lib.local.Bounds"
local decorators = require "lib.local.decorators"
local exceptions = require "lib.local.exceptions"

-- Vendored
std.lume         = require "lib.vendored.lume"
std.profile      = require "lib.vendored.profile"

--
-- Pretty-printing utilities
--

function std.inspect(...)
    local function process(value)
        if type(value) == "table" then
            local metatable = getmetatable(value)
            local newMetatable = nil
            if metatable ~= nil and metatable.__pretty ~= nil then
                newMetatable = { __pretty = metatable.__pretty  }
            end
            return setmetatable(
                std.copy(value),
                newMetatable
            )
        end
        return value
    end
    return inspect(..., { process = process })
end

function std.pretty(...)
    print(std.inspect(...))
end

function std.debug(name, x)
    print("[debug] "..name..": "..std.inspect(x))
end

--
-- Assertions and exceptions
--

function std.assertType(x, ty, level)
    level = level or 0

    if type(ty) == "string" then
        if type(x) ~= ty then
            error("Expected "..ty..", got "..inspect(x), level + 2)
        end
    else
        if type(x) ~= "table" or
           x.is == nil        or
           not x:is(ty)       then
            error("Expected class, got "..inspect(x), level + 2)
        end
    end
end

std.abstractMethodException = exceptions.abstractMethodException
std.notImplementedException = exceptions.notImplementedException
std.unreachableException    = exceptions.unreachableException

--
-- Decorators
--

std.argcheck = decorators.argcheck
std.enum = decorators.enum
std.overload = decorators.overload
std.InstanceMethod = decorators.InstanceMethod
std.Nil = decorators.Nil

--
-- Math utilities
--

std.math = {}

function std.math.signum(x)
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    else
        return 0
    end
end

function std.math.clamp(x, low, high)
    return math.min(math.max(x, low), high)
end

function std.math.lerp(a, b, t)
    local dir = b - a
    local v = a + dir * t
    return v
end

-- https://en.wikipedia.org/wiki/Smoothstep
function std.math.smoothstep(t)
    t = std.math.clamp(t, 0, 1)
    return t * t * (3.0 - 2.0 * t)
end

function std.math.smoothpeak(t, peak)
    if t < peak then
        return std.math.smoothstep(t / peak)
    else
        return std.math.smoothstep(1 - ((t - peak) / (1 - peak)))
    end
end

--
-- Functional tools
--

local boxedNil = {}

-- If nil, return "boxedNil" value which can be detected
-- by `std.isNil`. This is useful because it can exist as
-- an item in tables.
function std.boxNil(value)
    if value == nil then
        return boxedNil
    else
        return value
    end
end

-- Check if nil, or if a "boxedNil" value created by `std.boxNil`.
function std.isNil(value)
    return value == nil or value == boxedNil
end

-- Partially apply arguments to a function
function std.partial(func, ...)
    local partialArgs = { ... }
    return function(...)
        local args = { ... }
        local fullArgs = std.concat(partialArgs, args):collect()
        return func(unpack(fullArgs))
    end
end

local Iterator = std.Object:extend()

function Iterator:new(iteratorFunc)
    self.iteratorFunc = iteratorFunc
end

function Iterator.__pretty(_, _)
    return "<Iterator object>"
end

-- Tests whether the provided value is an array
-- https://stackoverflow.com/a/25709704
function std.isArray(tbl)
    if type(tbl) ~= "table" then
        return false
    end

    local i = 0
    for _ in pairs(tbl) do
        i = i + 1
        if tbl[i] == nil then
            return false
        end
    end
    return true
end

-- Asserts that the provided value is an array
function std.assertArray(x, level)
    level = level or 0

    std.assertType(x, "table", 1)
    if not std.isArray(x) then
        error("Expected array, got hashmap: "..inspect(x), level + 2)
    end
end

local function coerceIterator(arrayOrIterator)
    if type(arrayOrIterator) == "table" then
        if std.isArray(arrayOrIterator) then
            -- Array
            return std.iterate(arrayOrIterator)
        elseif arrayOrIterator.is ~= nil and arrayOrIterator:is(Iterator) then
            -- Already is our iterator type
            return arrayOrIterator
        end
    elseif type(arrayOrIterator) == "function" then
        -- Lua iterator
        return Iterator(arrayOrIterator)
    else
        error("Expected array or iterator, got "..inspect(arrayOrIterator), 3)
    end
end

-- Iterate over an array
function std.iterate(array)
    std.assertArray(array, 1)

    local index = 0

    return Iterator(function()
        index = index + 1
        return array[index]
    end)
end

-- Iterate the pairs of a table
function std.iteratePairs(tbl)
    std.assertType(tbl, "table", 1)

    local key = nil

    return Iterator(function()
        key = next(tbl, key)

        if key == nil then
            return nil
        end

        return { key, tbl[key] }
    end)
end

-- Iterate over the keys of a table
function std.iterateKeys(tbl)
    std.assertType(tbl, "table", 1)

    return std.iteratePairs(tbl):map(function (pair)
        return pair[1]
    end)
end

-- Iterate over the values of a table
function std.iterateValues(tbl)
    std.assertType(tbl, "table", 1)

    return std.iteratePairs(tbl):map(function (pair)
        return pair[2]
    end)
end

-- Repeat the same value forever, in an infinite iterator.
-- Example: "a" -> { "a", "a", "a", ... }
function std.babble(value)
    return Iterator(function()
        return value
    end)
end

-- Cycle through the same list forever, in an infinite iterator.
-- Example: {"a", "b", "c"} -> { "a", "b", "c", "a", "b", "c", ... }
function std.cycle(array)
    std.assertArray(array, 1)

    local index = 0
    local modulo = #array

    return Iterator(function()
        index = (index % modulo) + 1
        return array[index]
    end)
end

-- Add an index to every value in an iterator.
-- Example: {"a", "b", ...} -> { {1, "a"}, {2, "b"}, ... }
function std.enumerate(iterator)
    iterator = coerceIterator(iterator)

    local index = 0

    return Iterator(function()
        index = index + 1
        local item = iterator:next()

        if item == nil then
            return nil
        end

        return { index, item }
    end)
end

function Iterator:enumerate()
    return std.enumerate(self)
end

-- Consume an iterator, turning it into an array.
-- (Iterators never evaluate _anything_ until they are consumed).
function std.collect(iterator)
    iterator = coerceIterator(iterator)

    local array = {}
    while true do
        local item = iterator:next()
        if item == nil then
            break
        end

        table.insert(array, item)
    end
    return array
end

function Iterator:collect()
    return std.collect(self)
end

-- Consume an iterator, turning it into a normal key/value table.
-- NOTE: This requires that the elements of the iterator be of the form `{ key, value }`.
function std.collectDict(iterator)
    iterator = coerceIterator(iterator)

    local tbl = {}
    while true do
        local item = iterator:next()
        if item == nil then
            break
        end

        if not std.isArray(item) then
            error("std.collectDict expects elements of the form { key, value }", 2)
        end

        local key, value = unpack(item)
        tbl[key] = value
    end
    return tbl
end

function Iterator:collectDict()
    return std.collectDict(self)
end

-- Consume an iterator, turning it into a string
function std.collectString(iterator, separator)
    iterator = coerceIterator(iterator)

    local array = iterator:collect()
    return table.concat(array, separator)
end

function Iterator:collectString()
    return std.collectString(self)
end

-- Consume the next item in an iterator
function std.next(iterator)
    iterator = coerceIterator(iterator)

    -- If the iterator has multiple return values,
    -- collect them all into a "tuple" (array)
    local item = { iterator.iteratorFunc() }
    if #item == 0 then
        return nil
    elseif #item == 1 then
        return item[1]
    else
        return item
    end
end

function Iterator:next()
    return std.next(self)
end

-- Apply a function to every item in an iterator.
function std.map(func, iterator)
    iterator = coerceIterator(iterator)

    return Iterator(function()
        local item = iterator:next()

        if item == nil then
            return nil
        end

        return func(item)
    end)
end

function Iterator:map(func)
    return std.map(func, self)
end

-- Test every item in an iterator with a predicate, and only return those which evaluate true.
function std.filter(predicate, iterator)
    iterator = coerceIterator(iterator)

    return Iterator(function()
        while true do
            local item = iterator:next()

            if item == nil then
                return nil
            end

            if predicate(item) then
                return item
            end
        end
    end)
end

function Iterator:filter(predicate)
    return std.filter(predicate, self)
end

-- Check if any item in the iterator satisfies the predicate.
-- (Consumes the iterator)
function std.any(predicate, iterator)
    iterator = coerceIterator(iterator)

    while true do
        local item = iterator:next()

        if item == nil then
            break
        end

        if predicate(item) then
            return true
        end
    end

    return false
end

function Iterator:any(predicate)
    return std.any(predicate, self)
end

function std.contains(iterator, value)
    iterator = coerceIterator(iterator)

    while true do
        local item = iterator:next()

        if item == nil then
            break
        end

        if item == value then
            return true
        end
    end

    return false
end

function Iterator:contains(value)
    return std.contains(self, value)
end

function std.fold(func, startingValue, iterator)
    iterator = coerceIterator(iterator)

    local value = startingValue

    while true do
        local item = iterator:next()

        if item == nil then
            break
        end

        value = func(value, item)
    end

    return value
end

function Iterator:fold(func, startingValue)
    return std.fold(func, startingValue, self)
end

function std.sum(iterator)
    iterator = coerceIterator(iterator)

    return iterator:fold(function(a, b) return a + b end, 0)
end

function Iterator:sum()
    return std.sum(self)
end

function std.product(iterator)
    iterator = coerceIterator(iterator)

    return iterator:fold(function(a, b) return a * b end, 0)
end

function Iterator:product()
    return std.product(self)
end

-- Join iterators together pairwise
-- Example: zip({1, 2, 3}, {"a", "b", "c"}) -> { {1, "a"}, (2, "b"), (3, "c") }
function std.zip(...)
    local args = { ... }

    if #args < 1 then
        error("zip requires >= 1 argument", 2)
    end

    local iterators = std.iterate(args)
        :map(function (iter) return coerceIterator(iter) end)
        :collect()

    return Iterator(function()
        local items = std.iterate(iterators)
            :map(function (iter) return std.boxNil(iter:next()) end)
            :collect()

        if std.any(std.isNil, items) then
            return nil
        end

        return items
    end)
end

function Iterator:zip(...)
    return std.zip(self, ...)
end

-- Join iterators together end-to-end
function std.join(iterator)
    iterator = coerceIterator(iterator)

    local iterators = iterator
        :map(function (iter) return coerceIterator(iter) end)

    local currentIterator = iterators:next()

    return Iterator(function()
        while true do
            if currentIterator == nil then
                return nil
            end

            local item = currentIterator:next()

            if item ~= nil then
                return item
            else
                currentIterator = iterators:next()
            end
        end
    end)
end

function Iterator:join()
    return std.join(self)
end

-- Join iterators together end-to-end
function std.concat(...)
    local args = { ... }

    if #args < 1 then
        error("concat requires >= 1 argument", 2)
    end

    return std.iterate(args):join()
end

function Iterator:concat(...)
    return std.concat(self, ...)
end

-- Take the first n items of the iterator
function std.take(n, iterator)
    iterator = coerceIterator(iterator)

    local counter = 0

    return Iterator(function()
        counter = counter + 1

        if counter > n then
            return nil
        end

        local item = iterator:next()

        if item == nil then
            return nil
        end

        return item
    end)
end

function Iterator:take(n)
    return std.take(n, self)
end

-- Drop (skip) the first n items of the iterator
function std.drop(n, iterator)
    iterator = coerceIterator(iterator)

    local counter = 0

    return Iterator(function()
        while counter < n do
            counter = counter + 1

            local item = iterator:next()

            if item == nil then
                return nil
            end
        end

        local item = iterator:next()

        if item == nil then
            return nil
        end

        return item
    end)
end

function Iterator:drop(n)
    return std.drop(n, self)
end

function std.max(keyFunction, iterator)
    iterator = coerceIterator(iterator)

    local largestKey, largestItem
    while true do
        local item = iterator:next()

        if item == nil then
            break
        end

        local key = keyFunction(item)

        if largestKey == nil or key > largestKey then
            largestKey = key
            largestItem = item
        end
    end

    return largestItem
end

function Iterator:max(keyFunction)
    return std.max(keyFunction, self)
end

function std.slice(array, start, stop)
    std.assertArray(array, 1)

    start = start or 1
    stop = stop or #array

    std.assertType(start, "number")
    std.assertType(stop, "number")

    if start < 1 or stop < 1 then
        error("Slice index must be >= 1", 2)
    end

    if start > #array or stop > #array then
        error("Slice index outside array bounds", 2)
    end

    local slice = {}
    local span = math.max(stop - start, 0)
    for i = start, start + span do
        table.insert(slice, array[i])
    end
    return slice
end

function std.compose(...)
    local args = { ... }
    if #args == 0 then
        return function(x)
            return x
        end
    else
        local f = args[#args]

        local rest
        if #args == 1 then
            rest = {}
        else
            rest = std.slice(args, 1, #args - 1)
        end

        return function(x)
            return std.compose(unpack(rest))(f(x))
        end
    end
end

function std.find(array, value)
    std.assertArray(array, 1)

    for index, item in ipairs(array) do
        if item == value then
            return index
        end
    end
end

function std.removeValue(array, value)
    std.assertArray(array, 1)

    local index = std.find(array, value)

    if index ~= nil then
        table.remove(array, index)
    else
        error("std.removeValue: No such item in array")
    end
end

function std.reverse(array)
    std.assertArray(array, 1)

    local reversed = {}
    for i = #array,1,-1 do
        table.insert(reversed, array[i])
    end
    return reversed
end

--
-- Mutable table tools
--

std.table = {}

function std.table.extend(table, extension)
    for _, item in ipairs(extension) do
        table.insert(table, item)
    end
end

--
-- Priority Queue
--

std.PriorityQueueDirection = std.enum {
    "Ascending",
    "Descending"
}

std.PriorityQueue = std.Object:extend()

function std.PriorityQueue:new(compare)
    self.contents = {}
    self.compare = compare
end

function std.PriorityQueue:_higherPriority(value, control)
    if self.compare == std.PriorityQueueDirection.Ascending then
        return value <= control
    elseif self.compare == std.PriorityQueueDirection.Descending then
        return value >= control
    else
        return self.compare(value, control)
    end
end

function std.PriorityQueue:count()
    return #self.contents
end

function std.PriorityQueue:_parentOf(index)
    assert(index >= 1)
    assert(index <= self:count())
    if index == 1 then
        return nil
    end
    return math.floor(index / 2)
end

function std.PriorityQueue:_leftChildOf(index)
    assert(index >= 1)
    assert(index <= self:count())

    local child = 2 * index + 1
    if child <= self:count() then
        return child
    end
end

function std.PriorityQueue:_rightChildOf(index)
    assert(index >= 1)
    assert(index <= self:count())

    local child = 2 * index + 2
    if child <= self:count() then
        return child
    end
end

function std.PriorityQueue:_swapIndices(i, j)
    assert(i >= 1)
    assert(i <= self:count())
    assert(j >= 1)
    assert(j <= self:count())

    local tmp = self.contents[i]
    self.contents[i] = self.contents[j]
    self.contents[j] = tmp
end

function std.PriorityQueue:_addToEnd(value)
    table.insert(self.contents, value)
    return self:count()
end

function std.PriorityQueue:_at(index)
    return self.contents[index]
end

function std.PriorityQueue:push(value)
    local index = self:_addToEnd(value)
    local parent = self:_parentOf(index)

    while parent ~= nil and self:_higherPriority(self:_at(index), self:_at(parent)) do
        self:_swapIndices(index, parent)
        index = parent
        parent = self:_parentOf(index)
    end
end

function std.PriorityQueue:pop()
    assert(not self:isEmpty())

    if self:count() == 1 then
        local popped = self:_at(1)
        self.contents = {}
        return popped
    end

    self:_swapIndices(1, self:count())
    local popped = table.remove(self.contents)

    local index = 1
    while true do
        local left = self:_leftChildOf(index)
        local right = self:_rightChildOf(index)

        local leftOk = true
        if left ~= nil then
            leftOk = self:_higherPriority(self:_at(index), self:_at(left))
        end

        local rightOk = true
        if right ~= nil then
            rightOk = self:_higherPriority(self:_at(index), self:_at(right))
        end

        if not leftOk then
            self:_swapIndices(index, left)
            index = left
        elseif not rightOk then
            self:_swapIndices(index, right)
            index = right
        else
            break
        end
    end

    return popped
end

function std.PriorityQueue:isEmpty()
    return self:count() == 0
end

return std
