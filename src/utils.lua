
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

    local Matrix = Matrix
    local pushMatrix = render.pushMatrix
    local popMatrix = render.popMatrix
    local enableDepth = render.enableDepth
    local setFont = render.setFont
    local setColor = render.setColor
    local defScale = Vector(0.1, -0.1, 1)
    local defAngles = Angle(0, 90, 90)
    local defColor = Color()

    ---[CLIENT] Display for entities
    ---@param ent Entity Entity
    ---@param offset Vector Offset of display
    ---@param angle Angle? Angles of display
    ---@param draw fun() Function to draw
    function BMod.displayEnt(ent, offset, angle, draw)
        local pos = Ply.getPos(Ply)
        local mPos = ent:localToWorld(offset)
        if mPos:getDistance(pos) > 196 then return end
        local ang = ent:getAngles()
        local m = Matrix(ang, mPos)
        m:rotate(defAngles + angle)
        m:setScale(defScale)
        pushMatrix(m)
        do
            enableDepth(true)
            setFont(font)
            setColor(defColor)
            draw()
        end
        popMatrix()
    end

    ---[CLIENT] Display in world
    ---@param pos Vector Offset of display
    ---@param angle Angle? Angles of display
    ---@param draw fun() Function to draw
    ---@param distance number? Distance to disappear. Default 196
    function BMod.display(pos, angle, draw, distance)
        local plyPos = Ply:getPos()
        distance = distance or 196
        if pos:getDistance(plyPos) > distance then return end
        local m = Matrix(angle, pos)
        m:rotate(defAngles + angle)
        m:setScale(defScale)
        pushMatrix(m)
        do
            enableDepth(true)
            setFont(font)
            setColor(defColor)
            draw()
        end
        popMatrix()
    end

    -- hook.add("DrawHUD", "BModEntityInfo", function()
    --     if !bgui.screenWidth then return end
    --     local ply = player()
    --     local shootPos = ply:getShootPos()
    --     local tr = trace.line(shootPos, shootPos + ply:getEyeAngles():getForward() * 96, {ply})
    --     if !isValid(tr.Entity) then return end
    --     local centerW, centerH = bgui.screenWidth / 2, bgui.screenHeight / 2
    --     render.setColor(Color(50, 50, 50))
    --     render.drawRoundedBox(4, centerW + 16, centerH + 16, 196, 128)
    --     render.setColor(bgui.COLORS.bg)
    --     render.drawRoundedBox(4, centerW + 20, centerH + 20, 196, 24)
    --     render.setFont("CenterPrintText")
    --     render.setColor(Color())
    --     if tr.Entity.BModMachine then
    --         local class = ents.registered[tr.Entity.BModMachine]
    --         render.drawSimpleText(centerW + 24, centerH + 24, class.Name)
    --     end
    -- end)
    --

    ---@type Bass?
    local hintSound

    ---@type Bass?
    local errorSound

    net.receive("BModErrorMessage", function()
        if !render.isHUDActive() then return end
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
        if !render.isHUDActive() then return end
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
    pcall(printConsole, Color(90, 150, 220), "[BMod] ", Color(255, 255, 255), string.format(msg, ...))
end

---[SHARED] Log debug BMod message in console
---@param msg string String to format
---@param ... any Arguments to format
function BMod.logDebug(msg, ...)
    if !BMod.debug then return end
    pcall(printConsole, Color(220, 220, 90), "[BMod Debug] ", Color(255, 255, 255), string.format(msg, ...))
end
