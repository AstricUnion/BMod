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

local mdl = model.new("pelvis_panel", hitbox {
    vertex {"cube", Vector(0, 0, 10), Angle(0, 0, 0), Vector(6, 6, 10)},
    mass = 10
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "pelvis_panel", scale = Vector(1.5, 1.4, 1.8) } )

---@class PelvisPanel: Equippable
local PelvisPanel = {}
PelvisPanel.Identifier = "pelvis_panel"
PelvisPanel.Name = "Pelvis Panel"
PelvisPanel.Model = function()
    return mdl:create()
end
PelvisPanel.BoneToEquip = "ValveBiped.Bip01_Pelvis"
PelvisPanel.EquipOffset = Vector(0, -5, 6)
PelvisPanel.EquipAngle = Angle(180, 0, -90)
PelvisPanel.EquipSlots = {[EquipSlot.pelvis] = 0.7}
PelvisPanel.DefenseProfile = DefenseProfile.Basic
PelvisPanel.MaxDurability = 350
PelvisPanel.hooks = {}

ents.register(PelvisPanel, "base_equippable")
