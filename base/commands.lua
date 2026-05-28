---Library for chat commands. I'm too lazy to made this, so... wait
---@name Chat commands
---@author AstricUnion
if CLIENT then return end

---Class to create commands
---@class bcommands
---@field commands table<string, BCommand> Key is command ID, value is handler
---@field prefix string Prefix of commands
local bcommands = {}
bcommands.prefix = "!"
bcommands.commands = {}

---@class BArgInfo
---@field regex string Regex to match argument

---@type table<string, BArgInfo>
bcommands.BArgType = {
    string = "string",
    number = "number",
    player = "player"
}


---@class BCommandArg
---@field type BArgType
---@field hint string?

---Command class
---@class BCommand
---@field args BCommandArg[]
local BCommand = {}

---[SERVER] Add new arg to command
---@param tbl BCommandArg
function BCommand:arg(tbl)
end


---[SERVER] Create new command
---@param id string Identifier of command: `!(id)`
function bcommands.add(id)
    local obj = setmetatable({}, BCommand)
    bcommands.commands[id] = obj
end
