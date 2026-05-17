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
            local status
            status, turr = pcall(prop.createSent, Vector(), Angle(-90, 0, 0), "gmod_wire_turret", true, {
                damage = damage,
                delay = 0,
                sound = "",
                tracer = "",
                tracernum = 0
            })
            if !status then return end
            turr:setNoDraw(true)
            turr:setCollisionGroup(COLLISION_GROUP.IN_VEHICLE)
            turrets[ent] = turr
            turr.dieTime = lifeTime and timer.curtime() + lifeTime or nil
        end
        turr.toFire = true
        wire.triggerInput(turr, "Fire", 1)
    end

    -- error with turret when player disconnects
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
else
    local Ply = player()

    -- local screenEffect = hologram.create(Vector(), Angle(), "models/holograms/plane.mdl", Vector(1, 1, 1))
    -- if screenEffect then
    --     render.createRenderTarget("BModScreenEffect")
    --     local mat = material.create("VertexLitGeneric")
    --     mat:setTextureRenderTarget("$basetexture", "BModScreenEffect")
    --     screenEffect:setRenderGroup(RENDERGROUP.VIEWMODEL_TRANSLUCENT)
    --     screenEffect:suppressEngineLighting(true)
    --     screenEffect:setSubMaterial(0, "!" .. mat:getName())
    --     screenEffect:setColor(Color(255, 255, 255, 200))
    --     -- local ang = 0
    --     local screenSpace = material.load("models/spawn_effect")
    --
    --     hook.add("RenderOffscreen", "BModScreenEffect", function()
    --         render.selectRenderTarget("BModScreenEffect")
    --             render.setMaterial(screenSpace)
    --             render.drawTexturedRect(0, 0, 1024, 1024)
    --         render.selectRenderTarget()
    --         local pos, angs
    --         if Ply:shouldDrawLocalPlayer() then
    --             pos = render.getEyePos()
    --             angs = render.getAngles()
    --         else
    --             pos = Ply:getEyePos()
    --             angs = Ply:getEyeAngles()
    --         end
    --         screenEffect:setPos(pos + angs:getForward() * 13)
    --         angs = angs:rotateAroundAxis(angs:getRight(), 90)
    --         angs = angs:rotateAroundAxis(angs:getUp(), 180)
    --         screenEffect:setAngles(angs)
    --         -- local sin = (1 - math.sin(math.rad(ang)))
    --         -- screenEffect:setScale(Vector(5 + (sin * 30), 5 + (sin * 30), 1))
    --         -- ang = ang + 5
    --         -- if ang >= 360 then
    --         --     screenEffect:setNoDraw(true)
    --         -- end
    --     end)
    -- end
end

return butils
