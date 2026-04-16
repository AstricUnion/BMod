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

---Base class for UI elements
---@class BUIPanel
---@field index number Index of panel
---@field parent BUIPanel? Parent of this panel. If not nil, panel will be relative to it
---@field x number Local panel position by X
---@field y number Local panel position by Y
---@field w number Panel width
---@field h number Panel height
---@field minW number Panel minimum width
---@field minH number Panel minimum height
---@field dock BDOCK height (GLua tall)
---@field visible boolean Is this panel visible
---@field bgcolor Color Background color of this panel
local BUIPanel = {}
BUIPanel.__index = BUIPanel


---Create new panel
---@param parent BUIPanel? Parent of this panel. If not nil, panel will be relative to it
---@return BUIPanel
function BUIPanel:new(parent)
    local x, y, w, h
    if parent then
        x = parent.x
        y = parent.y
        w = math.min(parent.w, 128)
        h = math.min(parent.h, 128)
    else
        x, y, w, h = 0, 0, 128, 128
    end
    local index = #bgui.inited+1
    local obj = setmetatable({
        index = index,
        parent = parent,
        x = y, y = x, w = w, h = h,
        minW = 0, minH = 0, dock = BDOCK.NODOCK, visible = true,
        bgcolor = Color(200, 200, 200)
    }, self)
    bgui.inited[index] = obj
    obj:init()
    return obj
end


---Get global position of this panel. Use this to draw
---@return number x, number y
function BUIPanel:getPos()
    local x, y
    if self.parent then
        x, y = self.parent.x + self.x, self.parent.y + self.y
    else
        x, y = self.x, self.y
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
    local w, h
    if self.parent then
        w, h = math.max(self.w, self.minW, self.parent.w), math.max(self.h, self.minH, self.parent.h)
    else
        w, h = math.max(self.w, self.minW), math.max(self.h, self.minH)
    end
    return w, h
end

---Set size for this panel
---@param w number
---@param h number
function BUIPanel:setSize(w, h)
    self.w = w
    self.h = h
end

---On panel initialize
function BUIPanel:init() end

---Paint in panel
function BUIPanel:paint(w, h)
    local x, y = self:getPos()
    render.setColor(Color(
        self.bgcolor.r - 50,
        self.bgcolor.g - 50,
        self.bgcolor.b - 50
    ))
    render.drawRect(x, y, w, h)
    render.setColor(self.bgcolor)
    render.drawRect(x + 2, y + 2, w - 4, h - 4)
end

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
bgui.create("BUILabel", pnl)
timer.simple(1, function()
    pnl:setPos(10, 10)
end)
enableHud(nil, true)
