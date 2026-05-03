
---@class bmodConfig
local cfg = bmodConfig


---@class CraftRow: BLabel
local CraftRow = {}

function CraftRow:init()
    self:dockMargin(0, 0, 0, 4)
    self:setSize(128, 64)
    self.craft = nil
    self.category = nil
    self.craftTable = nil
    self.canMake = false
    self.menu = nil
end

---@param craft BModCraft
function CraftRow:setCraft(category, craft)
    self.craft = craft
    self.category = category
end

---@param ent Entity
function CraftRow:setTable(ent)
    self.craftTable = ent
end

---@param menu CraftMenu
function CraftRow:setMenu(menu)
    self.menu = menu
    self:updateData()
end

function CraftRow:paint(x, y, w, h)
    if self.canMake then
        render.setColor(bgui.COLORS.bg)
        render.drawRoundedBox(4, x, y, w, h)
        render.setColor(Color())
    end
    local paintY = y + h / 2
    render.drawSimpleText(x + 48, paintY, self.text, TEXT_ALIGN.LEFT, TEXT_ALIGN.CENTER)
    local iconSize = 36
    if self.craft.icon then
        local draw = bicons.get(self.craft.icon)
        if draw then
            draw(x + 8, paintY - iconSize / 2, iconSize, iconSize)
        end
    end
    local offset = 16
    for id, count in pairs(self.craft.requires) do
        local icon = bicons.get(id)
        if icon then
            icon(x + w - offset - iconSize, paintY - iconSize / 2 - 8, iconSize, iconSize)
        else
            render.drawSimpleText(x + w - offset - iconSize / 2, paintY - 8, id, TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
        end
        render.drawSimpleText(x + w - offset - iconSize / 2, paintY + 18, "x" .. count, TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
        offset = offset + iconSize + 8
    end
    if !self.canMake then
        render.setColor(bgui.COLORS.bg)
        render.drawRoundedBox(4, x, y, w, h)
    end
end

function CraftRow:updateData()
    self.canMake = self:canByResources()
end

-- REPEAT CODE FROM autorun/sv_craftmenu.lua
function CraftRow:canByResources()
    local resources = self.menu.resources
    for id, count in pairs(self.craft.requires) do
        local current = resources[id]
        if !current or current < count then return false end
    end
    return true
end

function CraftRow:doClick()
    -- To error on server
    net.start("BModMakeCraft")
        net.writeString(self.category)
        net.writeString(self.craft.name)
        net.writeVector(self.craftTable:getPos() + Vector(0, 0, 50))
        net.writeAngle(self.craftTable:getAngles())
        net.writeBool(false)
    net.send()
    local menu = self.menu
    timer.simple(0, function()
        if !isValid(menu) then return end
        menu:updateResources()
    end)
end

bgui.register("CraftRow", CraftRow, "BLabel")


---@class ResourceRow: BLabel
local ResourceRow = {}

function ResourceRow:init()
    self:dockMargin(0, 0, 0, 4)
    self:setSize(128, 48)
    self.type = nil
    self.count = nil
end

function ResourceRow:paint(x, y, w, h)
    render.setColor(bgui.COLORS.bg)
    render.drawRoundedBox(4, x, y, w, h)
    render.setColor(Color())
    local paintY = y + h / 2
    render.drawSimpleText(x + 48, paintY, "x" .. self.count, TEXT_ALIGN.LEFT, TEXT_ALIGN.CENTER)
    local iconSize = 32
    local draw = bicons.get(self.type)
    if draw then
        draw(x + 8, paintY - iconSize / 2, iconSize, iconSize)
    end
end

bgui.register("ResourceRow", ResourceRow, "BLabel")


---@class CraftMenu: BFrame
---@field resourcesMenu BScrollPanel
---@field tabs BPropertySheet?
---@field rows CraftRow[]
---@field resources table<string, number>
local CraftMenu = {}

local oldInit = bgui.registered["BFrame"].init
function CraftMenu:init()
    oldInit(self)
    self:setSize(720, 512)
    local resourcesMenu = bgui.create("BScrollPanel", self)
    resourcesMenu.canvas:dockPadding(4, 4, 4, 4)
    resourcesMenu:dock(bgui.DOCK.LEFT)
    resourcesMenu:dockMargin(0, 0, 4, 0)
    resourcesMenu.paint = bgui.registered["BPanel"].paint
    self.resourcesMenu = resourcesMenu
    local tabs = bgui.create("BPropertySheet", self)
    tabs.canvas:dockPadding(4, 4, 4, 4)
    tabs:dock(bgui.DOCK.FILL)
    self.tabs = tabs
    self.craftTable = nil
    self.rows = {}
    self:updateResources()
end

function CraftMenu:updateResources()
    local resources = resource.getResources(player(), false)
    local formattedRes = {}
    for res, v in pairs(resources) do
        formattedRes[res] = v.count
    end
    self.resources = formattedRes
    for _, v in ipairs(self.rows) do
        v:updateData()
    end
    for type, count in pairs(formattedRes) do
        for _, v in ipairs(self.resourcesMenu.canvas.sortedChildren) do
            ---@cast v ResourceRow
            if v.type == type then
                if count == 0 then
                    v:remove()
                elseif count ~= v.count then
                    v.count = count
                end
                goto cont
            end
        end
        -- We didn't found the resource
        local resObj = bgui.create("ResourceRow")
        resObj.type = type
        resObj.count = count
        self.resourcesMenu:addItem(resObj)
        ::cont::
    end
end

---@param ent Entity
function CraftMenu:setTable(ent)
    self.craftTable = ent
end

function CraftMenu:setType(type)
    for category, crafts in pairs(cfg.crafts) do
        local categoryPanel = bgui.create("BScrollPanel", self.tabs)
        local craftsAdded = {}
        for _, craft in ipairs(crafts) do
            if !craft.methods[type] then goto cont end
            local butt = bgui.create("CraftRow")
            butt:setText(craft.name)
            butt:setCraft(category, craft)
            butt:setMenu(self)
            butt:setTable(self.craftTable)
            categoryPanel:addItem(butt)
            craftsAdded[#craftsAdded+1] = butt
            ::cont::
        end
        if next(craftsAdded) == nil then
            categoryPanel:remove()
        else
            table.add(self.rows, craftsAdded)
            self.tabs:addSheet(category, categoryPanel)
        end
    end
end

bgui.register("CraftMenu", CraftMenu, "BFrame")
