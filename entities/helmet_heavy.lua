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

local mdl = model.new("helmet_heavy", hitbox {
    vertex {"cube", Vector(0, 0, 6), Angle(0, 0, 0), Vector(5, 5, 5)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "helmet_heavy", scale = Vector(1.1, 1, 1.1)} )

---@class HelmetHeavy: Equippable
local HelmetHeavy = {}
HelmetHeavy.Identifier = "helmet_heavy"
HelmetHeavy.Name = "Helmet-Heavy"
HelmetHeavy.Model = function()
    return mdl:create()
end
HelmetHeavy.BoneToEquip = "ValveBiped.Bip01_Head1"
HelmetHeavy.EquipOffset = Vector(-3, -1, 0)
HelmetHeavy.EquipAngle = Vector(0, -90, -90)
HelmetHeavy.EquipSlots = {[EquipSlot.head] = 1}
HelmetHeavy.DefenseProfile = DefenseProfile.Basic
HelmetHeavy.MaxDurability = 350
HelmetHeavy.hooks = {}

ents.register(HelmetHeavy, "base_equippable")
