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

local mdl = model.new("helmet_medium", hitbox {
    vertex {"cube", Vector(0, 0, 6), Angle(0, 0, 0), Vector(5, 5, 5)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), scale = Vector(1.05, 1, 1.05), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "helmet_medium"} )

---@class HelmetMedium: Equippable
local HelmetMedium = {}
HelmetMedium.Identifier = "helmet_medium"
HelmetMedium.Name = "Helmet-Medium"
HelmetMedium.Model = function()
    return mdl:create()
end
HelmetMedium.BoneToEquip = "ValveBiped.Bip01_Head1"
HelmetMedium.EquipOffset = Vector(-2, -1, 0)
HelmetMedium.EquipAngle = Vector(0, -90, -90)
HelmetMedium.EquipSlots = {[EquipSlot.head] = 0.8}
HelmetMedium.DefenseProfile = DefenseProfile.Basic
HelmetMedium.MaxDurability = 300
HelmetMedium.hooks = {}

ents.register(HelmetMedium, "base_equippable")
