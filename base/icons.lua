---Just a lib for registering icons and textures. This is SOOO small lib, but it important for all
---@name Icons
---@author AstricUnion
---@shared
if SERVER then return end

---@alias drawIcon fun(x: number, y: number, w: number, h: number)

---@class bicons
---@field registered table<string, drawIcon>
local bicons = {}
bicons.registered = {}

---Register icon
---@param id string Identifier of an icon
---@param mat Material Matrerial of an icon
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
        render.drawTexturedRectUVFast(x, y, w, h, startU, startV, endU, endV, true)
    end
end


---Get icon function
---@param id string Identifier of an icon
---@return drawIcon
function bicons.get(id)
    return bicons.registered[id]
end


return bicons
