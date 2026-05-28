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

local mdl = model.new("mediumheavy_vest", hitbox {
    vertex {"cube", Vector(0, 0, 10), Angle(0, 0, 0), Vector(6, 6, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "vest_medium_heavy", scale = Vector(1.05, 1.05, 1) } )

---@class VestMediumHeavy: Equippable
local VestMediumHeavy = {}
VestMediumHeavy.Identifier = "vest_medium_heavy"
VestMediumHeavy.Name = "Vest Medium-Heavy"
VestMediumHeavy.Model = function()
    return mdl:create()
end
VestMediumHeavy.BoneToEquip = "ValveBiped.Bip01_Spine2"
VestMediumHeavy.EquipOffset = Vector(-13.5, 3, 0)
VestMediumHeavy.EquipAngle = Vector(0, 90, 90)
VestMediumHeavy.EquipSlots = {[EquipSlot.chest] = 0.8, [EquipSlot.abdomen] = 0.8}
VestMediumHeavy.DefenseProfile = DefenseProfile.Basic
VestMediumHeavy.MaxDurability = 725
VestMediumHeavy.hooks = {}

ents.register(VestMediumHeavy, "base_equippable")
