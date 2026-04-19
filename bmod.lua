---@name BMod - JMod, but implemented in Starfall
---@author AstricUnion
---@include bmod/base/entity.lua
---@include bmod/src/resource.lua
---@include bmod/src/crafting_table.lua
---@include bmod/src/gui.lua

-- Firstly, we should include our libraries. It will be shared in all files
---@class ents
ents = require("bmod/base/entity.lua")
---@class resource
resource = require("bmod/src/resource.lua")

-- Initialize entities
require("bmod/src/crafting_table.lua")

if SERVER then
    require("bmod/src/gui.lua")

    local ow = owner()
    hook.add("PlayerSay", "Commands", function(ply, text)
        if ply == ow and text == "!binv" then
            net.start("BModInventory")
            net.send(ply)
            return ""
        end
    end)
else
    ---@class bguiElements
    local bguiElements = require("bmod/src/gui.lua")

    net.receive("BModInventory", function()
        bguiElements.inventory()
    end)
end


if SERVER then
    -- ents.create("crafting_table"):spawn(chip():getPos(), Angle(), true)
end
