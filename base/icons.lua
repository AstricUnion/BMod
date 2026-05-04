---Just a lib for registering icons and textures. This is SOOO small lib, but it important for all
---@name Icons
---@author AstricUnion
---@shared
if SERVER then return end

---@alias drawIcon fun(x: number, y: number, w: number, h: number)

---@class ModelIcon
---@field model string
---@field cameraOffset Vector
---@field cameraAngle Angle

---@class bicons
---@field registered table<string, drawIcon>
---@field holo Hologram
---@field toDraw ModelIcon[]
---@field alreadyDraw number
local bicons = {}
bicons.registered = {}
local holo = hologram.create(Vector(), Angle(), "models/holograms/cube.mdl")
if !holo then return end
holo:setNoDraw(true)
bicons.holo = holo
bicons.alreadyDraw = 0
bicons.toDraw = {}

---Register icon
---@param id string Identifier of an icon
---@param mat Material Material of an icon
---@param startU number? Start of U coordinate. This maybe useful, if you load spritesheet
---@param startV number? Start of V coordinate. 
---@param endU number? End of U coordinate.
---@param endV number? End of V coordinate.
function bicons.register(id, mat, startU, startV, endU, endV)
    startU = startU or 0
    startV = startV or 0
    endU = endU or 1
    endV = endV or 1
    bicons.registered[id] = function(x, y, w, h)
        render.setColor(Color())
        render.setMaterial(mat)
        render.drawTexturedRectUV(x, y, w, h, startU, startV, endU, endV)
    end
end


---Get icon function
---@param id string Identifier of an icon
---@return drawIcon
function bicons.get(id)
    return bicons.registered[id]
end

render.createRenderTarget("BModModelIcons")

---Register model as icon
---@param identifier string Icon identifier
---@param model string Model to render
---@param cameraOffset Vector Camera offset
---@param cameraAngle Angle Camera angle
function bicons.registerModel(identifier, model, cameraOffset, cameraAngle)
    if bicons.alreadyDraw >= 64 then return end
    local index = #bicons.toDraw+1
    bicons.toDraw[index] = {
        model = model,
        cameraOffset = cameraOffset,
        cameraAngle = cameraAngle,
    }
    local row = math.ceil(index / 8)
    local column = index - ((row - 1) * 8)
    local startU = (column - 1) * 0.125
    local startV = (row - 1) * 0.125
    local endU = column * 0.125
    local endV = row * 0.125
    bicons.registered[identifier] = function(x, y, w, h)
        render.setColor(Color(255, 255, 255, 255))
        render.setRenderTargetTexture("BModModelIcons")
        render.drawTexturedRectUVFast(x, y, w, h, startU, startV, endU, endV, true)
    end
end

hook.add("RenderOffscreen", "BModModelIcons", function()
    render.selectRenderTarget("BModModelIcons")
    render.clear(Color(255, 255, 255, 0))
    render.setColor(Color())
    for i, v in ipairs(bicons.toDraw) do
        local row = math.ceil(i / 8)
        local column = i - ((row - 1) * 8)
        bicons.holo:setModel(v.model)
        ---@type RenderCamData
        local camData = {
            type = "3D",
            x = (column - 1) * 128, y = (row - 1) * 128,
            w = 128, h = 128, aspect = 1,
            fov = 42,
            origin = v.cameraOffset,
            angles = v.cameraAngle
        }
        render.pushViewMatrix(camData)
            render.setLightingMode(1)
            bicons.holo:draw()
            render.setLightingMode(0)
        render.popViewMatrix()
        bicons.alreadyDraw = bicons.alreadyDraw + 1
    end
    bicons.toDraw = {}
    hook.remove("RenderOffscreen", "BModModelIcons")
end)


return bicons
