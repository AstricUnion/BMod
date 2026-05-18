
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
---@field craftMenu BPanel
local CraftingTable = {}
CraftingTable.Identifier = "crafting_table"
CraftingTable.Name = "Crafting table"
CraftingTable.Model = function()
    return mdl:create().bones.origin
end
CraftingTable.hooks = {}

CraftingTable.WorkCooldown = 1
CraftingTable.OutputOffset = Vector(0, -46, 50)
CraftingTable.FontSize = 24

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
    function CraftingTable:machineInitialize()
        local pr = self.ent
        self.nextGasParticle = 0
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
                timer.simple(0.05, function()
                    local res = resource.salvage(ent)
                    local pos = ent:getPos()
                    ent:remove()
                    local angs = pr:getAngles()
                    local eff = beff.create("craft_effect")
                    eff:setOrigin(pos)
                    eff:setScale(0.6)
                    eff:play()
                    timer.simple(0.5, function()
                        print(res)
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
    function CraftingTable:onUse(ply, isWalking)
        if isWalking then return end
        local fuel = self:getInput("fuel")
        if fuel < 1 then
            BMod.errorMessage(ply, "You can't craft on empty crafting table! Use coal, wood or other solid fuel")
            return
        end
        net.start("BModCraftingTableOpen")
            net.writeEntity(self.ent)
        net.send(ply)
    end


    function CraftingTable:turnOn() return true end

    ---[SERVER] Stop smelting and produce resources
    function CraftingTable:turnOff()
        if self.smeltingEffect then
            self.smeltingEffect:destroy()
            self.smeltingEffect = nil
        end
        self:takeInputs()
    end


    ---[SERVER] Hook on setting input. Smelting to turn crafting table on
    function CraftingTable:onSetInput(id, count, type)
        if id == "smelting" and count > 0 then
            self:turnOnInternal()
        end
    end

    ---[SERVER] Smelting logic
    function CraftingTable:work()
        local cur = timer.curtime()
        local offsetPos = self.ent:localToWorld(self.OutputOffset)
        local currentUnits, resToSmelt = self:getInput("smelting")
        if !resToSmelt then return false end
        local fuel = self:getInput("fuel")
        local res = ents.registered[resToSmelt]
        if !res then return end
        ---@cast res Resource
        for id, multiplier in pairs(res.SmeltResource) do
            local currentProduce = self:getCustomProduce(id)
            self:setCustomProduce(id, currentProduce + 0.8 * multiplier)
        end
        if !self.smeltingEffect then
            local eff = beff.create("oilsmoke")
            eff:setOrigin(self.OutputOffset - Vector(0, 0, 30))
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
        self:consumeInput("smelting", 0.5, resToSmelt)
        self:consumeInput("fuel", 1)
        if currentUnits - 0.5 <= 0 or fuel - 1 < 1 then return false end
    end
end

if CLIENT then
    ---@class bgui
    local bgui = bgui


    function CraftingTable:machineInitialize()
        self.ent.craftOffset = Vector(5, 0, 60)
    end

    ---[CLIENT] Draw info about this resource within 3D2D
    ---@param self CraftingTable
    function CraftingTable.hooks.PostDrawTranslucentRenderables(self)
        BMod.displayEnt(self.ent, Vector(10.5, -50, 18), Angle(), function()
            local fields = {}
            fields[#fields+1] = {"Fuel", self:getInput("fuel"), 100, false, true, true}
            local currentUnits, resToSmelt = self:getInput("smelting")
            if resToSmelt then
                local res = ents.registered[resToSmelt]
                if res then
                    fields[#fields+1] = {"Progress", res.Name, 100, false, false}
                    fields[#fields+1] = {"Remaining", currentUnits, 50, true, true}
                end
            end
            self:drawFields(0, 0, fields, false, 8)
        end)
    end

    net.receive("BModCraftingTableOpen", function()
        if !render.isHUDActive() then return end
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

