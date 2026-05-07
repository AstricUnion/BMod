
---@class ents
local ents = ents

---@class resource
local resource = resource

---@class bmodConfig
local cfg = bmodConfig


if CLIENT then
    ---@class bicons
    local bicons = bicons
    bicons.registerModel("bucket", "models/props_junk/MetalBucket01a.mdl", Vector(-27, 0, 9), Angle(20, 0, 5))
    bicons.registerModel("toolbox", "models/props_c17/tools_wrench01a.mdl", Vector(0, 5, 16), Angle(90, 0, -80))
end



---@class Bucket: BModEntity
local Bucket = {}
Bucket.Identifier = "bucket"
Bucket.Name = "Bucket"
Bucket.Model = "models/props_junk/MetalBucket01a.mdl"
Bucket.hooks = {}

if SERVER then
    function Bucket:initialize()
        constraint.keepupright(self.ent, Angle(), 0, 5000)
        self:setNWVar("water", 0)
    end

    function Bucket.hooks.OnEntityWaterLevelChanged(self, ent, _, new)
        if ent ~= self.ent then return end
        if new == 3 and self:getNWVar("water") ~= 50 then
            self:setNWVar("water", 50)
        end
    end

    function Bucket.hooks.OnPlayerPhysicsPickup(self, ply, ent)
        local sprinting = ply:keyDown(IN_KEY.SPEED)
        if self.ent ~= ent then return end
        self.pickedUpBy = ply
        local count = self:getNWVar("water", 0)
        if sprinting and count > 0 then
            local pos = self.ent:getPos()
            local ang = self.ent:getAngles()
            timer.simple(0, function()
                if !isValid(self) then return end
                local res = resource.create("water", pos + Vector(0, 0, 21), ang, count, false, true)
                if res then
                    self:setNWVar("water", 0)
                end
            end)
        end
    end
else
    ---@param self Bucket
    function Bucket.hooks.PostDrawTranslucentRenderables(self)
        BMod.Display(self.ent, Vector(8.8, 0, 0), Angle(), function()
            render.drawSimpleText(0, -75, string.format("Water: %s", self:getNWVar("water", 0)), TEXT_ALIGN.CENTER)
            bicons.get("water")(-43, -43, 86, 86)
        end)
    end
end


ents.register(Bucket)


---@class ToolBox: BModEntity
---@field craftMenu CraftMenu
---@field salvagingProp Entity
---@field salvagingProgress number
local ToolBox = {}
ToolBox.Identifier = "toolbox"
ToolBox.Name = "ToolBox"
ToolBox.Model = "models/props_c17/suitcase001a.mdl"
ToolBox.hooks = {}

if SERVER then
    function ToolBox:initialize()
        constraint.keepupright(self.ent, Angle(), 0, 5000)
        self.ent:setColor(Color(255, 100, 100))
        self:setNWVar("gas", 0)
        self:setNWVar("power", 0)
        self:setNWVar("craft", nil)
        self:setNWVar("equippedBy", nil)
    end

    ---[SERVER] Open craft menu on click
    function ToolBox.hooks.KeyPress(self, ply, key)
        local sprinting = ply:keyDown(IN_KEY.SPEED)
        local walking = ply:keyDown(IN_KEY.WALK)
        local equippedBy = self:getEquippedBy()
        if equippedBy == nil and walking and key == IN_KEY.USE then
            local tr = ply:getEyeTrace()
            ---@cast tr TraceResult
            if tr.Entity ~= self.ent then return end
            if ply:getShootPos():getDistance(tr.HitPos) > 96 then return end
            self:equip(ply)
            return
        end
        local isCrowbar = ply == equippedBy and isValid(ply) and equippedBy:getActiveWeapon():getClass() == "weapon_crowbar" or false
        if !isCrowbar then return end
        local craftId = self:getNWVar("craft")
        local craft = cfg.crafts[craftId]
        if sprinting and key == IN_KEY.RELOAD then
            self:drop()
        elseif craft and walking and key == IN_KEY.RELOAD then
            self:setNWVar("craft", nil)
        elseif walking and key == IN_KEY.USE then
            local tr = ply:getEyeTrace()
            ---@cast tr TraceResult
            local ent = tr.Entity
            local resName = ent.BModResource
            if resName ~= "gas" and resName ~= "power" then return end
            if ply:getShootPos():getDistance(tr.HitPos) > 96 then return end
            local res = ents.inited[ent:entIndex()]
            ---@cast res Resource
            local currentCount = self:getNWVar(resName, 0)
            local toGet = 100 - currentCount
            ---@cast res Resource
            local took = res:take(toGet)
            self:setNWVar(resName, took)
        elseif key == IN_KEY.RELOAD then
            net.start("BModToolboxOpen")
                net.writeEntity(self.ent)
            net.send(ply)
        elseif craft and key == IN_KEY.ATTACK then
            local gas = self:getGas()
            local power = self:getPower()
            local requiredGas, requiredPower = math.ceil(math.min(3 * craft.scale, 100)), math.ceil(math.min(4 * craft.scale, 100))
            if requiredGas > gas or requiredPower > power then
                BMod.errorMessage(ply, "Firstly, refill gas and power in toolbox on ALT+E on resource")
                return
            end
            self:setGas(gas - requiredGas)
            self:setPower(power - requiredPower)
            local shootPos = ply:getShootPos()
            local angs = ply:getEyeAngles()
            local tr = trace.line(shootPos, shootPos + angs:getForward() * 256, {ply})
            BMod.makeCraft(ply, tr.HitPos, angs, craft)
        end
    end


    ---@param self ToolBox
    function ToolBox.hooks.Think(self)
        local function salvage()
            local ply = self:getEquippedBy()
            if !(ply and isValid(ply) and ply:getActiveWeapon():getClass() == "weapon_crowbar") then return end
            if !ply:keyDown(IN_KEY.ATTACK2) then return end
            local shootPos = ply:getShootPos()
            local eyeAngs = ply:getEyeAngles()
            local tr = trace.line(shootPos, shootPos + eyeAngs:getForward() * 256, {ply})
            local ent = tr.Entity
            if isValid(ent) and ent:getMass() > 10000 then
                BMod.errorMessage(ply, "Object too large")
                return
            end
            local salvagingCurrent, percent = self:getSalvage()
            if isValid(ent) and !ent.BModEntity or (salvagingCurrent and salvagingCurrent == ent) then
                if !isValid(salvagingCurrent) then
                    self:setNWVar("salvagingProp", ent)
                end
                local res = resource.salvage(ent)
                local pos = ent:getPos()
                local angs = ent:getAngles()
                if percent >= 1 then
                    ent:remove()
                    local height = 0
                    local time = 1 / prop.spawnRate()
                    for id, count in pairs(res) do
                        -- because prop limit. I don't use it in crafting table, because table makes less props
                        timer.simple(height * time, function()
                            resource.create(id, pos + Vector(0, 0, height * 12), angs, count, false, false)
                        end)
                        height = height + 1
                    end
                    return
                end
                percent = percent + 250 / ent:getMass() * game.getTickInterval()
                if game.getTickCount() % 15 == 0 then
                    self:setNWVar("salvagingProgress", percent)
                end
                return true
            end
        end
        if !salvage() then
            self:setNWVar("salvagingProp", nil)
            self:setNWVar("salvagingProgress", 0)
        end
    end


    ---@param self ToolBox
    ---@param ply Player
    function ToolBox.hooks.PlayerDeath(self, ply, _, _)
        if self:getEquippedBy() == ply then
            self:drop()
        end
    end

    ---[SERVER] Equip this toolbox
    ---@param ply Player
    function ToolBox:equip(ply)
        if self:getEquippedBy() or ply.EquippedToolbox then return end
        self.ent:enableMotion(false)
        self.ent:setNoDraw(true)
        self.ent:setCollisionGroup(COLLISION_GROUP.IN_VEHICLE)
        prop.createSent(ply:getPos(), Angle(), "weapon_crowbar", true)
        ply.EquippedToolbox = self
        self:setNWVar("equippedBy", ply)
        self.ent:emitSound("items/ammo_pickup.wav")
    end

    ---[SERVER] Drop toolbox
    function ToolBox:drop()
        local ply = self:getEquippedBy()
        if !ply or !isValid(ply) then return end
        local pos = ply:getShootPos()
        local angs = ply:getEyeAngles()
        local tr = trace.line(pos, pos + angs:getForward() * 64, {ply})
        self.ent:setPos(tr.HitPos)
        self.ent:enableMotion(true)
        self.ent:setNoDraw(false)
        self.ent:setCollisionGroup(COLLISION_GROUP.NONE)
        ply.EquippedToolbox = nil
        self:setNWVar("equippedBy", nil)
        self.ent:emitSound("AI_BaseNPC.BodyDrop_Heavy")
    end

    ---[SERVER] Set gas for toolbox
    ---@param gas number Gas
    function ToolBox:setGas(gas)
        gas = math.clamp(gas, 0, 100)
        self:setNWVar("gas", gas)
    end

    ---[SERVER] Set power for toolbox
    ---@param power number Gas
    function ToolBox:setPower(power)
        power = math.clamp(power, 0, 100)
        self:setNWVar("power", power)
    end


    net.receive("BModToolboxSetCraft", function()
        local ent = net.readEntity()
        if !isValid(ent) then return end
        local toolbox = ents.inited[ent:entIndex()]
        if !isValid(toolbox) then return end
        ---@cast toolbox ToolBox
        local craftId = net.readString()
        local craft = cfg.crafts[craftId]
        if !craft then return end
        local ply = toolbox:getEquippedBy()
        if !ply then return end
        local res = resource.getResourcesFast(ply)
        local errorMes = resource.canByResources(res, craft.requires)
        if errorMes then
            BMod.errorMessage(ply, errorMes)
            return
        end
        toolbox:setNWVar("craft", craftId)
    end)
else
    ---@param self ToolBox
    function ToolBox.hooks.PostDrawTranslucentRenderables(self)
        local ply = self:getEquippedBy()
        if !ply or !isValid(ply) then
            BMod.Display(self.ent, Vector(0, 7, 0), Angle(0, 90, 0), "ToolBox")
            return
        end
        if ply:isAlive() and ply:getActiveWeapon():getClass() ~= "weapon_crowbar" then return end
        local craftId = self:getNWVar("craft")
        local craft = cfg.crafts[craftId]
        if craft then
            local shootPos = ply:getShootPos()
            local angs = ply:getEyeAngles()
            local tr = trace.line(shootPos, shootPos + angs:getForward() * 256, {ply})
            render.draw3DWireframeBox(tr.HitPos, angs:setP(0), craft.scale * Vector(-30, -15, 0), craft.scale * Vector(0, 15, 30))
        end
    end

    ---@param self ToolBox
    function ToolBox.hooks.DrawHUD(self)
        local ply = self:getEquippedBy()
        if !isValid(ply) or !ply:isAlive() or ply:getActiveWeapon():getClass() ~= "weapon_crowbar" then return end
        local sw, sh = bgui.screenWidth, bgui.screenHeight
        render.setFont("Trebuchet18")
        -- Salvage progress
        local salvageProp, salvagePercent = self:getSalvage()
        if salvageProp and isValid(salvageProp) then
            render.drawSimpleText(sw * 0.4, sh * 0.5 - 16, string.format("Salvaging..."), TEXT_ALIGN.LEFT, TEXT_ALIGN.BOTTOM)
            local function drawRect(percent) render.drawRoundedBox(4, sw * 0.4, sh * 0.5 - 16, sw * 0.2 * percent, 32) end
            render.setColor(Color(255, 255, 255, 100))
            drawRect(1)
            render.setColor(Color(255, 255, 255))
            drawRect(salvagePercent)
        end
        render.drawSimpleText(sw * 0.2, sh * 0.5, string.format("Power: %s", self:getPower()), TEXT_ALIGN.LEFT, TEXT_ALIGN.CENTER)
        render.drawSimpleText(sw * 0.2, sh * 0.5 + 18, string.format("Gas: %s", self:getGas()), TEXT_ALIGN.LEFT, TEXT_ALIGN.CENTER)
        local function textLine(text, lineId)
            render.drawSimpleText(sw * 0.5, sh * 0.9 - lineId * 18, text, TEXT_ALIGN.CENTER, TEXT_ALIGN.BOTTOM)
        end
        textLine("SHIFT+R: Drop ToolBox", 0)
        textLine("ALT+RMB: Loosen", 1)
        textLine("RMB: Salvage", 2)
        textLine("ALT+LMB: Modify", 3)
        textLine("LMB: Build or upgrade", 4)
        textLine("R: Select build item", 5)
        textLine("ALT+R: Clear build item", 6)
        local craftId = self:getNWVar("craft")
        local craft = cfg.crafts[craftId]
        render.setFont("Trebuchet24")
        if craft then
            render.drawSimpleText(sw * 0.5, sh * 0.9 - 132, craft.name, TEXT_ALIGN.CENTER, TEXT_ALIGN.BOTTOM)
        end
    end

    function ToolBox:networkVariablesUpdate(oldVars, vars)
        local function equip()
            local ply = vars.equippedBy
            if oldVars.equippedBy == ply or player() ~= ply then return end
            ---@cast ply Player
            input.selectWeapon(ply:getWeapon("weapon_crowbar"))
        end

        local function craft()
            if vars.craft == oldVars.craft then return end
            if isValid(self.craftMenu) then
                self.craftMenu:remove()
                self.craftMenu = nil
            end
        end

        equip()
        craft()
    end

    function ToolBox:onRemove()
        if isValid(self.craftMenu) then self.craftMenu:remove() end
    end

    net.receive("BModToolboxOpen", function()
        net.readEntity(function(ent)
            local tbl = ents.inited[ent:entIndex()]
            ---@cast tbl ToolBox
            if !isValid(tbl) then return end
            if isValid(tbl.craftMenu) then return end
            tbl.craftMenu = bgui.create("CraftMenu")
            tbl.craftMenu:setTable(ent)
            tbl.craftMenu:setType("toolbox")
            tbl.craftMenu:center()
            tbl.craftMenu.doCraft = function(self, craftId)
                net.start("BModToolboxSetCraft")
                    net.writeEntity(ent)
                    net.writeString(craftId)
                net.send()
            end
            input.enableCursor(true)
        end)
    end)
end

---[SHARED] Get gas
---@return number gas
function ToolBox:getGas()
    return self:getNWVar("gas", 0)
end

---[SHARED] Get power
---@return number power
function ToolBox:getPower()
    return self:getNWVar("power", 0)
end

---[SHARED] Is toolbox equipped and who equipped it
---@return Player? owner
function ToolBox:getEquippedBy()
    return self:getNWVar("equippedBy", nil)
end

---[SHARED] Get salvage info
---@return Entity? salvaging
---@return number percent Percent of salvage
function ToolBox:getSalvage()
    return self:getNWVar("salvagingProp"), self:getNWVar("salvagingProgress", 0)
end


ents.register(ToolBox)

