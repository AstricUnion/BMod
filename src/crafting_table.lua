---@name Crafting table
---@author AstricUnion
---@shared

---@class ents
local ents = ents

---@class resource
local resource = resource

---Lib from AstricUnion (TODO: remade it)
---@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/holos.lua as holos
local holos = require("holos")
---@class Holo
local Holo = holos.Holo
local Rig = holos.Rig
local SubHolo = holos.SubHolo
---@class Trail
local Trail = holos.Trail
---@class Clip
local Clip = holos.Clip

local function getCube(offset, size)
    return {
        offset + Vector(-size.x, -size.y, -size.z), offset + Vector(size.x, -size.y, -size.z),
        offset + Vector(size.x, size.y, -size.z), offset + Vector(-size.x, size.y, -size.z),
        offset + Vector(-size.x, -size.y, size.z), offset + Vector(size.x, -size.y, size.z),
        offset + Vector(size.x, size.y, size.z), offset + Vector(-size.x, size.y, size.z),
    }
end


local function model()
    local base = {
        model = hologram.createPart(
            Holo(Rig()),
            Holo(SubHolo(Vector(0, 0, 18), Angle(), "models/props_c17/furnituretable002a.mdl", Vector(1.2, 1.2, 1))),
            Holo(SubHolo(Vector(-12, 0, 42), Angle(), "models/props_wasteland/cafeteria_table001a.mdl", Vector(0.4, 0.6, 0.5))),
            Holo(SubHolo(Vector(0, -50, 10), Angle(), "models/props_wasteland/laundry_basket002.mdl", Vector(0.4, 0.4, 0.5)))
        ),
    }
    base.model:setPos(Vector())
    base.hitbox = prop.createCustom(Vector(), Angle(), {
        getCube(Vector(0, 0, 18), Vector(24, 36, 18)),
        getCube(Vector(-12, 0, 43), Vector(8, 36, 7)),
        getCube(Vector(0, -50, 10), Vector(10, 10, 10))
    }, true)
    base.hitbox:setMass(72)
    base.hitbox:setNoDraw(true)
    base.model:setParent(base.hitbox)
    return base.hitbox
end



---@class CraftingTable: BModEntity
---@field inProcess Entity?
local CraftingTable = setmetatable({}, {__index = ents.Base})
CraftingTable.__index = CraftingTable
CraftingTable.Identifier = "crafting_table"
CraftingTable.Name = "Crafting table"
CraftingTable.Model = function()
    return model()
end
CraftingTable.hooks = {}



---Create new crafting table
if SERVER then
    function CraftingTable:initialize()
        local pr = self.ent
        ---@param colData CollisionData
        pr:addCollisionListener(function(colData)
            if colData.HitSpeed:getLength() < 500 then return end
            if pr:worldToLocal(colData.HitPos).y > -28 then return end
            local ent = colData.HitEntity
            if !isValid(ent) or ent:getClass() ~= "prop_physics" then return end
            if !ent.BModEntity then
                local res = resource.props[ent:getModel()]
                if !res then return end
                local pos = ent:getPos()
                ent:remove()
                local angs = pr:getAngles()
                net.start("BModCreateSmoke")
                    net.writeString("pereplavka")
                    net.writeFloat(0.2)
                    net.writeUInt(8, 8)
                    net.writeVector(Vector(0, -44, 0))
                    net.writeEntity(pr)
                net.send(find.allPlayers())
                timer.simple(1, function()
                    for id, count in pairs(res) do
                        resource.create(id, pos, angs, count, false)
                    end
                end)
            elseif ent.BModResource then
                local fuelInUnit = ents.registered[ent.BModResource].FuelInUnit
                if !fuelInUnit then return end
                local res = ents.inited[ent:entIndex()]
                ---@cast res Resource
                if !isValid(res) or !isValid(res.pickedUpBy) then return end
                local count = res:getCount()
                local fuel = self:getFuel()
                local fuelDiff = 100 - fuel
                if fuelDiff <= 0 then return end
                local units = math.min(fuelDiff / fuelInUnit, count)
                res:setCount(count - units)
                self:setFuel(fuel + units * fuelInUnit)
            end
        end)
    end


    ---[SERVER] Set fuel for table
    ---@param fuel number Fuel
    function CraftingTable:setFuel(fuel)
        if fuel < 1 then self:remove() end
        fuel = math.clamp(fuel, 0, 100)
        self:setNWVar("fuel", fuel)
    end
end

if CLIENT then
    ---@type table<string, ParticleEmitter> 
    local EMMITERS = {}

    local mats = {
        material.load("particle/particle_smokegrenade1"),
        material.load("particle/particle_smokegrenade"),
        material.load("particle/particle_smoke_dust")
    }
    net.receive("BModCreateSmoke", function()
        -- Time and ID to create particles
        local id = net.readString()
        local time = net.readFloat()
        local repeations = net.readUInt(8)
        local offset = net.readVector()
        net.readEntity(function(ent)
            local emm = EMMITERS[id]
            if emm then emm:destroy() end
            emm = particle.create(Vector(), false)
            EMMITERS[id] = emm
            local repeation = 0
            timer.create(id, time, repeations, function()
                local pos = ent:localToWorld(offset)
                emm:setPos(pos)
                local size = math.random() * 20
                local part = emm:add(mats[math.random(1, 3)], pos - Vector(math.random() * 5, math.random() * 5, 10), 8, 64 + size, 8, 64 + size, 200, 0, 2)
                part:setVelocity(Vector(0, 0, 60))
                if repeations ~= 0 then repeation = repeation + 1 end
                if repeation == repeations then
                    emm:destroy()
                    EMMITERS[id] = nil
                end
            end)
        end)
    end)


    local Ply = player()
    local font = render.createFont("Roboto",32,500,false,false,false,false,0,false,0)

    ---[CLIENT] Draw info about this resource within 3D2D
    ---@param self CraftingTable
    function CraftingTable.hooks.PostDrawTranslucentRenderables(self)
        local pos = Ply:getPos()
        if !isValid(self.ent) then return end
        if self.ent:getPos():getDistance(pos) > 256 then return end
        local ang = self.ent:getAngles()
        local m = Matrix(ang, self.ent:localToWorld(Vector(10.5, -50, 18)))
        m:rotate(Angle(0, 90, 90))
        m:setScale(Vector(0.1, -0.1, 1))
        render.pushMatrix(m)
        do
            render.enableDepth(true)
            render.setFont(font)
            render.drawSimpleText(0, -8, string.format("Fuel: %s", self:getFuel()), TEXT_ALIGN.CENTER)
        end
        render.popMatrix()
    end
end

---[SHARED] Get fuel
function CraftingTable:getFuel()
    return self:getNWVar("fuel", 0)
end

ents.register(CraftingTable)

