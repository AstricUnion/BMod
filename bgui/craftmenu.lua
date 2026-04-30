
---@class bmodConfig
local cfg = bmodConfig


---@class CraftRow: BLabel
local CraftRow = {}

function CraftRow:init()
    self:setSize(128, 64)
    self.craft = nil
    self.category = nil
    self.craftTable = nil
    self.canMake = false
end

---@param craft BModCraft
---@param resources table<string, number>
function CraftRow:setCraft(category, craft, resources)
    self.craft = craft
    self.category = category
    self.canMake = self:canByResources(resources)
end

---@param ent Entity
function CraftRow:setTable(ent)
    self.craftTable = ent
end

function CraftRow:paint(x, y, w, h)
    if self.canMake then
        render.setColor(Color(0, 0, 0, 200))
        render.drawRect(x, y, w, h)
        render.setColor(Color())
    end
    local paintY = y + h / 2
    render.drawSimpleText(x + 48, paintY, self.text, TEXT_ALIGN.LEFT, TEXT_ALIGN.CENTER)
    local iconSize = 32
    if self.craft.icon then
        bicons.get(self.craft.icon)(x + 8, paintY - iconSize / 2, iconSize, iconSize)
    end
    local offset = 16 + iconSize
    for id, count in pairs(self.craft.requires) do
        local icon = bicons.get(id)
        if icon then
            icon(x + w - offset - iconSize, paintY - iconSize / 2 - 8, iconSize, iconSize)
        else
            render.drawSimpleText(x + w - offset - iconSize / 2, paintY - 8, id, TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
        end
        render.drawSimpleText(x + w - offset - iconSize / 2, paintY + 16, "x" .. count, TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
        offset = offset - iconSize - 8
    end
    if !self.canMake then
        render.setColor(Color(0, 0, 0, 200))
        render.drawRect(x, y, w, h)
    end
end

-- REPEAT CODE FROM autorun/sv_craftmenu.lua
function CraftRow:canByResources(resources)
    for id, count in pairs(self.craft.requires) do
        if resources[id] < count then return false end
    end
    return true
end

function CraftRow:doClick()
    if !self.canMake then
        notification.addLegacy("You can't make this craft!", NOTIFY.ERROR, 3)
        return
    end
    net.start("BModMakeCraft")
        net.writeString(self.category)
        net.writeString(self.craft.name)
        net.writeEntity(self.craftTable)
    net.send()
end

bgui.register("CraftRow", CraftRow, "BLabel")


---@class CraftMenu: BFrame
---@field resources table<string, number>
local CraftMenu = {}

local oldInit = bgui.registered["BFrame"].init
function CraftMenu:init()
    oldInit(self)
    self:setSize(720, 512)
    self.tabs = nil
    local resources = resource.getResources(player(), false)
    local formattedRes = {}
    for res, v in pairs(resources) do
        formattedRes[res] = v.count
    end
    self.resources = formattedRes
    self.craftTable = nil
end

---@param ent Entity
function CraftMenu:setTable(ent)
    self.craftTable = ent
end

function CraftMenu:setType(type)
    if self.tabs then self.tabs:remove() end
    local tabs = bgui.create("BPropertySheet", self)
    tabs.canvas:dockPadding(4, 4, 4, 4)
    tabs:dock(bgui.DOCK.FILL)
    for category, crafts in pairs(cfg.crafts) do
        local categoryPanel = bgui.create("BScrollPanel", tabs)
        local craftsAdded = {}
        for _, craft in ipairs(crafts) do
            if !craft.methods[type] then goto cont end
            local butt = bgui.create("CraftRow")
            butt:setText(craft.name)
            butt:setCraft(category, craft, self.resources)
            butt:setTable(self.craftTable)
            categoryPanel:addItem(butt)
            craftsAdded[#craftsAdded+1] = craft
            ::cont::
        end
        if next(craftsAdded) == nil then
            categoryPanel:remove()
        else
            tabs:addSheet(category, categoryPanel)
        end
    end
    self.tabs = tabs
end

bgui.register("CraftMenu", CraftMenu, "BFrame")
