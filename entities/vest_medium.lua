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
local part = model.part
local holo = model.holo
local rig = model.rig

local mdl = model.create(hitbox {
    vertex {"cube", Vector(0, 0, 10), Angle(0, 0, 0), Vector(6, 6, 10)},
    mass = 30
})
mdl:add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "medium_vest"} )

---@class VestMedium: Equippable
local VestMedium = {}
VestMedium.Identifier = "vest_medium"
VestMedium.Name = "Vest Medium"
VestMedium.Model = function()
    return mdl:create()
end
VestMedium.BoneToEquip = "ValveBiped.Bip01_Spine2"
VestMedium.EquipOffset = Vector(-7, 3.5, 0)
VestMedium.EquipAngle = Vector(0, 88, 90)
VestMedium.EquipSlots = {[EquipSlot.chest] = 1, [EquipSlot.abdomen] = 1}
VestMedium.DefenseProfile = DefenseProfile.Basic
VestMedium.MaxDurability = 120
VestMedium.hooks = {}

ents.register(VestMedium, "base_equippable")
