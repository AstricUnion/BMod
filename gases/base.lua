---@name BMod gas classes
---@author AstricUnion

---@class gas
local gas = gas
---@class butils
local butils = butils
---@class equipment
local equipment = equipment


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
        local inhale, _, _ = equipment.getBiologicalResistance(ply, DAMAGE.NERVEGAS)
        if inhale >= 0.75 then return end
        ply:emitSound("ambient/voices/cough" .. math.random(1, 4) .. ".wav", 75, math.random(90, 110), 0.6)
        if math.random(1, math.round(1 / (particle.DamageChance or 0.1))) == 1 then
            butils.applyDamage(ply, math.random(unpack(particle.PoisonDamage or {3, 10})))
        end
        self.nextCough[ply] = cur + (particle.CoughRate or 2) * math.rand(0.8, 1.2)
    end

    gas.registerEffect(Poisoning)
end


if SERVER then
    ---Blinding effect, eyes irritation
    ---@class Blinding: GasEffect
    ---@field nextBlind table<Player, number>
    local Blinding = setmetatable({}, gas.EffectBase)
    Blinding.__index = Blinding
    Blinding.Identifier = "blinding"

    function Blinding:initialize()
        self.nextBlind = {}
    end

    function Blinding:effect(ply, particle)
        local next = self.nextBlind[ply] or 0
        local cur = timer.curtime()
        if next > cur then return end
        net.start("BModScreenEffectBlind")
        net.send(ply)
        self.nextBlind[ply] = cur + 2
    end

    gas.registerEffect(Blinding)
else
    local ang = 0
    local screenSpace = material.load("pp/blurscreen")

    net.receive("BModScreenEffectBlind", function()
        hook.add("DrawBModScreenEffect", "BModScreenEffectBlind", function()
            render.setMaterial(screenSpace)
            render.drawTexturedRect(0, 0, 1024, 1024)
            local sin = math.sin(math.rad(ang))
            if sin > 0.1 then
                render.drawBlurEffect(sin * 3, sin * 3, 1)
            end
            ang = ang + 70 * game.serverFrameTime()
            if ang >= 360 then
                hook.remove("DrawBModScreenEffect", "BModScreenEffectBlind")
                ang = 0
                return
            end
            return true
        end)
    end)
end

---Carbon monoxide gas (CO)
---@class CarbonMonoxide: Gas
local CarbonMonoxide = {}
CarbonMonoxide.Identifier = "carbonmonoxide"
CarbonMonoxide.ThinkRate = 2
CarbonMonoxide.MaxVelocity = 100
CarbonMonoxide.MaxLife = 120
CarbonMonoxide.Gravity = Vector(0, 0, -8)
CarbonMonoxide.AirResistance = Vector(1, 1, 2)
CarbonMonoxide.BounceMultiplier = 0.8
CarbonMonoxide.VelocityMultiplier = 6
if SERVER then
    CarbonMonoxide.Effect = true
    CarbonMonoxide.EffectRadius = 200
    CarbonMonoxide.Effects = {
        gas.getEffect("poisoning")
    }
end
CarbonMonoxide.DamageChance = 0.1
CarbonMonoxide.PoisonDamage = {3, 10}
CarbonMonoxide.CoughRate = 2.5

if CLIENT then
    function CarbonMonoxide:getColor()
        return Color(124, 124, 124, 25)
    end
end

gas.register(CarbonMonoxide)


---Fumigant for fumigator. NFPA 704 from JMod similar to CH3Br
---@class Fumigant: Gas
local Fumigant = {}
Fumigant.Identifier = "fumigant"
Fumigant.ThinkRate = 1
Fumigant.MaxVelocity = 100
Fumigant.MaxLife = 120
Fumigant.Gravity = Vector(0, 0, -8)
Fumigant.AirResistance = Vector(1, 1, 1)
Fumigant.BounceMultiplier = 1
Fumigant.VelocityMultiplier = 4
if SERVER then
    Fumigant.Effect = true
    Fumigant.EffectRadius = 300
    Fumigant.Effects = {
        gas.getEffect("poisoning"),
        gas.getEffect("blinding")
    }
end
Fumigant.DamageChance = 0.1
Fumigant.PoisonDamage = {3, 10}
Fumigant.CoughRate = 0.8

if CLIENT then
    function Fumigant:getColor()
        return Color(math.random(120, 120), math.random(120, 150), 75, 25)
    end
end

gas.register(Fumigant)
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
