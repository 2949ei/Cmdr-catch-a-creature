**Cmdr** is a fully extensible and type safe command console for Roblox developers.

- This is a fork from [Cmdr](https://github.com/evaera/Cmdr)
# Added Stuff
- Permission System
- Colored Returns for commands when color not exist its white


### CmdrServer
```lua
-- This is a script you would create in ServerScriptService, for example.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrPlus = require(path.to.CmdrPlus)

CmdrPlus:RegisterDefaultCommands() -- This loads the default set of commands that Cmdr comes with. (Optional)
-- CmdrPlus:RegisterCommandsIn(script.Parent.CmdrCommands) -- Register commands from your own folder. (Optional)
```

### CmdrClient
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CmdrPlus = require(ReplicatedStorage:WaitForChild("CmdrPlusClient"))

-- Configurable, and you can choose multiple keys
CmdrPlus:Init()
-- See below for the full API.
```