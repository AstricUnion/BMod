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
local rig = model.rig
local holo = model.holo

local mdl = model.new("oil_refinery", part {
    hitbox {
        vertex {"cube", Vector(-8, 0, 36), Angle(0, 0, 0), Vector(24, 64, 48)},
        vertex {"cylinder", Vector(0, -100, 116), Angle(0, 0, 0), Vector(31, 31, 128)},
        mass = 4000,
        visible = false
    },
    holo { Vector(0, 0, 32), Angle(0, 0, 0), "models/props_c17/substation_transformer01a.mdl", Vector(0.4, 0.6, 0.6) },
    holo { Vector(0, -100, 110), Angle(0, -90, 0), "models/props_wasteland/coolingtank02.mdl", Vector(0.6, 0.6, 0.6), subcolor = 1 },
    holo { Vector(-12, 0, 80), Angle(0, 90, 0), "models/props_wasteland/horizontalcoolingtank04.mdl", Vector(0.4, 0.3, 0.3), submaterial = 1 },
    holo { Vector(10, -28, 36), Angle(0, 0, 0), "models/props_c17/tv_monitor01.mdl", Vector(1.6, 1.6, 1.8) },
    holo { Vector(19, -28, 36), Angle(90, 0, 0), "models/holograms/plane.mdl", Vector(2, 2.5, 2), color = Color(20, 20, 30), noLight = true },
    holo { Vector(24, 28, 32), Angle(0, 0, 0), "models/props_wasteland/panel_leverbase001a.mdl", Vector(1, 1, 1) },
    holo { Vector(0, -100, 200), Angle(0, 0, 0), "models/props_rooftop/roof_vent004.mdl", Vector(0.5, 0.5, 0.4) },
})

---@class OilRefinery: BaseMachine
---@field effect BEffect
local OilRefinery = {}
OilRefinery.Identifier = "oil_refinery"
OilRefinery.Name = "Oil Refinery"
OilRefinery.Model = function()
    return mdl:create()
end
OilRefinery.hooks = {}

---@type table<string, ResourceInput>
OilRefinery.Inputs = {}
OilRefinery.Inputs.oil = { affectedByGrade = true, type = "oil", maxCount = 500, gradePower = 1.75 }
OilRefinery.Inputs.power = { affectedByGrade = true, type = "power", maxCount = 500, gradePower = 1.5 }

---@type table<string, ResourceOutput>
OilRefinery.Outputs = {}
OilRefinery.Outputs.fuel = { affectedByGrade = true, type = "fuel", maxCount = 400 }
OilRefinery.Outputs.plastic = { affectedByGrade = true, type = "plastic", maxCount = 50 }
OilRefinery.Outputs.rubber = { affectedByGrade = true, type = "rubber", maxCount = 50 }
OilRefinery.Outputs.gas = { affectedByGrade = true, type = "gas", maxCount = 20 }
OilRefinery.OutputOffset = Vector(42, -100, 42)

OilRefinery.WorkSound = "ambient/machines/refinery_loop_1.wav"
OilRefinery.WorkCooldown = 1
OilRefinery.FontSize = 24

OilRefinery.Display = true
OilRefinery.DisplayOffset = Vector(19.2, -32, 48)
OilRefinery.DisplayAngle = Angle(0, 0, 0)

OilRefinery.MaxDurability = 900

if SERVER then
    function OilRefinery:turnOn(ply)
        if self:getInput("power") <= 0 then return end
        self.effect = beff.create("oilsmoke")
        self.effect:setEntity(self.ent)
        self.effect:setOrigin(Vector(0, -100, 256))
        self.effect:play()
        return true
    end

    function OilRefinery:turnOff(_)
        self.effect:destroy()
        self.effect = nil
    end

    ---[SERVER] Work function. To make power
    function OilRefinery:work(cur)
        local power = self:getInput("power")
        local oil = self:getInput("oil")
        if power <= 0 or oil <= 0 then return false end
        self:consumeInput("power", 1.5)
        self:consumeInput("oil", 1)
        self:addToOutput("fuel", 4)
        self:addToOutput("plastic", 0.5)
        self:addToOutput("rubber", 0.5)
        self:addToOutput("gas", 0.2)
    end

    ---[SERVER] On remove
    function OilRefinery:onRemove()
        if isValid(self.effect) then
            self.effect:destroy()
        end
    end
end

if CLIENT then
    ---@class bgui
    local bgui = bgui

    ---[CLIENT] Draw info about this drill within 3D2D
    function OilRefinery:drawDisplay()
        local fields = {}
        fields[#fields+1] = {"Power", self:getInput("power"), 500, false, true}
        fields[#fields+1] = {"Oil", self:getInput("oil"), 500, false, true}
        fields[#fields+1] = {"Progress", self:getOutput("fuel"), 400, false, true}
        self:drawFields(0, 0, fields, false, 16)
    end
end

ents.register(OilRefinery, "base_machine")

