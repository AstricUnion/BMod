
---@class ents
local ents = ents

---@class BaseEquippable: BModEntity
---@field EquippedModel string|fun(): Hologram
---@field BoneToEquip string Bone to equip this equippable
---@field EquipOffset Vector? Offset for equipped entity
---@field EquipAngle Angle? Angle offset for equipped entity
---@field private equippedModel Hologram?
local BaseEquippable = {}
BaseEquippable.Identifier = "base_equippable"
BaseEquippable.Name = "Base equippable"
BaseEquippable.Model = ""
BaseEquippable.hooks = {}


if SERVER then
    ---[SERVER] Equip on click
    function BaseEquippable.hooks.KeyPress(self, ply, key)
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

    ---[SERVER] Equip this toolbox
    ---@param ply Player
    function BaseEquippable:equip(ply)
        self.ent:enableMotion(false)
        self.ent:setNoDraw(true)
        local bone = ply:lookupBone(self.BoneToEquip)
        if !bone then return end
        local matr = ply:getBoneMatrix(bone)
        self.equippedModel = isstring(self.EquippedModel) and hologram.create(Vector(), Angle(), self.EquippedModel) or self.EquippedModel()
        local pos, ang = localToWorld(self.EquipOffset or Vector(), self.EquipAngle or Angle(), matr:getTranslation(), matr:getAngles())
        self.equippedModel:setPos(pos)
        self.equippedModel:setAngles(ang)
        self.equippedModel:setParent(ply, nil, bone)
        self.ent:setCollisionGroup(COLLISION_GROUP.IN_VEHICLE)
        self.ent:emitSound("items/ammo_pickup.wav")
        self:setNWVar("equippedBy", ply)
    end


    function BaseEquippable:onRemove()
        if !isValid(self.equippedModel) then return end
        self.equippedModel:remove()
    end
end

---[SHARED] Is toolbox equipped and who equipped it
---@return Player? owner
function BaseEquippable:getEquippedBy()
    return self:getNWVar("equippedBy", nil)
end

ents.register(BaseEquippable)

