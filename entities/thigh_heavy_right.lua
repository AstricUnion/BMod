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

local mdl = model.new("thigh_heavy_right", hitbox {
    vertex {"cube", Vector(0, 0, -2), Angle(0, 0, 0), Vector(8, 8, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "thigh_heavy", scale = Vector(1, -1, 1), cullmode = 1 } )

---@class ThighHeavyRight: Equippable
local ThighHeavyRight = {}
ThighHeavyRight.Identifier = "thigh_heavy_right"
ThighHeavyRight.Name = "Thigh Heavy Right"
ThighHeavyRight.Model = function()
    return mdl:create()
end
ThighHeavyRight.BoneToEquip = "ValveBiped.Bip01_R_Thigh"
ThighHeavyRight.EquipOffset = Vector(10, -1.5, 0)
ThighHeavyRight.EquipAngle = Vector(-90, 0, 0)
ThighHeavyRight.EquipSlots = {[EquipSlot.rightThigh] = 0.8}
ThighHeavyRight.DefenseProfile = DefenseProfile.Basic
ThighHeavyRight.MaxDurability = 250
ThighHeavyRight.hooks = {}
ents.register(ThighHeavyRight, "base_equippable")
