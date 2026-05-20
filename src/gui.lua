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
                    net.writeString("crafting_table")
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

        local pnl3 = bgui.create("BPanel", pnl)
        pnl3:dock(DOCK.LEFT)
        pnl3:dockPadding(4, 4, 4, 4)
        pnl3:setSize(96, 0)
        for name, id in pairs(equipment.EquipSlot) do
            local slot = bgui.create("BButton", pnl3)
            slot:setSize(0, 36)
            slot:dockMargin(0, 0, 0, 4)
            slot:dock(DOCK.TOP)
            slot:setText(name)
        end

        local pnl4 = bgui.create("BModelPanel", pnl)
        pnl4:dock(DOCK.LEFT)
        pnl4:dockPadding(4, 4, 4, 4)
        timer.simple(0.1, function()
            pnl4:setModel(player():getModel())
            pnl4.entity:setAnimation(3)
        end)

        local pnl5 = bgui.create("BPanel", pnl)
        pnl5:dock(DOCK.LEFT)
        pnl5:dockPadding(4, 4, 4, 4)
        pnl5:setSize(96, 0)

        input.enableCursor(true)
    end

    if OWNER then
        enableHud(nil, true)
    end

    return bguiElements
end
