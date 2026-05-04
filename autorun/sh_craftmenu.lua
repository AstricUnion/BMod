if SERVER then
    ---@class bmodConfig
    local cfg = bmodConfig

    ---@class beff
    local beff = beff

    net.receive("BModMakeCraft", function(_, ply)
        local id = net.readString()
        local pos = net.readVector()
        local ang = net.readAngle()
        local useProps = net.readBool()
        local item = cfg.crafts[id]
        if !item then return end
        local errorMes = resource.takeResources(ply, item.requires, useProps)
        if errorMes then
            net.start("BModErrorMessage")
                net.writeString(errorMes)
            net.send(ply)
            return
        end
        local eff = beff.create("craft_effect")
        eff:setOrigin(pos)
        eff:setScale(item.scale or 1)
        eff:play()
        sound.emitSound("ambient/machines/spinup.wav", pos)
        sound.emitSound("ambient/machines/pneumatic_drill_4.wav", pos)
        sound.emitSound("ambient/misc/hammer1.wav", pos, 75, 100, 2)
        timer.simple(0.5, function()
            sound.emitSound("plats/hall_elev_door.wav", pos)
            item.result(pos, ang)
        end)
    end)

else
    net.receive("BModErrorMessage", function()
        local mes = net.readString()
        bass.loadFile("sound/buttons/button10.wav", "", function() end)
        notification.addLegacy(mes, NOTIFY.ERROR, 3)
    end)
end
