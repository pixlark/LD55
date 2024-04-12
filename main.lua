-- Immediately output a newline, otherwise stdout starts directly on the terminal prompt
print()

--
-- Augment the package loader
--

-- Allow modules located at `./someModule/someModule.lua` to be loaded simply as `require "someModule"`
local function moduleDirectoryLoader(modulePath)
    local moduleName = string.match(modulePath, "%.?([%w_-]+)$")
    if moduleName == nil then
        return nil
    end

    local amendedName = modulePath.."."..moduleName
    for _, loader in ipairs(package.loaders) do
        if loader ~= moduleDirectoryLoader then
            local result = loader(amendedName)

            if result ~= nil and type(result) ~= "string" then
                return result
            end
        end
    end

    return "\n        no directory module '"..amendedName.."'"
end

package.path = ".\\src\\?.lua;"..package.path

-- Loader setup with Love:
--  (1) preloader
--  (2) Love loader
--  (3) Love C loader
--  (4) Lua loader
--  (5) Our loader (!)
--  ...
table.insert(package.loaders, 5, moduleDirectoryLoader)

-- Actual game entry point
require "game.entry"
