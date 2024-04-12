local Event = std.Object:extend()

function Event:new()
    self.observers = {}
end

function Event:watch(observer)
    self.observers[observer] = true
end

function Event:unregister(observer)
    self.observers[observer] = nil
end

function Event:publish(...)
    for observer, _ in pairs(self.observers) do
        observer(...)
    end
end

return Event
