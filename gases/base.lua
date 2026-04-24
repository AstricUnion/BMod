---@name BMod gas classes
---@author AstricUnion

---@class gas
local gas = gas
---@class butils
local butils = butils


-- Gas effects
if SERVER then
    ---Poisoning, used for carbon-monoxide (CO). Cough and damage
    ---@class Poisoning: GasEffect
    ---@field nextCough table<Player, number>
    local Poisoning = setmetatable({}, gas.EffectBase)
    Poisoning.__index = Poisoning
    Poisoning.Identifier = "poisoning"

    function Poisoning:initialize()
        self.nextCough = {}
    end

    function Poisoning:effect(ply, particle)
        local next = self.nextCough[ply] or 0
        local cur = timer.curtime()
        if next > cur then return end
        ply:emitSound("ambient/voices/cough" .. math.random(1, 4) .. ".wav", 75, math.random(90, 110), 0.6)
        if math.random(1, math.round(1 / (particle.DamageChance or 0.1))) == 1 then
            butils.applyDamage(ply, math.random(unpack(particle.PoisonDamage or {3, 10})))
        end
        self.nextCough[ply] = cur + (particle.CoughRate or 2)
    end

    gas.registerEffect(Poisoning)

    gas.Base.Effect = true
end

---Carbon monoxide gas (CO)
---@class CarbonMonoxide: Gas
local CarbonMonoxide = {}
CarbonMonoxide.Identifier = "gas_carbonmonoxide"
CarbonMonoxide.ThinkRate = 1
CarbonMonoxide.MaxVelocity = 80
CarbonMonoxide.MaxLife = 100
CarbonMonoxide.Gravity = Vector(0, 0, -8)
CarbonMonoxide.AirResistance = Vector(1, 1, 2)
CarbonMonoxide.BounceMultiplier = 0.8
CarbonMonoxide.VelocityMultiplier = 6
if SERVER then
    CarbonMonoxide.Effect = true
    CarbonMonoxide.EffectRadius = 300
    CarbonMonoxide.Effects = {
        gas.getEffect("poisoning")
    }
end
CarbonMonoxide.DamageChance = 0.1
CarbonMonoxide.PoisonDamage = {3, 10}
CarbonMonoxide.CoughRate = 2.5

if CLIENT then
    function CarbonMonoxide:getColor()
        return Color(120, math.random(120, 150), 75, 25)
    end
end

gas.register(CarbonMonoxide)
if SERVER then
    --[[
    timer.create("", 2, 0, function()
        local posOffset = gas.randVector(-50, 50):setZ(0)
        local part = gas.create("gas_carbonmonoxide")
        if !part then return end
        part:setPos(chip():getPos() + posOffset)
        part:spawn()
        part.velocity = gas.randVector() * math.random(1, 100)
    end)]]
end
