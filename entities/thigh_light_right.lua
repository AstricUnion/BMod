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

local mdl = model.new("thigh_light_right", hitbox {
    vertex {"cube", Vector(0, 0, -2), Angle(0, 0, 0), Vector(8, 8, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "thigh_light", scale = Vector(1, -1, -1) } )

---@class ThighLightRight: Equippable
local ThighLightRight = {}
ThighLightRight.Identifier = "thigh_light_right"
ThighLightRight.Name = "Thigh Light Right"
ThighLightRight.Model = function()
    return mdl:create()
end
ThighLightRight.BoneToEquip = "ValveBiped.Bip01_R_Thigh"
ThighLightRight.EquipOffset = Vector(0.9, 0, 0)
ThighLightRight.EquipAngle = Vector(180, 90, 0)
ThighLightRight.EquipSlots = {[EquipSlot.rightThigh] = 0.5}
ThighLightRight.DefenseProfile = DefenseProfile.Basic
ThighLightRight.MaxDurability = 200
ThighLightRight.hooks = {}
ents.register(ThighLightRight, "base_equippable")
