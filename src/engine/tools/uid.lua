local uid = {}

uid._counter = 10000

function uid.generate()
    local id = uid._counter
    uid._counter = uid._counter + 1
    return id
end

return uid
