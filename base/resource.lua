---@name BMod Resource Base
---@author AstricUnion
---@shared
---@include bmod/base/entity.lua

---@class ents
local ents = require("bmod/base/entity.lua")


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
-- Private fields
---@field pickedUpBy Player [SERVER] Player, that's picked up this resource
local Resource = setmetatable({}, ents.Base)
Resource.__index = Resource
Resource.Identifier = "base_resource"
Resource.Name = "Base"
Resource.Model = "models/hunter/blocks/cube05x05x05.mdl"
Resource.SignOffset = Vector(12, 0, 0)
Resource.SignAngle = Angle()
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
            timer.simple(0, function()
                resource.create(self.Identifier, ent:getPos(), ent:getAngles(), newCount, false, true)
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
    resource.font = render.createFont("Roboto",48,500,false,false,false,false,0,false,0)

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
            render.drawSimpleText(0, -48, self.Name, TEXT_ALIGN.CENTER)
            render.drawSimpleText(0, -8, string.format("%s units", self:getCount()), TEXT_ALIGN.CENTER)
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
    local class = setmetatable({}, {__index = Resource})
    class.__index = class
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
    ents.register(class)
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
            local id = res.Identifier
            local current = resources[id] or 0
            resources[id] = current + res:getCount()
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
end


---@class Wood: Resource
local Wood = resource.fastRegister(
    "Wood", "wood", "models/hunter/blocks/cube05x05x05.mdl", Vector(14, 0, 2), nil,
    "physics/wood/wood_box_break1.wav", "physics/wood/wood_box_impact_hard4.wav"
)
Wood.modifyEntity = function(ent)
    ent:setMaterial("phoenix_storms/wood")
end
Wood.FuelInUnit = 5

---@class Paper: Resource
local Paper = resource.fastRegister(
    "Paper", "paper", "models/props/cs_office/file_box.mdl", Vector(0, 7, 5), Angle(0, 90, 0),
    "physics/cardboard/cardboard_box_break2.wav", "physics/cardboard/cardboard_box_impact_hard4.wav"
)

---@class Water: Resource
local Water = resource.fastRegister(
    "Water", "water", "models/props_borealis/bluebarrel001.mdl", Vector(14, 0, 0), nil,
    "ambient/water/water_splash1.wav", "player/footsteps/slosh1.wav"
)


---@class Aluminium: Resource
local Aluminium = resource.fastRegister(
    "Aluminium", "aluminium", "models/hunter/blocks/cube025x05x025.mdl", Vector(-5, 0, 12), Angle(0, 0, -90),
    "phx/hmetal1.wav", "phx/hmetal3.wav"
)
Aluminium.modifyEntity = function(ent)
    ent:setMaterial("models/xqm/cylinderx1_diffuse")
end


---@class Steel: Resource
local Steel = resource.fastRegister(
    "Steel", "steel", "models/hunter/blocks/cube025x05x025.mdl", Vector(-5, 0, 12), Angle(0, 0, -90),
    "phx/hmetal1.wav", "phx/hmetal3.wav"
)
Steel.modifyEntity = function(ent)
    ent:setMaterial("models/xqm/cylinderx1_diffuse")
    ent:setColor(Color(100, 100, 100))
end


---@class Ceramic: Resource
local Ceramic = resource.fastRegister(
    "Ceramic", "ceramic", "models/hunter/blocks/cube05x05x05.mdl", Vector(14, 0, 2), nil,
    "physics/glass/glass_strain2.wav", "physics/glass/glass_sheet_impact_hard3.wav"
)
Ceramic.modifyEntity = function(ent)
    ent:setMaterial("models/props_building_details/courtyard_template001c_bars")
end

--[[
---@class Oil: Resource
local Oil = {}
Oil.__index = Oil
setmetatable(Oil, Resource)
Oil.Name = "Oil"
Oil.Identifier = "oil"
Oil.Model = "models/props_c17/oildrum001.mdl"
Oil.SignOffset = Vector(14, 0, 20)
Oil.Sounds = {
    Merge = "ambient/water/water_spray1.wav",
    Split = "physics/surfaces/underwater_impact_bullet1.wav"
}
resource.register(Oil)


---@class Gas: Resource
local Gas = {}
Gas.__index = Gas
setmetatable(Gas, Resource)
Gas.Name = "Gas"
Gas.Identifier = "gas"
Gas.Model = "models/props_explosive/explosive_butane_can.mdl"
Gas.SignOffset = Vector(8, 0, 5)
Gas.Sounds = {
    Merge = "physics/metal/metal_box_impact_soft1.wav",
    Split = "physics/metal/metal_box_impact_bullet2.wav"
}
resource.register(Gas)


---@class Power: Resource
local Power = {}
Power.__index = Power
setmetatable(Power, Resource)
Power.Name = "Power"
Power.Identifier = "power"
Power.Model = "models/Items/car_battery01.mdl"
Power.SignOffset = Vector(7, 0, -1)
Power.Sounds = {
    Merge = "ambient/energy/zap7.wav",
    Split = "ambient/energy/zap1.wav"
}
resource.register(Power)


---@class Fuel: Resource
local Fuel = {}
Fuel.__index = Fuel
setmetatable(Fuel, Resource)
Fuel.Name = "Fuel"
Fuel.Identifier = "fuel"
Fuel.Model = "models/props_junk/gascan001a.mdl"
Fuel.SignOffset = Vector(4, 0, -1)
Fuel.Sounds = {
    Merge = "ambient/water/water_spray1.wav",
    Split = "physics/surfaces/underwater_impact_bullet1.wav"
}
resource.register(Fuel)


---@class Plastic: Resource
local Plastic = {}
Plastic.__index = Plastic
setmetatable(Plastic, Resource)
Plastic.Name = "Plastic"
Plastic.Identifier = "plastic"
Plastic.Model = "models/hunter/blocks/cube05x05x05.mdl"
Plastic.SignOffset = Vector(14, 0, 2)
Plastic.Sounds = {
    Merge = "physics/plastic/plastic_barrel_break1.wav",
    Split = "physics/plastic/plastic_box_impact_hard4.wav"
}
resource.register(Plastic)



---@class Rubber: Resource
local Rubber = {}
Rubber.__index = Rubber
setmetatable(Rubber, Resource)
Rubber.Name = "Rubber"
Rubber.Identifier = "rubber"
Rubber.Model = "models/props_vehicles/apc_tire001.mdl"
Rubber.SignOffset = Vector(10, 0, 1)
Rubber.Sounds = {
    Merge = "physics/body/body_medium_impact_soft1.wav",
    Split = "physics/body/body_medium_impact_soft2.wav"
}
resource.register(Rubber)


---@class Glass: Resource
local Glass = {}
Glass.__index = Glass
setmetatable(Glass, Resource)
Glass.Name = "Glass"
Glass.Identifier = "glass"
Glass.Model = "models/hunter/blocks/cube05x05x05.mdl"
Glass.modifyEntity = function(ent)
    ent:setMaterial("models/debug/debugwhite")
    ent:setColor(Color(100, 100, 100, 100))
end
Glass.SignOffset = Vector(14, 0, 2)
Glass.Sounds = {
    Merge = "physics/glass/glass_strain2.wav",
    Split = "physics/glass/glass_sheet_impact_hard3.wav"
}
resource.register(Glass)


---@class Sand: Resource
local Sand = {}
Sand.__index = Sand
setmetatable(Sand, Resource)
Sand.Name = "Sand"
Sand.Identifier = "sand"
Sand.Model = "models/props_trenches/sandbag01.mdl"
Sand.SignOffset = Vector(0, 8, 2)
Sand.SignAngle = Angle(0, 90, 0)
Sand.Sounds = {
    Merge = "physics/surfaces/sand_impact_bullet4.wav",
    Split = "player/footsteps/sand4.wav"
}
resource.register(Sand)


---@class Cloth: Resource
local Cloth = {}
Cloth.__index = Cloth
setmetatable(Cloth, Resource)
Cloth.Name = "Cloth"
Cloth.Identifier = "cloth"
Cloth.Model = "models/props/cs_office/Paper_towels.mdl"
Cloth.SignOffset = Vector(0, 8, 2)
Cloth.SignAngle = Angle(0, 90, 0)
Cloth.Sounds = {
    Merge = "physics/surfaces/sand_impact_bullet4.wav",
    Split = "player/footsteps/sand4.wav"
}
resource.register(Cloth)


---@class Ceramic: Resource
local Ceramic = {}
Ceramic.__index = Ceramic
setmetatable(Ceramic, Resource)
Ceramic.Name = "Ceramic"
Ceramic.Identifier = "ceramic"
Ceramic.Model = "models/hunter/blocks/cube05x05x05.mdl"
Ceramic.modifyEntity = function(ent)
    ent:setMaterial("models/props_building_details/courtyard_template001c_bars")
end
Ceramic.SignOffset = Vector(14, 0, 2)
Ceramic.Sounds = {
    Merge = "physics/glass/glass_strain2.wav",
    Split = "physics/glass/glass_sheet_impact_hard3.wav"
}
resource.register(Ceramic)


---@class BasicParts: Resource
local BasicParts = {}
BasicParts.__index = BasicParts
setmetatable(BasicParts, Resource)
BasicParts.Name = "Basic parts"
BasicParts.Identifier = "basicParts"
BasicParts.Model = "models/Items/item_item_crate.mdl"
BasicParts.SignOffset = Vector(17, 0, 2)
BasicParts.Sounds = {
    Merge = "physics/wood/wood_box_break1.wav",
    Split = "physics/wood/wood_box_impact_hard4.wav",
}
resource.register(BasicParts)


---@class Coolant: Resource
local Coolant = {}
Coolant.__index = Coolant
setmetatable(Coolant, Resource)
Coolant.Name = "Coolant"
Coolant.Identifier = "coolant"
Coolant.Model = "models/props_junk/metalgascan.mdl"
Coolant.modifyEntity = function(ent)
    ent:setColor(Color(150, 150, 255))
end
Coolant.SignOffset = Vector(4, 0, 0)
Coolant.Sounds = {
    Merge = "ambient/water/water_spray1.wav",
    Split = "physics/surfaces/underwater_impact_bullet1.wav"
}
resource.register(Coolant)


---@class Ammo: Resource
local Ammo = {}
Ammo.__index = Ammo
setmetatable(Ammo, Resource)
Ammo.Name = "Ammo"
Ammo.Identifier = "ammo"
Ammo.Model = "models/Items/BoxSRounds.mdl"
Ammo.SignOffset = Vector(4, 0, 0)
Ammo.Sounds = {
    Merge = "BaseCombatCharacter.AmmoPickup",
    Split = "player/pl_shell1.wav"
}
resource.register(Ammo)
]]--


-- Props to resources --
resource.addProp({
    "models/props_junk/wood_crate001a.mdl",
    "models/props_junk/wood_crate001a_damaged.mdl"
}, { wood = 23 })

resource.addProp({
    "models/props_docks/channelmarker_gib01.mdl",
    "models/props_c17/furnituredrawer001a_shard01.mdl"
}, { wood = 21 })

resource.addProp({
    "models/props_c17/furnituredrawer001a_chunk01.mdl",
    "models/props_c17/furnituredrawer001a_chunk02.mdl",
    "models/props_c17/furnituredrawer001a_chunk03.mdl",
    "models/props_c17/furnituredrawer002a.mdl",
    "models/gibs/wood_gib01a.mdl",
    "models/gibs/wood_gib01b.mdl",
    "models/gibs/wood_gib01c.mdl",
    "models/gibs/wood_gib01d.mdl",
    "models/gibs/wood_gib01e.mdl",
}, { wood = 11 })


resource.addProp({
    "models/props_c17/streetsign001c.mdl",
    "models/props_c17/streetsign002b.mdl",
    "models/props_c17/streetsign003b.mdl",
    "models/props_c17/streetsign004f.mdl",
    "models/props_c17/streetsign005b.mdl",
    "models/props_c17/streetsign005c.mdl",
    "models/props_c17/streetsign005d.mdl"
}, { aluminium = 8, steel = 6 })

resource.addProp({
    "models/props_junk/popcan01a.mdl"
}, { aluminium = 2 })

resource.addProp({
    "models/props_junk/terracotta01.mdl"
}, { ceramic = 2 })

resource.addProp({
    "models/props_c17/lamp001a.mdl"
}, { ceramic = 6 })


if CLIENT then
    local function enablehud()
        if owner() ~= player() then return end
        enableHud(owner(), true)
    end
    enablehud()
end

return resource
