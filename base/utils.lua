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
        local valid = isValid(turr)
        if valid and turr.damage ~= damage then
            turr:remove()
            valid = false
        end
        if !valid then
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
        turr.toFire = true
        wire.triggerInput(turr, "Fire", 1)
    end

    hook.add("Think", "BModTurretUpdate", function()
        local cur = timer.curtime()
        for ply, turr in pairs(turrets) do
            if !isValid(ply) or (turr.dieTime and turr.dieTime < cur) then
                turr:remove()
                goto cont
            end
            if !turr.toFire then goto cont end
            local pos = ply:getPos()
            -- PROBLEM: can hit other players, if player moving too fast
            turr:setAngles((pos - turr:getPos()):getAngle())
            turr:setPos(pos + Vector(0, 0, 50))
            ::cont::
        end
    end)

    hook.add("EntityFireBullets", "BModTurret", function(ent)
        for _, turr in pairs(turrets) do
            if turr == ent then
                wire.triggerInput(ent, "Fire", 0)
                turr.toFire = false
                return
            end
        end
    end)
end

return butils
