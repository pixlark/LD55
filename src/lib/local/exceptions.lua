local e = {}

function e.abstractMethodException()
    error("Abstract method exception", 2)
end

function e.notImplementedException()
    error("Not implemented exception", 2)
end

function e.unreachableException()
    error("Unreachable code exception", 2)
end

return e
