---@name BMod GUI elements
---@author AstricUnion
---@shared

---@class ents
local ents = ents

---@class beff
local beff = beff

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
                local ply = player()
                local shootPos = ply:getShootPos()
                local tr = trace.line(shootPos, shootPos + ply:getEyeAngles():getForward() * 256, {ply})
                net.start("BModMakeCraft")
                    net.writeString("Handcraft")
                    net.writeString("Crafting table")
                    net.writeVector(tr.HitPos)
                    net.writeAngle(Angle())
                    net.writeBool(true)
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
            pnl3.entity:setAnimation(3)
        end)
        input.enableCursor(true)
    end

    if player() == owner() then
        enableHud(nil, true)
    end

    return bguiElements
end
