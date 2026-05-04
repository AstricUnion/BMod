
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
        local isCrowbar = ply == equippedBy and equippedBy:getActiveWeapon():getClass() == "weapon_crowbar" or false
        if !isCrowbar then return end
        if sprinting and key == IN_KEY.RELOAD then
            self:drop()
        elseif walking and key == IN_KEY.USE then
            local tr = ply:getEyeTrace()
            ---@cast tr TraceResult
            local ent = tr.Entity
            if ent.BModResource ~= "gas" and ent.BModResource ~= "power" then return end
            if ply:getShootPos():getDistance(tr.HitPos) > 96 then return end
            local res = ents.inited[ent:entIndex()]
            local diff = res:getCount() - self:getNWVar(ent.BModResource, 0)
            ---@cast res Resource
            res:setCount(100 - diff)
            self:setNWVar(ent.BModResource, diff)
        elseif key == IN_KEY.RELOAD then
            net.start("BModToolboxOpen")
                net.writeEntity(self.ent)
            net.send(ply)
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
        if !ply then return end
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
            net.start("BModErrorMessage")
                net.writeString(errorMes)
            net.send(ply)
            return
        end
        toolbox:setNWVar("craft", craftId)
    end)
else
    ---@param self ToolBox
    function ToolBox.hooks.PostDrawTranslucentRenderables(self)
        if self:getEquippedBy() then return end
        BMod.Display(self.ent, Vector(0, 7, 0), Angle(0, 90, 0), "ToolBox")
    end

    function ToolBox.hooks.DrawHUD(self)
        local ply = self:getEquippedBy()
        if !ply or ply:getActiveWeapon():getClass() ~= "weapon_crowbar" then return end
        local sw, sh = bgui.screenWidth, bgui.screenHeight
        render.setFont("Trebuchet18")
        render.drawSimpleText(sw * 0.2, sh * 0.5, string.format("Gas: %s", self:getGas()), TEXT_ALIGN.LEFT, TEXT_ALIGN.CENTER)
        render.drawSimpleText(sw * 0.2, sh * 0.5 + 18, string.format("Power: %s", self:getPower()), TEXT_ALIGN.LEFT, TEXT_ALIGN.CENTER)
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
        if craft then
            render.setFont("Trebuchet24")
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
            if self.craftMenu then self.craftMenu:remove() end
        end

        equip()
        craft()
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


ents.register(ToolBox)

