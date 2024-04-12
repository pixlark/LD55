-- Global configuration options

local conf = {
    _releaseMode = os.getenv("RELEASE_MODE") ~= nil,
    _profilerEnabled = os.getenv("PROFILER_ENABLED") ~= nil,
    _loggingEnabled = true,
    _logFile = "log.txt",
    _debugGraphics = false,
}

function conf:releaseMode()
    return self._releaseMode
end

function conf:allRuntimeTests()
    return not self:releaseMode()
end

function conf:profilerEnabled()
    return self._profilerEnabled
end

function conf:loggingEnabled()
    return self._loggingEnabled
end

function conf:logFile()
    return conf._logFile
end

function conf:debugGraphics()
    return conf._debugGraphics
end

function conf:toggleDebugGraphics()
    conf._debugGraphics = not conf._debugGraphics
end

return conf
