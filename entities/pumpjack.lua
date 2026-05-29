---@class ents
local ents = ents

---@class deposit
local deposit = deposit

---@class resource
local resource = resource

---@class beff
local beff = beff

---@class model
local model = model
local hitbox = model.hitbox
local vertex = model.vertex
local part = model.part
local holo = model.holo
local rig = model.rig

local mdl = model.new("pumpjack", hitbox {
    vertex {"cube", Vector(0, 0, 42), Angle(0, 0, 0), Vector(64, 36, 54)},
    mass = 3000,
    visible = true
})
    :add("base", part {
        holo { Vector(0, 0, -6), Angle(0, 90, 0), "models/props_vents/vent_medium_straight001.mdl", Vector(3, 1.2, 1.2), clips = {{Vector(0, 0, 10), Vector(0, 0, -1)}} },
        holo { Vector(-8, 0, 16), Angle(90, 0, 0), "models/props_c17/light_decklight01_off.mdl", Vector(4, 2, 3) },
        holo { Vector(-16, 0, 16), Angle(90, 0, 0), "models/props_c17/light_decklight01_off.mdl", Vector(5, 1, 3) },
        holo { Vector(-8, 0, 38), Angle(0, 0, 0), "models/props_lab/rotato.mdl", Vector(5, 14, 5) },
        holo { Vector(-8, -28, 38), Angle(0, 0, -90), "models/props_combine/combine_barricade_bracket01a.mdl", Vector(2.2, 2.2, 0.5) },
        holo { Vector(-8, 28, 38), Angle(0, 0, -90), "models/props_combine/combine_barricade_bracket01a.mdl", Vector(2.2, 2.2, 0.5) },
        holo { Vector(8, 0, 42), Angle(0, 0, 0), "models/props_rooftop/scaffolding01a.mdl", Vector(0.8, 0.1, 0.8) },
        holo { Vector(-42, 0, 96), Angle(90, 0, 0), "models/props_mining/pickaxe01.mdl", Vector(5, 5, 5) },
    })


-- if CLIENT then
--     bicons.registerModel("augerdrill", function()
--         return mdl:create()
--     end, Vector(-240, 128, 128), Angle(10, -30, 0))
-- end


---@class PumpJack: BaseMachine
local PumpJack = {}
PumpJack.Identifier = "pumpjack"
PumpJack.Name = "Pumpjack"
PumpJack.Model = function()
    return mdl:create()
end
PumpJack.hooks = {}

---@type table<string, ResourceInput>
PumpJack.Inputs = {}
PumpJack.Inputs.power = { affectedByGrade = true, type = "power", maxCount = 400 }

---@type table<string, ResourceOutput>
PumpJack.Outputs = {}
PumpJack.Outputs.resource = { affectedByGrade = true, maxCount = 100 }

PumpJack.OutputOffset = Vector(30, 0, 10)

PumpJack.WorkCooldown = 1

PumpJack.Display = true
PumpJack.DisplayOffset = Vector(30, 0, 148)

if SERVER then
    function PumpJack:machineInitialize()
    end

    function PumpJack:turnOn(ply)
        if self:getInput("power") < 1 then return end
        local found = self:findDeposit()
        if found and found.rate and found.resource ~= "geothermal" then
            self:install()
            return true
        else
            BMod.hintMessage(ply, "You should place it on deposit with liquid resource, like water or oil. Deposit can be found with GroundScanner")
        end
    end

    function PumpJack:turnOff(_) end

    ---[SERVER] Work function. To pump deposit
    function PumpJack:work()
        local dep = self:getDeposit()
        if !dep then return false end
        local power = self:getInput("power")
        if power <= 0 then return false end
        self:consumeInput("power", 0.5)
        self:addToOutput("resource", 1, dep.resource)
    end
end

if CLIENT then
    ---@class bgui
    local bgui = bgui

    function PumpJack:drawDisplay()
        local fields = {}
        fields[#fields+1] = {"Power", self:getInput("power"), 400, false, true}
        -- render.drawSimpleText(0, 0, string.format("Power: %s", math.round(self:getInput("power"))), TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
        local count, resId = self:getOutput("resource")
        if resId then
            local res = ents.registered[resId]
            fields[#fields+1] = {"Extracting", res.Name}
            fields[#fields+1] = {"Progress", count, 100, false, true}
        end
        self:drawFields(0, 0, fields)
    end
end

ents.register(PumpJack, "base_machine")

