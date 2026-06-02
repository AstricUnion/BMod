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
GasMask.EquipOffset = Vector(0, -0.1, 0)
GasMask.EquipAngle = Vector(0, -80, -90)
GasMask.EquipSlots = {[EquipSlot.eyes] = 1, [EquipSlot.mouthAndNose] = 1}
GasMask.DefenseProfile = DefenseProfile.NonArmor
GasMask.Defense = {
    [DAMAGE.NERVEGAS] = 1,
    [DAMAGE.RADIATION] = 0.75
}
GasMask.MaxDurability = 2
GasMask.hooks = {}

if CLIENT then
    local function pushMask(mask)
        render.clearStencil()
        render.setStencilEnable(true)

        render.setStencilWriteMask(1)
        render.setStencilTestMask(1)

        render.setStencilFailOperation(STENCIL.REPLACE)
        render.setStencilPassOperation(STENCIL.ZERO)
        render.setStencilZFailOperation(STENCIL.ZERO)
        render.setStencilCompareFunction(STENCIL.NEVER)
        render.setStencilReferenceValue(1)

        mask()

        render.setStencilFailOperation(STENCIL.ZERO)
        render.setStencilPassOperation(STENCIL.REPLACE)
        render.setStencilZFailOperation(STENCIL.ZERO)
        render.setStencilCompareFunction(STENCIL.EQUAL)
        render.setStencilReferenceValue(0)
    end

    local function popMask()
        render.setStencilEnable(false)
        render.clearStencil()
    end

    function GasMask:drawView()
        render.clear(Color(0, 0, 0, 0))
        render.setColor(Color(255, 255, 255, 200))
        render.drawRect(0, 0, 1024, 1024)
        pushMask(function()
            render.drawFilledCircle(512, 512, 256)
        end)
        render.setColor(Color(0, 0, 0))
        render.drawRectFast(0, 0, 1024, 1024)
        popMask()
        render.drawBlurEffect(10, 10, 10)
    end
end

ents.register(GasMask, "base_equippable")
