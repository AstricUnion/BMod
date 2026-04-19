---@name BMod GUI elements
---@author AstricUnion
---@shared
---@owneronly
---@include bmod/base/bgui.lua

---@class ents
local ents = ents
---@class resource
local resource = resource


if CLIENT then
    ---@class bgui
    local bgui = require("bmod/base/bgui.lua")
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

    enableHud(nil, true)

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
        ---@cast ply Player
        local res = resource.getResources(ply, true)
        local wood = res.wood and res.wood.count or 0
        local aluminium = res.aluminium and res.aluminium.count or 0
        local ceramic = res.ceramic and res.ceramic.count or 0
        local errorMes = "You need"
        local wDiff = req.wood - wood
        if wDiff > 0 then
            errorMes = errorMes .. " " .. wDiff .. " more wood"
        end
        local aDiff = req.aluminium - aluminium
        if aDiff > 0 then
            errorMes = errorMes .. " " .. aDiff .. " more aluminium"
        end
        local cDiff = req.ceramic - ceramic
        if cDiff > 0 then
            errorMes = errorMes .. " " .. cDiff .. " more ceramic"
        end
        if errorMes ~= "You need" then
            net.start("BModCenterError")
                net.writeString(errorMes)
            net.send(ply)
            return
        end

        local function takeResources(type, originalTbl)
            table.sortByMember(originalTbl, "count")
            local required = req[type]
            for _, info in ipairs(originalTbl) do
                if required <= 0 then break end
                local resType = info.ent.BModResource
                if !resType then
                    required = required - info.count
                    info.ent:remove()
                else
                    local foundRes = ents.inited[info.ent:entIndex()]
                    ---@cast foundRes Resource
                    local count = foundRes:getCount()
                    local diff = count - required
                    res:setCount(diff)
                    required = math.abs(diff)
                end
            end
            return required
        end

        takeResources("wood", res.wood.ents)
        takeResources("aluminium", res.aluminium.ents)
        takeResources("ceramic", res.ceramic.ents)

        local shootPos = ply:getShootPos()
        ---@type TraceResult
        local tr = trace.line(shootPos, shootPos + ply:getForward() * 256, {ply})
        local ent = ents.create("crafting_table")
        ent:spawn(tr.HitPos + Vector(0, 0, 1), Angle(), false)
    end)
end
