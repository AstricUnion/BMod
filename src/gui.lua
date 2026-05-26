---@class ents
local ents = ents

---@class beff
local beff = beff

---@class resource
local resource = resource

---@class equipment
local equipment = equipment


if !CLIENT then return end

local Ply = player()

---@class bgui
local bgui = bgui
local DOCK = bgui.DOCK
---@class bguiElements
local bguiElements = {}

local EquipSlot = equipment.EquipSlot


---@type table<EquipSlot, string>
local PrettySlot = {
    [EquipSlot.abdomen] = "Abdomen",
    [EquipSlot.chest] = "Chest",
    [EquipSlot.back] = "Back",
    [EquipSlot.ears] = "Ears",
    [EquipSlot.eyes] = "Eyes",
    [EquipSlot.head] = "Head",
    [EquipSlot.mouthAndNose] = "Mouth & nose",
    [EquipSlot.pelvis] = "Pelvis",
    [EquipSlot.waist] = "Waist",
    [EquipSlot.leftCalf] = "Left calf",
    [EquipSlot.leftThigh] = "Left thigh",
    [EquipSlot.leftForearm] = "Left forearm",
    [EquipSlot.leftShoulder] = "Left shoulder",
    [EquipSlot.rightCalf] = "Right calf",
    [EquipSlot.rightThigh] = "Right thigh",
    [EquipSlot.rightForearm] = "Right forearm",
    [EquipSlot.rightShoulder] = "Right shoulder",
}

local C = bgui.COLORS

---BModelPanel class
---@class ArmorSlotButton: BButton
---@field player Player
---@field slot EquipSlot
---@field equippable Equippable?
local ArmorSlotButton = {}

---Set player and slot for this button
---@param slot EquipSlot
function ArmorSlotButton:setSlot(slot)
    self.slot = slot
end

function ArmorSlotButton:think()
    local plyEquipment = equipment.players[Ply]
    if plyEquipment then
        local slotInfo = plyEquipment[self.slot]
        if slotInfo then
            self.equippable = slotInfo
        end
    end
end

local slotFont = render.createFont("Verdana",11,500,true,false,false,false,0,true,0)

function ArmorSlotButton:paint(x, y, w, h)
    local isHover = self:testHover(bgui.cursorX, bgui.cursorY)
    local isDown = input.isMouseDown(MOUSE.MOUSE1)
    local col = (isHover and !isDown and C.fg1) or (isHover and isDown and C.blue) or C.fg
    local fgCol = (isHover and !isDown and C.blue) or (isHover and isDown and C.fg) or C.black
    render.setColor(col)
    render.drawRoundedBox(4, x, y, w, h)
    render.setColor(fgCol)
    render.setFont("Default")
    render.drawSimpleText(x + w / 2, y + h / 2, PrettySlot[self.slot], TEXT_ALIGN.CENTER, TEXT_ALIGN.BOTTOM)
    render.setColor(fgCol / 1.2)
    render.setFont(slotFont)
    local slotName = "-- EMPTY --"
    local plyEquipment = equipment.players[Ply]
    if plyEquipment then
        local slot = plyEquipment[self.slot]
        if slot then
            local entInfo = ents.registered[slot.ent.BModEquippable]
            if entInfo then
                slotName = entInfo.Name
            end
        end
    end
    render.drawSimpleText(x + w / 2, y + h / 2, slotName, TEXT_ALIGN.CENTER, TEXT_ALIGN.TOP)
end

function ArmorSlotButton:doClick()
    local plyEquipment = equipment.players[Ply]
    if !plyEquipment then return end
    local slot = plyEquipment[self.slot]
    if !slot then return end
    local control = bgui.create("BPanel")
    control:setPos(bgui.cursorX, bgui.cursorY)
    control:makePopup()
    local dropButton = bgui.create("BButton", control)
    dropButton:dock(DOCK.TOP)
    dropButton:dockMargin(4, 32, 4, 4)
    dropButton:setSize(0, 32)
    dropButton:setText("Drop")

    function dropButton.doClick(btn)
        equipment.dropEquippable(self.slot)
        control:remove()
    end

    function control:paint(x, y, w, h)
        render.setColor(Color(C.bg.r, C.bg.g, C.bg.b, 230))
        render.drawRoundedBox(4, x, y, w, h)
        render.setColor(C.fg1)
        render.setFont("DermaDefault")
        render.drawSimpleText(x + 8, y + 6, string.format("Durability: %s/%s", slot:getDurability(), slot.MaxDurability))
    end

    function control:onFocusChanged(gained)
        timer.simple(0, function()
            if !isValid(self) then return end
            for _, v in ipairs(self.sortedChildren) do
                if v:hasFocus() then return end
            end
            if !gained then
                self:remove()
            end
        end)
    end
end

bgui.register("ArmorSlotButton", ArmorSlotButton, "BButton")

local EquipSlotsLeft = {
    EquipSlot.head,
    EquipSlot.eyes,
    EquipSlot.mouthAndNose,
    EquipSlot.ears,
    EquipSlot.leftShoulder,
    EquipSlot.leftForearm,
    EquipSlot.leftThigh,
    EquipSlot.leftCalf,
}

local EquipSlotsRight = {
    EquipSlot.chest,
    EquipSlot.back,
    EquipSlot.waist,
    EquipSlot.pelvis,
    EquipSlot.rightShoulder,
    EquipSlot.rightForearm,
    EquipSlot.rightThigh,
    EquipSlot.rightCalf,
}


function bguiElements.inventory()
    local pnl = bgui.create("BFrame")
    pnl:setSize(640, 358)
    pnl:setText("Inventory")
    timer.simple(0, function()
        pnl:center()
    end)

    local pnl2 = bgui.create("BPanel", pnl)
    pnl2:dock(DOCK.RIGHT)
    pnl2:dockPadding(4, 4, 4, 4)

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
    end

    local pnl3 = bgui.create("BPanel", pnl)
    pnl3:dock(DOCK.LEFT)
    pnl3:dockPadding(4, 4, 4, 4)
    pnl3:setSize(96, 0)
    for _, id in ipairs(EquipSlotsLeft) do
        local slot = bgui.create("ArmorSlotButton", pnl3)
        slot:setSlot(id)
        slot:setSize(0, 36)
        slot:dockMargin(0, 0, 0, 4)
        slot:dock(DOCK.TOP)
    end

    local pnl4 = bgui.create("BModelPanel", pnl)
    pnl4:dock(DOCK.LEFT)
    pnl4:setSize(160, 0)
    pnl4:dockPadding(4, 4, 4, 4)
    timer.simple(0.1, function()
        if !isValid(pnl4.entity) then return end
        pnl4:setModel(player():getModel())
        pnl4.entity:setAnimation(3)
        timer.simple(0, function()
            if !isValid(pnl4.entity) then return end
            pnl4.entity.__drawOld = pnl4.entity.__drawOld or pnl4.entity.draw
            function pnl4.entity:draw()
                self:__drawOld()
                local plyEquipment = equipment.players[Ply]
                if !plyEquipment then return end
                for _, armor in pairs(plyEquipment) do
                    if !isValid(armor) then goto cont end
                    armor:draw(self)
                    ::cont::
                end
            end
        end)
    end)

    local pnl5 = bgui.create("BPanel", pnl)
    pnl5:dock(DOCK.LEFT)
    pnl5:dockPadding(4, 4, 4, 4)
    pnl5:setSize(96, 0)

    for _, id in ipairs(EquipSlotsRight) do
        local slot = bgui.create("ArmorSlotButton", pnl5)
        slot:setSlot(id)
        slot:setSize(0, 36)
        slot:dockMargin(0, 0, 0, 4)
        slot:dock(DOCK.TOP)
    end

    input.enableCursor(true)
end

if OWNER then
    enableHud(nil, true)
end

return bguiElements
