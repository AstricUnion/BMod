
---@class BMod
local BMod = BMod

---@class beff
local beff = beff

---@class ents
local ents = ents

---@class resource
local resource = resource

---@class bmodConfig
local cfg = bmodConfig

---@class bicons
local bicons = bicons

---@class model
local model = model
local hitbox = model.hitbox
local vertex = model.vertex
local part = model.part
local holo = model.holo

local mdl = model.create(hitbox {
    vertex {"cube", Vector(0, 0, 18), Vector(24, 36, 18)},
    vertex {"cube", Vector(-12, 0, 43), Vector(8, 36, 7)},
    vertex {"cube", Vector(0, -50, 10), Vector(10, 10, 10)},
    mass = 72
})
mdl:add("base", part {
    holo { Vector(0, 0, 18), Angle(), "models/props_c17/furnituretable002a.mdl", Vector(1.2, 1.2, 1) },
    holo { Vector(-12, 0, 42), Angle(), "models/props_wasteland/cafeteria_table001a.mdl", Vector(0.4, 0.6, 0.5) },
    holo { Vector(0, -50, 10), Angle(), "models/props_wasteland/laundry_basket002.mdl", Vector(0.4, 0.4, 0.5) }
})


---@class CraftingTable: BModEntity
---@field inProcess Entity?
---@field used boolean
---@field craftMenu BPanel
local CraftingTable = {}
CraftingTable.Identifier = "crafting_table"
CraftingTable.Name = "Crafting table"
CraftingTable.Model = function()
    return mdl:create().bones.origin
end
CraftingTable.hooks = {}



---Create new crafting table
if SERVER then
    function CraftingTable:initialize()
        local pr = self.ent
        pr.craftOffset = Vector(0, 0, 50)
        ---@param colData CollisionData
        pr:addCollisionListener(function(colData)
            if colData.HitSpeed:getLength() < 500 then return end
            local ent = colData.HitEntity
            if !isValid(ent) or ent:getClass() ~= "prop_physics" then return end
            if !ent.BModEntity then
                -- If I picked up object, his mass will be 1, so I must make this shit. Sorry
                ent:enableMotion(false)
                if self.inProcess then return end
                self.inProcess = ent
                timer.simple(0.01, function()
                    local res = resource.salvage(ent)
                    local pos = ent:getPos()
                    ent:remove()
                    local angs = pr:getAngles()
                    local eff = beff.create("craft_effect")
                    eff:setOrigin(pos)
                    eff:setScale(0.6)
                    eff:play()
                    timer.simple(0.5, function()
                        for id, count in pairs(res) do
                            resource.create(id, pos, angs, count, false)
                        end
                        self.inProcess = nil
                    end)
                end)
            end
        end)
    end


    ---[SERVER] Set fuel for table
    ---@param fuel number Fuel
    function CraftingTable:setFuel(fuel)
        fuel = math.clamp(fuel, 0, 100)
        self:setNWVar("fuel", fuel)
    end


    ---[SERVER] Set smelting resource
    ---@param res string Resource to smelt
    function CraftingTable:setSmelting(res)
        self:setNWVar("smelting", res)
    end


    ---[SERVER] Set smelting progress
    ---@param progress number Progress
    function CraftingTable:setSmeltingProgress(progress)
        self:setNWVar("smeltingProgress", progress)
    end


    ---[SERVER] Open craft menu on click
    function CraftingTable.hooks.KeyPress(self, ply, key)
        if key ~= IN_KEY.USE then return end
        if self:getFuel() < 1 then return end
        local tr = ply:getEyeTrace()
        ---@cast tr TraceResult
        if tr.Entity ~= self.ent then return end
        if ply:getShootPos():getDistance(tr.HitPos) > 96 then return end
        net.start("BModCraftingTableOpen")
            net.writeEntity(self.ent)
        net.send(ply)
    end


    ---[SERVER] Interaction of resource
    ---@param self CraftingTable
    ---@param res Resource
    ---@param ent Entity
    function CraftingTable.hooks.BModResourceInteracted(self, res, ent)
        if ent ~= self.ent then return end
        local function tryToRefill()
            local fuelInUnit = res.SolidFuelInUnit
            if !fuelInUnit then return end
            ---@cast res Resource
            if !isValid(res) or !isValid(res.pickedUpBy) then return end
            local count = res:getCount()
            local fuel = self:getFuel()
            local fuelDiff = 100 - fuel
            if fuelDiff <= 0 then return end
            local units = fuelDiff / fuelInUnit
            units = res:take(count - units)
            self:setFuel(fuel + units * fuelInUnit)
            return true
        end
        local function tryToSmelt()
            local smeltTbl = res.SmeltResource
            if !smeltTbl then return end
        end
        if !tryToRefill() then
            tryToSmelt()
        end
    end
end

if CLIENT then
    ---@class bgui
    local bgui = bgui

    ---[CLIENT] Draw info about this resource within 3D2D
    ---@param self CraftingTable
    function CraftingTable.hooks.PostDrawTranslucentRenderables(self)
        BMod.Display(self.ent, Vector(10.5, -50, 18), Angle(), string.format("Fuel: %s", self:getFuel()))
    end

    net.receive("BModCraftingTableOpen", function()
        net.readEntity(function(ent)
            local tbl = ents.inited[ent:entIndex()]
            ---@cast tbl CraftingTable
            if !isValid(tbl) then return end
            if isValid(tbl.craftMenu) then return end
            tbl.craftMenu = bgui.create("CraftMenu")
            tbl.craftMenu:setTable(ent)
            tbl.craftMenu:setType("crafting_table")
            tbl.craftMenu:center()
            input.enableCursor(true)
        end)
    end)

    function CraftingTable:onRemove()
        if isValid(self.craftMenu) then self.craftMenu:remove() end
    end
end

---[SHARED] Get fuel
function CraftingTable:getFuel()
    return self:getNWVar("fuel", 0)
end

---[SHARED] Set smelting resource
---@return string? res Resource to smelt
function CraftingTable:getSmelting()
    return self:getNWVar("smelting", nil)
end

---[SHARED] Set smelting progress
---@return number progress Progress
function CraftingTable:getSmeltingProgress()
    self:setNWVar("smeltingProgress", 0)
end

ents.register(CraftingTable)

