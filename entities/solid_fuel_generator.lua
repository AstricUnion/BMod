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

local mdl = model.create(hitbox {
    vertex {"cube", Vector(28, 0, 12), Angle(0, 0, 0), Vector(42, 24, 24)},
    vertex {"cube", Vector(0, 0, 41), Angle(0, 0, 0), Vector(14, 24, 4)},
    mass = 400,
    visible = false
})
mdl:add("base", part {
    holo { Vector(52, 0, 22), Angle(0, 0, 0), "models/xqm/cylinderx2huge.mdl", Vector(0.6, 0.8, 0.8), material = "models/props_c17/furnituremetal002a" },
    holo { Vector(60, 0, -11), Angle(0, 0, 0), "models/props_c17/metalladder001.mdl", Vector(1, 1.4, 0.35), material = "models/props_c17/furnituremetal002a" },
    holo { Vector(44, 0, -3), Angle(0, 0, 0), "models/props_lab/partsbin01.mdl", Vector(2, 1.5, 0.7), color = Color(255, 0, 0), material = "models/props_c17/furnituremetal002a" },
    holo { Vector(52, 0, 48), Angle(0, 0, 0), "models/props_wasteland/chimneypipe02b.mdl", Vector(0.15, 0.15, 0.15), material = "models/props_c17/furnituremetal002a" },
    holo { Vector(48, 5, 5), Angle(0, 0, -90), "models/props_pipes/valvewheel002.mdl", Vector(2, 2, 2), material = "models/props_c17/furnituremetal002a" },
    holo {
        Vector(4, 0, 56), Angle(0, 180, 0), "models/props_c17/FurnitureFireplace001a.mdl", Vector(1.6, 1.6, 1.8),
        material = "models/props_c17/furnituremetal002a", clips = {
            { Vector(0, 0, -10), Vector(0, 0, -1) }
        }
    },
    holo { Vector(44, 0, 22), Angle(90, 0, 0), "models/props_pipes/pipecluster08d_extender128.mdl", Vector(4.3, 4.3, 0.3), color = Color(255, 255, 0) },
})

---@class SolidFuelGenerator: BaseMachine
---@field nextGas number
local SolidFuelGenerator = {}
SolidFuelGenerator.Identifier = "solid_fuel_generator"
SolidFuelGenerator.Name = "Solid Fuel Generator"
SolidFuelGenerator.Model = function()
    return mdl:create()
end
SolidFuelGenerator.hooks = {}

---@type table<string, ResourceInput>
SolidFuelGenerator.Inputs = {}
SolidFuelGenerator.Inputs.fuel = { affectedByGrade = true, rateField = "SolidFuelInUnit", maxCount = 1000 }
SolidFuelGenerator.Inputs.water = { affectedByGrade = true, type = "water", maxCount = 300 }

---@type table<string, ResourceOutput>
SolidFuelGenerator.Outputs = {}
SolidFuelGenerator.Outputs.power = { affectedByGrade = true, type = "power", maxCount = 100 }

SolidFuelGenerator.OutputOffset = Vector(0, 30, 10)

SolidFuelGenerator.WorkCooldown = 1
SolidFuelGenerator.FontSize = 24

if SERVER then
    function SolidFuelGenerator:machineInitialize()
        self.nextGas = 0
    end

    function SolidFuelGenerator:turnOn(ply)
        if self:getInput("fuel") <= 0 then
            BMod.hintMessage(ply, "There's no fuel in the machine")
            return
        end
        self.effect = beff.create("oilsmoke")
        self.effect:setEntity(self.ent)
        self.effect:setOrigin(Vector(56, 0, 64))
        self.effect:play()
        return true
    end

    function SolidFuelGenerator:turnOff(_)
        self.effect:destroy()
        self.effect = nil
    end

    ---[SERVER] Work function. To make power
    function SolidFuelGenerator:work(cur)
        local fuel = self:getInput("fuel")
        if fuel <= 0 then return false end
        local grade = self:getGrade()
        local speedMultiplier = 4
        local actually = self:consumeInput("fuel", speedMultiplier)
        local fuelEfficiency = (0.2 + ((grade - 1) * 0.075))
        self:consumeInput("water", actually * fuelEfficiency * 0.4)
        self:addToOutput("power", actually * fuelEfficiency)
        if self.nextGas <= cur then
            local offsetPos = self.ent:localToWorld(Vector(8, -8, 81))
            local par = gas.create("carbonmonoxide")
            par:setPos(offsetPos + self.ent:getUp() * 50)
            par:setVelocity(gas.randVector() * 50 * Vector(1, 1, 2))
            par:spawn()
            self.nextGas = cur + 5
        end
    end

    ---[SERVER] On remove
    function SolidFuelGenerator:onRemove()
        if isValid(self.effect) then
            self.effect:destroy()
        end
    end
end

if CLIENT then
    ---@class bgui
    local bgui = bgui

    ---[CLIENT] Draw info about this drill within 3D2D
    ---@param self LiquidFuelGenerator
    function SolidFuelGenerator.hooks.PostDrawTranslucentRenderables(self)
        BMod.displayEnt(self.ent, Vector(-20, 0, 36), Angle(0, 180, 0), function()
            local fields = {}
            local power = self:getOutput("power")
            fields[#fields+1] = {"Fuel", self:getInput("fuel"), 1000, false, true}
            fields[#fields+1] = {"Water", self:getInput("water"), 300, false, true}
            if self:isTurnedOn() then
                fields[#fields+1] = {"Progress", (power / 400) * 100, 100, false, true}
            end
            self:drawFields(0, 0, fields, false, 16)
        end)
    end
end

ents.register(SolidFuelGenerator, "base_machine")

