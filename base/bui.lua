---@name BUI (BMod User Interface)
---@author AstricUnion
---@client

-----[ Prelude ]-----

---Class to manipulate UI
---@class bgui
---@field inited table<number, BUIPanel> Inited panels
---@field registered table<string, BUIPanel> Registrated classes
local bgui = {}
bgui.inited = {}
bgui.registered = {}
bgui.hooks = {}


---Register new BUI element
---@param classname string Panel class name, to identificate it
---@param panelclass BUIPanel Panel class to create new GUI panel
function bgui.register(classname, panelclass)
    bgui.registered[classname] = panelclass
end

---Create new BUI element
---@generic T: BUIPanel
---@param classname `T` Panel class name, to identificate it
---@param parent BUIPanel? Parent object
---@return T
function bgui.create(classname, parent)
    return bgui.registered[classname]:new(parent)
end

hook.add("DrawHUD", "BUIPaint", function()
    for _, v in pairs(bgui.inited) do
        local w, h = v:getSize()
        v:paint(w, h)
        render.setColor(Color(255, 255, 255, 255))
        render.setFont("Default")
        render.setMaterial()
    end
end)


hook.add("Think", "BUIThink", function()
    for _, v in pairs(bgui.inited) do
        v:think()
    end
end)

local function isMouse(key)
    for _, en in pairs(MOUSE) do
        if key == en then
            return true
        end
    end
    return false
end

hook.add("InputPressed", "BUIThink", function(key)
    if input.getCursorVisible() then
        if isMouse(key) then
            for _, v in pairs(bgui.inited) do
                v:onMousePressed(key)
            end
        end
    end
end)

hook.add("InputReleased", "BUIThink", function(key)
    if input.getCursorVisible() then
        if isMouse(key) then
            for _, v in pairs(bgui.inited) do
                v:onMouseReleased(key)
            end
        end
    end
end)


---@enum BDOCK
local BDOCK = {
    NODOCK = 0,
    FILL = 1,
    LEFT = 2,
    RIGHT = 3,
    TOP = 4,
    BOTTOM = 5
}


-----[ Base class ]-----
---@class Margins
---@field left number
---@field top number
---@field right number
---@field bottom number

---Base class for UI elements
---@class BUIPanel
---@field index number Index of panel
---@field parent BUIPanel? Parent of this panel. If not nil, panel will be relative to it
---@field childs BUIPanel[] Childs of this panel
---@field x number Local panel position by X
---@field y number Local panel position by Y
---@field w number Panel width
---@field h number Panel height
---@field dockX number Local panel position by X on dock
---@field dockY number Local panel position by Y on dock
---@field dockW number Panel width on dock
---@field dockH number Panel height on dock
---@field dockMargins Margins Margins on dock
---@field dockPaddings Margins Padding on dock
---@field minW number Panel minimum width
---@field minH number Panel minimum height
---@field docktype BDOCK height (GLua tall)
---@field visible boolean Is this panel visible
---@field bgcolor Color Background color of this panel
local BUIPanel = {}
BUIPanel.__index = BUIPanel


---Create new panel
---@param parent BUIPanel? Parent of this panel. If not nil, panel will be relative to it
---@return BUIPanel
function BUIPanel:new(parent)
    local x, y, w, h = 0, 0, 128, 128
    local index = #bgui.inited+1
    local obj = setmetatable({
        index = index,
        parent = parent,
        childs = {},
        x = y, y = x, w = w, h = h,
        dockX = y, dockY = x,
        dockMargins = {left = 0, top = 0, right = 0, bottom = 0},
        dockPaddings = {left = 0, top = 0, right = 0, bottom = 0},
        minW = 0, minH = 0, docktype = 0, visible = true,
        bgcolor = Color(200, 200, 200)
    }, self)
    if parent then
        parent.childs[#parent.childs+1] = obj
        parent:invalidateLayout()
    end
    bgui.inited[index] = obj
    obj:init()
    return obj
end


---Get global position of this panel. Use this to draw
---@return number x, number y
function BUIPanel:getPos()
    local cond = self.docktype > 0
    local selfX = cond and self.dockX or self.x
    local selfY = cond and self.dockY or self.y
    local x, y
    if self.parent then
        local pX, pY = self.parent:getPos()
        x, y = pX + selfX, pY + selfY
    else
        x, y = selfX, selfY
    end
    return x, y
end

---Set local position of this panel
---@param x number
---@param y number
function BUIPanel:setPos(x, y)
    self.x = x
    self.y = y
end

---Get size of this panel. Use this to draw
---@return number w, number h
function BUIPanel:getSize()
    local cond = self.docktype > 0
    local selfW = cond and self.dockW or self.w
    local selfH = cond and self.dockH or self.h
    local w, h = math.max(selfW, self.minW), math.max(selfH, self.minH)
    return w, h
end

---Set size for this panel
---@param w number
---@param h number
function BUIPanel:setSize(w, h)
    self.w = w
    self.h = h
    self:invalidateLayout()
end


---Invalidate layout. Will call hook performLayout
function BUIPanel:invalidateLayout()
    local w, h = self:getSize()
    local pad = self.dockPaddings
    for _, v in pairs(self.childs) do
        if v.docktype == 0 then goto cont end
        v.dockX = v.dockMargins.left + pad.left
        v.dockY = v.dockMargins.top + pad.top
        v.dockW = (w - v.dockMargins.right * 2 - pad.right * 2)
        v.dockH = (h - v.dockMargins.bottom * 2 - pad.bottom * 2)
        if v.docktype == BDOCK.LEFT then
            v.dockW = v.w
        elseif v.docktype == BDOCK.RIGHT then
            v.dockX = v.dockW - v.w + v.dockMargins.right + pad.right
            v.dockW = v.w
        elseif v.docktype == BDOCK.TOP then
            v.dockH = v.h
        elseif v.docktype == BDOCK.BOTTOM then
            v.dockY = v.dockH - v.h + v.dockMargins.left + pad.left
            v.dockH = v.h
        end
        v:invalidateLayout()
        ::cont::
    end
    self:performLayout()
end


---Invalidate parent layout. Will call hook performLayout on parent
---You can safely call it
function BUIPanel:invalidateParent()
    if self.parent then
        self.parent:invalidateLayout()
    end
end


---Dock this panel on parent
---@param docktype BDOCK Dock type
function BUIPanel:dock(docktype)
    self.docktype = docktype
    self:invalidateParent()
end


---Dock margins for panel
---@param left number
---@param top number
---@param right number
---@param bottom number
function BUIPanel:dockMargin(left, top, right, bottom)
    self.dockMargins = {
        left = left,
        top = top,
        right = right,
        bottom = bottom
    }
    self:invalidateParent()
end


---Dock padding for panel children
---@param left number
---@param top number
---@param right number
---@param bottom number
function BUIPanel:dockPadding(left, top, right, bottom)
    self.dockPaddings = {
        left = left,
        top = top,
        right = right,
        bottom = bottom
    }
    self:invalidateLayout()
end


---On panel initialize
function BUIPanel:init() end

---Paint in panel
function BUIPanel:paint(w, h)
    local x, y = self:getPos()
    render.setColor(Color(
        self.bgcolor.r / 1.5,
        self.bgcolor.g / 1.5,
        self.bgcolor.b / 1.5
    ))
    render.drawRect(x, y, w, h)
    render.setColor(self.bgcolor)
    render.drawRect(x + 2, y + 2, w - 4, h - 4)
end

---Perform layout. Can be called with invalidateLayout
function BUIPanel:performLayout() end

---Think hook. To place server tick addicted functions
function BUIPanel:think() end

---Calls when mouse button pressed
---@param key MOUSE
function BUIPanel:onMousePressed(key) end

---Calls when mouse button released
---@param key MOUSE
function BUIPanel:onMouseReleased(key) end


bgui.register("BUIPanel", BUIPanel)


-----[ Other classes ]-----

---Label class
---@class BUILabel: BUIPanel
---@field font string
---@field text string
---@field fgcolor Color
local BUILabel = setmetatable({}, BUIPanel)
BUILabel.__index = BUILabel


function BUILabel:init()
    self.font = "Default"
    self.text = "Label"
    self.fgcolor = Color(0, 0, 0)
end


function BUILabel:paint(w, h)
    local x, y = self:getPos()
    render.setFont(self.font)
    render.setColor(self.fgcolor)
    render.drawSimpleText(x, y, self.text)
end

bgui.register("BUILabel", BUILabel)


local pnl = bgui.create("BUIPanel")
pnl:setSize(256, 256)
pnl:dockPadding(10, 10, 10, 10)
local pnl2 = bgui.create("BUIPanel", pnl)
pnl2.bgcolor = Color(50, 50, 50)
pnl2:dockMargin(20, 20, 20, 20)
local pnl3 = bgui.create("BUIPanel", pnl2)
pnl3.bgcolor = Color(150, 0, 0)
timer.simple(1, function()
    pnl:setPos(10, 10)
    pnl2:dock(BDOCK.FILL)
    pnl3:dock(BDOCK.LEFT)
end)
enableHud(nil, true)
