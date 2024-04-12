function love.conf(t)
    if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
        require("lldebugger").start()
    end

    local releaseMode = os.getenv("RELEASE_MODE") ~= nil

    if not releaseMode then
        t.console = true
    end

    t.window.width = 1000
    t.window.height = 1000
    t.window.resizable = true
end
