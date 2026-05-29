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

local drillMat = "models/props_canal/canal_bridge_railing_01a"
local mdl = model.new("augerdrill", hitbox {
    vertex {"cube", Vector(-8, 36, 96), Angle(-60, 0, 0), Vector(35, 118, 5)},
    vertex {"cube", Vector(-8, -36, 96), Angle(60, 0, 0), Vector(35, 118, 5)},
    vertex {"cube", Vector(0, 0, 128), Angle(0, 0, 0), Vector(30, 30, 24)},
    mass = 2000,
    visible = false
})
    :add("base", part {
        holo { Vector(-8, -36, 96), Angle(30, 90, 0), "models/props_c17/handrail04_short.mdl", Vector(6, 2, 6) },
        holo { Vector(-8, 36, 96), Angle(-30, 90, 0), "models/props_c17/handrail04_short.mdl", Vector(6, 2, 6) },
        holo { Vector(0, 0, 128), Angle(0, 0, 0), "models/holograms/cube.mdl", Vector(4.8, 4.8, 4), material = "models/props_c17/metalladder001" },
        holo { Vector(0, 0, 86), Angle(0, 0, 0), "models/holograms/hq_cylinder.mdl", Vector(2.5, 2.5, 3), material = "models/props_c17/metalladder001" },
    })
    :add("drill", part {
        rig(),
        holo { Vector(0, 0, 56), Angle(90, 0, 0), "models/xqm/CoasterTrack/special_full_corkscrew_right_1.mdl", Vector(0.01, 0.18, 0.18), material = drillMat },
        holo { Vector(0, 0, 32), Angle(90, 0, 0), "models/xqm/CoasterTrack/special_full_corkscrew_right_1.mdl", Vector(0.01, 0.18, 0.18), material = drillMat  },
        holo { Vector(0, 0, 8), Angle(90, 0, 0), "models/xqm/CoasterTrack/special_full_corkscrew_right_1.mdl", Vector(0.01, 0.18, 0.18), material = drillMat  },
        holo { Vector(0, 0, -16), Angle(90, 0, 0), "models/xqm/CoasterTrack/special_full_corkscrew_right_1.mdl", Vector(0.01, 0.18, 0.18), material = drillMat },
    })


if CLIENT then
    bicons.registerModel("augerdrill", function()
        return mdl:create()
    end, Vector(-240, 128, 128), Angle(10, -30, 0))
end


---@class AugerDrill: BaseMachine
---@field nextEffect number Next effect. Relative to curtime
---@field nextDecal number Next decal. Relative to curtime
---@field effect BEffect
local AugerDrill = {}
AugerDrill.Identifier = "augerdrill"
AugerDrill.Name = "Auger Drill"
AugerDrill.Model = function()
    return mdl:create()
end
AugerDrill.hooks = {}

---@type table<string, ResourceInput>
AugerDrill.Inputs = {}
AugerDrill.Inputs.power = { affectedByGrade = true, type = "power", maxCount = 400 }

---@type table<string, ResourceOutput>
AugerDrill.Outputs = {}
AugerDrill.Outputs.resource = { affectedByGrade = true, maxCount = 100 }

AugerDrill.OutputOffset = Vector(30, 0, 10)

AugerDrill.WorkCooldown = 1

AugerDrill.Display = true
AugerDrill.DisplayOffset = Vector(30, 0, 148)

if SERVER then
    function AugerDrill:machineInitialize()
        self.nextDecal = 0
        self.nextEffect = 0
    end

    function AugerDrill:turnOn(ply)
        if self:getInput("power") < 1 then return end
        local found = self:findDeposit()
        if found and found.amount then
            self:install()
            return true
        else
            BMod.hintMessage(ply, "You should place it on deposit with solid resource. Deposit can be found with GroundScanner")
        end
    end

    function AugerDrill:turnOff(_) end

    ---[SERVER] Work function. To drill deposit
    function AugerDrill:work(cur)
        local dep = self:getDeposit()
        if !dep then return false end
        local power = self:getInput("power")
        if power <= 0 then return false end
        self:consumeInput("power", 0.8)
        self:addToOutput("resource", 1, dep.resource)
        if self.nextEffect < cur then
            local pos = self.ent:localToWorld(Vector(8, 2, 0))
            self.effect = beff.create("dirt")
            self.effect:setOrigin(pos)
            self.effect:play()
            if self.nextDecal < cur then
                trace.decal("Unburrow", pos + Vector(0, 0, 32), pos - Vector(0, 0, 1))
                self.nextDecal = cur + 5
            end
            self.nextEffect = cur + 0.1
        end
    end
end

if CLIENT then
    ---@class bgui
    local bgui = bgui

    function AugerDrill:drawDisplay()
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

    ---[CLIENT] Drill animation
    ---@param self AugerDrill
    function AugerDrill.hooks.RenderOffscreen(self)
        if self:isTurnedOn() then
            local ent = self.ent:getBoneEntity(self.ent:lookupBone("drill"))
            ent:setLocalAngles(ent:getLocalAngles() + Angle(0, -5, 0))
        end
    end
end

ents.register(AugerDrill, "base_machine")

