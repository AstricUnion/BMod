---@class ents
local ents = ents

---@class deposit
local deposit = deposit

---@class resource
local resource = resource

---@class beff
local beff = beff

---@class model
local model = model
local hitbox = model.hitbox
local vertex = model.vertex
local part = model.part
local rig = model.rig
local holo = model.holo

local mdl = model.new("solar_panel", hitbox {
    vertex {"wedge", Vector(0, 0, 7.5), Angle(0, 0, 0), Vector(30, 46, 15)},
    mass = 100
})
    :add("base", part {
        holo { Vector(0, 0, 8), Angle(90, 0, 0), "models/props_rooftop/scaffolding01a.mdl", Vector(0.4, 0.4, 0.4) },
        holo { Vector(1, 0, 9), Angle(30, 0, 0), "models/hunter/plates/plate16x24.mdl", Vector(0.07, 0.09, 0.2), color = Color(100, 100, 255), material = "models/XQM/boxfull_diffuse" },
        holo { Vector(-16, 0, 3), Angle(0, 0, 0), "models/props_lab/reciever_cart.mdl", Vector(0.6, 0.7, 0.3) },
    })

if CLIENT then
    bicons.registerModel("solar_panel", function()
        return mdl:create()
    end, Vector(-240, 128, 128), Angle(10, -30, 0))
end

---@class SolarPanel: BaseMachine
local SolarPanel = {}
SolarPanel.Identifier = "solar_panel"
SolarPanel.Name = "Solar Panel"
SolarPanel.Model = function()
    return mdl:create()
end
SolarPanel.hooks = {}

---@type table<string, ResourceInput>
SolarPanel.Inputs = {}

---@type table<string, ResourceOutput>
SolarPanel.Outputs = {}
SolarPanel.Outputs.power = { affectedByGrade = true, type = "power", maxCount = 100 }

SolarPanel.OutputOffset = Vector(0, 30, 10)

SolarPanel.WorkCooldown = 5
SolarPanel.FontSize = 24

SolarPanel.Display = true
SolarPanel.DisplayOffset = Vector(-32, 12, 16)
SolarPanel.DisplayAngle = Angle(0, 180, 0)


if SERVER then
    function SolarPanel:machineInitialize() end

    ---[SERVER] Get light alignment
    ---@return number
    function SolarPanel:getLightAlignment()
        local lightEnt = find.byClass("light_environment")[1]
        if isValid(lightEnt) then
            ---@cast lightEnt Entity
            local sunVec = -(lightEnt:getAngles()):getForward()
            local ourFacingVec = self.ent:getUp()
            local angleDifference = -math.deg(math.asin(sunVec:dot(ourFacingVec)))
            return 1 - (angleDifference + 90) / 180
        else
            local sunEnt = find.byClass("env_sun")[1]
            if sunEnt then
                ---@cast lightEnt Entity
                local ang = sunEnt:getAngles():setP(0):setR(0)
                local sunVec= ang:getForward()
                local ourFacingVec = self.ent:getUp()
                local angleDifference= -math.deg(math.asin(sunVec:dot(ourFacingVec)))
                return (angleDifference + 90) / 180
            end
        end
        return 0.5
    end

    local mapModifiers = {
        { substrings = {"cloud"}, modifier = 0.5 },
        { substrings = {"storm", "shady", "marsh"}, modifier = 0.2 },
        { substrings = {"night"}, modifier = 0 }
    }

    function SolarPanel:checkSky()
        local skyMod, mapName = 1, string.lower(game.getMap())
        for _, mods in ipairs(mapModifiers) do
            for _, word in ipairs(mods.substrings) do
                if string.find(mapName, word) then
                    skyMod = mods.modifier
                    break
                end
            end
        end
        local hitAmount, startPos = 0, self.ent:obbCenterW()
        for i = 1, 5 do
            for j = 1, 10 do
                local angs = self.ent:localToWorldAngles(Angle(230 - j*2, 130 + i*16, 0))
                local dir = angs:getForward()
                local tr = trace.line(startPos, startPos + dir * 9e9, {self.ent}, MASK.SOLID)
                if (tr.HitSky) then
                    hitAmount = hitAmount + 0.02
                end
            end
        end
        return hitAmount * skyMod
    end

    ---[SERVER] Check and update panel efficiency
    function SolarPanel:checkEfficiency()
        if self.ent:getWaterLevel() >= 2 then return 0 end
        local sky = self:checkSky()
        local alignment = self:getLightAlignment()
        local efficiency = sky * alignment
        self:setEfficiency(efficiency)
        return efficiency
    end

    function SolarPanel:turnOn(ply)
        local eff = self:checkEfficiency()
        if eff <= 0 then return end
        return true
    end

    ---[SERVER] Work function. To make power
    function SolarPanel:work(cur)
        local eff = self:checkEfficiency()
        if eff <= 0 then return false end
        self:addToOutput("power", math.round(eff, 2))
    end

    ---[SERVER] Set solar panel efficiency
    function SolarPanel:setEfficiency(efficiency)
        self:setNWVar("efficiency", efficiency)
    end
end

if CLIENT then
    ---@class bgui
    local bgui = bgui

    function SolarPanel:drawDisplay()
        if !self:isTurnedOn() then return end
        local fields = {}
        fields[#fields+1] = {"Progress", self:getOutput("power"), 100, false, true}
        fields[#fields+1] = {"Efficiency", self:getEfficiency(), 1, false, true}
        self:drawFields(0, 0, fields, true, 16)
    end
end

---[SHARED] Get solar panel efficiency
function SolarPanel:getEfficiency()
    return self:getNWVar("efficiency", 0)
end

ents.register(SolarPanel, "base_machine")

