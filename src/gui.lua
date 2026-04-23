---@name BMod GUI elements
---@author AstricUnion
---@shared

---@class ents
local ents = ents
---@class resource
local resource = resource


if CLIENT then
    ---@class bgui
    local bgui = bgui
    local DOCK = bgui.DOCK
    ---@class bguiElements
    local bguiElements = {}


    function bguiElements.inventory()
        --[[test example]]
        local pnl = bgui.create("BFrame")
        pnl:setSize(512, 320)
        pnl:setText("Inventory")
        timer.simple(0, function()
            pnl:center()
        end)

        local pnl2 = bgui.create("BPanel", pnl)
        -- pnl2.bgcolor = Color(0, 0, 0, 0)
        pnl2:dock(DOCK.RIGHT)
        pnl2:dockPadding(4, 4, 4, 4)

        local buttons = {}
        local buttonsInfo = {
            ["Bombdrop"] = function() end,
            ["Launch"] = function() end,
            ["Trigger"] = function() end,
            ["Scrounge"] = function() end,
            ["Grab"] = function() end,
            ["Handcraft"] = function()
                net.start("BModHandcraft")
                net.send()
            end,
        }

        for name, func in pairs(buttonsInfo) do
            local btn = bgui.create("BButton", pnl2)
            btn:setSize(0, 24)
            btn:dockMargin(0, 0, 0, 4)
            btn:setText(name)
            btn:dock(DOCK.TOP)
            btn.doClick = func
            buttons[#buttons+1] = btn
        end

        local pnl3 = bgui.create("BModelPanel", pnl)
        pnl3:dock(DOCK.LEFT)
        pnl3:dockPadding(4, 4, 4, 4)
        timer.simple(0.1, function()
            pnl3:setModel(player():getModel())
            pnl3.entity:setAnimation(2)
        end)
        input.enableCursor(true)
    end

    if player() == owner() then
        enableHud(nil, true)
    end

    net.receive("BModCenterError", function()
        local msg = net.readString()
        printMessage(4, msg)
    end)

    return bguiElements
else
    -- hardcoded shitt
    local req = {
        wood = 25,
        aluminium = 8,
        ceramic = 15
    }
    net.receive("BModHandcraft", function(_, ply)
        -- local errorMes = resource.takeResources(ply, req, true)
        if errorMes then
            net.start("BModCenterError")
                net.writeString(errorMes)
            net.send(ply)
            return
        end
        local shootPos = ply:getShootPos()
        ---@type TraceResult
        local tr = trace.line(shootPos, shootPos + ply:getEyeAngles():getForward() * 256, {ply})
        local ent = ents.create("crafting_table")
        ent:spawn(tr.HitPos + Vector(0, 0, 1), Angle(), false)
    end)
end
