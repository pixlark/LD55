local Logger = std.Object:extend()

function Logger:new(filePath)
    self.filePath = filePath
    self.startedLogging = love.timer.getTime()

    local file = io.open(filePath, "a")
    if file == nil then
        error("Log file "..filePath.." doesn't exist.")
    end

    file:write("********** GAME START ***********\n")
    file:write(string.format("Game started at %s\n", os.date("%X (%a, %d %b %Y)")))

    file:close()
end

function Logger:log(message, ...)
    local timestamp = love.timer.getTime() - self.startedLogging
    local output = string.format("[%04.3f] %s\n", timestamp, string.format(message, ...))

    local file = io.open(self.filePath, "a")
        file:write(output)
    file:close()

    io.stdout:write(output)
end

return Logger
