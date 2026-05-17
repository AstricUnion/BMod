---Lib for safely particle control. It creates emmiters for limit and overrides functions.
---By this you can use all particle count, not emmiter limit. 3D particles not supported
if SERVER then return end

---@class ParticleEmmiterPool
---@field pool ParticleEmitter[]
local ParticleEmmiterPool = {}
ParticleEmmiterPool.__index = ParticleEmmiterPool
ParticleEmmiterPool.emmiters = {}

---[CLIENT] Create new particle emmiters pool
function ParticleEmmiterPool:new()
    local pool = {}
    for _=1, particle.particleEmittersLeft() do
        pool[#pool+1] = particle.create(Vector(), false)
    end
    return setmetatable({ pool = pool }, self)
end


---@return ParticleEmitter?
function ParticleEmmiterPool:getFreeEmmiter()
    for _, v in ipairs(self.pool) do
        if v:getParticlesLeft() > 0 then
            return v
        end
    end
end


---[CLIENT] Create new particle
---@return Particle?
function ParticleEmmiterPool:add(material, position, startSize, endSize, startLength, endLength, startAlpha, endAlpha, dieTime)
    local emm = self:getFreeEmmiter()
    if !emm then return end
    return emm:add(material, position, startSize, endSize, startLength, endLength, startAlpha, endAlpha, dieTime)
end


---[CLIENT] Get particles left
---@return number
function ParticleEmmiterPool:getParticlesLeft()
    local part = 0
    for _, v in ipairs(self.pool) do
        part = part + v:getParticlesLeft()
    end
    return part
end


---[CLIENT] Just a placeholder
function ParticleEmmiterPool:destroy() end


particle.pool = ParticleEmmiterPool:new()
particle.__createOld = particle.__createOld or particle.create

---[CLIENT] Get particle emmiter pool
---@return ParticleEmmiterPool
function particle.create(_, _)
    return particle.pool
end

