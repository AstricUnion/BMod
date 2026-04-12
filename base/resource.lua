---@name BMod Resource Base
---@author AstricUnion
---@shared


---Class for resource manipulations
---@class resource
local resource = {}
resource.inited = {}
resource.registered = {}

---[SHARED] Register new resource to use it after
---@param class Resource
function resource.register(class)
    if CLIENT then class:initNet() end
    resource.registered[class.Identifier] = class
end


if SERVER then
    ---[SERVER] Create new resource
    ---@param identifier string Identifier of resource to create
    ---@param pos Vector Init position of resource
    ---@param ang Angle Init angles of resource
    ---@param count number Count of resource in this block
    ---@param freeze boolean Freeze resource entity
    ---@return Resource
    function resource.create(identifier, pos, ang, count, freeze)
        return resource.registered[identifier]:new(pos, ang, count, freeze)
    end
end

---@class ResourceSounds
---@field Merge string
---@field Split string


---Base class for resources
---@class Resource
-- Public fields
---@field Identifier string Identifier of a resource
---@field Name string Pretty name of a resource
---@field Model string Model of a resource
---@field SignOffset Vector Offset of a sign with resource info
---@field SignAngle Angle Angle of a sign with resource info
---@field Sounds ResourceSounds Angle of a sign with resource info
-- Private fields
---@field count number Count of resource in this block. Maximum is 1024 resource
---@field ent Entity Prop with hooks for interactions. Can be nil on client
---@field pickedUpBy Player [SERVER] Player, that's picked up this resource
local Resource = {}
Resource.__index = Resource
Resource.Name = "Base"
Resource.Identifier = "base"
Resource.Model = "models/hunter/blocks/cube05x05x05.mdl"
Resource.SignOffset = Vector(12, 0, 0)
Resource.SignAngle = Angle()
Resource.Sounds = {
    Merge = "items/ammocrate_close.wav",
    Split = "items/ammocrate_open.wav"
}


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
                count = math.clamp(count, 1, 128),
                ent = nil,
                pickedUpBy = nil
            },
            self
        )
        -- This prop will be like entity for this resource
        local pr = prop.create(pos, ang, self.Model, freeze)
        pr:setMass(30)
        pr:setUnbreakable(true)
        pr.BModResource = true
        if obj.modifyEntity then obj.modifyEntity(pr) end
        ---Collision listener to merge resources
        ---@param colData CollisionData
        pr:addCollisionListener(function(colData)
            if !isValid(obj) then return end
            local ow = pr:getOwner()
            if !isValid(ow) or obj.pickedUpBy ~= ow then return end
            local ent = colData.HitEntity
            if !ent.BModResource then return end
            ---@type Resource
            local res = resource.inited[ent:entIndex()]
            if res.Identifier ~= obj.Identifier then return end
            if res.count == 128 and obj.count == 128 then return end
            if colData.HitSpeed:getLength() < 600 then return end
            local diff = 128 - res.count
            if obj.count > diff then
                res:setCount(128)
                obj:setCount(obj.count - diff)
            else
                obj:remove()
                res:setCount(res.count + obj.count)
            end
            res.ent:emitSound(self.Sounds.Merge)
        end)
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

    ---[SERVER] Set count of resource
    ---@param count number Count
    function Resource:setCount(count)
        count = math.clamp(count, 1, 128)
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


    ---[SERVER] Is resource valid
    function Resource:isValid()
        return self ~= nil and self.ent:isValid()
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
                resource.create(self.Identifier, ent:getPos(), ent:getAngles(), newCount, false)
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
    resource.font = render.createFont("Roboto",64,500,false,false,false,false,0,false,0)

    ---[CLIENT] Init net messages
    function Resource:initNet()
        -- Init new resource
        net.receive("BModInitializeResource" .. self.Identifier, function()
            local count = net.readUInt(8)
            ---@param ent Entity
            net.readEntity(function(ent)
                ent.BModResource = true
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
                render.drawSimpleText(0, -116, self.Name, TEXT_ALIGN.CENTER)
                render.drawSimpleText(0, -48, string.format("%s units", self.count), TEXT_ALIGN.CENTER)
            end
            render.popMatrix()
            ::cont::
        end
    end)
end
resource.Resource = Resource

return resource
