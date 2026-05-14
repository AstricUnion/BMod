---@class ents
local ents = ents

---@class equipment
local equipment = equipment
local EquipSlot = equipment.EquipSlot
local DefenseProfile = equipment.DefenseProfile

---@class VestMedium: Equippable
---@field toScan Deposit[]
---@field nextEffect number Next effect. Relative to curtime
---@field nextDecal number Next decal. Relative to curtime
---@field effect BEffect
---@field drill Entity
local VestMedium = {}
VestMedium.Identifier = "vest_medium"
VestMedium.Name = "Vest Medium"
VestMedium.Model = "models/player/armor_gjel/gjel.mdl" -- used from original jmod, just to test
VestMedium.BoneToEquip = "ValveBiped.Bip01_Spine2"
VestMedium.EquipOffset = Vector(-7, 3, 0)
VestMedium.EquipAngle = Vector(0, 88, 90)
VestMedium.EquipSlots = {[EquipSlot.chest] = 1, [EquipSlot.abdomen] = 1}
VestMedium.DefenseProfile = DefenseProfile.Basic
VestMedium.MaxDurability = 120
VestMedium.hooks = {}

ents.register(VestMedium, "base_equippable")
