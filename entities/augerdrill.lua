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

local mdl = model.create(hitbox {
    vertex {"cube", Vector(-8, 36, 96), Angle(-60, 0, 0), Vector(35, 118, 5)},
    vertex {"cube", Vector(-8, -36, 96), Angle(60, 0, 0), Vector(35, 118, 5)},
    vertex {"cube", Vector(0, 0, 128), Angle(0, 0, 0), Vector(30, 30, 24)},
    mass = 2000,
    visible = false
})
mdl:add("base", part {
    holo { Vector(-8, -36, 96), Angle(30, 90, 0), "models/props_c17/handrail04_short.mdl", Vector(6, 2, 6) },
    holo { Vector(-8, 36, 96), Angle(-30, 90, 0), "models/props_c17/handrail04_short.mdl", Vector(6, 2, 6) },
    holo { Vector(0, 0, 128), Angle(0, 0, 0), "models/holograms/cube.mdl", Vector(4.8, 4.8, 4), material = "models/props_c17/metalladder001" },
    holo { Vector(0, 0, 86), Angle(0, 0, 0), "models/holograms/hq_cylinder.mdl", Vector(2, 2, 3), material = "models/props_c17/metalladder001" },
})

local drillMat = "models/props_canal/canal_bridge_railing_01a"
local drill = model.create(part {
    rig(),
    holo { Vector(0, 0, 56), Angle(90, 0, 0), "models/xqm/CoasterTrack/special_full_corkscrew_right_1.mdl", Vector(0.01, 0.15, 0.15), material = drillMat },
    holo { Vector(0, 0, 32), Angle(90, 0, 0), "models/xqm/CoasterTrack/special_full_corkscrew_right_1.mdl", Vector(0.01, 0.15, 0.15), material = drillMat  },
    holo { Vector(0, 0, 8), Angle(90, 0, 0), "models/xqm/CoasterTrack/special_full_corkscrew_right_1.mdl", Vector(0.01, 0.15, 0.15), material = drillMat  },
    holo { Vector(0, 0, -16), Angle(90, 0, 0), "models/xqm/CoasterTrack/special_full_corkscrew_right_1.mdl", Vector(0.01, 0.15, 0.15), material = drillMat },
})


---@class AugerDrill: BaseMachine
---@field toScan Deposit[]
---@field nextEffect number Next effect. Relative to curtime
---@field nextDecal number Next decal. Relative to curtime
---@field effect BEffect
---@field drill Entity
local AugerDrill = {}
AugerDrill.Identifier = "augerdrill"
AugerDrill.Name = "Auger Drill"
AugerDrill.Model = function()
    return mdl:create().bones.origin
end
AugerDrill.hooks = {}

---@type table<string, ResourceInput>
AugerDrill.Inputs = {}
AugerDrill.Inputs.power = { type = "power", maxCount = 100 }

---@type table<string, ResourceOutput>
AugerDrill.Outputs = {}
AugerDrill.Outputs.resource = { maxCount = 100 }

AugerDrill.OutputOffset = Vector(30, 0, 10)

AugerDrill.WorkCooldown = 1

if SERVER then
    function AugerDrill:initialize()
        self.ent:setMass(25)
        self.drill = drill:create().bones.origin
        self.drill:setPos(self.ent:getPos())
        self.drill:setAngles(self.ent:getAngles())
        self.drill:setParent(self.ent)
        self:setInput("power", 100)
        self.nextDecal = 0
        self.nextEffect = 0
    end

    function AugerDrill:turnOn(ply)
        if self:getInput("power") < 1 then return end
        local pos = self.ent:getPos()
        local tr = trace.line(pos, pos - Vector(0, 0, 32768), {self.ent}, MASK.SOLID_BRUSHONLY)
        if !tr.Hit then return end
        self:findDeposit()
        if self:findDeposit() then
            self:install()
            self.drill:setLocalAngularVelocity(Angle(0, -400, 0))
            return true
        else
            BMod.hintMessage(ply, "You should place it on deposit with solid resource. Deposit can be found with GroundScanner")
        end
    end

    function AugerDrill:turnOff(_)
        self.drill:setLocalAngularVelocity(Angle(0, 0, 0))
    end

    ---[SERVER] Work function. To drill deposit
    function AugerDrill:work()
        local cur = timer.curtime()
        local dep = self:getDeposit()
        if !dep then return false end
        local power = self:getInput("power")
        if power <= 0 then
            return false
        end
        local count = self:getOutput("resource")
        self:setInput("power", power - 0.2)
        self:setOutput("resource", count + 1, dep.resource)
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

    ---[CLIENT] Draw info about this drill within 3D2D
    ---@param self AugerDrill
    function AugerDrill.hooks.PostDrawTranslucentRenderables(self)
        BMod.displayEnt(self.ent, Vector(30, 0, 128), Angle(0, 0, 0), function()
            render.setFont("Trebuchet24")
            render.drawSimpleText(0, 0, string.format("Power: %s", math.round(self:getInput("power"))), TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
            local count, resId = self:getOutput("resource")
            if resId then
                local res = ents.registered[resId]
                render.drawSimpleText(0, 24, res.Name, TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
                render.drawSimpleText(0, 48, count .. "%", TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
            end
        end)
    end
end

ents.register(AugerDrill, "base_machine")

