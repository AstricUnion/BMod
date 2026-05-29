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

local mdl = model.new("heavy_vest", hitbox {
    vertex {"cube", Vector(0, 0, -2), Angle(0, 0, 0), Vector(8, 8, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "heavy_vest", scale = Vector(0.9, 0.9, 1) } )

---@class VestHeavy: Equippable
local VestHeavy = {}
VestHeavy.Identifier = "vest_heavy"
VestHeavy.Name = "Vest Heavy"
VestHeavy.Model = function()
    return mdl:create()
end
VestHeavy.BoneToEquip = "ValveBiped.Bip01_Spine2"
VestHeavy.EquipOffset = Vector(4.5, 3, 0)
VestHeavy.EquipAngle = Vector(0, 85, 90)
VestHeavy.EquipSlots = {[EquipSlot.chest] = 1, [EquipSlot.abdomen] = 0.9}
VestHeavy.DefenseProfile = DefenseProfile.Basic
VestHeavy.MaxDurability = 900
VestHeavy.hooks = {}

ents.register(VestHeavy, "base_equippable")
