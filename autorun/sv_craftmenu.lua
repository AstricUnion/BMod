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
    ---@cast item BModCraft
    -- REPEAT CODE FROM bgui/craftmenu.lua
    local errorMes = resource.takeResources(player(), item.requires, false)
    if errorMes then
        print(errorMes)
        return
    end
    local ent = net.readEntity()
    local pos = ent:getPos() + Vector(0, 0, 50)
    item.result(pos, ent:getAngles())
end)
