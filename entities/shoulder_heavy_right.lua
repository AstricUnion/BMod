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

local mdl = model.new("shoulder_heavy_right", hitbox {
    vertex {"cube", Vector(0, 0, -2), Angle(0, 0, 0), Vector(8, 8, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "shoulder_heavy", scale = Vector(1, -1, 1), cullmode = 1 })

---@class ShoulderHeavyRight: Equippable
local ShoulderHeavyRight = {}
ShoulderHeavyRight.Identifier = "shoulder_heavy_right"
ShoulderHeavyRight.Name = "Shoulder Heavy Right"
ShoulderHeavyRight.Model = function()
    return mdl:create()
end
ShoulderHeavyRight.BoneToEquip = "ValveBiped.Bip01_R_Upperarm"
ShoulderHeavyRight.EquipOffset = Vector(4, 0, 0)
ShoulderHeavyRight.EquipAngle = Vector(0, -110, 110)
ShoulderHeavyRight.EquipSlots = {[EquipSlot.rightShoulder] = 0.8}
ShoulderHeavyRight.DefenseProfile = DefenseProfile.Basic
ShoulderHeavyRight.MaxDurability = 300
ShoulderHeavyRight.hooks = {}

ents.register(ShoulderHeavyRight, "base_equippable")
