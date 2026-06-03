---@class ents
local ents = ents

---@class BWeapon: BModEntity
---@field WeaponToReplace string Weapon to replace
---@field weaponReplace Entity? Already replaced weapon
local BWeapon = {}
BWeapon.Identifier = "base_weapon"
BWeapon.Name = "Base weapon"
BWeapon.Model = ""
BWeapon.hooks = {}
BWeapon.WeaponToReplace = "weapon_fists"


---[SHARED] Initialize weapon
function BWeapon:weaponInitialize() end

---[SHARED] Initialize BWeapon entity
function BWeapon:initialize()
    self.ent.BModWeapon = self.Identifier
    self:weaponInitialize()
end

if SERVER then
    ---[SERVER] Equip on click
    ---@param self BWeapon
    function BWeapon.hooks.KeyPress(self, ply, key)
        local ow = self:getOwner()
        local walking = ply:keyDown(IN_KEY.WALK)
        if !ow and walking and key == IN_KEY.USE then
            local tr = ply:getEyeTrace()
            ---@cast tr TraceResult
            if tr.Entity ~= self.ent then return end
            if ply:getShootPos():getDistance(tr.HitPos) > 96 then return end
            self:equip(ply)
            return
        end
        if !self:isInHands(ply) then return end
        self:inputHandler(ply, key, walking, ply:keyDown(IN_KEY.SPEED))
    end

    ---[SERVER] Input handler when active
    ---@param ply Player
    ---@param key number
    ---@param isWalking boolean
    ---@param isSprinting boolean
    function BWeapon:inputHandler(ply, key, isWalking, isSprinting) end


    ---@param self BWeapon
    ---@param ply Player
    function BWeapon.hooks.PlayerDeath(self, ply, _, _)
        if self:getOwner() == ply then
            self:drop()
        end
    end

    ---[SERVER] Equip this item
    ---@param ply Player
    function BWeapon:equip(ply)
        local equipped = self:getOwner()
        if isValid(equipped) then return end
        if !ply:isHUDActive() then return end
        self.ent:enableMotion(false)
        self.ent:setCollisionGroup(COLLISION_GROUP.IN_VEHICLE)
        self.ent:setNoDraw(true)
        self.ent:emitSound("items/ammo_pickup.wav")
        self.weaponReplace = prop.createSent(ply:getPos(), Angle(), self.WeaponToReplace, true)
        self:setNWVar("equippedBy", ply)
    end


    ---[SERVER] Drop this item
    function BWeapon:drop()
        local ply = self:getOwner()
        if !isValid(ply) then return end
        local angs = ply:getEyeAngles()
        local shootPos = ply:getShootPos()
        local pos = trace.line(shootPos, shootPos + angs:getForward() * 64, {ply}).HitPos
        self.ent:setPos(pos)
        self.ent:setAngles(angs)
        self.ent:enableMotion(true)
        self.ent:setCollisionGroup(COLLISION_GROUP.NONE)
        self.ent:setNoDraw(false)
        self.ent:setVelocity(ply:getVelocity())
        self.ent:emitSound("AI_BaseNPC.BodyDrop_Heavy")
        if isValid(self.weaponReplace) then
            self.weaponReplace:remove()
        end
        self:setNWVar("equippedBy", nil)
    end
else
    ---[CLIENT] Weapon HUD
    ---@param self BWeapon
    function BWeapon.hooks.DrawHUD(self)
        local ow = self:getOwner()
        if !isValid(ow) or !self:isInHands(ow) then return end
        self:drawHUD()
    end

    ---[CLIENT] HUD draw for weapon
    function BWeapon:drawHUD() end

    local holo = hologram.create(Vector(), Angle(), "models/props_c17/tools_wrench01a.mdl", Vector(1, 1, 1))
    if !holo then return end
    holo:setRenderGroup(RENDERGROUP.VIEWMODEL)

    local holo1 = hologram.create(Vector(), Angle(), "models/props_c17/tools_pliers01a.mdl", Vector(1, 1, 1))
    if !holo1 then return end
    holo1:setRenderGroup(RENDERGROUP.VIEWMODEL)

    ---[CLIENT] Weapon viewmodel
    ---@param self BWeapon
    function BWeapon.hooks.PreDrawViewModels(self)
        local ow = self:getOwner()
        if !isValid(ow) or !self:isInHands(ow) then
            holo:setNoDraw(true)
            holo1:setNoDraw(true)
            return
        end
        holo:setNoDraw(false)
        holo1:setNoDraw(false)
        local viewmodel = ow:getViewModel()
        do
            local mat = viewmodel:getBoneMatrix(viewmodel:lookupBone("ValveBiped.Bip01_R_Hand"))
            local oPos, oAng = localToWorld(Vector(3, -1.5, 0), Angle(0, 90, -90), mat:getTranslation(), mat:getAngles())
            holo:setPos(oPos)
            holo:setAngles(oAng)
        end
        do
            local mat = viewmodel:getBoneMatrix(viewmodel:lookupBone("ValveBiped.Bip01_L_Hand"))
            local oPos, oAng = localToWorld(Vector(3, -2.5, -2), Angle(0, 180, 90), mat:getTranslation(), mat:getAngles())
            holo1:setPos(oPos)
            holo1:setAngles(oAng)
        end
    end
end

---[SHARED] Weapon think
---@param self BWeapon
function BWeapon.hooks.Think(self)
    local ow = self:getOwner()
    if !isValid(ow) or !self:isInHands(ow) then return end
    self:think()
end

---[SERVER] Think hook of weapon
function BWeapon:think() end


---[SHARED] Is weapon in player hands
---@param ply Player
function BWeapon:isInHands(ply)
    local activeWeapon = ply and isValid(ply) and ply:getActiveWeapon()
    return activeWeapon and isValid(activeWeapon) and activeWeapon:getClass() == self.WeaponToReplace
end


---[SHARED] Is weapon equipped and who equipped it
---@return Player owner
function BWeapon:getOwner()
    return self:getNWVar("equippedBy", nil)
end

ents.register(BWeapon)
