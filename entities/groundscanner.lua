
-- models/props_silo/launch_button.mdl

---@class ents
local ents = ents

---@class deposit
local deposit = deposit

---@class resource
local resource = resource

---@class GroundScanner: BModEntity
local GroundScanner = {}
GroundScanner.Identifier = "groundscanner"
GroundScanner.Name = "Resource Crate"
GroundScanner.Model = "models/props_silo/launch_button.mdl"
GroundScanner.hooks = {}

local unitsInMeter = 39.37008
local foundRadius = 50 * unitsInMeter

if SERVER then
    function GroundScanner:initialize()
        self.ent:setMass(25)
    end

    ---[SERVER] Activate ground scanner
    ---@param ply Player
    ---@param key number
    function GroundScanner.hooks.KeyPress(self, ply, key)
        if key ~= IN_KEY.USE or !ply:keyDown(IN_KEY.WALK) then return end
        local tr = ply:getEyeTrace()
        ---@cast tr TraceResult
        if tr.Entity ~= self.ent then return end
        if ply:getShootPos():getDistance(tr.HitPos) > 96 then return end
        self:activate()
    end

    function GroundScanner:activate()
        local result = table.copy(deposit.findInSphere(self.ent:getPos(), foundRadius))
        for _, v in ipairs(result) do
            local angs = self.ent:getAngles()
            angs = angs:rotateAroundAxis(angs:getUp(), -90)
            local pos = worldToLocal(v.position, Angle(), self.ent:getPos(), angs)
            v.position = pos
        end
        self:setNWVar("scanned", result)
    end

    ---[SERVER] Set power of scanner
    function GroundScanner:setPower(power)
        self:setNWVar("power", power)
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
        BMod.Display(self.ent, Vector(0, 0, 20), Angle(0, 0, -60), function()
            ---@type Deposit[]
            local scanned = self:getNWVar("scanned", nil)
            if !scanned then return end
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
            render.setFont("Trebuchet24")
            render.drawSimpleText(-256, 256, "Power: 100%", TEXT_ALIGN.LEFT, TEXT_ALIGN.CENTER)
        end)
    end
end

ents.register(GroundScanner)

