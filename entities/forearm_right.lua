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

local mdl = model.new("forearm_right", hitbox {
    vertex {"cube", Vector(0, 0, -2), Angle(0, 0, 0), Vector(8, 8, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "forearm", scale = Vector(1.1, -1, -1) } )

---@class ForearmRight: Equippable
local ForearmRight = {}
ForearmRight.Identifier = "forearm_right"
ForearmRight.Name = "Forearm Right"
ForearmRight.Model = function()
    return mdl:create()
end
ForearmRight.BoneToEquip = "ValveBiped.Bip01_R_Forearm"
ForearmRight.EquipOffset = Vector(0.5, 0, 0)
ForearmRight.EquipAngle = Vector(85, 0, -90)
ForearmRight.EquipSlots = {[EquipSlot.rightForearm] = 0.7}
ForearmRight.DefenseProfile = DefenseProfile.Basic
ForearmRight.MaxDurability = 250
ForearmRight.hooks = {}

ents.register(ForearmRight, "base_equippable")
