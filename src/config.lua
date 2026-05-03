---@name BMod config
---@author AstricUnion
---@shared

---Class to configurate BMod
---@class bmodConfig
local bmodConfig = {}

---@class BModCraft
---@field name string Name of the craft
---@field description string? Description for craft
---@field icon string? Identifier of icon from bicons
---@field scale number? Scale of effect for this craft
---@field requires table<string, number> What requires this craft?
---@field result fun(pos: Vector, ang: Angle) Result of craft
---@field methods string[] Methods to craft. In base version, can be crafting_table

---@type table<string, BModCraft[]> Key is a craft category
bmodConfig.crafts = {
    ["Handcraft"] = {
        {
            name = "Crafting table",
            methods = {},
            scale = 1.8,
            requires = {
                wood = 25,
                aluminium = 8,
                ceramic = 15
            },
            result = function(pos, ang)
                local ent = ents.create("crafting_table")
                ent:spawn(pos, ang, false)
            end
        }
    },
    ["Resources"] = {
        {
            name = "Paper, x100",
            scale = 0.6,
            description = "Writing material that can be used for more malicious purposes",
            icon = "paper",
            methods = {
                ["crafting_table"] = true
            },
            requires = {
                wood = 39,
                water = 91
            },
            result = function(pos, ang)
                resource.create("paper", pos, ang, 100, false, true)
            end
        },
        {
            name = "Basic Parts, x50",
            scale = 0.6,
            description = "",
            icon = "basicparts",
            methods = {
                ["crafting_table"] = true
            },
            requires = {
                glass = 7,
                rubber = 7,
                plastic = 13,
                copper = 20,
                aluminium = 20,
                steel = 20
            },
            result = function(pos, ang)
                resource.create("basicparts", pos, ang, 50, false, true)
            end
        }
    },
    ["Tools"] = {
        {
            name = "Bucket",
            scale = 0.6,
            description = "Writing material that can be used for more malicious purposes",
            icon = "bucket",
            methods = {
                ["crafting_table"] = true
            },
            requires = { aluminium = 13 },
            result = function(pos, ang)
                local ent = ents.create("bucket")
                ent:spawn(pos, ang, false)
            end
        }
    }
}


---@type table<string, table<string, number>>
bmodConfig.salvageByPhys = {
    metalgrate = { steel = 0.1, aluminium = 0.1 },
    default = { steel = 0.2 },
    wood = { wood = 0.7 },
    wood_panel = { wood = 0.5 },
    wood_crate = { wood = 0.5 },
    wood_furniture = { wood = 0.4, cloth = 0.1, plastic = 0.05 },
    wood_solid = { wood = 0.7 },
    metal = { steel = 0.3, aluminium = 0.2 },
    metal_barrel = { steel = 0.4 },
    metal_box = { steel = 0.4 },
    floating_metal_barrel = { steel = 0.3, fuel = 0.3, oil = 0.3 },
    metalpanel = { steel = 0.5 },
    metalvehicle = { lead = 0.05, steel = 0.3, aluminium = 0.1, basicparts = 0.1, copper = 0.05, plastic = 0.1, rubber = 0.2, precisionparts = 0.05 },
    canister = { steel = 0.3, gas = 0.5 },
    plastic = { plastic = 0.5 },
    paintcan = { plastic = 0.2, chemicals = 0.4, steel = 0.2 },
    plastic_barrel = { plastic = 0.2, water = 0.3 },
    plastic_barrel_buoyant = { plastic = 0.2, water = 0.3 },
    plastic_box = { plastic = 0.2, glass = 0.2, copper = 0.2 },
    computer = { plastic = 0.2, copper = 0.2, silver = 0.1, gold = 0.05, basicparts = 0.2 },
    dirt = { wood = 0.1, cloth = 0.1 },
    sand = { sand = 0.4 },
    sandbags = { sand = 0.8, wood = 0.1 },
    concrete = { ceramic = 0.5 },
    paper = { paper = 0.8 },
    cardboard = { paper = 0.8 },
    rubber = { rubber = 0.8 },
    carpet = { cloth = 0.4, steel = 0.1 },
    watermelon = { organics = 0.8 },
    porcelain = { ceramic = 0.4 },
    item = { power = 0.3, basicparts = 0.2, chemicals = 0.3 },
    glassbottle = { glass = 0.4 },
    glass = { glass = 0.5 },
    popcan = { aluminium = 0.8 },
    pottery = { ceramic = 0.4 },
    wood_plank = { wood = 0.5 },
    ceiling_tile = { ceramic = 0.4 },
    metalvent = { steel = 0.2, aluminium = 0.3, plastic = 0.2 },
    flesh = { organics = 3 },
    zombieflesh = { organics = 2 },
    alienflesh = { organics = 1, chemicals = 0.5 },
    antlion = { organics = 0.5, chemicals = 0.7 },
    weapon = { steel = 0.1, aluminium = 0.1, tungsten = 0.05, plastic = 0.1, basicparts = 0.2, precisionparts = 0.2 },
    rubbertire = { rubber = 0.6, steel = 0.2 },
    jeeptire = { rubber = 0.6, aluminium = 0.2 },
    hay = { organics = 0.3 },
    brick = { ceramic = 0.4 },
    solidmetal = { steel = 0.4, tungsten = 0.1, titanium = 0.1 },
    combine_metal = { steel = 0.4, tungsten = 0.1, titanium = 0.1 },
    gm_torpedo = { steel = 0.2, explosives = 0.4, basicparts = 0.2 },
    phx_ww2bomb = { steel = 0.2, explosives = 0.4, basicparts = 0.2 },
    phx_explosiveball = { steel = 0.2, explosives = 0.4, basicparts = 0.2 },
    grenade = { steel = 0.2, explosives = 0.7 },
    crowbar = { steel = 0.8 },
    tile = { ceramic = 0.5, organics = 0.1 },
    strider = { advancedparts = 0.1, organics = 0.1, titanium = 0.2, ceramic = 0.1 },
    hunter = { advancedtextiles = 0.1, organics = 0.1, titanium = 0.2, plastic = 0.1 },
    slipperymetal = { steel = 0.3, aluminium = 0.3 },
    chainlink = { steel = 0.5 },
    snow = { water = 0.5 },
    ice = { water = 0.6 },
    rock = { ceramic = 0.5 },
    boulder = { ceramic = 0.5 },
    grass = { organics = 0.5 }
}


---@class BModSalvage
---@field substrings string[]? Substrings to find
---@field resources table<string, number> Resources to give

---@type table<string, BModSalvage>
bmodConfig.salvageByModel = {
    {
        substrings = {"crate_fruit", "fruit_crate"},
        resources = {
            wood = 0.2,
            organics = 0.4
        }
    },
    {
        substrings = {"food"},
        resources = {
            nutrients = 0.8
        }
    },
    {
        substrings = {"explosive"},
        resources = {
            steel = 0.2,
            explosives = 0.4
        }
    },
    {
        substrings = {"oildrum"},
        resources = {
            steel = 0.2,
            oil = 0.3,
            fuel = 0.1
        }
    },
    {
        substrings = {"vendingmachine"},
        resources = {
            plastic = 0.1,
            basicparts = 0.2,
            water = 0.3,
            nutrients = 0.3
        }
    },
    {
        substrings = {"machine", "laundry_washer", "engine", "laundry_dryer"},
        resources = {
            steel = 0.2,
            basicparts = 0.4,
            precisionparts = 0.1
        }
    },
    {
        substrings = {"generator0"},
        resources = {
            steel = 0.2,
            basicparts = 0.2,
            precisionparts = 0.1,
            copper = 0.3
        }
    },
    {
        substrings = {"forklift"},
        resources = {
            steel = 0.2,
            aluminium = 0.1,
            basicparts = 0.5,
            copper = 0.05,
            plastic = 0.1,
            rubber = 0.1,
            precisionparts = 0.05,
            lead = 0.05
        }
    },
    {
        substrings = {"propane", "coolingtank"},
        resources = {
            steel = 0.2,
            gas = 0.6
        }
    },
    {
        substrings = {"gaspump", "gascan"},
        resources = {
            steel = 0.2,
            fuel = 0.6
        }
    },
    {
        substrings = {"spotlight"},
        resources = {
            steel = 0.2,
            glass = 0.5,
            basicparts = 0.2
        }
    },
    {
        substrings = {"radio", "receiver", "monitor", "consolebox"},
        resources = {
            basicparts = 0.2,
            copper = 0.2,
            gold = 0.05,
            silver = 0.1,
            plastic = 0.1
        }
    },
    {
        substrings = {"combine_soldier", "combine_super_soldier"},
        resources = {
            advancedtextiles = 0.3,
            organics = 0.3
        }
    },
    {
        substrings = {"police"},
        resources = {
            cloth = 1,
            organics = 0.3
        }
    },
    {
        substrings = {"helicopter"},
        resources = {
            titanium = 0.1,
            aluminium = 0.2,
            basicparts = 0.2,
            precisionparts = 0.2,
            copper = 0.1,
            lead = 0.05
        }
    },
    {
        substrings = {"train0"},
        resources = {
            steel = 0.3,
            basicparts = 0.3
        }
    },
    {
        substrings = {"battery"},
        resources = {
            plastic = 0.2,
            lead = 0.5,
            power = 5
        }
    },
    {
        substrings = {"pipe"},
        resources = {
            lead = 0.2,
            steel = 0.5
        }
    },
    {
        substrings = {"ammocrate"},
        resources = {
            steel = 0.1,
            ammo = 0.7
        }
    },
    {
        substrings = {"garbage_plasticbottle"},
        resources = {
            plastic = 0.1,
            chemicals = 0.8
        }
    },
    {
        substrings = {"/blu/tanks/", "_apc"}, -- simphys tanks and hl2 apcs
        resources = {
            steel = 0.3,
            basicparts = 0.2,
            copper = 0.05,
            tungsten = 0.1,
            precisionparts = 0.1,
            rubber = 0.05,
            lead = 0.05
        }
    },
    {
        substrings = {"computer", "/props_lab/"},
        resources = {
            plastic = 0.5,
            precisionparts = 0.1
        }
    },
    {
        substrings = {"sink", "mooring_cleat"},
        resources = {
            steel = 0.5,
            copper = 0.3
        }
    },
    {
        substrings = {"pot"},
        resources = {
            steel = 0.4,
            aluminium = 0.2,
            copper = 0.1
        }
    },
    {
        substrings = {"/hunter/"},
        resources = {
            plastic = 0.7,
        }
    },
    {
        substrings = {"acorn"},
        resources = {
            organics = 0.5,
        }
    },
    {
        substrings = {"metalbucket"},
        resources = {
            steel = 0.6,
            aluminium = 0.2
        }
    },
    {
        substrings = {"sawblade"},
        resources = {
            steel = 0.6,
            tungsten = 0.2,
        }
    },
    {
        substrings = {"/props_wasteland/barricade"},
        resources = {
            steel = 0.2,
            wood = 0.5,
        }
    },
    {
        substrings = {"trashbin"},
        resources = {
            plastic = 0.25,
            rubber = 0.25,
            paper = 0.2,
            steel = 0.05,
            aluminium = 0.1,
            copper = 0.05
        }
    }
}

return bmodConfig

