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

local mdl = model.create(hitbox {
    vertex {"cube", Vector(0, 0, 10), Angle(0, 0, 0), Vector(6, 6, 10)},
    mass = 30
})
mdl:add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "respirator"} )

---@class Respirator: Equippable
local Respirator = {}
Respirator.Identifier = "respirator"
Respirator.Name = "Respirator"
Respirator.Model = function()
    return mdl:create()
end
Respirator.BoneToEquip = "ValveBiped.Bip01_Head1"
Respirator.EquipOffset = Vector(-7, 3.5, 0)
Respirator.EquipAngle = Vector(0, 88, 90)
Respirator.EquipSlots = {[EquipSlot.chest] = 1, [EquipSlot.abdomen] = 1}
Respirator.DefenseProfile = DefenseProfile.Basic
Respirator.MaxDurability = 120
Respirator.hooks = {}

ents.register(Respirator, "base_equippable")
