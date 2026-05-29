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

local mdl = model.new("shoulder_light_left", hitbox {
    vertex {"cube", Vector(0, 0, -2), Angle(0, 0, 0), Vector(8, 8, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "shoulder_light", scale = Vector(1, 1, 1) } )

---@class ShoulderLightLeft: Equippable
local ShoulderLightLeft = {}
ShoulderLightLeft.Identifier = "shoulder_light_left"
ShoulderLightLeft.Name = "Shoulder Light Left"
ShoulderLightLeft.Model = function()
    return mdl:create()
end
ShoulderLightLeft.BoneToEquip = "ValveBiped.Bip01_L_Upperarm"
ShoulderLightLeft.EquipOffset = Vector(0, 0, -0.5)
ShoulderLightLeft.EquipAngle = Vector(0, -90, 0)
ShoulderLightLeft.EquipSlots = {[EquipSlot.leftShoulder] = 0.5}
ShoulderLightLeft.DefenseProfile = DefenseProfile.Basic
ShoulderLightLeft.MaxDurability = 200
ShoulderLightLeft.hooks = {}

ents.register(ShoulderLightLeft, "base_equippable")
