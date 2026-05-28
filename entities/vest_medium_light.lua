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

local mdl = model.new("mediumlight_vest", hitbox {
    vertex {"cube", Vector(0, 0, 10), Angle(0, 0, 0), Vector(6, 6, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "vest_medium_light", scale = Vector(1.05, 1.05, 0.95) } )

---@class VestMediumLight: Equippable
local VestMediumLight = {}
VestMediumLight.Identifier = "vest_medium_light"
VestMediumLight.Name = "Vest Medium-Light"
VestMediumLight.Model = function()
    return mdl:create()
end
VestMediumLight.BoneToEquip = "ValveBiped.Bip01_Spine2"
VestMediumLight.EquipOffset = Vector(-7, 3, 0)
VestMediumLight.EquipAngle = Vector(0, 90, 90)
VestMediumLight.EquipSlots = {[EquipSlot.chest] = 0.6, [EquipSlot.abdomen] = 0.4}
VestMediumLight.DefenseProfile = DefenseProfile.Basic
VestMediumLight.MaxDurability = 450
VestMediumLight.hooks = {}

ents.register(VestMediumLight, "base_equippable")
