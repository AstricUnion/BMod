
---@class ents
local ents = ents

---@class resource
local resource = resource

---@class ResourceCrate: BModEntity
local ResourceCrate = {}
ResourceCrate.Identifier = "resource_crate"
ResourceCrate.Name = "Resource Crate"
ResourceCrate.Model = "models/props_junk/wood_crate002a.mdl"
ResourceCrate.hooks = {}



if SERVER then
    function ResourceCrate:initialize()
        self.ent:setMass(100)
        self.ent:setUnbreakable(true)
    end

    ---[SERVER] Interaction of resource
    ---@param self ResourceCrate
    ---@param res Resource
    ---@param ent Entity
    function ResourceCrate.hooks.BModResourceInteracted(self, res, ent)
        if ent ~= self.ent then return end
        local type = self:getResourceType()
        if !type then
            self:setResourceType(res.Identifier)
            self:setResourceCount(res:getCount())
            res:remove()
        elseif type == res.Identifier then
            local canPut = 2000 - self:getResourceCount()
            local actual = res:take(canPut)
            self:setResourceCount(self:getResourceCount() + actual)
        end
    end

    ---[SERVER] Get resource from crate
    ---@param ply Player
    ---@param key number
    function ResourceCrate.hooks.KeyPress(self, ply, key)
        if key ~= IN_KEY.USE then return end
        local type = self:getResourceType()
        if !type then return end
        local count = self:getResourceCount()
        local tr = ply:getEyeTrace()
        ---@cast tr TraceResult
        if tr.Entity ~= self.ent then return end
        if ply:getShootPos():getDistance(tr.HitPos) > 96 then return end
        local toGet = math.min(count, 100)
        local angs = ply:getEyeAngles()
        angs = angs:rotateAroundAxis(angs:getUp(), 180)
        local res = resource.create(type, tr.HitPos, angs, toGet, false, true)
        self:setResourceCount(count - toGet)
        if next(res) ~= nil then
            local resEnt = res[1]
            timer.simple(0, function()
                if !isValid(resEnt) then return end
                resEnt.ent:use()
            end)
        end
    end

    ---[SERVER] Set resource type of this crate
    ---@param type string? Type of resource or nil, to clear
    function ResourceCrate:setResourceType(type)
        self:setNWVar("type", type)
    end

    ---[SERVER] Set resource count
    ---@param count number Count
    function ResourceCrate:setResourceCount(count)
        self.ent:setMass(100 + math.ceil(count / 100) * 15)
        self:setNWVar("count", count)
        if count < 1 then self:setResourceType(nil) end
    end
end

if CLIENT then
    ---@class bgui
    local bgui = bgui

    local font = render.createFont("Roboto",64,500,false,false,false,false,0,false,0)

    ---[CLIENT] Draw info about this resource within 3D2D
    ---@param self ResourceCrate
    function ResourceCrate.hooks.PostDrawTranslucentRenderables(self)
        BMod.Display(self.ent, Vector(20, 0, 0), Angle(), function()
            render.setFont(font)
            local type = self:getResourceType()
            local res = ents.registered[type]
            local name = res and res.Name or "Put resource"
            render.drawSimpleText(0, 0, name, TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
            render.setFont("Trebuchet24")
            render.drawSimpleText(0, 44, string.format("%s units", self:getResourceCount()), TEXT_ALIGN.CENTER, TEXT_ALIGN.TOP)
        end)
    end
end

---[SHARED] Get resource type of this crate
---@return string? type Type of resource
function ResourceCrate:getResourceType()
    return self:getNWVar("type", nil)
end

---[SERVER] Get resource count
---@return number count Count
function ResourceCrate:getResourceCount()
    return self:getNWVar("count", 0)
end


ents.register(ResourceCrate)

