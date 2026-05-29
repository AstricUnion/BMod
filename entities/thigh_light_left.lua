---@class ents
local ents = ents

---@class equipment
local equipment = equipment
local EquipSlot = equipment.EquipSlot
local DefenseProfile = equipment.DefenseProfile

---@class model
local model = model
local hitbox = model.hitbox
local vertex = model.vertex
local holo = model.holo

local mdl = model.new("thigh_light_left", hitbox {
    vertex {"cube", Vector(0, 0, -2), Angle(0, 0, 0), Vector(8, 8, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "thigh_light", scale = Vector(1, 1, 1) } )

---@class ThighLightLeft: Equippable
local ThighLightLeft = {}
ThighLightLeft.Identifier = "thigh_light_left"
ThighLightLeft.Name = "Thigh Light Left"
ThighLightLeft.Model = function()
    return mdl:create()
end
ThighLightLeft.BoneToEquip = "ValveBiped.Bip01_L_Thigh"
ThighLightLeft.EquipOffset = Vector(0.9, 0, 0)
ThighLightLeft.EquipAngle = Vector(0, -90, 0)
ThighLightLeft.EquipSlots = {[EquipSlot.leftThigh] = 0.5}
ThighLightLeft.DefenseProfile = DefenseProfile.Basic
ThighLightLeft.MaxDurability = 200
ThighLightLeft.hooks = {}

ents.register(ThighLightLeft, "base_equippable")
