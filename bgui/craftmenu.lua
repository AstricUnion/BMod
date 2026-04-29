
---@class bmodConfig
local cfg = bmodConfig


---@class CraftRow: BLabel
local CraftRow = {}

function CraftRow:init()
    self:setSize(128, 64)
    self.craft = nil
end

function CraftRow:paint(x, y, w, h)
    render.setColor(Color(0, 0, 0, 200))
    render.drawRect(x, y, w, h)
    render.setColor(Color())
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
            icon(x + w - offset - iconSize, paintY - iconSize / 2, iconSize, iconSize)
        else
            render.drawSimpleText(x + w - offset - iconSize / 2, paintY, id, TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
        end
        render.drawSimpleText(x + w - offset - iconSize / 2, paintY + 24, "x" .. count, TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
        offset = offset - iconSize - 8
    end
end

bgui.register("CraftRow", CraftRow, "BLabel")


---@class CraftMenu: BFrame
local CraftMenu = {}

local oldInit = bgui.registered["BFrame"].init
function CraftMenu:init()
    oldInit(self)
    self:setSize(720, 512)
    self.tabs = nil
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
            butt.craft = craft
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
