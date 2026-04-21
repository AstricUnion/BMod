---@name BMod gas classes
---@author AstricUnion

---@class gas
local gas = gas
---@class butils
local butils = butils


-- Gas effects
if SERVER then
    ---Poisoning, used for carbon-monooxide (CO). Cough and damage
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
    gas.Base.Effects = {
        gas.getEffect("poisoning")
    }
    gas.Base.DamageChance = 0.1
    gas.Base.PoisonDamage = {3, 10}
    gas.Base.CoughRate = 2.5
end


gas.register(gas.Base)

if SERVER then
    timer.create("", 2, 0, function()
        local posOffset = gas.randVector(-50, 50):setZ(0)
        local part = gas.create("base_gas")
        if !part then return end
        part:setPos(chip():getPos() + posOffset)
        part:spawn()
        part.velocity = gas.randVector() * math.random(1, 100)
    end)
end
