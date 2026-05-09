
---@class beff
local beff = beff

---@class OilSmoke: BEffect
---@field emmiter ParticleEmitter Emmiter
---@field nextParticle number Next particle to spawn. Relative to CurTime
local OilSmoke = {}
OilSmoke.Identifier = "oilsmoke"

if CLIENT then
    local smokes = {
        material.load("particle/smokestack"),
        material.load("particles/smokey"),
        material.load("particle/particle_smokegrenade"),
    }
    local fires = {
        material.load("particles/flamelet1"),
        material.load("particles/flamelet2"),
        material.load("particles/flamelet3"),
        material.load("particles/flamelet4"),
        material.load("particles/flamelet5")
    }

    function OilSmoke:init()
        local emm = self.emmiter or particle.create(Vector(), false)
        self.emmiter = emm
        self.nextParticle = 0
    end

    function OilSmoke:think()
        local cur = timer.curtime()
        if self.nextParticle >= cur then return end
        local entity = self:getEntity()
        local originStart = self:getOrigin()
        local origin = isValid(entity) and entity:localToWorld(originStart) or originStart
        local sprite
        local isFire = false
        if math.random(1, 4) ~= 4 then
            local len = #smokes
            local smIndex = math.random(1, len)
            sprite = smokes[smIndex]
        else
            local len = #fires
            local fireIndex = math.random(1, len)
            sprite = fires[fireIndex]
            isFire = true
        end
        local size = !isFire and math.rand(20, 30) or math.rand(10, 20)
        local particle = self.emmiter:add(
            sprite, origin, size - 8, size + 5,
            0, 0, isFire and 100 or 255, 0, 1
        )
        if particle then
            particle:setGravity(Vector(0, 0, 200))
            particle:setLighting(true)
            local darg = !isFire and math.rand(50, 100) or 255
            particle:setColor(Color(darg, darg, darg))
            particle:setCollide(false)
            if isFire then
                particle:setRollDelta(1)
                particle:setRoll(2)
            end
        end
        self.nextParticle = cur + 0.1
    end

    function OilSmoke:onDestroy()
        self.emmiter:destroy()
    end
end


beff.register(OilSmoke)
