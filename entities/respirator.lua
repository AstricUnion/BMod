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
    vertex {"cube", Vector(0, 0, 2), Angle(0, 30, 0), Vector(4, 4, 3)},
    mass = 10,
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
Respirator.EquipOffset = Vector(1, -3, 0)
Respirator.EquipAngle = Vector(0, -80, -90)
Respirator.EquipSlots = {[EquipSlot.mouthAndNose] = 1}
Respirator.DefenseProfile = DefenseProfile.NonArmor
Respirator.Defense = {
    [DAMAGE.NERVEGAS] = 0.75,
    [DAMAGE.RADIATION] = 0.75
}
Respirator.MaxDurability = 2
Respirator.hooks = {}

ents.register(Respirator, "base_equippable")
