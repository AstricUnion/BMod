---@name BMod - JMod, but implemented in Starfall
---@author AstricUnion
---@include bmod/base/entity.lua
---@include bmod/base/bgui.lua
---@include bmod/base/effects.lua
---@include bmod/base/gas.lua
---@include bmod/base/utils.lua
---@include bmod/base/resource.lua
---@include bmod/base/remote.lua
---@include bmod/base/deposits.lua
---@include bmod/src/config.lua
---@include bmod/src/gui.lua

-- Just to not remove all in one press
if SERVER then
    prop.setPropUndo(true)
end

-- Firstly, we should include our libraries. It will be shared in all files
--
---@class ents
ents = require("bmod/base/entity.lua")

---@class gas
gas = require("bmod/base/gas.lua")

---@class resource
resource = require("bmod/base/resource.lua")

---@class butils
butils = require("bmod/base/utils.lua")

---@class deposit
deposit = require("bmod/base/deposits.lua")

---@class bmodConfig
bmodConfig = require("bmod/src/config.lua")

if SERVER then
    ---@class remote
    remote = require("bmod/base/remote.lua")
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
---@includedir bmod/entities
dodir("bmod/entities", {})

-- Initialize gases
---@includedir bmod/gases
dodir("bmod/gases", {})


if SERVER then
    -- ents.create("crafting_table"):spawn(chip():getPos(), Angle(), true)
    resource.create("wood", chip():getPos() + Vector(0, 0, 12), Angle(), 30, true)
    local cor = deposit.startGeneration(20, true)
    if !cor then return end
    hook.add("Think", "BModDepositGeneration", function()
        if cor() == true then
            hook.remove("Think", "BModDepositGeneration")
        end
    end)
end
