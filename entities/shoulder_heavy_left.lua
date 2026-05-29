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

local mdl = model.new("shoulder_heavy_left", hitbox {
    vertex {"cube", Vector(0, 0, -2), Angle(0, 0, 0), Vector(8, 8, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "shoulder_heavy", scale = Vector(1, 1, 1) } )

---@class ShoulderHeavyLeft: Equippable
local ShoulderHeavyLeft = {}
ShoulderHeavyLeft.Identifier = "shoulder_heavy_left"
ShoulderHeavyLeft.Name = "Shoulder Heavy Left"
ShoulderHeavyLeft.Model = function()
    return mdl:create()
end
ShoulderHeavyLeft.BoneToEquip = "ValveBiped.Bip01_L_Upperarm"
ShoulderHeavyLeft.EquipOffset = Vector(4, 0, 0)
ShoulderHeavyLeft.EquipAngle = Vector(0, -110, 70)
ShoulderHeavyLeft.EquipSlots = {[EquipSlot.leftShoulder] = 0.8}
ShoulderHeavyLeft.DefenseProfile = DefenseProfile.Basic
ShoulderHeavyLeft.MaxDurability = 300
ShoulderHeavyLeft.hooks = {}

ents.register(ShoulderHeavyLeft, "base_equippable")
