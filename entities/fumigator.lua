---@class ents
local ents = ents

---@class Fumigator: BaseMachine
---@field containedGas number
local Fumigator = {}
Fumigator.Identifier = "fumigator"
Fumigator.Name = "Fumigator"
Fumigator.Model = "models/props_explosive/explosive_butane_can02.mdl"
Fumigator.hooks = {}
Fumigator.WorkCooldown = 0.2


if SERVER then
    function Fumigator:machineInitialize()
        self.containedGas = 100
    end

    function Fumigator:turnOn() return true end

    function Fumigator:work()
        if self.containedGas < 1 then self:remove() end
        local par = gas.create("fumigant")
        par:setPos(self.ent:getPos() + self.ent:getUp() * 50)
        par:setVelocity(self.ent:getVelocity() + (gas.randVector() * 50) + self.ent:getUp() * 5)
        par:spawn()
        self.containedGas = self.containedGas - 1
    end
end


ents.register(Fumigator, "base_machine")
