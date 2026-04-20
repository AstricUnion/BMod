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


---Gas particle base class
---@class GasParticle
---Public fields
---@field Identifier string Identifier of an gas
---@field ThinkRate number Rate for gas update
---@field MaxVelocity number Particle max velocity
---@field MaxLife number Particle max lifetime
---@field Gravity Vector Particle gravity vector
---@field AirResistance Vector Particle air resistance
---@field BounceMultiplier number Speed multiplier to bounce
---@field VelocityMultiplier number Multiply random velocity
---Private fields
---@field position Vector Position of particle
---@field index number Particle index
---@field velocity Vector Current velocity of the gas
---@field nextThink number Next time to think, relative to curtime
---@field dieTime number Lifetime, but relative to curtime
---@field lifeTime number Lifetime in seconds
---On client
---@field particle Particle Client-side particle for smoke texture
---@field visualPosition Vector Visual position of smoke
local Gas = {}
Gas.__index = Gas
Gas.Identifier = "base_gas"
Gas.ThinkRate = 1
Gas.MaxVelocity = 80
Gas.MaxLife = 100
Gas.Gravity = Vector(0, 0, -8)
Gas.AirResistance = Vector(1, 1, 2)
Gas.BounceMultiplier = 0.8
Gas.VelocityMultiplier = 6


local function randVector(m, n)
    m = m or -1
    n = n or 1
    return Vector(math.rand(m, n), math.rand(m, n), math.rand(m, n))
end

if SERVER then
    function Gas:new(pos)
        local lifetime = math.random(self.MaxLife * 0.5, self.MaxLife)
        local cur = timer.curtime()
        local obj = setmetatable({
            -- save it to initialize on client
            Identifier = self.Identifier,
            velocity = randVector() * 50,
            lifeTime = lifetime,
            dieTime = cur + lifetime,
            position = pos,
            nextThink = cur
        }, self)
        local index = #gas.inited + 1
        obj.index = index
        gas.inited[index] = obj
        net.start("BModInitializeGases")
            net.writeTable({[index] = obj})
        net.send(find.allPlayers())
    end


    ---Remove this particle
    function Gas:remove()
        gas.inited[self.index] = nil
        setmetatable(self, nil)
        net.start("BModRemoveGas")
            net.writeUInt(self.index, 32)
        net.send(find.allPlayers())
    end


    ---This hook should initialize resource to new players and
    ---delay it, if creating in same tick with chip
    hook.add("ClientInitialized", "BModInitializeGases", function(ply)
        net.start("BModInitializeGases")
            net.writeTable(gas.inited)
        net.send(ply)
    end)

    hook.add("Think", "BModUpdateGas", function()
        local allPlayers = find.allPlayers()
        local edits = {}
        local cur = timer.curtime()
        for _, v in pairs(gas.inited) do
            if v.dieTime - cur <= 0 then
                v:remove()
                goto cont
            end
            if v.nextThink > cur then goto cont end
            local selfPos = v.position
            local rand = randVector() * v.VelocityMultiplier
            local force = rand / v.AirResistance + v.Gravity
            v.velocity = v.velocity + force
            v.velocity = v.velocity:getNormalized() * math.min(v.velocity:getLength(), v.MaxVelocity)
            local newPos = selfPos + v.velocity
            ---@type TraceResult
            local tr = trace.line(selfPos, newPos, {}, MASK.SOLID + MASK.WATER)
            if !tr.Hit then
                selfPos = newPos
            else
                selfPos = tr.HitPos + tr.HitNormal * 10
                local ang, speed = v.velocity:getAngle(), v.velocity:getLength() * v.BounceMultiplier
                ang:rotateAroundAxis(tr.HitNormal, 180)
                v.velocity = -(ang:getForward() * speed)
            end
            v.position = selfPos
            v.nextThink = cur + math.random(1 / v.ThinkRate, 1.5 / v.ThinkRate)
            edits[v.index] = selfPos
            ::cont::
        end
        net.start("BModUpdateGas")
            net.writeTable(edits)
        net.send(allPlayers)
    end)
end


function Gas:isValid()
    return getmetatable(self) ~= nil
end


if CLIENT then
    -- yeeeep, i use particles. This is more economic and shared variant, than Render. But, sad, there is limits to particles
    local gasEmmiter = particle.create(Vector(), true)
    local mat = material.load("particle/smokestack")


    ---@param obj GasParticle
    local function createParticle(obj)
        if gasEmmiter:getParticlesLeft() <= 0 then return end
        local size = math.random(50, 150)
        local particle = gasEmmiter:add(mat, obj.position, size, size, size, size, 25, 25, math.clamp(obj.dieTime - timer.curtime(), 0, 60))
        particle:setColor(obj:getColor())
        obj.particle = particle
    end


    ---[CLIENT] Gets color for particle. You can override it
    ---@return Color
    function Gas:getColor()
        return Color(124, 124, 124)
    end


    -- Initialize entity on client
    net.receive("BModInitializeGases", function()
        local inited = net.readTable()
        for id, objInfo in pairs(inited) do
            local self = gas.registered[objInfo.Identifier]
            if !self then goto cont end
            local obj = setmetatable(objInfo, self)
            obj.dieTime = timer.curtime() + obj.lifeTime
            createParticle(obj)
            -- bruh, just optimization
            obj.visualPosition = Vector(unpack(obj.position))
            gas.inited[id] = obj
            ::cont::
        end
    end)

    net.receive("BModUpdateGas", function()
        local edits = net.readTable()
        local cur = timer.curtime()
        for index, pos in pairs(edits) do
            local gasParticle = gas.inited[index]
            if !gasParticle then return end
            gasParticle.position = pos
            if gasParticle.dieTime - cur <= 2 then
                createParticle(gasParticle)
            end
        end
    end)

    net.receive("BModRemoveGas", function()
        local index = net.readUInt(32)
        local obj = gas.inited[index]
        if isValid(obj) then
            setmetatable(obj, nil)
            gas.inited[index] = nil
        end
    end)

    local lerpVector = math.lerpVector
    local tickInterval = game.getTickInterval
    local getAngles = render.getAngles
    local subAngs = Angle(180, 0, 0)
    hook.add("RenderOffscreen", "BModGasGraphics", function()
        if cpuAverage() > cpuMax() / 2 then return end
        local eyeAngles = getAngles() - subAngs
        local delta = tickInterval()
        for _, v in pairs(gas.inited) do
            local pos = lerpVector(delta, v.visualPosition, v.position)
            local part = v.particle
            if !part then goto cont end
            part.setPos(part, pos)
            part.setAngles(part, eyeAngles)
            v.visualPosition = pos
            ::cont::
        end
    end)
end

---[SHARED] Register new gas particle to use it after
---@param class GasParticle
function gas.register(class)
    local id = class.Identifier
    gas.registered[id] = class
end

gas.register(Gas)

if SERVER then
    timer.create("", 0.1, 100, function()
        local posOffset = randVector(-50, 50):setZ(0)
        local part = Gas:new(chip():getPos() + posOffset + Vector(0, 0, 100))
        if !part then return end
        part.velocity = randVector() * math.random(1, 100)
    end)
end

