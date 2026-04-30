if !SERVER then return end

---@class bmodConfig
local cfg = bmodConfig

net.receive("BModMakeCraft", function()
    local category = net.readString()
    local name = net.readString()
    local cat = cfg[category]
    if !cat then return end
    local item
    for _, v in ipairs(cat) do
        if v.name == name then
            item = v
            break
        end
    end
    if !item then return end
    -- REPEAT CODE FROM bgui/craftmenu.lua
    local resources = resource.getResources(player(), false)
    for id, count in pairs(item.requires) do
        if resources[id].count < count then return end
    end
end)
