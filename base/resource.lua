---@name BMod Resource Base
---@author AstricUnion
---@shared
---@include bmod/base/entity.lua

---@class ents
local ents = require("bmod/base/entity.lua")


---Class for resource manipulations
---@class resource
local resource = {}
resource.registered = {}
resource.props = {}


---@class ResourceSounds
---@field Merge string
---@field Split string


---Base class for resources
---@class Resource: BModEntity
-- Public fields
---@field Resource string Identifier of resource. Entity ID and this is different
---@field SignOffset Vector Offset of a sign with resource info
---@field SignAngle Angle Angle of a sign with resource info
---@field Sounds ResourceSounds Angle of a sign with resource info
-- Private fields
---@field count number Count of resource in this block. Maximum is 1024 resource
---@field pickedUpBy Player [SERVER] Player, that's picked up this resource
local Resource = {}
Resource.__index = Resource
setmetatable(Resource, ents.Base)
Resource.Identifier = "base_resource"
Resource.Name = "Base"
Resource.Resource = "base"
Resource.Model = "models/hunter/blocks/cube05x05x05.mdl"
Resource.SignOffset = Vector(12, 0, 0)
Resource.SignAngle = Angle()
Resource.Sounds = {
    Merge = "items/ammocrate_close.wav",
    Split = "items/ammocrate_open.wav"
}

local maxResource = 100

if SERVER then
    function Resource:initialize()
        local pr = self.ent
        pr:setMass(30)
        pr:setUnbreakable(true)
        pr.BModResource = self.Resource
        ---Collision listener to merge resources
        ---@param colData CollisionData
        pr:addCollisionListener(function(colData)
            if !isValid(self) then return end
            local ow = pr:getOwner()
            if !isValid(ow) or self.pickedUpBy ~= ow then return end
            if colData.HitSpeed:getLength() < 500 then return end
            local ent = colData.HitEntity

            local function tryToMerge()
                if !ent.BModResource then return end
                ---@type Resource
                local res = ents.inited[ent:entIndex()]
                if res.Resource ~= self.Resource then return end
                if res.count == maxResource and self.count == maxResource then return end
                local diff = maxResource - res.count
                if self.count > diff then
                    res:setCount(maxResource)
                    self:setCount(self.count - diff)
                else
                    self:remove()
                    res:setCount(res.count + self.count)
                end
                res.ent:emitSound(res.Sounds.Merge)
                return true
            end
            if !tryToMerge() then
                hook.run("BModResourceInteracted", self, ent)
            end
        end)
    end

    ---[SERVER] Set count of resource
    ---@param count number Count
    function Resource:setCount(count)
        count = math.clamp(count, 1, maxResource)
        self.count = count
        net.start("BModResourceCountChanged")
            net.writeUInt(count, 8)
            net.writeEntity(self.ent)
        net.send(find.allPlayers())
    end


    ---[SERVER] OnPlayerPhysicsPickup hook
    ---@param self Resource
    ---@param ply Player
    ---@param ent Entity
    function Resource.hooks.OnPlayerPhysicsPickup(self, ply, ent)
        local sprinting = ply:keyDown(IN_KEY.SPEED)
        if self.ent ~= ent then return end
        self.pickedUpBy = ply
        if sprinting and self.count > 1 then
            local newCount = math.ceil(self.count / 2)
            local oldCount = self.count - newCount
            resource.create(self.Resource, ent:getPos(), ent:getAngles(), newCount, false, true)
            self:setCount(oldCount)
            self.ent:emitSound(self.Sounds.Split)
        end
    end


    ---[SERVER] OnPlayerPhysicsDrop hook
    ---@param self Resource
    ---@param _ Player
    ---@param ent Entity
    function Resource.hooks.OnPlayerPhysicsDrop(self, _, ent)
        if self.ent ~= ent then return end
        self.pickedUpBy = nil
    end
end


if CLIENT then
    local Ply = player()
    resource.font = render.createFont("Roboto",48,500,false,false,false,false,0,false,0)

    function Resource:initialize()
        local pr = self.ent
        pr.BModResource = self.Resource
        self.count = 1
    end

    -- Change resource count
    net.receive("BModResourceCountChanged", function()
        local count = net.readUInt(8)
        net.readEntity(function(ent)
            if !ent.BModResource then return end
            local res = ents.inited[ent:entIndex()]
            if !res then return end
            res.count = count
        end)
    end)

    ---[CLIENT] Draw info about this resource within 3D2D
    ---@param self Resource
    function Resource.hooks.PostDrawTranslucentRenderables(self)
        -- local resData = resource.registered[self.Resource]
        local pos = Ply:getPos()
        if !isValid(self.ent) then return end
        if self.ent:getPos():getDistance(pos) > 256 then return end
        local ang = self.ent:getAngles()
        local m = Matrix(ang, self.ent:localToWorld(self.SignOffset))
        m:rotate(Angle(0, 90, 90) + self.SignAngle)
        m:setScale(Vector(0.1, -0.1, 1))
        render.pushMatrix(m)
        do
            render.enableDepth(true)
            render.setFont(resource.font)
            render.drawSimpleText(0, -48, self.Name, TEXT_ALIGN.CENTER)
            render.drawSimpleText(0, -8, string.format("%s units", self.count), TEXT_ALIGN.CENTER)
        end
        render.popMatrix()
    end
end

ents.register(Resource)


resource.Resource = Resource


---[SHARED] Register new resource to use it after
---@param class Resource
function resource.register(class)
    resource.registered[class.Resource] = class
end


---[SHARED] Fast registration for resource
---@param name string
---@param identifier string
---@param model string
---@param signOffset Vector
---@param signAngle Angle?
---@param mergeSound string?
---@param splitSound string?
---@return Resource class Fast created class for this resource
function resource.fastRegister(name, identifier, model, signOffset, signAngle, mergeSound, splitSound)
    local class = {}
    class.__index = class
    setmetatable(class, Resource)
    class.Name = name
    class.Resource = identifier
    class.Model = model
    class.SignOffset = signOffset
    class.SignAngle = signAngle or Angle()
    if mergeSound or splitSound then
        class.Sounds = table.copy(class.Sounds)
        class.Sounds.Merge = mergeSound or class.Sounds.Merge
        class.Sounds.Split = splitSound or class.Sounds.Split
    end
    resource.register(class)
    return class
end


---[SHARED] Adds prop as resources
---@param model string[] Props to resources
---@param resources table<string, number> Key is resource type, value is amount of this resource
function resource.addProp(model, resources)
    for _, v in ipairs(model) do
        resource.props[v] = resources
    end
end


---[SHARED] Get player's available resources
---@param ply Player Player to inspect
---@param getProps boolean? Take props as a resource
---@return table<string, number> resources Key is resource type, value is amount of this resource
function resource.getResources(ply, getProps)
    local found = find.byClass("prop_physics")
    local resources = {}
    local pos = ply:getPos()
    for _, pr in ipairs(found) do
        if pr:getPos():getDistance(pos) > 256 then goto cont end
        if pr.BModResource then
            local res = ents.inited[pr:entIndex()]
            ---@cast res Resource
            if !isValid(res) then goto cont end
            local id = res.Resource
            local current = resources[id] or 0
            resources[id] = current + res.count
        elseif getProps then
            local counts = resource.props[pr:getModel()]
            if !counts then goto cont end
            for id, count in pairs(counts) do
                local current = resources[id] or 0
                resources[id] = current + count
            end
        end
        ::cont::
    end
    return resources
end


if SERVER then
    ---[SERVER] Create new resource
    ---@param identifier string Identifier of resource to create
    ---@param pos Vector Init position of resource
    ---@param ang Angle Init angles of resource
    ---@param count number Count of resource in this block
    ---@param freeze boolean Freeze resource entity
    ---@param dontStack boolean? Create a new resource without merging with existing one(s)
    ---@return Resource
    function resource.create(identifier, pos, ang, count, freeze, dontStack)
        if !dontStack then
            local found = find.byClass("prop_physics")
            local existingResource
            for _, pr in ipairs(found) do
                if pr:getPos():getDistance(pos) > 256 then goto cont end
                if pr.BModResource ~= identifier then goto cont end
                local res = ents.inited[pr:entIndex()]
                ---@cast res Resource
                if res.count == maxResource then goto cont end
                local diff = maxResource - res.count
                if count > diff then
                    res:setCount(maxResource)
                    count = count - diff
                else
                    res:setCount(res.count + count)
                    existingResource = res
                end
                ::cont::
            end
            if existingResource then return existingResource end
        end
        local newRes = resource.registered[identifier]:new(pos, ang, freeze)
        newRes:setCount(count)
    end
end

return resource
