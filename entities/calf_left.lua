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

local mdl = model.new("calf_left", hitbox {
    vertex {"cube", Vector(0, 0, -2), Angle(0, 0, 0), Vector(8, 8, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "calf", scale = Vector(1, 1, 1) } )

---@class CalfLeft: Equippable
local CalfLeft = {}
CalfLeft.Identifier = "calf_left"
CalfLeft.Name = "Calf Left"
CalfLeft.Model = function()
    return mdl:create()
end
CalfLeft.BoneToEquip = "ValveBiped.Bip01_L_Calf"
CalfLeft.EquipOffset = Vector(0, 1, 0)
CalfLeft.EquipAngle = Vector(180, 83, 180)
CalfLeft.EquipSlots = {[EquipSlot.leftCalf] = 0.7}
CalfLeft.DefenseProfile = DefenseProfile.Basic
CalfLeft.MaxDurability = 300
CalfLeft.hooks = {}

ents.register(CalfLeft, "base_equippable")
