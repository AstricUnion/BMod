---VGUI-like graphical interface for Starfall
---@name BGUI (BMod Graphical User Interface)
---@author AstricUnion
---@shared
if SERVER then return end

-----[ Prelude ]-----

---Class to manipulate UI
---@class bgui
---@field inited table<number, BPanel> Inited panels
---@field ordered table<number, BPanel> Ordered panels
---@field registered table<string, BPanel> Registrated classes
---@field focus BPanel? Focused panel
---@field screenWidth number Current screen width
---@field screenHeight number Current screen height
---@field cursorX number Current screen width
---@field cursorY number Current screen height
---@field cursorEnabled boolean Is cursor enabled now
---@field canvas BPanel? Canvas (default sized to screen)
---@field debug boolean Enable debug mode
local bgui = {}
bgui.inited = {}
bgui.ordered = {}
bgui.registered = {}
bgui.cursorX, bgui.cursorY = input.getCursorPos()
bgui.cursorEnabled = false


---Register new B element
---@param classname string Panel class name, to identificate it
---@param panelclass table Panel class to create new GUI panel
---@param inheritFrom string Already registered class to inherit it. Default BPanel
function bgui.register(classname, panelclass, inheritFrom)
    -- Inherit from other entity
    inheritFrom = inheritFrom or "BPanel"
    local inheritClass = bgui.registered[inheritFrom] -- base will be main for all
    if !inheritClass then
        throw("Can't inherit panel class \"" .. inheritFrom .. "\": doesn't exist")
        return
    end
    local inheritedClass = setmetatable(panelclass, inheritClass)
    inheritedClass.__index = panelclass
    inheritedClass.__name = classname
    inheritedClass.__tostring = inheritClass.__tostring
    bgui.registered[classname] = inheritedClass
end

---Create new B element
---@generic T: BPanel
---@param classname `T` Panel class name, to identificate it
---@param parent BPanel? Parent object
---@return T
function bgui.create(classname, parent)
    return bgui.registered[classname]:new(parent or bgui.canvas)
end

local function mouseMoved(x, y)
    local oldX, oldY = bgui.cursorX, bgui.cursorY
    bgui.cursorX = x
    bgui.cursorY = y
    if !input.getCursorVisible() then return end
    for _, v in ipairs(bgui.ordered) do
        if !isValid(v) or !v.visible then goto cont end
        if !v.mouseInput then goto cont end
        local isOldHover = v:testHover(oldX, oldY)
        local isNewHover = v:testHover(x, y)
        if isNewHover and !isOldHover then
            v:onCursorEntered()
        elseif !isNewHover and isOldHover then
            v:onCursorExited()
        elseif isNewHover and isOldHover then
            local selfX, selfY = v:getPos()
            v:onCursorMoved(x - selfX, y - selfY)
        end
        ::cont::
    end
end

bgui.oldEnableCursor = input.enableCursor

input.enableCursor = function(state)
    bgui.oldEnableCursor(state)
    bgui.cursorEnabled = state
end

local function sortByZPos(tbl)
    local sorted = {}
    for id, v in pairs(tbl) do
        if !isValid(v) then
            tbl[id] = nil
            goto cont
        end
        sorted[#sorted+1] = v
        ::cont::
    end
    table.sort(sorted, function(a, b)
        if !isValid(a) then return false end
        if !isValid(b) then return true end
        if !a.parent then return false end
        if !b.parent then return true end
        return a.parent == b or a.zPos > b.zPos or (a.zPos == b.zPos and a.index > b.index)
    end)
    return sorted
end

hook.add("PostDrawHUD", "BPaint", function()
    local sw, sh = render.getGameResolution()
    if sw ~= bgui.screenWidth or sh ~= bgui.screenHeight then
        bgui.screenWidth = sw
        bgui.screenHeight = sh
        bgui.canvas:setSize(sw, sh)
    end
    local cX, cY = input.getCursorPos()
    if cX ~= bgui.cursorX or cY ~= bgui.cursorY then
        mouseMoved(cX, cY)
    end
    if !input.getCursorVisible() and bgui.cursorEnabled then
        bgui.oldEnableCursor(true)
    end
    local ordered = bgui.ordered
    for i=#ordered, 1, -1 do
        local v = ordered[i]
        if !isValid(v) then goto cont end
        if !v.visible then goto cont end
        local x, y = v:getPos()
        local w, h = v:getSize()
        if v.parent and v.boundX then
            render.enableScissorRect(v.boundX, v.boundY, v.boundX2, v.boundY2)
        end
        v:paint(x, y, w, h)
        render.disableScissorRect()
        render.setColor(Color(255, 255, 255, 255))
        render.setFont("Default")
        render.setMaterial()
        ::cont::
    end
end)


hook.add("Think", "BThink", function()
    if table.isEmpty(bgui.ordered) then return end
    for _, v in ipairs(bgui.ordered) do
        if !isValid(v) or !v.visible then goto cont end
        v:think()
        ::cont::
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

hook.add("InputPressed", "BInputPressed", function(key)
    if table.isEmpty(bgui.ordered) then return end
    if input.getCursorVisible() then
        if isMouse(key) then
            local x, y = bgui.cursorX, bgui.cursorY
            local focus = bgui.focus
            if !isValid(focus) then return end
            for _, v in ipairs(bgui.ordered) do
                if !isValid(v) or !v.visible then goto cont end
                if !v.mouseInput then goto cont end
                if focus == v then
                    if v:onMousePressed(key) then return end
                elseif v:testHover(x, y) then
                    bgui.focus = v
                    v:onMousePressed(key)
                    return
                end
                ::cont::
            end
        end
    end
end)

hook.add("InputReleased", "BInputReleased", function(key)
    if table.isEmpty(bgui.ordered) then return end
    if input.getCursorVisible() then
        if isMouse(key) then
            for _, v in ipairs(bgui.ordered) do
                if !isValid(v) or !v.visible then goto cont end
                if !v.mouseInput then goto cont end
                if bgui.focus == v and v:onMouseReleased(key) then return end
                ::cont::
            end
        end
    end
end)

hook.add("MouseWheeled", "BMouseWheeled", function(delta)
    if table.isEmpty(bgui.ordered) then return end
    for _, v in ipairs(bgui.ordered) do
        if !isValid(v) or !v.visible then goto cont end
        if !v.mouseInput then goto cont end
        if v:onMouseWheeled(delta) then return end
        ::cont::
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

bgui.DOCK = BDOCK


-----[ Base class ]-----
---@class Margins
---@field left number
---@field top number
---@field right number
---@field bottom number

---Base class for UI elements
---@class BPanel
---@field index number Index of panel
---@field parent BPanel? Parent of this panel. If not nil, panel will be relative to it
---@field children BPanel[] Children of this panel
---@field sortedChildren BPanel[] Children, but sorted by ZPos
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
---@field performsLayout boolean Panel in performLayout now
---@field minW number Panel minimal width
---@field minH number Panel minimal height
---@field boundX number Panel render bounds minimum X
---@field boundY number Panel render bounds minimum Y
---@field boundX2 number Panel render bounds maximum X
---@field boundY2 number Panel render bounds maximum Y
---@field docktype BDOCK height (GLua tall)
---@field visible boolean Is this panel visible
---@field zPos number Number which determinates rendering order
---@field mouseInput boolean Get mouse input
---@field font string Font for panel
---@field text string Text for panel
---@field fgcolor Color Foreground color of this panel
---@field bgcolor Color Background color of this panel
local BPanel = {}
BPanel.__index = BPanel
BPanel.__name = "BPanel"
BPanel.__eq = function(a, b)
    return a.index == b.index
end
BPanel.__tostring = function(self)
    local w, h = self:getSize()
    return string.format("Panel[%i][name:%s][%i,%i,%i;%ix%i]", self.index, self.__name, self.x, self.y, self.zPos, w, h)
end


---Create new panel
---@param parent BPanel? Parent of this panel. If not nil, panel will be relative to it
---@return BPanel
function BPanel:new(parent)
    local x, y, w, h = 0, 0, 128, 128
    local index = #bgui.inited+1
    local obj = setmetatable({
        index = index,
        parent = parent,
        children = {},
        sortedChildren = {},
        x = y, y = x, w = w, h = h,
        dockX = y, dockY = x,
        dockMargins = {left = 0, top = 0, right = 0, bottom = 0},
        dockPaddings = {left = 0, top = 0, right = 0, bottom = 0},
        minW = 0, minH = 0, docktype = 0, visible = true, zPos = 1,
        mouseInput = true,
        font = "Default", text = "Label",
        bgcolor = Color(255, 255, 255), fgcolor = Color(0, 0, 0)
    }, self)
    if parent then
        parent.children[index] = obj
        parent.sortedChildren = sortByZPos(parent.children)
        timer.simple(0, function()
            parent:invalidateLayout()
        end)
    end
    bgui.inited[index] = obj
    bgui.ordered = sortByZPos(bgui.inited)
    obj:init()
    return obj
end


---Set parent of this panel
---@param parent? BPanel
function BPanel:setParent(parent)
    local changed = false
    if isValid(self.parent) then
        self.parent.children[self.index] = nil
        self.parent.sortedChildren = sortByZPos(self.parent.children)
        self.parent:invalidateLayout()
        self.parent = nil
        changed = true
    end
    if parent and isValid(parent) then
        parent.children[self.index] = self
        parent.sortedChildren = sortByZPos(parent.children)
        parent:invalidateLayout()
        self.parent = parent
        changed = true
    end
    if changed then
        bgui.ordered = sortByZPos(bgui.inited)
    end
end


---Get global position of this panel. Use this to draw
---@return number x, number y
function BPanel:getPos()
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
function BPanel:setPos(x, y)
    self.x = x
    self.y = y
    self:invalidateLayout()
end

---Get size of this panel. Use this to draw
---@return number w, number h
function BPanel:getSize()
    local cond = self.docktype > 0
    local selfW = cond and self.dockW or self.w
    local selfH = cond and self.dockH or self.h
    local w, h = math.max(selfW, self.minW), math.max(selfH, self.minH)
    return w, h
end

---Set size for this panel
---@param w number
---@param h number
function BPanel:setSize(w, h)
    self.w = w
    self.h = h
    self:invalidateLayout()
    self:onSizeChanged(w, h)
end


---Set visibility of this panel
---@param state boolean
function BPanel:setVisible(state)
    if self.parent and !self.parent.visible then state = false end
    self.visible = state
    for _, v in ipairs(self.sortedChildren) do
        if !isValid(v) then goto cont end
        v:setVisible(state)
        ::cont::
    end
end

---Get visibility of this panel
---@return boolean
function BPanel:isVisible()
    return self.visible
end


---Sets the font of the label
---@param font string The name of the font
function BPanel:setFont(font)
    self.font = font
end

---Returns the current font of the label
---@return string font The name of the current font
function BPanel:getFont()
    return self.font
end

---Sets the text value of a panel
---@param text string The text value to set
function BPanel:setText(text)
    self.text = text
end

---Returns the panel's text
---@return string text The panel's text
function BPanel:getText()
    return self.text
end

---Sets the foreground color of a panel
---@param fgcolor Color 
function BPanel:setFGColor(fgcolor)
    self.fgcolor = fgcolor
end

---Returns the panel's foreground color
---@return Color fgcolor
function BPanel:getFGColor()
    return self.fgcolor
end

---Set local Z position
---@param pos number
function BPanel:setZPos(pos)
    self.zPos = math.clamp(pos, -32768, 32768)
    bgui.ordered = sortByZPos(bgui.inited)
    self.sortedChildren = sortByZPos(self.children)
    self:invalidateLayout()
end

---Get local Z position
---@return number
function BPanel:getZPos()
    return self.zPos
end

---Enable mouse input. If false, will not be clickable
---@param state boolean
function BPanel:setMouseInputEnabled(state)
    self.mouseInput = state
end

---Get mouse input enabled
---@return boolean state
function BPanel:isMouseInputEnabled()
    return self.mouseInput
end

---Focuses the panel and enables it to receive input
function BPanel:makePopup()
    self.mouseInput = true
    bgui.focus = self
end


---Invalidate layout. Will call hook performLayout
function BPanel:invalidateLayout()
    if self.performsLayout then return end
    self.performsLayout = true
    local x, y = self:getPos()
    local w, h = self:getSize()
    -- wtf what i did there
    local pad = self.dockPaddings
    -- b - bounds, rb - render bounds
    local bX, bY, bW, bH = pad.left, pad.top, w - pad.right, h - pad.bottom
    local rbX, rbY, rbX2, rbY2
    if self.parent and self.parent.boundX then
        rbX, rbY  = math.max(x, self.parent.boundX), math.max(y, self.parent.boundY)
        rbX2, rbY2 = math.min(rbX + w, self.parent.boundX2), math.min(rbY + h, self.parent.boundY2)
    else
        rbX, rbY  = x, y
        rbX2, rbY2 = rbX + w, rbY + h
    end
    for _, v in ipairs(self.sortedChildren) do
        if !isValid(v) or !v.visible then goto cont end
        v.boundX, v.boundY, v.boundX2, v.boundY2 = rbX, rbY, rbX2, rbY2
        if v.docktype == 0 then goto cont end
        local vMargins = v.dockMargins
        v.dockX = bX + vMargins.left
        v.dockY = bY + vMargins.top
        v.dockW = bW - vMargins.right - bX
        v.dockH = bH - vMargins.bottom - bY
        local funcs = {
            [BDOCK.LEFT] = function()
                v.dockW = v.w
                bX = bX + v.w + vMargins.left
            end,
            [BDOCK.RIGHT] = function()
                v.dockX = v.dockW + vMargins.right + pad.right
                v.dockW = v.w
                bW = bW - v.w - vMargins.right
            end,
            [BDOCK.TOP] = function()
                v.dockH = v.h
                bY = bY + v.h + vMargins.top + vMargins.bottom
            end,
            [BDOCK.BOTTOM] = function()
                v.dockY = v.dockH + vMargins.left + pad.left
                v.dockH = v.h
                bH = bH - v.h - vMargins.bottom - vMargins.top
            end,
            [BDOCK.FILL] = function() end
        }
        funcs[v.docktype]()
        v:invalidateLayout()
        ::cont::
    end
    self:performLayout(w, h)
    self.performsLayout = false
end


---Invalidate parent layout. Will call hook performLayout on parent
---You can safely call it
function BPanel:invalidateParent()
    if !self.parent then return end
    self.parent:invalidateLayout()
end


---Invalidate children layout. Will call hook performLayout on children
---@param recursive boolean?
function BPanel:invalidateChildren(recursive)
    for _, v in ipairs(self.sortedChildren) do
        if !isValid(v) or !v.visible then goto cont end
        v:invalidateLayout()
        if recursive then
            v:invalidateChildren(true)
        end
        ::cont::
    end
end


---Dock this panel on parent
---@param docktype BDOCK Dock type
function BPanel:dock(docktype)
    self.docktype = docktype
    self:invalidateParent()
end


---Dock margins for panel
---@param left number
---@param top number
---@param right number
---@param bottom number
function BPanel:dockMargin(left, top, right, bottom)
    self.dockMargins = {
        left = left,
        top = top,
        right = right,
        bottom = bottom
    }
    self:invalidateParent()
end


---Get docked padding
---@return number left, number top, number right, number bottom
function BPanel:getDockMargin()
    local mar = self.dockMargins
    return mar.left, mar.top, mar.right, mar.bottom
end


---Dock padding for panel children
---@param left number
---@param top number
---@param right number
---@param bottom number
function BPanel:dockPadding(left, top, right, bottom)
    self.dockPaddings = {
        left = left,
        top = top,
        right = right,
        bottom = bottom
    }
    self:invalidateLayout()
end

---Get docked padding
---@return number left, number top, number right, number bottom
function BPanel:getDockPadding()
    local pad = self.dockPaddings
    return pad.left, pad.top, pad.right, pad.bottom
end


---Centers the panel horizontally with specified fraction
---@param fraction number? Center fraction. Default 0.5
function BPanel:centerHorizontal(fraction)
    if self.docktype > 0 then return end
    fraction = fraction or 0.5
    local _, h = self.parent:getSize()
    self:setPos(self.x, h * fraction)
end


---Centers the panel vertically with specified fraction
---@param fraction number? Center fraction. Default 0.5
function BPanel:centerVertical(fraction)
    if self.docktype > 0 then return end
    fraction = fraction or 0.5
    local w, _ = self.parent:getSize()
    self:setPos(w * fraction, self.y)
end

---Centers the panel on its parent.
function BPanel:center()
    if self.docktype > 0 then return end
    local w, h = self.parent:getSize()
    local selfW, selfH = self:getSize()
    self:setPos(w / 2 - selfW / 2, h / 2 - selfH / 2)
end


---Is panel valid
function BPanel:isValid()
    return self ~= nil
end


---Remove panel
function BPanel:remove()
    for _, v in ipairs(self.sortedChildren) do
        if !isValid(v) then goto cont end
        v:remove()
        ::cont::
    end
    self:onRemove()
    bgui.inited[self.index] = nil
    bgui.ordered = sortByZPos(bgui.inited)
    bgui.focus = bgui.canvas
    setmetatable(self, nil)
end


---Is position hovering panel
---@param x number
---@param y number
function BPanel:testHover(x, y)
    if !self.boundX then return end
    local selfX, selfY = self:getPos()
    local selfW, selfH = self:getSize()
    local bX, bY = math.max(self.boundX, selfX), math.max(selfY, self.boundY)
    local bX2, bY2 = math.min(self.boundX2, selfX + selfW), math.min(self.boundY2, selfY + selfH)
    return (x >= bX and x < bX2) and (y >= bY and y < bY2)
end


---Is focused
---@return boolean
function BPanel:hasFocus()
    return bgui.focus == self
end


---On panel initialize
function BPanel:init() end

local gradient_up = material.load("vgui/gradient_up")
local gradient_down = material.load("vgui/gradient_down")
local gradient_center = material.load("gui/center_gradient")
---Paint in panel
---@param x number X position to paint
---@param y number Y position to paint
---@param w number Width to paint
---@param h number Height to paint
function BPanel:paint(x, y, w, h)
    render.setColor((self.bgcolor / 1.5):setA(255))
    render.drawRoundedBox(4, x, y, w, h)
    render.setColor(self.bgcolor)
    render.drawRoundedBox(4, x + 2, y + 2, w - 4, h - 4)
    render.setColor((self.bgcolor / 1.2):setA(255))
    render.setMaterial(gradient_up)
    render.drawTexturedRect(x + 1, y + 1, w - 2, h - 2)
    render.setMaterial(gradient_down)
    render.drawTexturedRect(x + 1, y + 1, w - 2, h - 2)
end

---Perform layout. Can be called with invalidateLayout
---@param w number Width
---@param h number Height
function BPanel:performLayout(w, h) end

---Called just after the panel size changes.
function BPanel:onSizeChanged(newWidth, newHeight) end

---Called just after remove panel
function BPanel:onRemove() end

---Think hook. To place server tick addicted functions
function BPanel:think() end

---Called whenever mouse button pressed
---@param key MOUSE
---@return boolean? suppress Return true to suppress default action
function BPanel:onMousePressed(key) end

---Called whenever mouse button released
---@param key MOUSE
---@return boolean? suppress Return true to suppress default action
function BPanel:onMouseReleased(key) end

---Called whenever the mouse wheel was used
---@param delta number Scroll delta
---@return boolean? suppress Return true to suppress default action
function BPanel:onMouseWheeled(delta) end

---Called whenever the cursor entered the panels bounds
function BPanel:onCursorEntered() end

---Called whenever the cursor left the panels bounds.
function BPanel:onCursorExited() end

---Called whenever the cursor left the panels bounds.
---@param x number X position relative to panel
---@param y number Y position relative to panel
function BPanel:onCursorMoved(x, y) end


bgui.registered["BPanel"] = BPanel

-- Create canvas (our screen)
do
    local canvas = bgui.create("BPanel")
    canvas.visible = false
    canvas.mouseInput = false
    canvas.zPos = -1
    bgui.canvas = canvas
    bgui.focus = canvas
end


-----[ Other classes ]-----

---@enum COLORS
local C = {
    blue = Color(20, 200, 250),
    fg1 = Color(255, 255, 255),
    fg = Color(225, 225, 225),
    overlay = Color(156, 156, 156, 156),
    bg3 = Color(154, 157, 162),
    bg2 = Color(138, 138, 138),
    bg1 = Color(128, 128, 128),
    bg = Color(101, 104, 106),
    black = Color(20, 20, 20)
}
bgui.COLORS = C


---Label class
---@class BLabel: BPanel
local BLabel = {}

function BLabel:paint(x, y)
    render.setFont(self.font)
    render.setColor(self.fgcolor)
    render.drawSimpleText(x, y, self.text)
end

function BLabel:onMouseReleased(key)
    if !self:testHover(bgui.cursorX, bgui.cursorY) then return end
    local funcs = {
        [MOUSE.MOUSE1] = self.doClick,
        [MOUSE.MOUSE3] = self.doMiddleClick,
        [MOUSE.MOUSE2] = self.doRightClick,
    }
    local func = funcs[key]
    if func then func(self) end
end

function BLabel:doClick() end
function BLabel:doMiddleClick() end
function BLabel:doRightClick() end

bgui.register("BLabel", BLabel, "BPanel")


---Button class
---@class BButton: BLabel
local BButton = {}

function BButton:init()
    self.bgcolor = C.fg
    self.hoverbgcolor = C.fg1
    self.framecolor = C.bg1
    self.hoverfgcolor = C.blue
end

function BButton:paint(x, y, w, h)
    local isHover = self:testHover(bgui.cursorX, bgui.cursorY)
    local isDown = input.isMouseDown(MOUSE.MOUSE1)
    local col = (isHover and !isDown and C.fg1) or (isHover and isDown and C.blue) or C.fg
    local fgCol = (isHover and !isDown and C.blue) or (isHover and isDown and C.fg) or C.black
    render.setColor(C.bg)
    render.drawRoundedBox(4, x, y, w, h)
    render.setColor(col)
    render.drawRoundedBox(4, x + 1, y + 1, w - 2, h - 2)
    render.setColor(C.overlay)
    render.setMaterial(gradient_up)
    local height = h * 0.2
    render.drawTexturedRect(x + 1, y + 1 + (h - height), w - 2, height)
    render.setMaterial(gradient_down)
    render.drawTexturedRect(x + 1, y + 1, w - 2, height)
    render.setColor(fgCol)
    render.setFont("Default")
    render.drawSimpleText(x + w / 2, y + h / 2, self.text, TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
end

bgui.register("BButton", BButton, "BLabel")


---Frame class
---@class BFrame: BPanel
---@field dragging boolean
---@field draggingOffsetX number
---@field draggingOffsetY number
---@field exitButton BButton
local BFrame = {}

function BFrame:init()
    self.framecolor = Color(121, 124, 126)
    self.bgcolor = Color(108, 111, 114)
    self.fgcolor = Color(255, 255, 255)
    self.dragging = false
    self.exitButton = bgui.create("BButton", self)
    self.exitButton:setSize(32, 18)
    self.exitButton.font = "Marlett"
    self.exitButton.paint = function(btn, x, y, w, h)
        local col = C.fg
        if btn:testHover(bgui.cursorX, bgui.cursorY) then
            render.setColor(Color(0, 0, 0, 0))
            col = C.fg1
        else
            render.setColor(C.black)
        end
        render.drawRoundedBox(4, x, y, w, h)
        render.setColor(col)
        render.drawRoundedBox(4, x, y, w, h - 1)
        render.setColor(C.bg1)
        render.setFont("Marlett")
        render.drawSimpleText(x + w / 2, y + h / 2, "r", TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
    end
    self.exitButton.doClick = function(_)
        self:remove()
    end
    self:dockPadding(4, 29, 4, 4)
end

function BFrame:onSizeChanged(w, _)
    self.exitButton:setPos(w - 38, 5)
end

function BFrame:paint(x, y, w, h)
    render.setColor(C.black)
    render.drawRoundedBox(4, x, y, w, h)
    render.setColor(C.bg2)
    render.drawRoundedBox(4, x + 1, y + 1, w - 2, h - 2)
    render.setColor(C.bg1)
    render.drawRoundedBox(4, x + 2, y + 2, w - 4, h - 4)
    render.setColor(C.bg)
    render.drawRect(x + 2, y + 25, w - 4, h - 27)
    render.setColor(C.fg1)
    render.setFont("DermaDefault")
    render.drawSimpleText(x + 8, y + 6, self.text)
end

function BFrame:onMousePressed(key)
    local x, y = self:getPos()
    if key ~= MOUSE.MOUSE1 or !self:testHover(bgui.cursorX, bgui.cursorY) or bgui.cursorY - y > 32 then return end
    self.dragging = true
    self.draggingOffsetX, self.draggingOffsetY = bgui.cursorX - x, bgui.cursorY - y
end

function BFrame:onMouseReleased(key)
    if self.dragging and key ~= MOUSE.MOUSE1 then return end
    self.dragging = false
end

function BFrame:onCursorMoved(x, y)
    if !self.dragging then return end
    self:setPos(bgui.cursorX - self.draggingOffsetX, bgui.cursorY - self.draggingOffsetY)
end

function BFrame:onRemove()
    local meta = getmetatable(self)
    -- To disable cursor
    local ordered = bgui.ordered
    for i=#ordered, 1, -1 do
        local v = ordered[i]
        if v.index == self.index then goto cont end
        if getmetatable(v) == meta then
            return
        end
        ::cont::
    end
    input.enableCursor(false)
end

bgui.register("BFrame", BFrame, "BPanel")


---BModelPanel class
---@class BModelPanel: BPanel
---@field entity Hologram
local BModelPanel = {}

function BModelPanel:init()
    local holo = hologram.create(Vector(), Angle(), "models/holograms/cube.mdl")
    if !holo then return end
    holo:setNoDraw(true)
    self.entity = holo
end

function BModelPanel:paint(x, y, w, h)
    ---@type RenderCamData
    local camData = {
        type = "3D",
        x = x, y = y,
        w = w, h = h, aspect = w / h - 0.0333,
        fov = 42,
        origin = Vector(50, 0, 55),
        angles = Angle(15, 180, 0)
    }
    render.pushViewMatrix(camData)
    render.suppressEngineLighting(true)
        self.entity:draw()
    render.popViewMatrix()
end

---Set model for this panel
---@param model string
function BModelPanel:setModel(model)
    self.entity:setModel(model)
end

function BModelPanel:onRemove()
    if isValid(self.entity) then
        self.entity:remove()
    end
end

bgui.register("BModelPanel", BModelPanel, "BPanel")

---@private
---@class Tab
---@field button BButton
---@field panel BPanel

---BPropertySheet class
---@class BPropertySheet: BPanel
---@field tabs BPanel
---@field canvas BPanel
---@field sheets Tab[]
local BPropertySheet = {}

function BPropertySheet:init()
    local contentCanvas = bgui.create("BPanel", self)
    contentCanvas:dock(BDOCK.FILL)
    self.canvas = contentCanvas
    local tabs = bgui.create("BPanel", self)
    tabs.paint = function() end
    tabs:dock(BDOCK.TOP)
    tabs:setSize(0, 24)
    self.tabs = tabs
    self.sheets = {}
    self.activeSheet = 1
    self.bgcolor = Color(154, 157, 162)
    self.fgcolor = Color(225, 225, 225)
end

---Add new sheet
---@param name string Name of tab
---@param pnl BPanel Panel in this tab
function BPropertySheet:addSheet(name, pnl)
    local tab = bgui.create("BButton", self.tabs)
    function tab.doClick()
        for _, v in ipairs(self.sheets) do
            v.panel:setVisible(v.panel == pnl and true or false)
        end
        self:invalidateLayout()
    end
    function tab.paint(btn, x, y, w, h)
        render.setColor(C.black)
        render.drawRoundedBox(4, x, y, w, h)
        render.setColor(C.bg3)
        render.drawRoundedBox(4, x + 1, y + 1, w - 2, h - 2)
        render.setColor(C.fg)
        render.setFont("DermaDefault")
        render.drawSimpleText(x + 8, y + 6, btn.text)
    end
    tab:dock(BDOCK.LEFT)
    tab:setText(name)
    pnl:setParent(self.canvas)
    pnl:dock(BDOCK.FILL)
    local sheetId = #self.sheets+1
    pnl:setVisible(sheetId == 1)
    self.sheets[sheetId] = {
        button = tab,
        panel = pnl
    }
end

function BPropertySheet:performLayout()
    if !self.sheets then return end
    local len = #self.sheets
    for id, v in ipairs(self.sheets) do
        v.button:setZPos(len - id + 1)
    end
end

function BPropertySheet:paint() end

bgui.register("BPropertySheet", BPropertySheet, "BPanel")


---[INTERNAL] BScrollBar class
---@class BScrollBar: BPanel
---@field pos number Position of a scrollbar
---@field height number Height of a scrolled space
---@field ratio number Ratio of a scrollbar height and canvas height
local BScrollBar = {}

function BScrollBar:init()
    self.pos = 0
    self.height = 0
    self.ratio = 0
    self.scrollPanel = nil
end

function BScrollBar:paint(x, y, w, h)
    render.setColor(Color(255, 255, 255))
    render.drawRect(x + 3, y - (self.ratio * self.pos), w - 6, self.ratio * h)
end

function BScrollBar:performLayout(w, h)
    self.ratio = (h + 4) / self.height
end

function BScrollBar:onCursorMoved(x, y)
    if input.isMouseDown(MOUSE.MOUSE1) then
        self.pos = (-y + self.ratio * self.h / 2) / self.ratio
        self.scrollPanel.pos = self.pos
        self.scrollPanel:invalidateLayout()
    end
end

bgui.register("BScrollBar", BScrollBar, "BPanel")



---BScrollPanel class
---@class BScrollPanel: BPanel
---@field canvas BPanel
---@field pos number
---@field scrollbar BScrollBar
local BScrollPanel = {}

function BScrollPanel:init()
    local contentCanvas = bgui.create("BPanel", self)
    contentCanvas:dockPadding(0, 0, 16, 0)
    contentCanvas.paint = function() end
    self.canvas = contentCanvas
    local scrollbar = bgui.create("BScrollBar", self)
    scrollbar.scrollPanel = self
    self.scrollbar = scrollbar
    self.pos = 0
end

function BScrollPanel:performLayout(w, h)
    local _, pTop, _, pBottom = self:getDockPadding()
    local height = pTop + pBottom
    for _, v in ipairs(self.canvas.sortedChildren) do
        local _, chH = v:getSize()
        local _, mTop, _, mBottom = v:getDockMargin()
        height = height + chH + mTop + mBottom
    end
    self.pos = math.clamp(self.pos, -height + h, 0)
    self.scrollbar:setPos(w - 16, 0)
    self.scrollbar:setSize(16, h)
    self.scrollbar.pos = self.pos
    self.canvas:setPos(0, self.pos)
    self.canvas:setSize(w, height)
    self.scrollbar.height = height
end

---Add new child to scroll panel
---@param child BPanel
function BScrollPanel:addItem(child)
    child:setParent(self.canvas)
    child:dock(BDOCK.TOP)
end


function BScrollPanel:onMouseWheeled(delta)
    self.pos = self.pos + delta * 8
    self:invalidateLayout()
    return true
end

bgui.register("BScrollPanel", BScrollPanel, "BPanel")


return bgui
