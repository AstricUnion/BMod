---@include bmod/base/resource.lua
---@class resource
local resource = require("bmod/base/resource.lua")

---@class Resource
local Resource = resource.Resource

---@class Wood: Resource
local Wood = {}
Wood.__index = Wood
setmetatable(Wood, Resource)
Wood.Name = "Wood"
Wood.Identifier = "wood"
Wood.Model = "models/props_junk/wood_crate001a.mdl"
Wood.SignOffset = Vector(21, 0, 0)
Wood.Sounds = {
    Merge = "physics/wood/wood_box_break1.wav",
    Split = "physics/wood/wood_box_impact_hard4.wav",
}
resource.register(Wood)


---@class Paper: Resource
local Paper = {}
Paper.__index = Paper
setmetatable(Paper, Resource)
Paper.Name = "Paper"
Paper.Identifier = "paper"
Paper.Model = "models/props/cs_office/file_box.mdl"
Paper.SignOffset = Vector(0, 7, 1)
Paper.SignAngle = Angle(0, 90, 0)
Paper.Sounds = {
    Merge = "physics/cardboard/cardboard_box_break2.wav",
    Split = "physics/cardboard/cardboard_box_impact_hard4.wav"
}
resource.register(Paper)


---@class Water: Resource
local Water = {}
Water.__index = Water
setmetatable(Water, Resource)
Water.Name = "Water"
Water.Identifier = "water"
Water.Model = "models/props_borealis/bluebarrel002.mdl"
Water.SignOffset = Vector(14, 0, 0)
Water.Sounds = {
    Merge = "ambient/water/water_splash1.wav",
    Split = "player/footsteps/slosh1.wav"
}
resource.register(Water)


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
BasicParts.Model = "models/props_junk/cardboard_box001a.mdl"
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

if SERVER then
    resource.create("coolant", chip():getPos() + Vector(0, 50, 16), Angle(), 128, false)
    resource.create("basicParts", chip():getPos() + Vector(0, -50, 16), Angle(), 128, false)
else
    enableHud(nil, true)
end
