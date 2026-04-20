---@name BGUI (BMod Graphical User Interface)
---@author AstricUnion
---@client

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
local bgui = {}
bgui.inited = {}
bgui.registered = {}
bgui.cursorX, bgui.cursorY = input.getCursorPos()
bgui.cursorEnabled = false


---Register new B element
---@param classname string Panel class name, to identificate it
---@param panelclass BPanel Panel class to create new GUI panel
function bgui.register(classname, panelclass)
    bgui.registered[classname] = panelclass
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
    for _, v in pairs(bgui.inited) do
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


hook.add("DrawHUD", "BPaint", function()
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
    local ordered = table.add({}, bgui.inited)
    table.sort(ordered, function(a, b)
        if !isValid(a) then return false end
        if !isValid(b) then return true end
        return a.zPos < b.zPos
    end)
    bgui.ordered = ordered
    for _, v in pairs(ordered) do
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

hook.add("InputPressed", "BInputPressed", function(key)
    if input.getCursorVisible() then
        if isMouse(key) then
            local x, y = bgui.cursorX, bgui.cursorY
            local focus = bgui.focus
            if !isValid(focus) then return end
            local focusHovered = focus:testHover(x, y)
            for _, v in pairs(table.reverse(bgui.ordered)) do
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
    if input.getCursorVisible() then
        if isMouse(key) then
            for _, v in pairs(bgui.inited) do
                if !v.mouseInput then goto cont end
                if bgui.focus == v and v:onMouseReleased(key) then return end
                ::cont::
            end
        end
    end
end)

hook.add("MouseWheeled", "BMouseWheeled", function(delta)
    for _, v in pairs(bgui.inited) do
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
        x = y, y = x, w = w, h = h,
        dockX = y, dockY = x,
        dockMargins = {left = 0, top = 0, right = 0, bottom = 0},
        dockPaddings = {left = 0, top = 0, right = 0, bottom = 0},
        minW = 0, minH = 0, docktype = 0, visible = true, zPos = index,
        mouseInput = true,
        font = "Default", text = "Label",
        bgcolor = Color(200, 200, 200), fgcolor = Color(0, 0, 0)
    }, self)
    if parent then
        parent.children[index] = obj
        parent:invalidateLayout()
    end
    bgui.inited[index] = obj
    obj:init()
    return obj
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
    self.visible = state
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

---Set Z position
---@param pos number
function BPanel:setZPos(pos)
    pos = math.clamp(pos, -32768, 32768)
    self.zPos = pos
end

---Get Z position
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
    local x, y = self:getPos()
    local w, h = self:getSize()
    local pad = self.dockPaddings
    -- b - bounds, rb - render bounds
    local bX, bY, bW, bH = pad.left, pad.top, w - pad.right - pad.left, h - pad.bottom - pad.top
    local rbX, rbY  = x + bX, y + bY
    local rbX2, rbY2 = rbX + bW, rbY + bH
    for _, v in pairs(self.children) do
        if v.docktype == 0 then goto cont end
        v.dockX = bX + v.dockMargins.left
        v.dockY = bY + v.dockMargins.top
        v.dockW = bW - v.dockMargins.right * 2
        v.dockH = bH - v.dockMargins.bottom * 2
        if v.docktype == BDOCK.LEFT then
            v.dockW = v.w
            bX = bX + v.w + v.dockMargins.left
        elseif v.docktype == BDOCK.RIGHT then
            v.dockX = v.dockW - v.w + v.dockMargins.right + pad.right
            v.dockW = v.w
            bW = bW - v.w - v.dockMargins.right
        elseif v.docktype == BDOCK.TOP then
            v.dockH = v.h
            bY = bY + v.h + v.dockMargins.top + v.dockMargins.bottom
        elseif v.docktype == BDOCK.BOTTOM then
            v.dockY = v.dockH - v.h + v.dockMargins.left + pad.left
            v.dockH = v.h
            bH = bH - v.h - v.dockMargins.bottom - v.dockMargins.top
        end
        v.boundX, v.boundY, v.boundX2, v.boundY2 = rbX, rbY, rbX2, rbY2
        v:invalidateLayout()
        ::cont::
    end
    self:performLayout()
end


---Invalidate parent layout. Will call hook performLayout on parent
---You can safely call it
function BPanel:invalidateParent()
    if self.parent then
        self.parent:invalidateLayout()
    end
end


---Invalidate children layout. Will call hook performLayout on children
---@param recursive boolean?
function BPanel:invalidateChildren(recursive)
    for _, v in pairs(self.children) do
        v:invalidateLayout()
        if recursive then
            v:invalidateChildren(true)
        end
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
    for _, v in pairs(self.children) do
        if !isValid(v) then goto cont end
        v:remove()
        ::cont::
    end
    self:onRemove()
    bgui.inited[self.index] = nil
    bgui.focus = bgui.canvas
    setmetatable(self, nil)
end


---Is position hovering panel
---@param x number
---@param y number
function BPanel:testHover(x, y)
    local selfX, selfY = self:getPos()
    local selfW, selfH = self:getSize()
    return (x >= selfX and x < selfX + selfW) and (y >= selfY and y < selfY + selfH)
end


---Is focused
---@return boolean
function BPanel:hasFocus()
    return bgui.focus == self
end


---On panel initialize
function BPanel:init() end

---Paint in panel
---@param x number X position to paint
---@param y number Y position to paint
---@param w number Width to paint
---@param h number Height to paint
function BPanel:paint(x, y, w, h)
    local multiplier = 1.8
    render.setColor(Color(
        self.bgcolor.r / multiplier,
        self.bgcolor.g / multiplier,
        self.bgcolor.b / multiplier,
        self.bgcolor.a
    ))
    render.drawRect(x, y, w, h)
    render.setColor(self.bgcolor)
    render.drawRect(x + 1, y + 1, w - 2, h - 2)
end

---Perform layout. Can be called with invalidateLayout
function BPanel:performLayout() end

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


bgui.register("BPanel", BPanel)

-- Create canvas (our screen)
local canvas = bgui.create("BPanel")
canvas.visible = false
canvas.mouseInput = false
canvas.zPos = -32769
bgui.canvas = canvas
bgui.focus = canvas


-----[ Other classes ]-----


---Label class
---@class BLabel: BPanel
local BLabel = setmetatable({}, BPanel)
BLabel.__index = BLabel

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

bgui.register("BLabel", BLabel)


---Button class
---@class BButton: BLabel
local BButton = setmetatable({}, BLabel)
BButton.__index = BButton

function BButton:paint(x, y, w, h)
    render.setFont(self.font)
    local multiplier = 1.5
    render.setColor(Color(
        self.bgcolor.r / multiplier,
        self.bgcolor.g / multiplier,
        self.bgcolor.b / multiplier
    ))
    render.drawRect(x, y, w, h)
    local isHover = self:testHover(bgui.cursorX, bgui.cursorY)
    render.setColor(self.bgcolor * (isHover and (input.isMouseDown(MOUSE.MOUSE1) and 1.5 or 1.2) or 1))
    render.drawRect(x + 2, y + 2, w - 4, h - 4)
    render.setColor(self.fgcolor)
    render.drawSimpleText(x + w / 2, y + h / 2, self.text, TEXT_ALIGN.CENTER, TEXT_ALIGN.CENTER)
end

bgui.register("BButton", BButton)


---Frame class
---@class BFrame: BPanel
---@field dragging boolean
---@field draggingOffsetX number
---@field draggingOffsetY number
---@field exitButton BButton
local BFrame = setmetatable({}, BPanel)
BFrame.__index = BFrame

function BFrame:init()
    self.bgcolor = Color(120, 120, 120)
    self.fgcolor = Color(255, 255, 255)
    self.dragging = false
    self.exitButton = bgui.create("BButton", self)
    self.exitButton:setSize(24, 16)
    self.exitButton:setPos(128 - 30, 6)
    self.exitButton:setText("x")
    self.exitButton.doClick = function(btn)
        self:remove()
    end
    self:dockPadding(4, 30, 4, 4)
end

function BFrame:onSizeChanged(w, _)
    self.exitButton:setPos(w - 30, 6)
end

function BFrame:paint(x, y, w, h)
    render.setColor(self.bgcolor)
    render.drawRect(x, y, w, h)
    local multiplier = 1.5
    render.setColor(Color(
        self.bgcolor.r / multiplier,
        self.bgcolor.g / multiplier,
        self.bgcolor.b / multiplier
    ))
    render.drawRect(x + 2, y + 2, w - 4, 24)
    render.setFont(self.font)
    render.setColor(self.fgcolor)
    render.drawSimpleText(x + 8, y + 8, self.text)
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
    for i, v in ipairs(table.reverse(bgui.ordered)) do
        if v.index == self.index then goto cont end
        if getmetatable(v) == meta then
            return
        end
        ::cont::
    end
    input.enableCursor(false)
end

bgui.register("BFrame", BFrame)


---BModelPanel class
---@class BModelPanel: BPanel
---@field entity Hologram
local BModelPanel = setmetatable({}, BPanel)
BModelPanel.__index = BModelPanel

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
        self.entity:draw()
    render.popViewMatrix()
    render.drawRectOutline(x, y, w, h)
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


bgui.register("BModelPanel", BModelPanel)



return bgui
