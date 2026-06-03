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

local mdl = model.new("oil_rig", part {
    hitbox {
        vertex {"cube", Vector(0, 0, 42), Angle(0, 0, 0), Vector(108, 108, 3)},
        vertex {"cube", Vector(0, 0, 83), Angle(0, 0, 0), Vector(42, 42, 41)},
        vertex {"cylinder", Vector(0, 81, 10), Angle(0, 90, 0), Vector(26, 26, 96)},
        vertex {"cylinder", Vector(0, -81, 10), Angle(0, 90, 0), Vector(26, 26, 96)},
        mass = 4000,
        buoyancyRatio = 0.6,
        visible = false,
        material = "Metal"
    },
    holo { Vector(0, 0, 42), Angle(0, 90, 0), "models/holograms/hq_stube_thick.mdl", Vector(18, 18, 0.5), material = "models/props/generated_prop/metalgrate014a" },
    holo { Vector(0, 0, 42), Angle(0, 90, 0), "models/holograms/hq_stube_thick.mdl", Vector(9, 9, 0.5), material = "models/props/generated_prop/metalgrate014a" },
    holo { Vector(0, 0, 270), Angle(0, 0, 0), "models/props_wasteland/powertower01.mdl", Vector(0.2, 0.2, 0.3), clips = {{Vector(0, 0, -360), Vector(0, 0, -1)}} },
    holo { Vector(0, 0, 168), Angle(0, 0, 0), "models/mechanics/robotics/stand.mdl", Vector(0.4, 0.4, 0.25), material = {[1] = "phoenix_storms/roadside", [2] = "phoenix_storms/roadside"}, submaterial = 1 },
    holo { Vector(42, 0, 67), Angle(0, 0, 0), "models/props_silo/consolepanelloadingbay.mdl", Vector(1, 1, 1), subcolor = 1 },
    holo { Vector(36, 0, 96), Angle(0, 0, 0), "models/props/cs_office/tv_plasma.mdl", Vector(0.8, 0.8, 0.8) },
    holo { Vector(-108, -81, 10), Angle(90, 0, 0), "models/props_c17/canister_propane01a.mdl", Vector(1.8, 1.8, 3.5), subcolor = 1, clips = {{Vector(0, 0, 59.64), Vector(0, 0, -1)}} },
    holo { Vector(-108, 81, 10), Angle(90, 0, 0), "models/props_c17/canister_propane01a.mdl", Vector(1.8, 1.8, 3.5), subcolor = 1, clips = {{Vector(0, 0, 59.64), Vector(0, 0, -1)}} },
    holo { Vector(0, 0, 174), Angle(0, 0, 0), "models/props_rooftop/roof_vent002.mdl", Vector(0.8, 0.8, 0.5), submaterial = 1 },
})


-- if CLIENT then
--     bicons.registerModel("augerdrill", function()
--         return mdl:create()
--     end, Vector(-240, 128, 128), Angle(10, -30, 0))
-- end


---@class OilRig: BaseMachine
---@field decorativeRope Constraint
local OilRig = {}
OilRig.Identifier = "oil_rig"
OilRig.Name = "Oil Rig"
OilRig.Model = function()
    return mdl:create()
end
OilRig.hooks = {}

---@type table<string, ResourceInput>
OilRig.Inputs = {}
OilRig.Inputs.power = { affectedByGrade = true, type = "power", maxCount = 400 }

---@type table<string, ResourceOutput>
OilRig.Outputs = {}
OilRig.Outputs.resource = { affectedByGrade = true, maxCount = 100 }

OilRig.OutputOffset = Vector(86, 56, 64)

OilRig.WorkSound = "ambient/machines/pump_loop_1.wav"
OilRig.WorkCooldown = 1

OilRig.FontSize = 24
OilRig.Display = true
OilRig.DisplayOffset = Vector(40, 0, 120)
OilRig.DisplayAngle = Angle(0, 0, 0)

OilRig.InstallOffset = Vector(0, 0, -8)
OilRig.Anchorage = 2000
OilRig.MaxDurability = 1200

if SERVER then
    function OilRig:turnOn(ply)
        if self:getInput("power") < 1 then return end
        local found = self:findDeposit()
        if found and found.resource == "oil" and found.underwater then
            self:install(true)
            local pos = self.ent:getPos()
            local tr = trace.line(pos, pos - Vector(0, 0, 32768), {self.ent}, MASK.SOLID_BRUSHONLY)
            self.decorativeRope = constraint.rope(0, self.ent, game.getWorld(), 0, 0, Vector(0, 0, 172), tr.HitPos, 0, 0, 0, 5)
            self.effect = beff.create("oilsmoke")
            self.effect:setEntity(self.ent)
            self.effect:setOrigin(Vector(0, 0, 196))
            self.effect:play()
            return true
        else
            BMod.hintMessage(ply, "You should place it above underwater deposit with liquid resource, like oil. Deposit can be found with GroundScanner")
        end
    end

    function OilRig:turnOff()
        if self.decorativeRope then
            self.decorativeRope:remove()
        end
        if isValid(self.effect) then
            self.effect:destroy()
        end
        self:uninstall()
    end

    ---[SERVER] Work function. To pump deposit
    function OilRig:work()
        local dep = self:getDeposit()
        if !dep then return false end
        local power = self:getInput("power")
        if power <= 0 then return false end
        self:consumeInput("power", 0.5)
        self:addToOutput("resource", 1, dep.resource)
    end
end

if CLIENT then
    ---@class bgui
    local bgui = bgui

    function OilRig:machineInitialize()
        self.animProcess = 0
        self.animSpeed = 0
    end

    function OilRig:drawDisplay()
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
    ---@param self OilRig
    function OilRig.hooks.RenderOffscreen(self)
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

ents.register(OilRig, "base_machine")

