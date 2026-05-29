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

local mdl = model.new("thigh_heavy_left", hitbox {
    vertex {"cube", Vector(0, 0, -2), Angle(0, 0, 0), Vector(8, 8, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "thigh_heavy", scale = Vector(1, -1, -1) } )

---@class ThighHeavyLeft: Equippable
local ThighHeavyLeft = {}
ThighHeavyLeft.Identifier = "thigh_heavy_left"
ThighHeavyLeft.Name = "Thigh Heavy Left"
ThighHeavyLeft.Model = function()
    return mdl:create()
end
ThighHeavyLeft.BoneToEquip = "ValveBiped.Bip01_L_Thigh"
ThighHeavyLeft.EquipOffset = Vector(10, -1.5, 0)
ThighHeavyLeft.EquipAngle = Vector(-90, 0, 0)
ThighHeavyLeft.EquipSlots = {[EquipSlot.leftThigh] = 0.8}
ThighHeavyLeft.DefenseProfile = DefenseProfile.Basic
ThighHeavyLeft.MaxDurability = 250
ThighHeavyLeft.hooks = {}
ents.register(ThighHeavyLeft, "base_equippable")
