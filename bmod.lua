---@name BMod - JMod, but implemented in Starfall
---@author AstricUnion
---@include bmod/base/entity.lua
---@include bmod/base/bgui.lua
---@include bmod/base/effects.lua
---@include bmod/base/gas.lua
---@include bmod/base/utils.lua
---@include bmod/base/remote.lua
---@include bmod/base/icons.lua
---@include bmod/base/model.lua
---@include bmod/src/resource.lua
---@include bmod/src/machine.lua
---@include bmod/src/utils.lua
---@include bmod/src/deposits.lua
---@include bmod/src/config.lua
---@include bmod/src/gui.lua

-- Just to not remove all in one press
if SERVER then
    prop.setPropUndo(true)
end

---@class BMod
---@field debug boolean
---@field displayDeposits boolean
BMod = {}
BMod.debug = true

-- Firstly, we should include our libraries. It will be shared in all files
---@class ents
ents = require("bmod/base/entity.lua")

---@class gas
gas = require("bmod/base/gas.lua")

---@class butils
butils = require("bmod/base/utils.lua")

---@class bicons
bicons = require("bmod/base/icons.lua")

---@class model
model = require("bmod/base/model.lua")

require("bmod/src/utils.lua")

---@class deposit
deposit = require("bmod/src/deposits.lua")

---@class bmodConfig
bmodConfig = require("bmod/src/config.lua")

---@class resource
resource = require("bmod/src/resource.lua")

require("bmod/src/machine.lua")


---@class beff
beff = require("bmod/base/effects.lua")


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

    ---@class bguiElements
    local bguiElements = require("bmod/src/gui.lua")

    -- Initialize GUI elements
    ---@includedir bmod/bgui
    dodir("bmod/bgui", {})

    net.receive("BModInventory", function()
        bguiElements.inventory()
    end)
end

-- Autorun scripts
---@includedir bmod/autorun
dodir("bmod/autorun", {})

-- Initialize entities
---@includedir bmod/entities
dodir("bmod/entities", {})

-- Initialize gases
---@includedir bmod/gases
dodir("bmod/gases", {})

-- Initialize effects
---@includedir bmod/effects
dodir("bmod/effects", {})


if SERVER then
    -- local ent = ents.create("crafting_table")
    -- ent:setInput("fuel", 100)
    -- ent:spawn(chip():getPos() + Vector(0, 0, 0), Angle(), true)
    -- resource.create("copperore", chip():getPos() + Vector(0, 0, 12), Angle(), 100, true)
    -- local toolbox = ents.create("toolbox")
    -- toolbox:spawn(chip():getPos() + Vector(0, 0, 12), Angle(), false)
    -- toolbox:setGas(100)
    -- toolbox:setPower(100)
    ents.create("augerdrill"):spawn(chip():getPos() + Vector(0, 0, 12), Angle(), false)
    -- ents.create("groundscanner"):spawn(chip():getPos() + Vector(0, 0, 12), Angle(), false)
    deposit.create("coal", chip():getPos(), 300, 727)
    -- resource.create("coal", chip():getPos() + Vector(0, 20, 12), Angle(), 100, true)
    local cor = deposit.startGeneration(20, true)
    if !cor then return end
    hook.add("Think", "BModDepositGeneration", function()
        if cor() == true then
            hook.remove("Think", "BModDepositGeneration")
        end
    end)
end
