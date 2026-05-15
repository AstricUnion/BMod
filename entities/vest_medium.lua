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

if CLIENT then
    model.newMesh("vest_medium", "https://raw.githubusercontent.com/AstricUnion/BMod/refs/heads/main/mesh/armor.obj")
        :load()

    local mat = model.newMaterial("vest_medium", "VertexLitGeneric")
    mat:setTextureURL("$basetexture", "https://raw.githubusercontent.com/AstricUnion/BMod/refs/heads/main/textures/vest_medium_old.jpg")
    mat:setInt("$realwidth", 256)
    mat:setInt("$realheight", 256)
    mat:recompute()
end

local mdl = model.create(hitbox {
    vertex {"cube", Vector(0, 0, 10), Angle(0, 0, 0), Vector(6, 6, 10)},
    mass = 30
})
mdl:add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "vest_medium", materialId = "vest_medium", meshPart = "AR_Gjel_lod0"} )

---@class VestMedium: Equippable
---@field toScan Deposit[]
---@field nextEffect number Next effect. Relative to curtime
---@field nextDecal number Next decal. Relative to curtime
---@field effect BEffect
---@field drill Entity
local VestMedium = {}
VestMedium.Identifier = "vest_medium"
VestMedium.Name = "Vest Medium"
VestMedium.Model = function()
    return mdl:create()
end
VestMedium.BoneToEquip = "ValveBiped.Bip01_Spine2"
VestMedium.EquipOffset = Vector(-6.5, 3, 0)
VestMedium.EquipAngle = Vector(0, 88, 90)
VestMedium.EquipSlots = {[EquipSlot.chest] = 1, [EquipSlot.abdomen] = 1}
VestMedium.DefenseProfile = DefenseProfile.Basic
VestMedium.MaxDurability = 120
VestMedium.hooks = {}

ents.register(VestMedium, "base_equippable")
