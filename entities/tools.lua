
---@class ents
local ents = ents

---@class resource
local resource = resource

if CLIENT then
    ---@class bicons
    local bicons = bicons
    bicons.registerModel("bucket", "models/props_junk/MetalBucket01a.mdl", Vector(-27, 0, 9), Angle(20, 0, 5))
end



---@class Bucket: BModEntity
local Bucket = {}
Bucket.Identifier = "bucket"
Bucket.Name = "Bucket"
Bucket.Model = "models/props_junk/MetalBucket01a.mdl"
Bucket.hooks = {}

if SERVER then
    function Bucket:initialize()
        constraint.keepupright(self.ent, Angle(), 0, 5000)
        self:setNWVar("water", 0)
    end

    function Bucket.hooks.OnEntityWaterLevelChanged(self, ent, _, new)
        if ent ~= self.ent then return end
        if new == 3 and self:getNWVar("water") ~= 50 then
            self:setNWVar("water", 50)
        end
    end

    function Bucket.hooks.OnPlayerPhysicsPickup(self, ply, ent)
        local sprinting = ply:keyDown(IN_KEY.SPEED)
        if self.ent ~= ent then return end
        self.pickedUpBy = ply
        local count = self:getNWVar("water", 0)
        if sprinting and count > 0 then
            local pos = self.ent:getPos()
            local ang = self.ent:getAngles()
            timer.simple(0, function()
                if !isValid(self) then return end
                local res = resource.create("water", pos + Vector(0, 0, 21), ang, count, false, true)
                if res then
                    self:setNWVar("water", 0)
                end
            end)
        end
    end
else
    ---@param self Bucket
    function Bucket.hooks.PostDrawTranslucentRenderables(self)
        BMod.Display(self.ent, Vector(8.8, 0, 0), Angle(), function()
            render.drawSimpleText(0, -75, string.format("Water: %s", self:getNWVar("water", 0)), TEXT_ALIGN.CENTER)
            bicons.get("water")(-43, -43, 86, 86)
        end)
    end
end


ents.register(Bucket)

