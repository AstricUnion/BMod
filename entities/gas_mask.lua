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

local mdl = model.new("gas_mask", hitbox {
    vertex {"cube", Vector(0, 0, 2), Angle(0, 30, 0), Vector(4, 4, 3)},
    mass = 10,
})
    :add("base", holo { ang = Angle(90, 0, 0), model = "models/holograms/cube.mdl", mesh = "armor", meshPart = "gas_mask"} )

---@class GasMask: Equippable
local GasMask = {}
GasMask.Identifier = "gas_mask"
GasMask.Name = "Gas Mask"
GasMask.Model = function()
    return mdl:create()
end
GasMask.BoneToEquip = "ValveBiped.Bip01_Head1"
GasMask.EquipOffset = Vector(-0.5, 0.4, 0)
GasMask.EquipAngle = Vector(0, -80, -90)
GasMask.EquipSlots = {[EquipSlot.eyes] = 1, [EquipSlot.mouthAndNose] = 1}
GasMask.DefenseProfile = DefenseProfile.NonArmor
GasMask.Defense = {
    [DAMAGE.NERVEGAS] = 1,
    [DAMAGE.RADIATION] = 0.75
}
GasMask.MaxDurability = 2
GasMask.hooks = {}

ents.register(GasMask, "base_equippable")
