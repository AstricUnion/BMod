---@name BMod config
---@author AstricUnion
---@shared

---@class resource
local resource = resource

---Class to configurate BMod
---@class bmodConfig
local bmodConfig = {}

---@class BModCraft
---@field name string Name of the craft
---@field description string? Description for craft
---@field icon string Identifier of icon from bicons
---@field requires table<string, number> What requires this craft?
---@field result fun(pos: Vector, ang: Angle) Result of craft
---@field methods string[] Methods to craft. In base version, can be crafting_table

---@type table<string, BModCraft[]> Key is a craft category
bmodConfig.crafts = {
    ["Resources"] = {
        {
            name = "Paper",
            description = "Writing material that can be used for more malicious purposes",
            icon = "paper",
            methods = {
                ["crafting_table"] = true
            },
            requires = {
                wood = 39,
                water = 91
            },
            result = function(pos, ang)
                resource.create("paper", pos, ang, 100, false, true)
            end
        }
    }
}

return bmodConfig

