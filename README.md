### Ludum Dare 55

This jam game is based on the engine from a different game I worked on in Love2D, which I since
discontinued. I've torn out the game-specific code, so I can use the engine code as a basis for
this jame game. Everything present in the first commit on this repo is the "base code" that I started
with, and every commit after that is code written as part of Ludum Dare.

Below is the README taken from that game:

----

### Project Atlas

 - `conf.lua` - configuration script executed by Love before game boot
 - `main.lua` - entry point executed by Love
 - `src/`
    - `engine/` - core engine code. relatively game-agnostic
    - `game/` - game code
    - `lib/` - lua library dependencies
        - `forked/` - external libraries modified for the game
        - `local/` - local libraries created for the game
        - `vendored/` - external libraries copied straight into the repo
        - `std.lua` - standard module that re-exports the majority of dependencies
 - `native/` - native C code loaded by Lua as a dynamic library
 - `res/` - resources (images, fonts, etc)

### Style/Patterns/Conventions

This project uses the Lua programming language in a relatively non-standard way, with a variety of libraries and extensions. Here is a list of the common styles, patterns, and/or conventions used in this project:

 - Global definitions are kept to a minimum, and all global definitions are declared in `Global.lua`.
 - The Lua standard library is relatively sparse, so `std.lua` provides definitions for a wide variety of useful functions and types. It also re-exports handles to a handful of libraries that provide additional support.
   - The `std.lua` module is declared globally in `Global.lua`, so any location in the project should have access to the `std` namespace.
   - Many of the functions provided in this extended standard libary are meant to support a functional programming style, which is preferred.
 - A feature of the standard library which is used absolutely everywhere is a function decorator called `argcheck`.
   - `argcheck` provides an easy way to define functions that use keyword arguments, some (or all) of which may have default values.
   - A common `argcheck` declaration might look something like this:

```Lua
local myFunction = std.argcheck {
    -- Required
    "firstArgument", "secondArgument",
    -- Optional
    { "argumentWithDefaultValue", 1337 },
    { "andAnotherOne", "abc" },

    function(t)
        print(t.firstArgument)
        print(t.argumentWithDefaultValue)
    end
}
```

 - .
   - The syntax is a little bit clunky, but it's an extremely useful pattern that is used widely across the project.
   - It also works for instance methods on objects, which simply requires the following small modification:

```Lua
MyObject.someMethod = std.argcheck {
    -- This marks the function as an instance method
    std.InstanceMethod,
    "someArgument",

    -- The function itself then requires a `self` argument
    function(self, t)
        print(t)
    end
}
```
 - .
   - There are a couple other similar decorators that are somewhat commonly used, `std.enum` which is relatively self-explanatory, and `std.overload` which allows you to define multiple version of a function based on the types of the parameters.

 - The Lua dependency system (using `require`) is slightly modified.
   - A module at `engine/mymodule.lua` can be imported simply with `require engine.mymodule`.
   - However, if a module is big enough to require its own supporting files, it can be placed within a folder that matches its same name, and imported with just the folder name.
   - So `engine/mymodule/mymodule.lua` can be imported the same way, as `engine.mymodule`.
 - Usually, we stick to having one type per file, where the type is then exported as the file's module. This makes imports very simple: if you want the `Foo` type, you just do `local Foo = require "Foo"`.
   - If you have a collection of functions with no type, then you can export a more classic Lua module (just a table of functions), in which case the module name is lowercased. It is extremely preferred that one does not export modules which contain types, otherwise you end up having to write things like this everywhere:

```Lua
-- Don't do this!
local mymodule = require "mymodule"
local FooType = mymodule.FooType
local BarType = mymodule.BarType
```

 - .
   - Which is just needlessly verbose.

 - The `classic` library is used to provide object-oriented support. The large-scale structure of the codebase is written in an object-oriented style, to encourage code separation and encapsulation.
 - The game and engine are built around Love2D, and care is taken to conceal the Love2D API as little as possible, especially with regards to rendering.
   - For example, rather than wrapping all Love2D functionality with our own local functions, we instead use a pattern in which rendering classes expose a `renderWith` function that takes a callback. The function then internally sets up any relevant Love2D context (coordinate transforms, scissor clipping, etc) and invokes the callback in that context.
   - This means that common rendering logic can still be implemented with normal Love2D API calls like `love.graphics.draw`, `love.graphics.rectangle`, and so on.
 - In a game, allowing distant objects and modules to occasionally communicate with each other is unfortunately necessary, even when it introduces coupling.
   - The simplest approach to this is to a keep some global handles around that anyone can reach into. This is the approach taken for some *very* common objects, such as the resource manager which handles the loading of images, fonts, etc.
   - For everything else, a service locator pattern is used, to keep coupling to a minimum. Objects can be registered as a service (under some name) with the global `Game` object, and retrieved with `Game.getService("...")`. Those services also need to be unregistered when the object dies, so as not to keep things alive unnecessarily through the service locator.
   - Although this is a very handy (and necessary) pattern, care should still be taken to employ it as little as possible. Nearby dependencies that can simply be injected into function calls or constructors should still be preferred wherever feasible.
 - Flow control in any given frame of the game's main runloop is handled through the scene manager.
   - A `Scene` object is one that provides `init`, `load`, `die`, `update`, and `render` functions. Extending this class is how different game scenes are created.
   - The scene manager holds a stack of scenes, the topmost of which is what is run on any given frame. When a scene completes, it can pop itself from the stack, at which point the next scene down can take control. A scene can also push new scenes atop the stack, or replace itself with a different scene.
   - Most of the `Scene` virtual functions are self-explanatory, but there is an important difference between `init` and `load`. `init` is called the very first time a Scene is created, whereas `load` is called any time a `Scene` retakes control of the runloop.
