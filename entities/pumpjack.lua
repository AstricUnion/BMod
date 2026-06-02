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
local holo = model.holo
local rig = model.rig

local metalMat = "models/props_c17/furnituremetal002a"
local colorMat = "models/props_pipes/pipemetal001a"

local mdl = model.new("pumpjack", part {
    hitbox {
        vertex {"cube", Vector(0, 0, 42), Angle(0, 0, 0), Vector(64, 36, 54)},
        mass = 3000,
        material = "Metal",
        visible = false
    },
    holo { Vector(0, 0, -6), Angle(0, 90, 0), "models/props_vents/vent_medium_straight001.mdl", Vector(3, 1.2, 1.2), clips = {{Vector(0, 0, 8.33), Vector(0, 0, -1)}}, material = metalMat },
    holo { Vector(-8, 0, 16), Angle(90, 0, 0), "models/props_c17/light_decklight01_off.mdl", Vector(4, 2, 3), material = metalMat },
    holo { Vector(-16, 0, 16), Angle(90, 0, 0), "models/props_c17/light_decklight01_off.mdl", Vector(5, 1, 3), material = metalMat },
    holo { Vector(-8, 0, 38), Angle(0, 0, 0), "models/props_lab/rotato.mdl", Vector(5, 14, 5) },
    holo { Vector(36, 0, -8), Angle(0, -45, 0), "models/phxtended/trieq1x1x2.mdl", Vector(0.9, 0.9, 1.4) },
})
    :add("weight", part {
        rig(Vector(-8, 0, 38)),
        holo { Vector(-8, 28, 38), Angle(0, 90, 90), "models/props_debris/wood_board06a.mdl", Vector(1, 1, 1), material = metalMat },
        holo { Vector(32, 28, 38), Angle(180, 180, 90), "models/props_lab/walllight001a.mdl", Vector(2, 1.8, 0.5), material = colorMat, subcolor = 1 },
        holo { Vector(-8, -28, 38), Angle(0, 90, 90), "models/props_debris/wood_board06a.mdl", Vector(1, 1, 1), material = metalMat },
        holo { Vector(32, -28, 38), Angle(180, 180, 90), "models/props_lab/walllight001a.mdl", Vector(2, 1.8, 0.5), material = colorMat, subcolor = 1 },
    })
    :add("horsehead", part {
        rig(Vector(42, 0, 118)),
        holo { Vector(48, 0, 118), Angle(0, 0, 0), "models/props_junk/iBeam01a.mdl", Vector(0.8, 1, 1.5), material = metalMat },
        holo { Vector(148, 0, 118), Angle(0, 0, 90), "models/props_lab/walllight001a.mdl", Vector(4, 4, 2), material = colorMat, subcolor = 1 },
    })
    :add("weight", "pitman", part {
        rig(Vector(-26, 0, 0)),
        holo { Vector(-24, 0, 56), Angle(180, 0, 0), "models/props_wasteland/light_spotlight02_base.mdl", Vector(3, 5, 12), subcolor = 1 }
    })


-- if CLIENT then
--     bicons.registerModel("augerdrill", function()
--         return mdl:create()
--     end, Vector(-240, 128, 128), Angle(10, -30, 0))
-- end


---@class PumpJack: BaseMachine
local PumpJack = {}
PumpJack.Identifier = "pumpjack"
PumpJack.Name = "Pumpjack"
PumpJack.Model = function()
    return mdl:create()
end
PumpJack.hooks = {}

---@type table<string, ResourceInput>
PumpJack.Inputs = {}
PumpJack.Inputs.power = { affectedByGrade = true, type = "power", maxCount = 400 }

---@type table<string, ResourceOutput>
PumpJack.Outputs = {}
PumpJack.Outputs.resource = { affectedByGrade = true, maxCount = 100 }

PumpJack.OutputOffset = Vector(108, 0, 10)

PumpJack.WorkSound = "ambient/machines/pump_loop_1.wav"
PumpJack.WorkCooldown = 1

PumpJack.FontSize = 24
PumpJack.Display = true
PumpJack.DisplayOffset = Vector(-32, 0, 42)
PumpJack.DisplayAngle = Angle(0, 180, -30)

PumpJack.Anchorage = 2000
PumpJack.MaxDurability = 1200

if SERVER then
    function PumpJack:turnOn(ply)
        if self:getInput("power") < 1 then return end
        local found = self:findDeposit()
        if found and (found.resource == "water" or found.resource == "oil") then
            self:install()
            return true
        else
            BMod.hintMessage(ply, "You should place it on deposit with liquid resource, like water or oil. Deposit can be found with GroundScanner")
        end
    end

    ---[SERVER] Work function. To pump deposit
    function PumpJack:work()
        local dep = self:getDeposit()
        if !dep then return false end
        local power = self:getInput("power")
        if power <= 0 then return false end
        self:consumeInput("power", 0.5)
        self:addToOutput("resource", (dep.rate or 1), dep.resource)
    end
end

if CLIENT then
    ---@class bgui
    local bgui = bgui

    function PumpJack:machineInitialize()
        self.animProcess = 0
        self.animSpeed = 0
    end

    function PumpJack:drawDisplay()
        local fields = {}
        fields[#fields+1] = {"Power", self:getInput("power"), 400, false, true}
        -- render.drawSimpleText(0, 0, string.format("Power: %s", math.round(self:getInput("power"))), TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
        local count, resId = self:getOutput("resource")
        if resId then
            local res = ents.registered[resId]
            fields[#fields+1] = {"Extracting", res.Name}
            fields[#fields+1] = {"Progress", count, 100, false, true}
        end
        self:drawFields(0, 0, fields)
    end


    ---[CLIENT] Pump animation
    ---@param self PumpJack
    function PumpJack.hooks.RenderOffscreen(self)
        if !self.ent.getBoneEntity then return end
        local frameTime = game.serverFrameTime()
        if !self:isTurnedOn() then
            self.animSpeed = math.max(self.animSpeed - frameTime / 2, 0)
        else
            self.animSpeed = math.min(self.animSpeed + frameTime / 2, 1)
        end
        if self.animSpeed == 0 then return end
        local horsehead = self.ent:getBoneEntity(self.ent:lookupBone("horsehead"))
        local weight = self.ent:getBoneEntity(self.ent:lookupBone("weight"))
        local pitman = self.ent:getBoneEntity(self.ent:lookupBone("pitman"))
        if !(isValid(horsehead) and isValid(pitman) and isValid(weight)) then return end
        local process = self.animProcess
        local ang = process * 42
        local sin = math.sin(math.rad(ang))
        -- i don't remember i wrote this part
        local horseheadAng = (20 * sin)
        local horseheadAngRad = math.rad(horseheadAng)
        local weightAng = ang
        local weightAngRad = math.rad(weightAng)
        local pos1 = (Vector(math.sin(horseheadAngRad), math.cos(horseheadAngRad), 0) * -58) + horsehead:getLocalPos()
        local pos2 = (Vector(math.sin(weightAngRad), math.cos(weightAngRad), 0) * -26) + weight:getLocalPos()
        local pitmanAng = (pos1 - pos2):getAngle().y
        horsehead:setLocalAngles(Angle(horseheadAng, 0, 0))
        weight:setLocalAngles(Angle(weightAng, 0, 0))
        pitman:setLocalAngles(Angle(pitmanAng - weightAng + 32, 0, 0))
        self.animProcess = process + frameTime * self.animSpeed
    end
end

ents.register(PumpJack, "base_machine")

