
-- models/props_silo/launch_button.mdl

---@class ents
local ents = ents

---@class deposit
local deposit = deposit

---@class resource
local resource = resource

---@class GroundScanner: BaseMachine
---@field toScan Deposit[]
---@field nextThink number Next think. Relative to curtime
local GroundScanner = {}
GroundScanner.Identifier = "groundscanner"
GroundScanner.Name = "Resource Crate"
GroundScanner.Model = "models/props_silo/launch_button.mdl"
GroundScanner.hooks = {}
---@type table<string, ResourceInput>
GroundScanner.Inputs = {}
GroundScanner.Inputs.power = { type = "power", maxCount = 100 }

local unitsInMeter = 39.37008
local foundRadius = 50 * unitsInMeter

if SERVER then
    function GroundScanner:machineInitialize()
        self.ent:setMass(25)
        self.nextThink = 0
    end

    function GroundScanner:turnOn()
        if self:getInput("power") < 1 then return end
        local entPos = self.ent:getPos()
        local result = table.copy(deposit.findInSphere(entPos, foundRadius))
        table.sort(result, function(a, b)
            return entPos:getDistance(a.position) < entPos:getDistance(b.position)
        end)
        for _, v in ipairs(result) do
            local angs = self.ent:getAngles()
            angs = angs:rotateAroundAxis(angs:getUp(), -90)
            local pos = worldToLocal(v.position, Angle(), entPos, angs)
            v.position = pos
        end
        self.toScan = result
        self:setNWVar("scanned", {})
        return true
    end

    function GroundScanner:turnOff()
        self:setNWVar("scanned", nil)
    end

    ---[SERVER] Think function. To scan deposits
    function GroundScanner.hooks:Think()
        local cur = timer.curtime()
        local scanned = self:getNWVar("scanned")
        if !scanned then return end
        if self.nextThink >= cur then return end
        local power = self:getInput("power")
        if power <= 0 then
            self:setNWVar("scanned", nil)
            return
        end
        self:setInput("power", power - 0.5)
        local index = #scanned+1
        if index <= #self.toScan then
            scanned[index] = self.toScan[index]
        end
        self.nextThink = cur + 1
    end
end

if CLIENT then
    ---@class bgui
    local bgui = bgui

    -- local font = render.createFont("Roboto",64,500,false,false,false,false,0,false,0)
    local scale = (512 / (foundRadius * 2))

    local function pushMask(mask)
        render.clearStencil()
        render.setStencilEnable(true)

        render.setStencilWriteMask(1)
        render.setStencilTestMask(1)

        render.setStencilFailOperation(STENCIL.REPLACE)
        render.setStencilPassOperation(STENCIL.ZERO)
        render.setStencilZFailOperation(STENCIL.ZERO)
        render.setStencilCompareFunction(STENCIL.NEVER)
        render.setStencilReferenceValue(1)

        mask()

        render.setStencilFailOperation(STENCIL.ZERO)
        render.setStencilPassOperation(STENCIL.REPLACE)
        render.setStencilZFailOperation(STENCIL.ZERO)
        render.setStencilCompareFunction(STENCIL.EQUAL)
        render.setStencilReferenceValue(1)
    end

    local function popMask()
        render.setStencilEnable(false)
        render.clearStencil()
    end

    ---[CLIENT] Draw info about this resource within 3D2D
    ---@param self GroundScanner
    function GroundScanner.hooks.PostDrawTranslucentRenderables(self)
        BMod.displayEnt(self.ent, Vector(0, 0, 20), Angle(0, 0, -60), function()
            ---@type Deposit[]
            local scanned = self:getNWVar("scanned", nil)
            if scanned then
                render.setColor(Color(0, 0, 0, 200))
                pushMask(function()
                    render.drawFilledCircle(0, 0, 256)
                end)
                render.enableDepth(false)
                render.drawRect(-256, -256, 512, 512)
                render.enableDepth(true)
                render.setColor(Color(0, 255, 0, 150))
                render.drawLine(-256, 0, 256, 0)
                render.drawLine(0, 0, 0, 256)
                render.setFont("Default")
                for i=1, 4 do
                    local rad = i * 10
                    local navCircRadius = rad * scale * unitsInMeter
                    render.setColor(Color(0, 255, 0, 150))
                    render.drawCircle(0, 0, navCircRadius)
                    render.setColor(Color(200, 200, 200, 150))
                    render.drawSimpleText(navCircRadius, 0, rad .. "m", TEXT_ALIGN.RIGHT, TEXT_ALIGN.BOTTOM)
                end
                render.setColor(Color())
                render.drawLine(0, 0, 0, -256)
                for _, v in ipairs(scanned) do
                    local pos = v.position * Vector(-scale, scale, 0)
                    local size = v.size * scale
                    local icon = bicons.get(v.resource)
                    local half = size / 2
                    if icon then
                        icon(pos.x - half, pos.y - half, size, size)
                    else
                        render.drawCircle(0, 0, half)
                    end
                    local res = ents.registered[v.resource]
                    render.drawSimpleText(pos.x, pos.y - half - 10, res and res.Name or v.resource, TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
                    render.drawSimpleText(
                        pos.x, pos.y + half + 10,
                        v.rate and v.rate .. " per second" or v.amount and v.amount .. " units" or "",
                        TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER
                    )
                end
                popMask()
            end
            render.setFont("Trebuchet24")
            render.drawSimpleText(-256, 256, string.format("Power: %s", math.round(self:getInput("power"))), TEXT_ALIGN.LEFT, TEXT_ALIGN.CENTER)
        end)
    end
end

ents.register(GroundScanner, "base_machine")

