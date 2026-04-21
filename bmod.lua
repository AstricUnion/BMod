---@name BMod - JMod, but implemented in Starfall
---@author AstricUnion
---@include bmod/base/entity.lua
---@include bmod/base/bgui.lua
---@include bmod/base/effects.lua
---@include bmod/base/gas.lua
---@include bmod/src/resource.lua
---@include bmod/src/utils.lua
---@include bmod/src/crafting_table.lua
---@include bmod/src/gui.lua
---@include bmod/src/gases.lua

-- Firstly, we should include our libraries. It will be shared in all files
---@class ents
ents = require("bmod/base/entity.lua")
---@class resource
resource = require("bmod/src/resource.lua")
---@class gas
gas = require("bmod/base/gas.lua")
---@class butils
butils = require("bmod/src/utils.lua")

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
    ---@class bgui
    bgui = require("bmod/base/bgui.lua")

    ---@class beff
    beff = require("bmod/base/effects.lua")


    ---@class bguiElements
    local bguiElements = require("bmod/src/gui.lua")

    net.receive("BModInventory", function()
        bguiElements.inventory()
    end)
end

-- Initialize entities
require("bmod/src/crafting_table.lua")

-- Initialize gases
require("bmod/src/gases.lua")
