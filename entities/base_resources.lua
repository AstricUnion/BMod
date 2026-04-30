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
    -- idk, but on laptop i have other UV coordinates
    iconsU = 0.1125
    iconsV = 0.1125
    -- iconsU = 0.125
    -- iconsV = 0.125

    ---@param id string
    ---@param row number
    ---@param column number
    local function addIcon(id, row, column)
        bicons.register(id, icons, iconsU * (column - 1), iconsV * (row - 1), iconsU * column, iconsV * row)
    end

    addIcon("advanced_parts", 1, 1)
    addIcon("advanced_textile", 1, 2)
    addIcon("aluminium_ore", 1, 3)
    addIcon("aluminium", 1, 4)
    addIcon("ammo", 1, 5)
    addIcon("antimatter", 1, 7)
    addIcon("basic_parts", 1, 8)
    addIcon("ceramic", 2, 1)
    addIcon("chemicals", 2, 2)
    addIcon("cloth", 2, 3)
    addIcon("coal", 2, 4)
    addIcon("coolant", 2, 6)
    addIcon("copper_ore", 2, 7)
    addIcon("copper", 2, 8)
    addIcon("paper", 5, 2)
    addIcon("steel", 6, 5)
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


---@class Steel: Resource
local Steel = resource.fastRegister(
    "Steel", "steel", "models/hunter/blocks/cube025x05x025.mdl", Vector(-5, 0, 12), Angle(0, 0, -90),
    "phx/hmetal1.wav", "phx/hmetal3.wav"
)
Steel.modifyEntity = function(ent)
    ent:setMaterial("models/xqm/cylinderx1_diffuse")
    ent:setColor(Color(100, 100, 100))
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
    "Oil", "oil", "models/props_c17/oildrum001.mdl", Vector(14, 0, 20), nil,
    "ambient/water/water_spray1.wav", "physics/surfaces/underwater_impact_bullet1.wav"
)
Oil.modifyEntity = function(ent)
    ent:setColor(Color(50, 50, 50))
end
deposit.add("oil", 300, 8, nil, 600, true)


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
    "Rubber", "rubber", "models/props_vehicles/apc_tire001.mdl", Vector(10, 0, 1), nil,
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


---@class BasicParts: Resource
local BasicParts = resource.fastRegister(
    "Basic parts", "basic_parts", "models/Items/item_item_crate.mdl", Vector(17, 0, 10), Angle(0, 0, 0),
    "physics/wood/wood_box_break1.wav", "physics/wood/wood_box_impact_hard4.wav"
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


if SERVER then
    -- local res = ents.create("ammo")
    ---@cast res Resource
    -- res:setCount(50)
    -- res:spawn(chip():getPos(), Angle(), true)
end


-- Props to resources --
resource.addProp({
    "models/props_junk/wood_crate001a.mdl",
    "models/props_junk/wood_crate001a_damaged.mdl"
}, { wood = 23 })

resource.addProp({
    "models/props_docks/channelmarker_gib01.mdl",
    "models/props_c17/furnituredrawer001a_shard01.mdl"
}, { wood = 21 })

resource.addProp({
    "models/props_c17/furnituredrawer001a_chunk01.mdl",
    "models/props_c17/furnituredrawer001a_chunk02.mdl",
    "models/props_c17/furnituredrawer001a_chunk03.mdl",
    "models/props_c17/furnituredrawer002a.mdl",
    "models/gibs/wood_gib01a.mdl",
    "models/gibs/wood_gib01b.mdl",
    "models/gibs/wood_gib01c.mdl",
    "models/gibs/wood_gib01d.mdl",
    "models/gibs/wood_gib01e.mdl",
}, { wood = 11 })


resource.addProp({
    "models/props_c17/streetsign001c.mdl",
    "models/props_c17/streetsign002b.mdl",
    "models/props_c17/streetsign003b.mdl",
    "models/props_c17/streetsign004f.mdl",
    "models/props_c17/streetsign005b.mdl",
    "models/props_c17/streetsign005c.mdl",
    "models/props_c17/streetsign005d.mdl"
}, { aluminium = 8, steel = 6 })

resource.addProp({
    "models/props_junk/popcan01a.mdl"
}, { aluminium = 2 })

resource.addProp({
    "models/props_junk/terracotta01.mdl"
}, { ceramic = 2 })

resource.addProp({
    "models/props_c17/lamp001a.mdl"
}, { ceramic = 6 })
