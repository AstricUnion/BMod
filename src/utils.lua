
if SERVER then
    ---@param ply Player Player to message
    ---@param message string String to message
    function BMod.errorMessage(ply, message)
        net.start("BModErrorMessage")
            net.writeString(message)
        net.send(ply)
    end

    ---@param ply Player Player to message
    ---@param message string String to message
    function BMod.hintMessage(ply, message)
        net.start("BModHintMessage")
            net.writeString(message)
        net.send(ply)
    end

    net._oldSend = net._oldSend or net.send
    local tickStart = game.getTickCount

    ---[SERVER] Send message to client optimized
    ---@param target table|Player|nil
    ---@param unreliable boolean?
    function net.send(target, unreliable)
        if game.getTickCount() == tickStart then
            pcall(net.abort)
            return
        end
        net._oldSend(target, unreliable)
    end
else
    local Ply = player()
    local font = render.createFont("Roboto",32,500,false,false,false,false,0,false,0)

    ---[CLIENT] Display for entities
    ---@param ent Entity Entity
    ---@param offset Vector? Offset of display
    ---@param angle Angle? Angles of display
    ---@param draw string|fun() Text to display or function to draw
    ---@param distance number? Distance to disappear. Default 256
    function BMod.displayEnt(ent, offset, angle, draw, distance)
        local pos = Ply:getPos()
        distance = distance or 256
        local mPos = ent and ent:localToWorld(offset or Vector())
        if mPos:getDistance(pos) > distance then return end
        local ang = ent:getAngles()
        local m = Matrix(ang, mPos)
        m:rotate(Angle(0, 90, 90) + angle)
        m:setScale(Vector(0.1, -0.1, 1))
        render.pushMatrix(m)
        do
            render.enableDepth(true)
            render.setFont(font)
            render.setColor(Color())
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

    ---[CLIENT] Display in world
    ---@param pos Vector Offset of display
    ---@param angle Angle? Angles of display
    ---@param draw string|fun() Text to display or function to draw
    ---@param distance number? Distance to disappear. Default 256
    function BMod.display(pos, angle, draw, distance)
        local plyPos = Ply:getPos()
        distance = distance or 256
        if pos:getDistance(plyPos) > distance then return end
        local m = Matrix(angle, pos)
        m:rotate(Angle(0, 90, 90) + angle)
        m:setScale(Vector(0.1, -0.1, 1))
        render.pushMatrix(m)
        do
            render.enableDepth(true)
            render.setFont(font)
            render.setColor(Color())
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


    ---@type Bass?
    local hintSound

    ---@type Bass?
    local errorSound

    net.receive("BModErrorMessage", function()
        local mes = net.readString()
        if errorSound then
            errorSound:setTime(0)
            errorSound:play()
        else
            bass.loadFile("sound/buttons/button10.wav", "noblock", function(bass, err)
                if err ~= 0 then return end
                errorSound = bass
            end)
        end
        notification.addLegacy(mes, NOTIFY.ERROR, 3)
    end)


    net.receive("BModHintMessage", function()
        local mes = net.readString()
        if hintSound then
            hintSound:setTime(0)
            hintSound:play()
        else
            bass.loadFile("sound/buttons/blip1.wav", "noblock", function(bass, err)
                if err ~= 0 then return end
                hintSound = bass
            end)
        end
        notification.addLegacy(mes, NOTIFY.HINT, 3)
    end)
end

---[SHARED] Log BMod message in console
---@param msg string String to format
---@param ... any Arguments to format
function BMod.log(msg, ...)
    printConsole(Color(90, 150, 220), "[BMod] ", Color(255, 255, 255), string.format(msg, ...))
end

---[SHARED] Log debug BMod message in console
---@param msg string String to format
---@param ... any Arguments to format
function BMod.logDebug(msg, ...)
    if !BMod.debug then return end
    printConsole(Color(220, 220, 90), "[BMod Debug] ", Color(255, 255, 255), string.format(msg, ...))
end
