---Solution for effects. Can spawned on a server or a client, like gmod effects
---@name BMod effects
---@author AstricUnion
---@shared


---@class beff
---@field inited table<number, BEffect> Inited and therefore spawned effects
---@field registered table<string, BEffect> Registered classes
local beff = {}
beff.inited = {}
beff.registered = {}


---Effect class
---@class BEffect
---@field Identifier string Identifier of the effect
---@field index number Index of effect
---@field origin Vector Origin of the effect
---@field angles Angle Angles of the effect
---@field attachment number Attachment ID of the effect
---@field entity Entity? Entity assigned to the effect
---@field flags number Flags assigned to the effect
---@field hitbox number Hitbox ID of the effect
---@field magnitude number magnitude of the effect
---@field material number Material ID of the effect
---@field normal Vector Normalized direction vector of the effect
---@field radius number Radius of the effect
---@field scale number Scale of the effect
---@field start Vector Start position of the effect
---@field surfaceProp number Surface property index of the effect
local BEffect = {}
BEffect.__index = BEffect


---Create new effect
function BEffect:new()
    return setmetatable(
        {
            Identifier = self.Identifier,
            origin = Vector(), angles = Angle(), attachment = 0,
            flags = 0, hitbox = 0, magnitude = 0, material = 0,
            normal = Vector(0, 0, 1), radius = 0, scale = 1, start = 0,
            surfaceProp = 0
        },
        self
    )
end


---Initialize effect hook
function BEffect:init() end

---Think hook of effect. Return false to destroy effect
---@return boolean
function BEffect:think() return true end


-- Methods of the effect
-- (i used abolish-vim btw, very useful plugin to fast replace with case saving)
-- TODO: make function to generate get/set, and make normal docs solution

---Set origin of the effect
---@param origin Vector
function BEffect:setOrigin(origin) self.origin = origin end

---Get origin of the effect
---@return Vector origin
function BEffect:getOrigin() return self.origin end


---Set angles of the effect
---@param angles Angle
function BEffect:setAngles(angles) self.angles = angles end

---Get angles of the effect
---@return Angle angles
function BEffect:getAngles() return self.angles end


---Set attachment of the effect
---@param attachment number
function BEffect:setAttachment(attachment) self.attachment = attachment end

---Get attachment of the effect
---@return number attachment
function BEffect:getAttachment() return self.attachment end


---Set flags of the effect
---@param flags number
function BEffect:setFlags(flags) self.flags = flags end

---Get flags of the effect
---@return number flags
function BEffect:getFlags() return self.flags end


---Set hitbox of the effect
---@param hitbox number
function BEffect:setHitbox(hitbox) self.hitbox = hitbox end

---Get hitbox of the effect
---@return number hitbox
function BEffect:getHitbox() return self.hitbox end


---Set magnitude of the effect
---@param magnitude number
function BEffect:setMagnitude(magnitude) self.magnitude = magnitude end

---Get magnitude of the effect
---@return number magnitude
function BEffect:getMagnitude() return self.magnitude end


---Set material of the effect
---@param material number
function BEffect:setMaterial(material) self.material = material end

---Get material of the effect
---@return number material
function BEffect:getMaterial() return self.material end


---Set normal of the effect
---@param normal Vector
function BEffect:setNormal(normal) self.normal = normal end

---Get normal of the effect
---@return Vector normal
function BEffect:getNormal() return self.normal end


---Set radius of the effect
---@param radius number
function BEffect:setRadius(radius) self.radius = radius end

---Get radius of the effect
---@return number radius
function BEffect:getRadius() return self.radius end


---Set scale of the effect
---@param scale number
function BEffect:setScale(scale) self.scale = scale end

---Get scale of the effect
---@return number scale
function BEffect:getScale() return self.scale end


---Set start of the effect
---@param start Vector
function BEffect:setStart(start) self.start = start end

---Get start of the effect
---@return Vector start
function BEffect:getStart() return self.start end


---Set surfaceProp of the effect
---@param surfaceProp number
function BEffect:setSurfaceProp(surfaceProp) self.surfaceProp = surfaceProp end

---Get surfaceProp of the effect
---@return number surfaceProp
function BEffect:getSurfaceProp() return self.surfaceProp end

-- yaaaay i did it


if SERVER then
    ---Play this effect
    function BEffect:play()
        local index = #beff.inited+1
        beff.inited[index] = self
        self.index = index
        net.start("BModEffect")
            net.writeTable(self)
        net.send(find.allPlayers())
    end

    ---Destroy effect
    function BEffect:destroy()
        net.start("BModEffectDestroy")
            net.writeUInt(self.index, 32)
        net.send(find.allPlayers())
        beff.inited[self.index] = nil
        setmetatable(self, nil)
    end
else
    ---Play this effect
    function BEffect:play()
        local index = self.index or #beff.inited+1
        beff.inited[index] = self
        self.index = index
        self:init()
    end

    ---Destroy effect
    function BEffect:destroy()
        beff.inited[self.index] = nil
        setmetatable(self, nil)
    end

    net.receive("BModEffect", function()
        local tbl = net.readTable()
        local class = beff.registered[tbl.Identifier]
        if !class then return end
        local inherited = setmetatable(tbl, class)
        inherited:play()
    end)

    net.receive("BModEffectDestroy", function()
        local id = net.readUInt(32)
        local eff = beff.inited[id]
        if eff then
            eff:destroy()
        end
    end)

    hook.add("Think", "BModEffectsThink", function()
        for _, v in pairs(beff.inited) do
            if v:think() == false then
                v:destroy()
            end
        end
    end)
end


---[SHARED] Register new effect to use it after
---@param class table Effect class
function beff.register(class)
    local inheritedClass = setmetatable(class, BEffect)
    inheritedClass.__index = inheritedClass
    beff.registered[class.Identifier] = inheritedClass
end

---[SHARED] Create new effect
---@param classname string
---@return BEffect
function beff.create(classname)
    local class = beff.registered[classname]
    return class:new()
end


return beff
