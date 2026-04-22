---Deposits library, to create deposits with resource. Also not a base, requires resources module
---@name BMod deposits
---@author AstricUnion
---@shared

-- TODO: System without addiction to navareas

---Class to create and control deposits
---@class deposit
---@field id string Identifier of this generated deposits
local deposit = {}
-- deposit.id = "mainDeposit"


if SERVER then
    local allowedMat = {
        [MAT.SNOW] = "snow",
        [MAT.SAND] = "sand",
        [MAT.FOLIAGE] = "foliage",
        [MAT.SLOSH] = "slime",
        [MAT.GRASS] = "grass",
        [MAT.DIRT] = "dirt",
    }
    local navAreas = navmesh.getAllNavAreas()
    ---@cast navAreas NavArea[]
    -- local count = #navAreas
    local depositsLeft = 50

    local cor = coroutine.wrap(function()
        while depositsLeft > 0 do
            coroutine.yield()
            if table.isEmpty(navAreas) then return end
            local navarea = table.random(navAreas)
            if !navarea then goto cont end
            local point = navarea:getRandomPoint()
            local tr = trace.line(point, point + Vector(0, 0, -1), nil, MASK_SOLID)
            ---@cast tr TraceResult
            if !allowedMat[tr.MatType] then goto cont end
            local size = 400 * math.rand(0.5, 1.5)
            table.removeByValue(navAreas, navarea)
            local areas = navmesh.find(point, size + 800, 300, 300)
            for _, v in ipairs(areas) do
                ---@cast v NavArea
                table.removeByValue(navAreas, v)
            end
            hologram.create(point, Angle(), "models/holograms/sphere.mdl"):setSize(Vector(size, size, 100))
            depositsLeft = depositsLeft - 1
            ::cont::
        end
        return true
    end)

    hook.add("Think", "", function()
        if cor() == true then hook.remove("Think", "") end
    end)
end

