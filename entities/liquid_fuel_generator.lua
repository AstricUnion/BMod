---@class ents
local ents = ents

---@class deposit
local deposit = deposit

---@class resource
local resource = resource

---@class beff
local beff = beff

---@class LiquidFuelGenerator: BaseMachine
---@field nextGas number
local LiquidFuelGenerator = {}
LiquidFuelGenerator.Identifier = "liquid_fuel_generator"
LiquidFuelGenerator.Name = "Liquid Fuel Generator"
LiquidFuelGenerator.Model = "models/props_mining/diesel_generator.mdl"
LiquidFuelGenerator.hooks = {}

---@type table<string, ResourceInput>
LiquidFuelGenerator.Inputs = {}
LiquidFuelGenerator.Inputs.fuel = { affectedByGrade = true, rateField = "LiquidFuelInUnit", maxCount = 100 }

---@type table<string, ResourceOutput>
LiquidFuelGenerator.Outputs = {}
LiquidFuelGenerator.Outputs.power = { affectedByGrade = true, type = "power", maxCount = 100 }

LiquidFuelGenerator.OutputOffset = Vector(0, 30, 10)

LiquidFuelGenerator.WorkCooldown = 1
LiquidFuelGenerator.FontSize = 24


if SERVER then
    function LiquidFuelGenerator:machineInitialize()
        self.ent:setMass(250)
        self.nextGas = 0
    end

    function LiquidFuelGenerator:turnOn(ply)
        if self:getInput("fuel") <= 0 then
            BMod.hintMessage(ply, "There's no fuel in the machine")
            return
        end
        self.effect = beff.create("oilsmoke")
        self.effect:setEntity(self.ent)
        self.effect:setOrigin(Vector(8, -8, 81))
        self.effect:play()
        return true
    end

    function LiquidFuelGenerator:turnOff(_)
        self.effect:destroy()
        self.effect = nil
    end

    ---[SERVER] Work function. To make power
    function LiquidFuelGenerator:work(cur)
        local fuel = self:getInput("fuel")
        if fuel <= 0 then return false end
        local grade = self:getGrade()
        local speedMultiplier = 0.5
        local actually = self:consumeInput("fuel", speedMultiplier)
        local fuelEfficiency = (0.2 + ((grade - 1) * 0.075)) * 20
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
    function LiquidFuelGenerator:onRemove()
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
    function LiquidFuelGenerator.hooks.PostDrawTranslucentRenderables(self)
        BMod.displayEnt(self.ent, Vector(-65, 12, 66), Angle(0, 180, 0), function()
            local fields = {}
            fields[#fields+1] = {"Progress", self:getOutput("power"), 100, false, true}
            fields[#fields+1] = {"Fuel", self:getInput("fuel"), 100, false, true}
            self:drawFields(0, 0, fields, false, 16)
        end)
    end
end

ents.register(LiquidFuelGenerator, "base_machine")

