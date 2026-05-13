---@class ents
local ents = ents


---@alias ArmorInfo table<EquipSlot, Equippable>


---Class to handle equipment and info about it
---@class equipment
---@field players table<Player, ArmorInfo>
---@field FullBody table<number, boolean>
---@field Locational table<number, boolean>
---@field Biological table<number, boolean>
---@field Piercing table<number, boolean>
local equipment = {}
equipment.players = {}

---@enum EquipSlot
equipment.EquipSlot = {
    head = 1,
    eyes = 2,
    mouthAndNose = 3,
    ears = 4,
    leftShoulder = 5,
    leftForearm = 6,
    leftThigh = 7,
    leftCalf = 8,
    chest = 9,
    back = 10,
    waist = 11,
    pelvis = 12,
    rightShoulder = 13,
    rightForearm = 14,
    rightThigh = 15,
    rightCalf = 16,
}

equipment.Locational = {
    [DAMAGE.BULLET] = true, [DAMAGE.BUCKSHOT] = true, [DAMAGE.AIRBOAT] = true, [DAMAGE.SNIPER] = true
}

equipment.FullBody = {
    [DAMAGE.CRUSH] = true, [DAMAGE.SLASH] = true, [DAMAGE.BURN] = true,
    [DAMAGE.VEHICLE] = true, [DAMAGE.BLAST] = true, [DAMAGE.CLUB] = true,
    [DAMAGE.PLASMA] = true, [DAMAGE.ACID] = true, [DAMAGE.POISON] = true
}

equipment.Biological = { [DAMAGE.NERVEGAS] = true, [DAMAGE.RADIATION] = true }

equipment.Piercing = {
    [DAMAGE.BULLET] = true, [DAMAGE.BUCKSHOT] = true, [DAMAGE.AIRBOAT] = true, [DAMAGE.SNIPER] = true, [DAMAGE.SLASH] = true
}

---@enum DefenseProfile
equipment.DefenseProfile = {
    Basic = {
        [DAMAGE.BUCKSHOT] = .999,
        [DAMAGE.CLUB] = .99,
        [DAMAGE.SLASH] = .99,
        [DAMAGE.BULLET] = .98,
        [DAMAGE.BLAST] = .95,
        [DAMAGE.SNIPER] = .9,
        [DAMAGE.AIRBOAT] = .85,
        [DAMAGE.CRUSH] = .75,
        [DAMAGE.VEHICLE] = .65,
        [DAMAGE.BURN] = .65,
        [DAMAGE.PLASMA] = .65,
        [DAMAGE.ACID] = .55
    },
    Poor = {
        [DAMAGE.BUCKSHOT] = .6,
        [DAMAGE.CLUB] = .6,
        [DAMAGE.SLASH] = .6,
        [DAMAGE.BULLET] = .2,
        [DAMAGE.BLAST] = .2,
        [DAMAGE.SNIPER] = .1,
        [DAMAGE.AIRBOAT] = .2,
        [DAMAGE.CRUSH] = .3,
        [DAMAGE.VEHICLE] = .2,
        [DAMAGE.BURN] = .2,
        [DAMAGE.PLASMA] = .1,
        [DAMAGE.ACID] = .1
    },
    NonArmor = {
        [DAMAGE.BUCKSHOT] = .05,
        [DAMAGE.BLAST] = .05,
        [DAMAGE.BULLET] = .05,
        [DAMAGE.SNIPER] = .05,
        [DAMAGE.AIRBOAT] = .05,
        [DAMAGE.CLUB] = .05,
        [DAMAGE.SLASH] = .05,
        [DAMAGE.CRUSH] = .05,
        [DAMAGE.VEHICLE] = .05,
        [DAMAGE.BURN] = .05,
        [DAMAGE.PLASMA] = .05,
        [DAMAGE.ACID] = .05
    }
}
local EquipSlot = equipment.EquipSlot

if SERVER then
    ---[SERVER] Reserve slots for equippable
    ---@param ply Player Player to equip
    ---@param toEquip Equippable Item to equip
    ---@param force boolean Force equip, drop if reserved
    ---@return boolean success Is succesfully equipped
    function equipment.reserveSlot(ply, toEquip, force)
        local plyEquipment = equipment.players[ply] or {}
        local newEquipment = {}
        for v, _ in pairs(toEquip.EquipSlots) do
            local current = plyEquipment[v]
            if isValid(current) and !force then
                return false
            elseif isValid(current) and force then
                current:drop()
            end
            newEquipment[v] = toEquip
        end
        for i, v in pairs(newEquipment) do
            plyEquipment[i] = v
        end
        equipment.players[ply] = plyEquipment
        return true
    end

    ---[SERVER] Reserve slots for equippable
    ---@param ply Player Player to equip
    ---@param toEquip Equippable Item to equip
    function equipment.emptySlot(ply, toEquip)
        local plyEquipment = equipment.players[ply]
        if !plyEquipment then return end
        for v, _ in pairs(toEquip.EquipSlots) do
            plyEquipment[v] = nil
        end
    end
end

---@class Equippable: BModEntity
---@field EquippedModel string|fun(): Hologram
---@field BoneToEquip string Bone to equip this equippable
---@field EquipOffset Vector? Offset for equipped entity
---@field EquipAngle Angle? Angle offset for equipped entity
---@field EquipSlots table<EquipSlot, number> Slots to reserve for this equippable. Value is coverage of this equipment
---@field DefenseProfile DefenseProfile? Defense profile for this equipment. Sets default reaction to any damage types. If nil, then no defense
---@field Defense table<number, number>? Defense by damage types
---@field MaxDurability number? Max durability of this equippable
---@field private equippedPoint Hologram?
local Equippable = {}
Equippable.Identifier = "base_equippable"
Equippable.Name = "Base equippable"
Equippable.Model = ""
Equippable.hooks = {}


if SERVER then
    ---[SERVER] Equip on click
    function Equippable.hooks.KeyPress(self, ply, key)
        local walking = ply:keyDown(IN_KEY.WALK)
        if walking and key == IN_KEY.USE then
            local tr = ply:getEyeTrace()
            ---@cast tr TraceResult
            if tr.Entity ~= self.ent then return end
            if ply:getShootPos():getDistance(tr.HitPos) > 96 then return end
            self:equip(ply)
            return
        end
    end

    ---[SERVER] Equip this item
    ---@param ply Player
    function Equippable:equip(ply)
        local equipped = self:getEquippedBy()
        if isValid(equipped) then return end
        equipment.reserveSlot(ply, self, true)
        self.ent:enableMotion(false)
        local bone = ply:lookupBone(self.BoneToEquip)
        if !bone then return end
        local matr = ply:getBoneMatrix(bone)
        local pos, ang = localToWorld(self.EquipOffset or Vector(), self.EquipAngle or Angle(), matr:getTranslation(), matr:getAngles())
        self.equippedPoint = hologram.create(pos, ang, "models/hunter/plates/plate.mdl")
        self.equippedPoint:setParent(ply, nil, bone)
        self.equippedPoint:setNoDraw(true)
        self.ent:setPos(pos)
        self.ent:setAngles(ang)
        self.ent:setParent(self.equippedPoint)
        self.ent:setCollisionGroup(COLLISION_GROUP.IN_VEHICLE)
        self.ent:emitSound("items/ammo_pickup.wav")
        self:setNWVar("equippedBy", ply)
    end


    ---[SERVER] Drop this item
    function Equippable:drop()
        local ply = self:getEquippedBy()
        if !isValid(ply) then return end
        local pos = ply:getShootPos()
        local angs = ply:getEyeAngles()
        local tr = trace.line(pos, pos + angs:getForward() * 64, {ply})
        self.ent:setParent(nil)
        self.ent:setPos(tr.HitPos)
        self.ent:enableMotion(true)
        self.ent:setNoDraw(false)
        self.ent:setCollisionGroup(COLLISION_GROUP.NONE)
        if isValid(self.equippedPoint) then
            self.equippedPoint:remove()
            self.equippedPoint = nil
        end
        self:setNWVar("equippedBy", nil)
        self.ent:emitSound("AI_BaseNPC.BodyDrop_Heavy")
        equipment.emptySlot(ply, self)
    end


    function Equippable:onRemove()
        if !isValid(self.equippedPoint) then return end
        self.equippedPoint:remove()
    end


    ---[SERVER] Set durability of equippable
    ---@param durability number
    function Equippable:setDurability(durability)
        self:setNWVar("durability", math.clamp(durability, 0, self.MaxDurability))
    end

    local damageMultipliers = {
        [HITGROUP.HEAD] = { [EquipSlot.head] = 1, [EquipSlot.eyes] = 0.5, [EquipSlot.mouthAndNose] = 0.5 },
        [HITGROUP.CHEST] = { [EquipSlot.chest] = 1, [EquipSlot.back] = 1 },
        [HITGROUP.GENERIC] = { [EquipSlot.chest] = 1, [EquipSlot.back] = 1 },
        [HITGROUP.STOMACH] = { [EquipSlot.pelvis] = 1 },
        [HITGROUP.RIGHTARM] = { [EquipSlot.rightShoulder] = 1, [EquipSlot.rightForearm] = 1 },
        [HITGROUP.LEFTARM] = { [EquipSlot.leftShoulder] = 1, [EquipSlot.leftForearm] = 1 },
        [HITGROUP.RIGHTLEG] = { [EquipSlot.rightThigh] = 1, [EquipSlot.rightCalf] = 1 },
        [HITGROUP.LEFTLEG] = { [EquipSlot.leftThigh] = 1, [EquipSlot.leftCalf] = 1 },
    }

    local nonProtective = {
        [EquipSlot.ears] = true,
        [EquipSlot.waist] = true
    }

    ---[SERVER] Hook to damage equipment
    ---@param target Entity
    hook.add("EntityTakeDamage", "BModEquipmentDurability", function(target, attacker, inflictor, amount, type, position, force)
        ---@type ArmorInfo
        local plyEquipped = equipment.players[target]
        local dmgType = inflictor.dmgType or type
        if !plyEquipped then return end
        local multiplier = 1
        ---@cast target Player
        local damageSlots = damageMultipliers[target:lastHitGroup()]
        local protection = 0
        for armorSlot, armor in pairs(plyEquipped) do
            if nonProtective[armorSlot] or !armor.DefenseProfile then goto cont end
            local coverage = armor.EquipSlots[armorSlot]
            local damageMutliplier = damageSlots[armorSlot] or 1
            local damageProtection = armor.Defense and armor.Defense[dmgType] or armor.DefenseProfile[dmgType]
            protection = protection + damageProtection * coverage * damageMutliplier
            ::cont::
        end
        local scale = multiplier * protection
        target:setHealth(target:getHealth() + amount * scale)
    end)
else
    function Equippable.hooks.RenderOffscreen(self)
        local ply = self:getEquippedBy()
        if !isValid(ply) then
            self.ent:setNoDraw(false)
            return
        end
        self.ent:setNoDraw(ply == player() and !ply:shouldDrawLocalPlayer())
    end
end

---[SHARED] Is toolbox equipped and who equipped it
---@return Player owner
function Equippable:getEquippedBy()
    return self:getNWVar("equippedBy", nil)
end

---[SHARED] Get durability of equippable
---@return number durability
function Equippable:getDurability()
    return self:getNWVar("durability", self.MaxDurability)
end


ents.register(Equippable)

return equipment
