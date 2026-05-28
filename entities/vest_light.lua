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

local mdl = model.new("light_vest", hitbox {
    vertex {"cube", Vector(0, 0, 10), Angle(0, 0, 0), Vector(6, 6, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "vest_light", scale = Vector(1, 1.05, 0.9) } )

---@class VestLight: Equippable
local VestLight = {}
VestLight.Identifier = "vest_light"
VestLight.Name = "Vest Light"
VestLight.Model = function()
    return mdl:create()
end
VestLight.BoneToEquip = "ValveBiped.Bip01_Spine2"
VestLight.EquipOffset = Vector(-5.6, 3, 0)
VestLight.EquipAngle = Vector(0, 90, 90)
VestLight.EquipSlots = {[EquipSlot.chest] = 0.4, [EquipSlot.abdomen] = 0.3}
VestLight.DefenseProfile = DefenseProfile.Basic
VestLight.MaxDurability = 250
VestLight.hooks = {}

ents.register(VestLight, "base_equippable")
