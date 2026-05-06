---@class resource
local resource = resource

---@class deposit
local deposit = deposit

---@class bicons
local bicons = bicons
local iconsU, iconsV, icons
if CLIENT then
    icons = material.create("UnlitGeneric")
    icons:setTextureURL("$basetexture", "https://raw.githubusercontent.com/AstricUnion/BMod/refs/heads/main/textures/resources.png")
    icons:setInt("$flags", 256)
    iconsU = 0.1125
    iconsV = 0.1125

    ---@param id string
    ---@param row number
    ---@param column number
    local function addIcon(id, row, column)
        bicons.register(id, icons, iconsU * (column - 1), iconsV * (row - 1), iconsU * column, iconsV * row)
    end

    addIcon("advancedparts", 1, 1)
    addIcon("advancedtextiles", 1, 2)
    addIcon("aluminiumore", 1, 3)
    addIcon("aluminium", 1, 4)
    addIcon("ammo", 1, 5)
    addIcon("antimatter", 1, 7)
    addIcon("basicparts", 1, 8)
    addIcon("ceramic", 2, 1)
    addIcon("chemicals", 2, 2)
    addIcon("cloth", 2, 3)
    addIcon("coal", 2, 4)
    addIcon("coolant", 2, 6)
    addIcon("copperore", 2, 7)
    addIcon("copper", 2, 8)
    addIcon("explosives", 3, 2)
    addIcon("fuel", 3, 4)
    addIcon("gas", 3, 5)
    addIcon("glass", 3, 7)
    addIcon("gold", 4, 1)
    addIcon("lead", 4, 4)
    addIcon("nutrients", 4, 7)
    addIcon("oil", 4, 8)
    addIcon("organics", 5, 1)
    addIcon("paper", 5, 2)
    addIcon("plastic", 5, 3)
    addIcon("power", 5, 6)
    addIcon("precisionparts", 5, 7)
    addIcon("propellant", 5, 8)
    addIcon("rubber", 6, 1)
    addIcon("silver", 6, 4)
    addIcon("steel", 6, 5)
    addIcon("water", 7, 4)
    addIcon("wood", 7, 5)
end


---@class Wood: Resource
local Wood = resource.fastRegister(
    "Wood", "wood", "models/hunter/blocks/cube05x05x05.mdl", Vector(12, 0, 0), nil,
    "physics/wood/wood_box_break1.wav", "physics/wood/wood_box_impact_hard4.wav"
)
Wood.modifyEntity = function(ent)
    ent:setMaterial("phoenix_storms/wood")
end
Wood.FuelInUnit = 5


---@class Paper: Resource
local Paper = resource.fastRegister(
    "Paper", "paper", "models/props/cs_office/file_box.mdl", Vector(0, 7, 7), Angle(0, 90, 0),
    "physics/cardboard/cardboard_box_break2.wav", "physics/cardboard/cardboard_box_impact_hard4.wav"
)
Paper.modifyEntity = function(ent)
    ent:setAngles(ent:localToWorldAngles(Angle(0, -90, 0)))
end


---@class Water: Resource
local Water = resource.fastRegister(
    "Water", "water", "models/props_borealis/bluebarrel001.mdl", Vector(14, 0, 0), nil,
    "ambient/water/water_splash1.wav", "player/footsteps/slosh1.wav"
)
deposit.add("water", 400, 10, 0.5, 0, false)


---@class Aluminium: Resource
local Aluminium = resource.fastRegister(
    "Aluminium", "aluminium", "models/hunter/blocks/cube025x05x025.mdl", Vector(-5, 0, 12), Angle(0, 0, -90),
    "phx/hmetal1.wav", "phx/hmetal3.wav"
)
Aluminium.modifyEntity = function(ent)
    ent:setMaterial("models/xqm/cylinderx1_diffuse")
end


---@class Copper: Resource
local Copper = resource.fastRegister(
    "Copper", "copper", "models/hunter/blocks/cube025x05x025.mdl", Vector(-5, 0, 12), Angle(0, 0, -90),
    "phx/hmetal1.wav", "phx/hmetal3.wav"
)
Copper.modifyEntity = function(ent)
    ent:setMaterial("models/xqm/cylinderx1_diffuse")
    ent:setColor(Color(220, 120, 40))
end


---@class Explosives: Resource
local Explosives = resource.fastRegister(
    "Explosives", "explosives", "models/Items/ammoCrate_Rockets.mdl", Vector(16, 0, 2), Angle(0, 0, 0),
    "BaseCombatCharacter.AmmoPickup", "player/pl_shell1.wav"
)


---@class Gold: Resource
local Gold = resource.fastRegister(
    "Gold", "gold", "models/hunter/blocks/cube025x05x025.mdl", Vector(-5, 0, 12), Angle(0, 0, -90),
    "phx/hmetal1.wav", "phx/hmetal3.wav"
)
Gold.modifyEntity = function(ent)
    ent:setMaterial("models/xqm/cylinderx1_diffuse")
    ent:setColor(Color(255, 215, 0))
end

---@class Lead: Resource
local Lead = resource.fastRegister(
    "Lead", "lead", "models/hunter/blocks/cube025x05x025.mdl", Vector(-5, 0, 12), Angle(0, 0, -90),
    "phx/hmetal1.wav", "phx/hmetal3.wav"
)
Lead.modifyEntity = function(ent)
    ent:setMaterial("models/xqm/cylinderx1_diffuse")
    ent:setColor(Color(120, 120, 150))
end

-- edit sounds
---@class Nutrients: Resource
local Nutrients = resource.fastRegister(
    "Nutrients", "nutrients", "models/props/cs_office/Cardboard_box01.mdl", Vector(0, 12, 8), Angle(0, 90, 0),
    "phx/hmetal1.wav", "phx/hmetal3.wav"
)
Nutrients.modifyEntity = function(ent)
    ent:setAngles(ent:localToWorldAngles(Angle(0, -90, 0)))
end

---@class Steel: Resource
local Steel = resource.fastRegister(
    "Steel", "steel", "models/hunter/blocks/cube025x05x025.mdl", Vector(-5, 0, 12), Angle(0, 0, -90),
    "phx/hmetal1.wav", "phx/hmetal3.wav"
)
Steel.modifyEntity = function(ent)
    ent:setMaterial("models/xqm/cylinderx1_diffuse")
    ent:setColor(Color(100, 100, 100))
end


---@class Silver: Resource
local Silver = resource.fastRegister(
    "Silver", "silver", "models/hunter/blocks/cube025x05x025.mdl", Vector(-5, 0, 12), Angle(0, 0, -90),
    "phx/hmetal1.wav", "phx/hmetal3.wav"
)
Silver.modifyEntity = function(ent)
    ent:setMaterial("models/xqm/cylinderx1_diffuse")
    ent:setColor(Color(200, 200, 200))
end


---@class Ceramic: Resource
local Ceramic = resource.fastRegister(
    "Ceramic", "ceramic", "models/hunter/blocks/cube05x05x05.mdl", Vector(12, 0, 0), nil,
    "physics/glass/glass_strain2.wav", "physics/glass/glass_sheet_impact_hard3.wav"
)
Ceramic.modifyEntity = function(ent)
    ent:setMaterial("models/props_building_details/courtyard_template001c_bars")
end


---@class Oil: Resource
local Oil = resource.fastRegister(
    "Oil", "oil", "models/props_c17/oildrum001.mdl", Vector(14, 0, 24), nil,
    "ambient/water/water_spray1.wav", "physics/surfaces/underwater_impact_bullet1.wav"
)
Oil.modifyEntity = function(ent)
    ent:setColor(Color(50, 50, 50))
end
deposit.add("oil", 300, 8, nil, 600, true)


-- edit sounds
---@class Organics: Resource
local Organics = resource.fastRegister(
    "Organics", "organics", "models/props_junk/PlasticCrate01a.mdl", Vector(9, 0, 0), nil,
    "ambient/water/water_spray1.wav", "physics/surfaces/underwater_impact_bullet1.wav"
)
Organics.modifyEntity = function(ent)
    local holo = hologram.create(ent:getPos() - Vector(0, 0, 3), ent:getAngles(), "models/holograms/cube.mdl", Vector(1.4, 2, 0.7))
    if !holo then return end
    holo:setMaterial("phoenix_storms/ps_grass")
    holo:setParent(ent)
end


---@class Gas: Resource
local Gas = resource.fastRegister(
    "Gas", "gas", "models/props_explosive/explosive_butane_can.mdl", Vector(8, 0, 15), nil,
    "physics/metal/metal_box_impact_soft1.wav", "physics/metal/metal_box_impact_bullet2.wav"
)
Gas.modifyEntity = function(ent)
    ent:setMaterial("phoenix_storms/grey_chrome")
end


---@class Power: Resource
local Power = resource.fastRegister(
    "Power", "power", "models/Items/car_battery01.mdl", Vector(6, 0, -1), nil,
    "ambient/energy/zap7.wav", "ambient/energy/zap1.wav"
)


---@class Fuel: Resource
local Fuel = resource.fastRegister(
    "Fuel", "fuel", "models/props_junk/gascan001a.mdl", Vector(4, 0, -1), nil,
    "ambient/water/water_spray1.wav", "physics/surfaces/underwater_impact_bullet1.wav"
)


---@class Plastic: Resource
local Plastic = resource.fastRegister(
    "Plastic", "plastic", "models/hunter/blocks/cube05x05x05.mdl", Vector(12, 0, 0), nil,
    "physics/plastic/plastic_barrel_break1.wav", "physics/plastic/plastic_box_impact_hard4.wav"
)


---@class Rubber: Resource
local Rubber = resource.fastRegister(
    "Rubber", "rubber", "models/props_vehicles/carparts_wheel01a.mdl", Vector(0, 6, 0), Angle(0, 90, 0),
    "physics/body/body_medium_impact_soft1.wav", "physics/body/body_medium_impact_soft2.wav"
)


---@class Glass: Resource
local Glass = resource.fastRegister(
    "Glass", "glass", "models/hunter/blocks/cube05x05x05.mdl", Vector(12, 0, 0), nil,
    "physics/glass/glass_strain2.wav", "physics/glass/glass_sheet_impact_hard3.wav"
)
Glass.modifyEntity = function(ent)
    ent:setMaterial("models/debug/debugwhite")
    ent:setColor(Color(100, 100, 100, 100))
end


---@class Sand: Resource
local Sand = resource.fastRegister(
    "Sand", "sand", "models/props_trenches/sandbag01.mdl", Vector(0, 8, 2), Angle(0, 90, 0),
    "physics/surfaces/sand_impact_bullet4.wav", "player/footsteps/sand4.wav"
)
Sand.modifyEntity = function(ent)
    ent:setMaterial("models/debug/debugwhite")
    ent:setColor(Color(100, 100, 100, 100))
end


---@class Cloth: Resource
local Cloth = resource.fastRegister(
    "Cloth", "cloth", "models/props/cs_office/Paper_towels.mdl", Vector(0, 5, 3), Angle(0, 90, 0),
    "physics/surfaces/sand_impact_bullet4.wav", "player/footsteps/sand4.wav"
)


---@class Chemicals: Resource
local Chemicals = resource.fastRegister(
    "Chemicals", "chemicals", "models/props/CS_militia/caseofbeer01.mdl", Vector(0, 7, 7), Angle(0, 90, 0),
    "physics/glass/glass_strain2.wav", "physics/glass/glass_sheet_impact_hard3.wav"
)


---@class BasicParts: Resource
local BasicParts = resource.fastRegister(
    "Basic parts", "basicparts", "models/Items/item_item_crate.mdl", Vector(17, 0, 12), Angle(0, 0, 0),
    "physics/wood/wood_box_break1.wav", "physics/wood/wood_box_impact_hard4.wav"
)

---@class PrecisionParts: Resource
local PrecisionParts = resource.fastRegister(
    "Precision parts", "precisionparts", "models/props_lab/partsbin01.mdl", Vector(7, 0, 3), Angle(0, 0, 0),
    "ambient/materials/footsteps_glass1.wav", "phx/epicmetal_soft7.wav"
)
PrecisionParts.modifyEntity = function(ent)
    ent:setColor(Color(80, 130, 80))
end

---@class Propellant: Resource
local Propellant = resource.fastRegister(
    "Propellant", "propellant", "models/props_junk/plasticbucket001a.mdl", Vector(7, 0, 3), Angle(0, 0, 0),
    "physics/surfaces/sand_impact_bullet4.wav", "player/footsteps/sand4.wav"
)

---@class Coolant: Resource
local Coolant = resource.fastRegister(
    "Coolant", "coolant", "models/props_junk/metalgascan.mdl", Vector(4, 0, 0), Angle(0, 0, 0),
    "ambient/water/water_spray1.wav", "physics/surfaces/underwater_impact_bullet1.wav"
)
Coolant.modifyEntity = function(ent)
    ent:setMaterial("models/debug/debugwhite")
    ent:setColor(Color(100, 100, 220))
end


---@class Ammo: Resource
local Ammo = resource.fastRegister(
    "Ammo", "ammo", "models/Items/BoxSRounds.mdl", Vector(4, 0, 5), Angle(0, 0, 0),
    "BaseCombatCharacter.AmmoPickup", "player/pl_shell1.wav"
)


