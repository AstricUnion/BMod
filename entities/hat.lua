---@class ents
local ents = ents

---@class equipment
local equipment = equipment
local EquipSlot = equipment.EquipSlot
local DefenseProfile = equipment.DefenseProfile

---@class Hat: Equippable
---@field toScan Deposit[]
---@field nextEffect number Next effect. Relative to curtime
---@field nextDecal number Next decal. Relative to curtime
---@field effect BEffect
---@field drill Entity
local Hat = {}
Hat.Identifier = "hat"
Hat.Name = "Hat"
Hat.Model = "models/player/items/humans/top_hat.mdl"
Hat.EquippedModel = "models/player/items/humans/top_hat.mdl"
Hat.BoneToEquip = "ValveBiped.Bip01_Head1"
Hat.EquipOffset = Vector(0, -1, 0)
Hat.EquipAngle = Vector(0, 110, 90)
Hat.EquipSlots = {[EquipSlot.head] = 0.6}
Hat.DefenseProfile = DefenseProfile.Poor
Hat.hooks = {}

ents.register(Hat, "base_equippable")
