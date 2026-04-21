---@name BMod Gas
---@author AstricUnion
---@shared


---Class for gas particles and emmiters manipulations
---@class gas
---@field inited table<number, Gas> Inited and therefore spawned entities
---@field registered table<string, Gas> Registrated classes. Index is inner Identifier
---@field registeredEffects table<string, GasEffect> Registrated classes. Index is inner Identifier
---@field Base Gas
---@field BaseEffect GasEffect
---Index in outer table is a hook name, in inner is an entity identifier
local gas = {}
gas.inited = {}
gas.registered = {}


if SERVER then
    gas.registeredEffects = {}

    ---Effect base class
    ---@class GasEffect
    ---@field Identifier string Identifier of this effect
    local GasEffect = {}
    GasEffect.__index = GasEffect
    GasEffect.Identifier = "base_effect"

    ---[SERVER] Gas effect initialize, to set variables
    function GasEffect:initialize() end

    ---[SERVER] Effect hook
    ---@param ply Player Player to have an effect
    ---@param particle Gas Particle to effect
    function GasEffect:effect(ply, particle) end

    ---[SERVER] Register new effect to use it
    ---@param effect GasEffect Gas effect class
    function gas.registerEffect(effect)
        local newEffect = setmetatable({}, effect)
        newEffect:initialize()
        gas.registeredEffects[effect.Identifier] = newEffect
    end

    ---[SERVER] Get registered effect by identifier
    ---@param effect string Identifier of effect
    ---@return GasEffect?
    function gas.getEffect(effect)
        return gas.registeredEffects[effect]
    end

    gas.EffectBase = GasEffect
end


---Gas particle base class
---@class Gas
---Public fields
---@field Identifier string Identifier of an gas
---@field ThinkRate number [SERVER] Rate for gas update
---@field NoDraw boolean [CLIENT] True to prevent particle draw
---@field MaxVelocity number [SERVER] Particle max velocity
---@field MaxLife number [SERVER] Particle max lifetime
---@field Gravity Vector [SERVER] Particle gravity vector
---@field AirResistance Vector [SERVER] Particle air resistance
---@field BounceMultiplier number [SERVER] Speed multiplier to bounce
---@field VelocityMultiplier number [SERVER] Multiply random velocity
---@field Effect boolean [SERVER] Effect players
---@field EffectRadius number [SERVER] Radius to Effect players and other
---@field Effects GasEffect[] [SERVER] Functions to effect
---Private fields
---@field index number Particle index
---@field position Vector [SHARED] Position of particle
---@field velocity Vector [SERVER] Current velocity of the gas
---@field nextThink number [SERVER] Next time to think, relative to curtime
---@field dieTime number [SHARED] Lifetime, but relative to curtime
---@field lifeTime number [SHARED] Lifetime in seconds
---@field particle Particle? [CLIENT] Client-side particle for smoke texture. Nil if NoDraw or limits
---@field visualPosition Vector? [CLIENT] Visual position of smoke, to reduce some calls
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
Gas.Effect = true
Gas.EffectRadius = 300
Gas.Effects = {}


---[SHARED] Get random vector
---@param m number? Minimum
---@param n number? Maximum
function gas.randVector(m, n)
    m = m or -1
    n = n or 1
    return Vector(math.rand(m, n), math.rand(m, n), math.rand(m, n))
end


if SERVER then
    ---[SERVER] Initialize new particle
    function Gas:new()
        local lifetime = math.random(self.MaxLife * 0.5, self.MaxLife)
        local cur = timer.curtime()
        local obj = setmetatable({
            -- save it to initialize on client
            Identifier = self.Identifier,
            velocity = gas.randVector() * 50,
            lifeTime = lifetime,
            dieTime = cur + lifetime,
            position = Vector(),
            nextThink = cur
        }, self)
        return obj
    end


    ---[SERVER] Spawn particle
    function Gas:spawn()
        local index = #gas.inited + 1
        self.index = index
        gas.inited[index] = self
        net.start("BModInitializeGases")
            net.writeTable({[index] = self})
        net.send(find.allPlayers())
    end


    ---[SERVER] Remove this particle
    function Gas:remove()
        gas.inited[self.index] = nil
        setmetatable(self, nil)
        net.start("BModRemoveGas")
            net.writeUInt(self.index, 32)
        net.send(find.allPlayers())
    end


    ---[SERVER] Set position of the gas. Updates only after update hook
    ---@param position Vector
    function Gas:setPos(position)
        self.position = position
    end


    ---[SERVER] Set velocity of the gas. Updates only after update hook
    ---@param velocity Vector
    function Gas:setVelocity(velocity)
        self.velocity = velocity
    end


    ---[SERVER] Can player see this particle
    ---@param ply Player
    function Gas:canSee(ply)
        return !trace.line(self.position, ply:getPos(), {ply}, MASK.SHOT + MASK.WATER).Hit
    end


    ---This hook should initialize resource to new players and
    ---delay it, if creating in same tick with chip
    hook.add("ClientInitialized", "BModInitializeGases", function(ply)
        if table.isEmpty(gas.inited) then return end
        net.start("BModInitializeGases")
            net.writeTable(gas.inited)
        net.send(ply)
    end)


    hook.add("Think", "BModUpdateGas", function()
        local allPlayers
        local edits = {}
        local cur = timer.curtime()
        for _, v in pairs(gas.inited) do
            if v.dieTime < cur then
                v:remove()
                goto cont
            end
            if v.nextThink > cur then goto cont end
            local selfPos = v.position
            local rand = gas.randVector() * v.VelocityMultiplier
            if v.Effect then
                allPlayers = allPlayers or find.allPlayers()
                for _, ply in ipairs(allPlayers) do
                    local pos = ply:getPos()
                    local gasPos = v.position
                    if gasPos:getDistance(pos) > v.EffectRadius then goto cont end
                    if !v:canSee(ply) then goto cont end
                    for _, effect in ipairs(v.Effects) do
                        effect:effect(ply, v)
                    end
                    ::cont::
                end
            end
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
        if edits ~= {} then
            net.start("BModUpdateGas")
                net.writeTable(edits)
            net.send(allPlayers or find.allPlayers())
        end
    end)
end


---[SERVER] Get position of the gas particle
---@return Vector position
function Gas:getPos()
    return self.position
end


---[SERVER] Get velocity of the gas particle
---@return Vector velocity
function Gas:getVelocity()
    return self.velocity
end


---[SHARED] Is particle valid
function Gas:isValid()
    return getmetatable(self) ~= nil
end


if CLIENT then
    -- yeeeep, i use particles. This is more economic and shared variant, than Render. But, sad, there is limits to particles
    local gasEmmiter = particle.create(Vector(), true)
    local mat = material.load("particle/smokestack")


    ---@param obj Gas
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
        return Color(124, 124, 124, 25)
    end


    -- Initialize entity on client
    net.receive("BModInitializeGases", function()
        local inited = net.readTable()
        for id, objInfo in pairs(inited) do
            local self = gas.registered[objInfo.Identifier]
            if !self then goto cont end
            local obj = setmetatable(objInfo, self)
            obj.dieTime = timer.curtime() + obj.lifeTime
            if !obj.NoDraw then
                createParticle(obj)
                obj.visualPosition = Vector(unpack(obj.position))
            end
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
            local part = v.particle
            if !part then goto cont end
            local pos = lerpVector(delta, v.visualPosition, v.position)
            part.setPos(part, pos)
            part.setAngles(part, eyeAngles)
            v.visualPosition = pos
            ::cont::
        end
    end)
end

---[SHARED] Register new gas particle to use it after
---@param class Gas
function gas.register(class)
    local id = class.Identifier
    gas.registered[id] = class
end

if SERVER then
    ---[SERVER] Create new particle
    ---@param classname string
    ---@return Gas?
    function gas.create(classname)
        local class = gas.registered[classname]
        if !class then return end
        return class:new()
    end
end

gas.Base = Gas

return gas
