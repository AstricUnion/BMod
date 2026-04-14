---@name Crafting table
---@author AstricUnion
---@shared

---Lib from AstricUnion (TODO: remade it)
---@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/holos.lua as holos
local holos = require("holos")
---@class Holo
local Holo = holos.Holo
local Rig = holos.Rig
local SubHolo = holos.SubHolo
---@class Trail
local Trail = holos.Trail
---@class Clip
local Clip = holos.Clip

local function getCube(offset, size)
    return {
        offset + Vector(-size.x, -size.y, -size.z), offset + Vector(size.x, -size.y, -size.z),
        offset + Vector(size.x, size.y, -size.z), offset + Vector(-size.x, size.y, -size.z),
        offset + Vector(-size.x, -size.y, size.z), offset + Vector(size.x, -size.y, size.z),
        offset + Vector(size.x, size.y, size.z), offset + Vector(-size.x, size.y, size.z),
    }
end


local function model(pos, ang)
    local base = {
        model = hologram.createPart(
            Holo(Rig()),
            Holo(SubHolo(Vector(0, 0, 18), Angle(), "models/props_c17/furnituretable002a.mdl", Vector(1.2, 1.2, 1))),
            Holo(SubHolo(Vector(-12, 0, 42), Angle(), "models/props_wasteland/cafeteria_table001a.mdl", Vector(0.4, 0.6, 0.5))),
            Holo(SubHolo(Vector(0, -50, 10), Angle(), "models/props_wasteland/laundry_basket002.mdl", Vector(0.4, 0.4, 0.5)))
        ),
    }
    base.model:setPos(pos)
    base.hitbox = prop.createCustom(pos + Vector(0, 0, 0), Angle(), {
        getCube(Vector(0, 0, 18), Vector(24, 36, 18)),
        getCube(Vector(-12, 0, 43), Vector(8, 36, 7)),
        getCube(Vector(0, -50, 10), Vector(10, 10, 10))
    }, true)
    base.hitbox:setMass(72)
    base.hitbox:setNoDraw(true)
    base.model:setParent(base.hitbox)
end



---@class CraftingTable
local CraftingTable = {}
CraftingTable.__index = CraftingTable



---Create new crafting table
function CraftingTable:new(pos, ang, freeze)
end
