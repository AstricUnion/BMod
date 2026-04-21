---@name Utilities
---@author AstricUnion
---@shared

---Utility to make admin-actions from Wire
---@class butils
local butils = {}

if SERVER then
    local turrets = {}

    ---[SERVER] Apply damage through turret
    ---@param ent Entity Entity to apply damage
    ---@param damage number Damage to apply
    ---@param lifeTime number? New turret life time. Default nil, no delete
    function butils.applyDamage(ent, damage, lifeTime)
        local turr = turrets[ent]
        if turrets[ent] == nil then
            turr = prop.createSent(Vector(), Angle(-90, 0, 0), "gmod_wire_turret", true, {
                damage = damage,
                delay = 0,
                sound = "",
                tracer = "",
                tracernum = 0
            })
            turr:setNoDraw(true)
            turr:setCollisionGroup(COLLISION_GROUP.IN_VEHICLE)
            turrets[ent] = turr
            turr.dieTime = lifeTime and timer.curtime() + lifeTime or nil
        end
        wire.triggerInput(turr, "Fire", 1)
    end

    hook.add("Think", "BModTurretUpdate", function()
        local tick = game.getTickInterval()
        local cur = timer.curtime()
        for ply, turr in pairs(turrets) do
            if !isValid(ply) or (turr.dieTime and turr.dieTime < cur) then
                turr:remove()
                goto cont
            end
            -- Applying velocity, or else turret will lag behind player
            turr:setPos(ply:getPos() + Vector(0, 0, 50) + ply:getVelocity() * tick)
            ::cont::
        end
    end)

    hook.add("EntityFireBullets", "BModTurret", function(ent)
        for _, turr in pairs(turrets) do
            if turr == ent then
                wire.triggerInput(ent, "Fire", 0)
                return
            end
        end
    end)

    butils.applyDamage(owner(), 1)
end
