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

local mdl = model.new("forearm_left", hitbox {
    vertex {"cube", Vector(0, 0, -2), Angle(0, 0, 0), Vector(8, 8, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "forearm", scale = Vector(1.1, 1, 1) } )

---@class ForearmLeft: Equippable
local ForearmLeft = {}
ForearmLeft.Identifier = "forearm_left"
ForearmLeft.Name = "Forearm Left"
ForearmLeft.Model = function()
    return mdl:create()
end
ForearmLeft.BoneToEquip = "ValveBiped.Bip01_L_Forearm"
ForearmLeft.EquipOffset = Vector(0.5, 0, -1)
ForearmLeft.EquipAngle = Vector(-85, 180, 90)
ForearmLeft.EquipSlots = {[EquipSlot.leftForearm] = 0.7}
ForearmLeft.DefenseProfile = DefenseProfile.Basic
ForearmLeft.MaxDurability = 250
ForearmLeft.hooks = {}

ents.register(ForearmLeft, "base_equippable")
