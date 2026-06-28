---@name BMod - JMod, but implemented in Starfall
---@author AstricUnion
---@include bmod/base/bmodentity/entity.lua
---@include bmod/base/bgui.lua
---@include bmod/base/beffect/effects.lua
---@include bmod/base/gas.lua
---@include bmod/base/utils.lua
---@include bmod/base/remote.lua
---@include bmod/base/beffect/safeparticle.lua
---@include bmod/base/icons.lua
---@include bmod/base/model/model.lua
---@include bmod/src/commands.lua
---@include bmod/src/resource.lua
---@include bmod/src/machine.lua
---@include bmod/src/equippable.lua
---@include bmod/src/weapon.lua
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
-- BMod.displayDeposits = true

-- Firstly, we should include our libraries. It will be shared in all files
require("bmod/base/beffect/safeparticle.lua")

---@class ents
ents = require("bmod/base/bmodentity/entity.lua")

---@class gas
gas = require("bmod/base/gas.lua")

---@class butils
butils = require("bmod/base/utils.lua")

---@class bicons
bicons = require("bmod/base/icons.lua")

---@class model
model = require("bmod/base/model/model.lua")

require("bmod/src/utils.lua")

---@class deposit
deposit = require("bmod/src/deposits.lua")

---@class bmodConfig
bmodConfig = require("bmod/src/config.lua")

---@class resource
resource = require("bmod/src/resource.lua")

require("bmod/src/machine.lua")

require("bmod/src/weapon.lua")

---@class equipment
equipment = require("bmod/src/equippable.lua")


---@class beff
beff = require("bmod/base/beffect/effects.lua")


if SERVER then
    ---@class remote
    remote = require("bmod/base/remote.lua")
    require("bmod/src/gui.lua")
else
    ---@class bgui
    bgui = require("bmod/base/bgui.lua")

    ---@class bguiElements
    bguiElements = require("bmod/src/gui.lua")

    -- Initialize GUI elements
    ---@includedir bmod/bgui
    dodir("bmod/bgui", {})
end

require("bmod/src/commands.lua")

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
    -- local ent = ents.create("oil_rig")
    -- ent:setInput("fuel", 100)
    -- ent:spawn(chip():getPos() + Vector(0, 0, 16), Angle(), true)
    -- resource.create("copperore", chip():getPos() + Vector(0, 0, 12), Angle(), 100, true)
    -- local toolbox = ents.create("toolbox")
    -- toolbox:setGas(100)
    -- toolbox:setPower(100)
    -- toolbox:spawn(chip():getPos() + Vector(0, 0, 12), Angle(), false)
    -- timer.simple(2, function()
    -- ents.create("helmet_heavy"):spawn(chip():getPos() + Vector(0, 5, 12), Angle(), false)
    -- ents.create("vest_medium"):spawn(chip():getPos() + Vector(0, -5, 12), Angle(), false)
    -- ents.create("gas_mask"):spawn(chip():getPos() + Vector(0, 0, 12), Angle(), false)
    -- ents.create("fumigator"):spawn(chip():getPos() + Vector(0, -5, 12), Angle(), false)
    -- resource.create("power", chip():getPos() + Vector(0, -50, 24), Angle(), 100, false)
    -- deposit.create("oil", chip():getPos(), 400, 13)
    -- deposit.create("oil", chip():getPos() + Vector, 400, 13)
    local cor = deposit.startGeneration(300, true)
    if !cor then return end
    hook.add("Think", "BModDepositGeneration", function()
        while quotaAverage() < quotaMax() / 4 do
            if cor() == true then
                hook.remove("Think", "BModDepositGeneration")
                return
            end
        end
    end)
end
