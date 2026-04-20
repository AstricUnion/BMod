---@name BMod Gas
---@author AstricUnion
---@shared


---Class for gas particles and emmiters manipulations
---@class gas
---@field inited table<number, GasParticle> Inited and therefore spawned entities
---@field registered table<string, GasParticle> Registrated classes. Index is inner Identifier
---Index in outer table is a hook name, in inner is an entity identifier
local gas = {}
gas.inited = {}
gas.registered = {}


---Gas particle
---@class GasParticle
---Public fields
---@field Identifier string Identifier of an entity
---Private fields
---@field position Vector Position of particle
---@field index number Particle index
---@field velocity Vector Current velocity of the gas
---@field airResistance number Air resistance of this particle
---@field dieTime number Lifetime, but relative to curtime
---On client
---@field particle Particle Client-side particle for smoke texture
---@field visualPosition Vector Visual position of smoke
local GasParticle = {}
GasParticle.__index = GasParticle
GasParticle.Identifier = "base_gas"


local function randVector(m, n)
    m = m or -1
    n = n or 1
    return Vector(math.rand(m, n), math.rand(m, n), math.rand(m, n))
end

if SERVER then
    function GasParticle:new(pos)
        local obj = setmetatable({
            velocity = randVector() * 50,
            dieTime = timer.curtime() + 60,
            position = pos
        }, self)
        local index = #gas.inited + 1
        obj.index = index
        local function init(ply)
            net.start("BModInitializeGas")
                net.writeString(self.Identifier)
                net.writeUInt(index, 32)
                net.writeUInt(obj.dieTime, 32)
                net.writeVector(pos)
            net.send(ply)
        end
        gas.inited[index] = obj
        -- This hook should initialize resource to new players and
        -- delay it, if creating in same tick with chip
        -- BUG: this method gives hooks limit
        hook.add("ClientInitialized", "BModInitializeGas" .. index, init)
        init(find.allPlayers())
    end

    timer.create("BModUpdateGas", 0.5, 0, function()
        local allPlayers = find.allPlayers()
        local edits = {}
        for _, v in pairs(gas.inited) do
            local force = randVector(-4, 4) + Vector(0, 0, -8) * 4
            v.velocity = v.velocity + force
            v.velocity = v.velocity:getNormalized() * math.min(v.velocity:getLength(), 80)
            local selfPos = v.position
            local newPos = v.position + v.velocity
            ---@type TraceResult
            local tr = trace.line(selfPos, newPos, {}, MASK.SOLID + MASK.WATER)
            if !tr.Hit then
                v.position = newPos
            else
                v.position = tr.HitPos + tr.HitNormal
                local ang, speed = v.velocity:getAngle(), v.velocity:getLength()
                ang:rotateAroundAxis(tr.HitNormal, 180)
                v.velocity = -(ang:getForward() * speed)
            end
            edits[v.index] = v.position
        end
        net.start("BModUpdateGas")
            net.writeTable(edits)
        net.send(allPlayers)
    end)
end


function GasParticle:remove()
    gas.inited[self.index] = nil
    setmetatable(self, nil)
end


function GasParticle:isValid()
    return self ~= nil
end


if CLIENT then
    local gasEmmiter = particle.create(Vector(), true)
    local mat = material.load("particle/smokestack")

    -- Initialize entity on client
    net.receive("BModInitializeGas", function()
        local identifier = net.readString()
        local self = gas.registered[identifier]
        if !self then return end
        local index = net.readUInt(32)
        local dieTime = net.readUInt(32)
        local pos = net.readVector()
        local size = math.random(50, 150)
        local particle = gasEmmiter:add(mat, pos, size, size, size, size, 25, 20, math.min(dieTime - timer.curtime(), 60))
        particle:setColor(Color(120, math.random(120, 150), 75))
        local obj = setmetatable({
            index = index,
            dieTime = dieTime,
            position = pos,
            visualPosition = pos,
            particle = particle
        }, self)
        gas.inited[index] = obj
    end)

    net.receive("BModUpdateGas", function()
        local edits = net.readTable()
        for index, pos in pairs(edits) do
            local particle = gas.inited[index]
            if !particle then return end
            particle.position = pos
        end
    end)

    hook.add("RenderOffscreen", "BModGasGraphics", function()
        local eyePos = render.getEyePos()
        for _, v in pairs(gas.inited) do
            local pos = math.lerpVector(game.getTickInterval() / 3, v.visualPosition, v.position)
            v.particle:setPos(pos)
            v.particle:setAngles((pos - eyePos):getAngle() + Angle(180, 0, 0))
            v.visualPosition = pos
            if v.dieTime - timer.curtime() <= 0 then
                v:remove()
            end
        end
    end)
end

---[SHARED] Register new gas particle to use it after
---@param class GasParticle
function gas.register(class)
    local id = class.Identifier
    gas.registered[id] = class
end

gas.register(GasParticle)

if SERVER then
    timer.create("", 1, 0, function()
        GasParticle:new(chip():getPos())
    end)
end

