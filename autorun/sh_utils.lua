
if CLIENT then
    local Ply = player()
    local font = render.createFont("Roboto",32,500,false,false,false,false,0,false,0)

    ---[CLIENT] Display for entities
    ---@param ent Entity
    ---@param offset Vector? Offset of display
    ---@param angle Angle? Angles of display
    ---@param draw string|fun() Text to display or function to draw
    function BMod.Display(ent, offset, angle, draw)
        local pos = Ply:getPos()
        if !isValid(ent) then return end
        if ent:getPos():getDistance(pos) > 256 then return end
        local ang = ent:getAngles()
        local m = Matrix(ang, ent:localToWorld(offset or Vector()))
        m:rotate(Angle(0, 90, 90) + (angle or Angle()))
        m:setScale(Vector(0.1, -0.1, 1))
        render.pushMatrix(m)
        do
            render.enableDepth(true)
            render.setFont(font)
            if isfunction(draw) then
                ---@cast draw fun()
                draw()
            else
                ---@cast draw string
                render.drawSimpleText(0, 0, draw, TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
            end
        end
        render.popMatrix()
    end
else
    ---@param ply Player Player to message
    ---@param message string String to message
    function BMod.errorMessage(ply, message)
        net.start("BModErrorMessage")
            net.writeString(message)
        net.send(ply)
    end
end
