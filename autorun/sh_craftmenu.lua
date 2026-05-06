if SERVER then
    ---@class bmodConfig
    local cfg = bmodConfig

    ---@class beff
    local beff = beff

    ---@param ply Player Player to make craft
    ---@param pos Vector Position to create craft result
    ---@param ang Angle Angle to create craft result
    ---@param craft BModCraft Craft to identificate
    ---@param useProps boolean? Use props for craft or not. Default false
    function BMod.makeCraft(ply, pos, ang, craft, useProps)
        local errorMes = resource.takeResources(ply, craft.requires, useProps)
        if errorMes then
            BMod.errorMessage(ply, errorMes)
            return
        end
        local eff = beff.create("craft_effect")
        eff:setOrigin(pos)
        eff:setScale(craft.scale or 1)
        eff:play()
        sound.emitSound("ambient/machines/spinup.wav", pos)
        sound.emitSound("ambient/machines/pneumatic_drill_4.wav", pos)
        sound.emitSound("ambient/misc/hammer1.wav", pos, 75, 100, 2)
        timer.simple(0.5, function()
            sound.emitSound("plats/hall_elev_door.wav", pos)
            craft.result(pos, ang)
        end)
    end

    net.receive("BModMakeCraft", function(_, ply)
        local id = net.readString()
        local pos = net.readVector()
        local ang = net.readAngle()
        local useProps = net.readBool()
        local item = cfg.crafts[id]
        if !item then return end
        BMod.makeCraft(ply, pos, ang, item, useProps)
    end)

else
    net.receive("BModErrorMessage", function()
        local mes = net.readString()
        bass.loadFile("sound/buttons/button10.wav", "", function() end)
        notification.addLegacy(mes, NOTIFY.ERROR, 3)
    end)
end
