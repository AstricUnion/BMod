
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

local mdl = model.new("smelting_furnace", part {
    hitbox {
        vertex {"cube", Vector(16, 0, 48), nil, Vector(20, 28, 48)},
        vertex {"cylinder", Vector(-16, 8, 36), nil, Vector(16, 16, 36)},
        mass = 750,
    },
    holo { Vector(16, 0, 0), Angle(0, 0, 0), "models/props_forest/furnace01.mdl", Vector(1.2, 1.2, 1.2) },
    holo { Vector(-16, 8, 0), Angle(0, 15, 0), "models/props_citizen_tech/firetrap_propanecanister01b.mdl", Vector(1, 1, 1) },
})
    :add("light", holo { Vector(26, 0, 72), Angle(90, 0, 0), "models/holograms/plane.mdl", Vector(1, 3.5, 0.8), noLight = true, color = Color(0, 0, 0) })


---@class SmeltingFurnace: BaseMachine
---@field nextThink number
---@field nextGasParticle number
---@field smeltingEffect BEffect
---@field light Light
local SmeltingFurnace = {}
SmeltingFurnace.Identifier = "smelting_furnace"
SmeltingFurnace.Name = "Smelting Furnace"
SmeltingFurnace.Model = function()
    return mdl:create()
end
SmeltingFurnace.hooks = {}

SmeltingFurnace.WorkCooldown = 1
SmeltingFurnace.OutputOffset = Vector(72, 0, 32)
SmeltingFurnace.FontSize = 24

---@type table<string, ResourceInput>
SmeltingFurnace.Inputs = {}
SmeltingFurnace.Inputs.power = { type = "power", maxCount = 500, affectedByGrade = true, gradePower = 1.5 }
SmeltingFurnace.Inputs.smelting = { maxCount = 100, affectedByGrade = true, callback = function(self, res, wantToTake)
    if !res.SmeltResource then return true end
end }

SmeltingFurnace.Display = true
SmeltingFurnace.DisplayOffset = Vector(35, 0, 64)

SmeltingFurnace.MaxDurability = 600


if SERVER then
    function SmeltingFurnace:machineInitialize()
        self.nextGas = 0
    end


    function SmeltingFurnace:turnOn()
        local currentUnits, resToSmelt = self:getInput("smelting")
        if !resToSmelt or currentUnits < 1 then return false end
        local power = self:getInput("power")
        if power <= 0 then return false end
        return true
    end

    ---[SERVER] Stop smelting and produce resources
    function SmeltingFurnace:turnOff()
        if self.smeltingEffect then
            self.smeltingEffect:destroy()
            self.smeltingEffect = nil
        end
        self:takeInputs()
    end

    ---[SERVER] Smelting logic
    function SmeltingFurnace:work(cur)
        local currentUnits, resToSmelt = self:getInput("smelting")
        if !resToSmelt or currentUnits < 1 then return false end
        local power = self:getInput("power")
        if power <= 0 then return false end
        local res = ents.registered[resToSmelt]
        if !res then return false end
        ---@cast res Resource
        for id, multiplier in pairs(res.SmeltResource) do
            local currentProduce = self:getCustomProduce(id)
            self:setCustomProduce(id, currentProduce + multiplier)
        end
        if !self.smeltingEffect then
            local eff = beff.create("oilsmoke")
            eff:setOrigin(Vector(9, 14, 146))
            eff:setEntity(self.ent)
            eff:play()
            self.smeltingEffect = eff
        end
        if self.nextGas <= cur then
            local par = gas.create("carbonmonoxide")
            par:setPos(self.ent:localToWorld(Vector(8, 16, 186)))
            par:setVelocity(gas.randVector() * 50 * Vector(1, 1, 2))
            par:spawn()
            self.nextGas = cur + 10
        end
        self:consumeInput("smelting", 1, resToSmelt)
        self:consumeInput("power", 1.5)
    end
end

if CLIENT then
    ---@class bgui
    local bgui = bgui

    function SmeltingFurnace:machineInitialize()
        self.animProcess = 0
        self.light = light.create(self.ent:getPos(), 128, 5, Color(255, 191, 83))
    end

    function SmeltingFurnace:drawDisplay()
        local fields1, fields2 = {}, {}
        fields1[#fields1+1] = {"Power", self:getInput("power"), 500, false, true}
        local currentUnits, resToSmelt = self:getInput("smelting")
        if resToSmelt then
            local res = ents.registered[resToSmelt]
            if res then
                fields1[#fields1+1] = {"Smelting", res.Name}
                fields2[#fields2+1] = {"Progress", 100 - currentUnits, 100, false, true}
                fields2[#fields2+1] = {"Remaining", currentUnits, 100, false, false}
            end
        end
        self:drawFields(-64, 0, fields1, false, 8)
        self:drawFields(64, 0, fields2, false, 8)
    end

    ---[CLIENT] Pump animation
    ---@param self SmeltingFurnace
    function SmeltingFurnace.hooks.RenderOffscreen(self)
        if !self.ent.getBoneEntity then return end
        local frameTime = game.serverFrameTime()
        local light = self.ent:getBoneEntity(self.ent:lookupBone("light"))
        if !isValid(light) then return end
        if !self:isTurnedOn() then
            self.animProcess = 0
            light:setColor(Color(0, 0, 0))
            return
        end
        local process = self.animProcess
        local ang = process * 128
        local sin = (((math.sin(math.rad(ang))) + 1) / 8) + 0.75
        local col = Color(255, 191, 83) * sin
        light:setColor(col)
        self.animProcess = process + frameTime
        if self.light then
            self.light:setPos(light:localToWorld(Vector(0, 0, 12)))
            self.light:setColor(col)
            pcall(self.light.draw, self.light)
        end
    end
end

ents.register(SmeltingFurnace, "base_machine")

