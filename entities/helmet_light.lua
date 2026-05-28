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

local mdl = model.new("helmet_light", hitbox {
    vertex {"cube", Vector(0, 0, 10), Angle(0, 0, 0), Vector(6, 6, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "helmet_light"} )

---@class HelmetLight: Equippable
local HelmetLight = {}
HelmetLight.Identifier = "helmet_light"
HelmetLight.Name = "Helmet-Light"
HelmetLight.Model = function()
    return mdl:create()
end
HelmetLight.BoneToEquip = "ValveBiped.Bip01_Head1"
HelmetLight.EquipOffset = Vector(-2, -0.5, 0)
HelmetLight.EquipAngle = Vector(0, -90, -90)
HelmetLight.EquipSlots = {[EquipSlot.head] = 0.6}
HelmetLight.DefenseProfile = DefenseProfile.Basic
HelmetLight.MaxDurability = 200
HelmetLight.hooks = {}

ents.register(HelmetLight, "base_equippable")
