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

local mdl = model.new("shoulder_light_right", hitbox {
    vertex {"cube", Vector(0, 0, -2), Angle(0, 0, 0), Vector(8, 8, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "shoulder_light", scale = Vector(1, -1, -1) } )

---@class ShoulderLightRight: Equippable
local ShoulderLightRight = {}
ShoulderLightRight.Identifier = "shoulder_light_right"
ShoulderLightRight.Name = "Shoulder Light Right"
ShoulderLightRight.Model = function()
    return mdl:create()
end
ShoulderLightRight.BoneToEquip = "ValveBiped.Bip01_R_Upperarm"
ShoulderLightRight.EquipOffset = Vector(0, 0, 0.5)
ShoulderLightRight.EquipAngle = Vector(180, 90, 0)
ShoulderLightRight.EquipSlots = {[EquipSlot.rightShoulder] = 0.5}
ShoulderLightRight.DefenseProfile = DefenseProfile.Basic
ShoulderLightRight.MaxDurability = 200
ShoulderLightRight.hooks = {}

ents.register(ShoulderLightRight, "base_equippable")
