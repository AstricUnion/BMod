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

local mdl = model.new("calf_right", hitbox {
    vertex {"cube", Vector(0, 0, -2), Angle(0, 0, 0), Vector(8, 8, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "calf", scale = Vector(1, 1, 1) } )

---@class CalfRight: Equippable
local CalfRight = {}
CalfRight.Identifier = "calf_right"
CalfRight.Name = "Calf Right"
CalfRight.Model = function()
    return mdl:create()
end
CalfRight.BoneToEquip = "ValveBiped.Bip01_R_Calf"
CalfRight.EquipOffset = Vector(0, 1, 0)
CalfRight.EquipAngle = Vector(0, -97, 0)
CalfRight.EquipSlots = {[EquipSlot.rightCalf] = 0.7}
CalfRight.DefenseProfile = DefenseProfile.Basic
CalfRight.MaxDurability = 300
CalfRight.hooks = {}

ents.register(CalfRight, "base_equippable")
