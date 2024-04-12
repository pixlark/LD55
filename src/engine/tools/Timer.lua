local Timer = std.Object:extend()

function Timer:new(totalTimeSeconds)
    self.timestamp = love.timer.getTime()
    self.totalTimeSeconds = totalTimeSeconds
end

function Timer:started()
    return self.timestamp
end

function Timer:seconds()
    return love.timer.getTime() - self.timestamp
end

function Timer:addSeconds(seconds)
    self.totalTimeSeconds = self.totalTimeSeconds + seconds
end

function Timer:relativeTime()
    return self:seconds() / self.totalTimeSeconds
end

function Timer:progress()
    return std.math.clamp(self:relativeTime(), 0, 1)
end

function Timer:polynomial(power)
    return math.pow(self:progress(), power)
end

function Timer:finished()
    return self:progress() >= 1
end

return Timer
