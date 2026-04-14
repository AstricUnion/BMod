---@name BMod Resource Base
---@author AstricUnion
---@shared
---@include bmod/base/entity.lua

---@class ents
local ents = require("bmod/base/entity.lua")


---Class for resource manipulations
---@class resource
local resource = {}
resource.inited = {}
resource.registered = {}
resource.props = {}


---@class ResourceSounds
---@field Merge string
---@field Split string


---Base class for resources
---@class Resource: BModEntity
-- Public fields
---@field SignOffset Vector Offset of a sign with resource info
---@field SignAngle Angle Angle of a sign with resource info
---@field Sounds ResourceSounds Angle of a sign with resource info
-- Private fields
---@field count number Count of resource in this block. Maximum is 1024 resource
---@field pickedUpBy Player [SERVER] Player, that's picked up this resource
local Resource = {}
Resource.__index = Resource
setmetatable(Resource, ents.Base)
Resource.Name = "Base"
Resource.Identifier = "base_resource"
Resource.Model = "models/hunter/blocks/cube05x05x05.mdl"
Resource.SignOffset = Vector(12, 0, 0)
Resource.SignAngle = Angle()
Resource.Sounds = {
    Merge = "items/ammocrate_close.wav",
    Split = "items/ammocrate_open.wav"
}

local maxResource = 100

if SERVER then
    ---[SERVER] Create new resource entity
    ---@param pos Vector Position of resource
    ---@param ang Angle Angle of resource
    ---@param count number Start count of resource
    ---@param freeze boolean Freeze a resource
    ---@return Resource
    function Resource:new(pos, ang, count, freeze)
        local obj = setmetatable(
            {
                count = math.clamp(count, 1, maxResource),
                ent = nil,
                pickedUpBy = nil
            },
            self
        )
        -- This prop will be like entity for this resource
        local pr = prop.create(pos, ang, self.Model, freeze)
        pr:setMass(30)
        pr:setUnbreakable(true)
        -- To easy identificate prop
        pr.BModResource = self.Identifier
        if obj.modifyEntity then obj.modifyEntity(pr) end
        
        obj.ent = pr
        local function init(ply)
            if !pr:isValid() then return end
            net.start("BModInitializeResource" .. self.Identifier)
                net.writeUInt(obj.count, 8)
                net.writeEntity(obj.ent)
            net.send(ply)
        end
        -- This hook should initialize resource to new players and
        -- delay it, if creating in same tick with chip
        hook.add("ClientInitialized", "BModInitializeResource" .. pr:entIndex(), init)
        init(find.allPlayers())
        resource.inited[pr:entIndex()] = obj
        -- obj:initHooks()
        return obj
    end

    function Resource:initialize()
        local pr = self.ent
        pr.BModResource = self.Identifier
        self.count = 1
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
                local res = resource.inited[ent:entIndex()]
                if res.Identifier ~= self.Identifier then return end
                if res.count == maxResource and self.count == maxResource then return end
                local diff = maxResource - res.count
                if self.count > diff then
                    res:setCount(self)
                    self:setCount(self.count - diff)
                else
                    self:remove()
                    res:setCount(res.count + self.count)
                end
                res.ent:emitSound(self.Sounds.Merge)
                return true
            end
            if !tryToMerge() then
                hook.run("BModResourceInteracted", self, ent)
            end
        end)

    ---[SERVER] Set count of resource
    ---@param count number Count
    function Resource:setCount(count)
        count = math.clamp(count, 1, maxResource)
        self.count = count
        net.start("BModCountChanged" .. self.Identifier)
            net.writeUInt(count, 8)
            net.writeEntity(self.ent)
        net.send(find.allPlayers())
    end


    ---[SERVER] Remove resource
    function Resource:remove()
        self.ent:remove()
        resource.inited[self.ent:entIndex()] = nil
        setmetatable(self, nil)
    end


    ---[SERVER] Modify entity after spawn. You can safely override it
    ---@param ent Entity
    function Resource.modifyEntity(ent) end


    ---[SERVER] OnPlayerPhysicsPickup hook
    ---@param ply Player
    ---@param ent Entity
    hook.add("OnPlayerPhysicsPickup", "BModResourcePickup", function(ply, ent)
        local sprinting = ply:keyDown(IN_KEY.SPEED)
        for _, self in pairs(resource.inited) do
            if self.ent ~= ent then goto cont end
            self.pickedUpBy = ply
            if sprinting and self.count > 1 then
                local newCount = math.ceil(self.count / 2)
                local oldCount = self.count - newCount
                resource.create(self.Identifier, ent:getPos(), ent:getAngles(), newCount, false, true)
                self:setCount(oldCount)
                self.ent:emitSound(self.Sounds.Split)
                return
            else
                return
            end
            ::cont::
        end
    end)


    ---[SERVER] OnPlayerPhysicsDrop hook
    ---@param _ Player
    ---@param ent Entity
    hook.add("OnPlayerPhysicsDrop", "BModResourcePickup", function(_, ent)
        for _, self in pairs(resource.inited) do
            if self.ent ~= ent then goto cont end
            self.pickedUpBy = nil
            ::cont::
        end
    end)
end


if CLIENT then
    local Ply = player()
    resource.font = render.createFont("Roboto",48,500,false,false,false,false,0,false,0)

    ---[CLIENT] Init net messages
    function Resource:initNet()
        -- Init new resource
        net.receive("BModInitializeResource" .. self.Identifier, function()
            local count = net.readUInt(8)
            ---@param ent Entity
            net.readEntity(function(ent)
                ent.BModResource = self.Identifier
                local obj = setmetatable(
                    {
                        count = count,
                        ent = ent,
                    },
                    self
                )
                resource.inited[ent:entIndex()] = obj
            end)
        end)

        -- Change resource count
        net.receive("BModCountChanged" .. self.Identifier, function()
            local count = net.readUInt(8)
            net.readEntity(function(ent)
                if !ent.BModResource then return end
                local res = resource.inited[ent:entIndex()]
                if !res then return end
                res.count = count
            end)
        end)
    end


    ---[CLIENT] Draw info about this resource within 3D2D
    hook.add("PostDrawTranslucentRenderables", "BModResourceInfo", function()
        local pos = Ply:getPos()
        for _, self in pairs(resource.inited) do
            if !isValid(self.ent) then goto cont end
            if self.ent:getPos():getDistance(pos) > 256 then
                goto cont
            end
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
            ::cont::
        end
    end)
end

---[SHARED] Is resource valid
function Resource:isValid()
    return self ~= nil and self.ent:isValid()
end


resource.Resource = Resource


---[SHARED] Register new resource to use it after
---@param class Resource
function resource.register(class)
    if CLIENT then class:initNet() end
    resource.registered[class.Identifier] = class
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
    class.Identifier = identifier
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
            local res = resource.inited[pr:entIndex()]
            if !isValid(res) then goto cont end
            local id = res.Identifier
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
                local res = resource.inited[pr:entIndex()]
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
        return resource.registered[identifier]:new(pos, ang, count, freeze)
    end
end

return resource
