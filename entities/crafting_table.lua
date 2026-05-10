
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

---@class gas
local gas = gas

---@class model
local model = model
local hitbox = model.hitbox
local vertex = model.vertex
local part = model.part
local holo = model.holo

local mdl = model.create(hitbox {
    vertex {"cube", Vector(0, 0, 18), nil, Vector(24, 36, 18)},
    vertex {"cube", Vector(-12, 0, 43), nil, Vector(8, 36, 7)},
    vertex {"cube", Vector(0, -50, 10), nil, Vector(10, 10, 10)},
    mass = 250
})
mdl:add("base", part {
    holo { Vector(0, 0, 18), Angle(), "models/props_c17/furnituretable002a.mdl", Vector(1.2, 1.2, 1) },
    holo { Vector(-12, 0, 42), Angle(), "models/props_wasteland/cafeteria_table001a.mdl", Vector(0.4, 0.6, 0.5) },
    holo { Vector(0, -50, 10), Angle(), "models/props_wasteland/laundry_basket002.mdl", Vector(0.4, 0.4, 0.5) }
})


---@class CraftingTable: BaseMachine
---@field inProcess Entity?
---@field used boolean
---@field nextThink number
---@field nextGasParticle number
---@field smeltingEffect BEffect
---@field produce Resources
---@field craftMenu BPanel
local CraftingTable = {}
CraftingTable.Identifier = "crafting_table"
CraftingTable.Name = "Crafting table"
CraftingTable.Model = function()
    return mdl:create().bones.origin
end
CraftingTable.hooks = {}

---@type table<string, ResourceInput>
CraftingTable.Inputs = {}
CraftingTable.Inputs.fuel = { rateField = "SolidFuelInUnit", maxCount = 100 }
CraftingTable.Inputs.smelting = { maxCount = 50, callback = function (self, res, _)
    if !res.SmeltResource or self:getInput("fuel") < 1 then
        return true
    end
end }



---Create new crafting table
if SERVER then
    function CraftingTable:initialize()
        local pr = self.ent
        self.nextThink = 0
        self.nextGasParticle = 0
        self.produce = {}
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


    ---[SERVER] Open craft menu on click or get smelting resource
    function CraftingTable:onUse(ply)
        local _, resToSmelt = self:getInput("smelting")
        if resToSmelt then
            self:stopSmelting()
        else
            local fuel = self:getInput("fuel")
            if fuel < 1 then
                BMod.errorMessage(ply, "You can't craft on empty crafting table! Use coal, wood or other solid fuel")
                return
            end
            net.start("BModCraftingTableOpen")
                net.writeEntity(self.ent)
            net.send(ply)
        end
    end


    ---[SERVER] Stop smelting and produce resources
    function CraftingTable:stopSmelting()
        print("dsjkl")
        local currentUnits, resToSmelt = self:getInput("smelting")
        local height = 0
        local time = 1 / prop.spawnRate()
        local pos = self.ent:localToWorld(Vector(0, -24, 10))
        if resToSmelt then
            self.produce[resToSmelt] = currentUnits ~= 0 and currentUnits or nil
        end
        for id, count in pairs(self.produce) do
            timer.simple(height * time, function()
                resource.create(id, pos + Vector(0, 0, height * 12), Angle(), count, false, true)
            end)
            height = height + 1
        end
        self.produce = {}
        self:setInput("smelting", 0)
        if self.smeltingEffect then
            self.smeltingEffect:destroy()
            self.smeltingEffect = nil
        end
    end

    ---[SERVER] Think hook. Smelting logic
    ---@param self CraftingTable
    function CraftingTable.hooks.Think(self)
        local cur = timer.curtime()
        if self.nextThink >= cur then return end
        local offsetPos = self.ent:localToWorld(Vector(0, -46, 20))
        local currentUnits, resToSmelt = self:getInput("smelting")
        if !resToSmelt then return end
        local fuel = self:getInput("fuel")
        local res = ents.registered[resToSmelt]
        if !res then return end
        ---@cast res Resource
        for id, multiplier in pairs(res.SmeltResource) do
            self.produce[id] = (self.produce[id] or 0) + 0.8 * multiplier
        end
        if !self.smeltingEffect then
            local eff = beff.create("oilsmoke")
            eff:setOrigin(Vector(0, -46, 20))
            eff:setEntity(self.ent)
            eff:play()
            self.smeltingEffect = eff
        end
        if self.nextGasParticle <= cur then
            local par = gas.create("carbonmonoxide")
            par:setPos(offsetPos + self.ent:getUp() * 50)
            par:setVelocity(gas.randVector() * 50 * Vector(1, 1, 2))
            par:spawn()
            self.nextGasParticle = cur + 10
        end
        self:setInput("smelting", currentUnits - 0.5)
        self:setInput("fuel", fuel - 1)
        if currentUnits - 0.5 <= 0 or fuel - 1 < 1 then self:stopSmelting() end
        self.nextThink = cur + 1
    end
end

if CLIENT then
    ---@class bgui
    local bgui = bgui


    function CraftingTable:initialize()
        self.ent.craftOffset = Vector(5, 0, 60)
    end

    ---[CLIENT] Draw info about this resource within 3D2D
    ---@param self CraftingTable
    function CraftingTable.hooks.PostDrawTranslucentRenderables(self)
        BMod.displayEnt(self.ent, Vector(10.5, -50, 18), Angle(), function()
            render.setFont("Trebuchet24")
            render.drawSimpleText(0, 0, string.format("Fuel: %s", self:getInput("fuel")), TEXT_ALIGN.CENTER, TEXT_ALIGN.TOP)
            local currentUnits, resToSmelt = self:getInput("smelting")
            if !resToSmelt then return end
            local res = ents.registered[resToSmelt]
            if !res then return end
            render.setFont("Trebuchet18")
            render.drawSimpleText(0, 32, "Progress: " .. res.Name, TEXT_ALIGN.CENTER, TEXT_ALIGN.TOP)
            render.drawSimpleText(0, 54, "Remaining: " .. math.ceil(currentUnits), TEXT_ALIGN.CENTER, TEXT_ALIGN.TOP)
        end)
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
ents.register(CraftingTable, "base_machine")

