
---@class beff
local beff = beff

---@class gas
local gas = gas

---@class Dirt: BEffect
---@field emmiter ParticleEmitter Emmiter
---@field nextParticle number Next particle to spawn. Relative to CurTime
local Dirt = {}
Dirt.Identifier = "dirt"

if CLIENT then
    local smoke = material.load("particle/smokestack")
    local fleck = {
        material.load("effects/fleck_cement1"),
        material.load("effects/fleck_cement2")
    }
    local fleckColors = {Color(100, 100, 100), Color(60, 40, 20)}
    local emm = particle.create(Vector(), false)

    function Dirt:init()
        local origin = self:getOrigin()
        local norm = self:getNormal()
        -- Fleck particles
        for _=1, 20 do
            if emm:getParticlesLeft() < 1 then return end
            local startSize = math.random(8, 12)
            local part = emm:add(
                fleck[math.random(1, #fleck)],
                origin + gas.randVector(-5, 5),
                startSize, 0,
                startSize, 0,
                255, 0,
                math.random(3, 5)
            )
            if !part then return end
            part:setVelocity(norm * math.random(10, 150) + gas.randVector() * math.random(10, 120))
            part:setAirResistance(10)
            part:setRoll(math.rand(-3, 3))
            part:setGravity(physenv.getGravity())
            part:setCollide(true)
            part:setColor(fleckColors[math.random(1, #fleckColors)])
            part:setBounce(math.rand(0, 0.5))
        end
        -- Smoke particles
        for _=1, 8 do
            if emm:getParticlesLeft() < 1 then return end
            local startSize = math.random(3, 5)
            local part = emm:add(
                smoke, origin + gas.randVector(-5, 5),
                startSize, startSize * 10,
                startSize, startSize * 10,
                255, 0,
                math.random(1, 3)
            )
            part:setAirResistance(20)
            part:setVelocity(norm * math.random(1, 60) + gas.randVector() * math.random(1, 60))
            part:setRoll(math.rand(-3, 3))
            part:setGravity(Vector(0, 0, -50))
            part:setCollide(true)
            part:setColor(fleckColors[math.random(1, #fleckColors)])
            part:setBounce(math.rand(0, 0.3))
        end
    end
end

function Dirt:think() return false end

beff.register(Dirt)
