-- This is not fully base, because it requires running from other file with entities lib
---@name BMod Resource Base
---@author AstricUnion
---@shared

---@class ents
local ents = ents


---Class for resource manipulations
---@class resource
local resource = {}
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
---@field FuelInUnit number How many fuel this 
---@field Icon fun(x: number, y: number, w: number, h: number) Icon paint function
-- Private fields
---@field pickedUpBy Player [SERVER] Player, that's picked up this resource
local Resource = {}
Resource.Identifier = "base_resource"
Resource.Name = "Base"
Resource.Model = "models/hunter/blocks/cube05x05x05.mdl"
Resource.SignOffset = Vector(12, 0, 0)
Resource.SignAngle = Angle()
Resource.Icon = function() end
Resource.Sounds = {
    Merge = "items/ammocrate_close.wav",
    Split = "items/ammocrate_open.wav"
}
Resource.FuelInUnit = nil
Resource.hooks = {}

local maxResource = 100

if SERVER then
    function Resource:initialize()
        local pr = self.ent
        pr:setMass(30)
        pr:setUnbreakable(true)
        self.modifyEntity(pr)
        pr.BModResource = self.Identifier
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
                local res = ents.inited[ent:entIndex()]
                ---@cast res Resource
                if res.Identifier ~= self.Identifier then return end
                local count = self:getCount()
                local resCount = res:getCount()
                if resCount == maxResource and count == maxResource then return end
                local diff = maxResource - resCount
                if count > diff then
                    res:setCount(maxResource)
                    self:setCount(count - diff)
                else
                    self:remove()
                    res:setCount(resCount + count)
                end
                res.ent:emitSound(res.Sounds.Merge)
                return true
            end
            if !tryToMerge() then
                hook.run("BModResourceInteracted", self, ent)
            end
        end)
    end


    ---[SERVER] Modify resource entity
    ---@param pr Entity
    function Resource.modifyEntity(pr) end

    ---[SERVER] Set count of resource
    ---@param count number Count
    function Resource:setCount(count)
        if count < 1 then self:remove() return end
        count = math.clamp(count, 1, maxResource)
        self:setNWVar("count", count)
    end

    ---[SERVER] OnPlayerPhysicsPickup hook
    ---@param self Resource
    ---@param ply Player
    ---@param ent Entity
    function Resource.hooks.OnPlayerPhysicsPickup(self, ply, ent)
        local sprinting = ply:keyDown(IN_KEY.SPEED)
        if self.ent ~= ent then return end
        self.pickedUpBy = ply
        local count = self:getCount()
        if sprinting and count > 1 then
            local newCount = math.ceil(count / 2)
            local oldCount = count - newCount
            local pos = ent:getPos()
            local ang = ent:getAngles()
            timer.simple(0, function()
                resource.create(self.Identifier, pos, ang, newCount, false, true)
            end)
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
    resource.font = render.createFont("Roboto",32,500,false,false,false,false,0,false,0)

    function Resource:initialize()
        local pr = self.ent
        pr.BModResource = self.Identifier
    end

    ---[CLIENT] Draw info about this resource within 3D2D
    ---@param self Resource
    function Resource.hooks.PostDrawTranslucentRenderables(self)
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
            render.drawSimpleText(0, -32, self.Name, TEXT_ALIGN.CENTER)
            render.drawSimpleText(0, 0, string.format("%s units", self:getCount()), TEXT_ALIGN.CENTER)
            self.Icon(32, 32, 32, 32)
        end
        render.popMatrix()
    end
end


---[SHARED] Get count of resource
function Resource:getCount()
    return self:getNWVar("count", 0)
end

ents.register(Resource)


resource.Base = Resource


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
    class.Name = name
    class.Identifier = identifier
    class.Model = model
    class.SignOffset = signOffset
    class.SignAngle = signAngle or Angle()
    if mergeSound or splitSound then
        class.Sounds = table.copy(Resource.Sounds)
        class.Sounds.Merge = mergeSound or class.Sounds.Merge
        class.Sounds.Split = splitSound or class.Sounds.Split
    end
    ents.register(class, "base_resource")
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


---@class ResourceInfo
---@field ent Entity
---@field count number

---@class FoundResources
---@field count number
---@field ents ResourceInfo[]

---[SHARED] Get player's available resources
---@param ply Player Player to inspect
---@param withProps boolean? Take props as a resource
---@return table<string, FoundResources> resources Key is resource type, value is amount of this resource
function resource.getResources(ply, withProps)
    local found = find.byClass("prop_physics")
    local resources = {}
    local pos = ply:getPos()
    for _, pr in ipairs(found) do
        if pr:getPos():getDistance(pos) > 256 or pr:getOwner() ~= ply then goto cont end
        if pr.BModResource then
            local res = ents.inited[pr:entIndex()]
            ---@cast res Resource
            if !isValid(res) then goto cont end
            local id = res.Identifier
            local current = resources[id] or { count = 0, ents = {} }
            resources[id] = current
            local count = res:getCount()
            current.count = current.count + count
            current.ents[#current.ents+1] = {ent = pr, count = count}
        elseif withProps then
            local counts = resource.props[pr:getModel()]
            if !counts then goto cont end
            for id, count in pairs(counts) do
                local current = resources[id] or { count = 0, ents = {} }
                resources[id] = current
                current.count = current.count + count
                current.ents[#current.ents+1] = {ent = pr, count = count}
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
    ---@return Resource?
    function resource.create(identifier, pos, ang, count, freeze, dontStack)
        if !dontStack then
            local found = find.byClass("prop_physics")
            local existingResource
            for _, pr in ipairs(found) do
                if pr:getPos():getDistance(pos) > 256 then goto cont end
                if pr.BModResource ~= identifier then goto cont end
                local res = ents.inited[pr:entIndex()]
                ---@cast res Resource
                local resCount = res:getCount()
                -- This means that's we have already created entity, may be it that's we want
                if !resCount then return end
                ---@cast res Resource
                if resCount == maxResource then goto cont end
                local diff = maxResource - resCount
                if count > diff then
                    res:setCount(maxResource)
                    count = count - diff
                else
                    res:setCount(resCount + count)
                    existingResource = res
                end
                res.ent:emitSound(res.Sounds.Merge)
                ::cont::
            end
            if existingResource then return existingResource end
        end
        local newRes = ents.create(identifier)
        ---@cast newRes Resource
        newRes:setCount(count)
        newRes:spawn(pos, ang, freeze)
        return newRes
    end


    ---[SERVER] Take resources from player
    ---@param ply Player Player to take
    ---@param required table Table of required resource. Index is name, value is count
    ---@param withProps boolean? Take props from player
    ---@return string? errorMessage If nil, then there is no error
    function resource.takeResources(ply, required, withProps)
        local function takeResources(reqCount, entities)
            table.sortByMember(entities, "count")
            for _, info in ipairs(entities) do
                if reqCount <= 0 then break end
                if info.ent:getOwner() ~= ply then goto cont end
                local resType = info.ent.BModResource
                if !resType then
                    reqCount = reqCount - info.count
                    info.ent:remove()
                else
                    local foundRes = ents.inited[info.ent:entIndex()]
                    if !isValid(foundRes) then return end
                    ---@cast foundRes Resource
                    local count = foundRes:getCount()
                    local diff = count - reqCount
                    foundRes:setCount(diff)
                    reqCount = math.abs(diff)
                end
                ::cont::
            end
            return required
        end

        local res = resource.getResources(ply, withProps)
        local errorMes = ""
        for requiredId, count in pairs(required) do
            local currentClass = res[requiredId]
            local currentCount = currentClass and currentClass.count or 0
            local class = ents.registered[requiredId]
            local diff = count - currentCount
            if diff > 0 then
                errorMes = errorMes .. " " .. diff .. " more " .. string.lower(class.Name)
            end
        end
        if errorMes ~= "" then return "You need" .. errorMes end
        for requiredId, count in pairs(required) do
            local currentClass = res[requiredId]
            takeResources(count, currentClass.ents)
        end
    end
end


return resource
