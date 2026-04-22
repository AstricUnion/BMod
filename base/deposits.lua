---Deposits library, to create deposits with resource. Also not a base, requires resources module
---@name BMod deposits
---@author AstricUnion
---@shared

-- TODO: System without addiction to navareas

---Deposit parameters
---@class DepositInfo
---@field resource string Identifier of deposit
---@field size number Average deposit size
---@field frequence number Chance to spawn for deposit. Addicts to other frequences
---@field rate? number Rate to mine
---@field amount? number Average max resource, that's can be mined from this deposit
---@field allowUnderwater boolean Can deposit spawn underwater?

---Info about deposit
---@class Deposit
---@field resource string Identifier of deposit
---@field size number Deposit size
---@field position Vector Deposit position
---@field underwater boolean Is deposit underwater
---@field rate? number Rate to mine
---@field amount? number Average max resource, that's can be mined from this deposit

---Class to create and control deposits
---@class deposit
---@field id string Identifier of this generated deposits
---@field info table<string, DepositInfo> Deposit's info for every resource
---@field inited table<number, Deposit> Already inited deposits
---@field frequence number Sum of deposit frequences
local deposit = {}
deposit.info = {}
deposit.inited = {}
deposit.frequence = 0
-- deposit.id = "mainDeposit"

---[SHARED] Add new deposit to generation
---@param resource string Identifier of this deposit
---@param size number Average size for deposit
---@param frequence number Frequence to spawn for deposit
---@param rate number? Rate to mine. Should be nil, if using amount
---@param amount number? Max resource, that's can be mined from this deposit. Should be nil, if using rate
---@param allowUnderwater boolean? Allow spawn deposit underwater
function deposit.add(resource, size, frequence, rate, amount, allowUnderwater)
    deposit.info[resource] = {
        resource = resource, size = size,
        frequence = frequence, rate = rate,
        amount = amount, allowUnderwater = allowUnderwater or false
    }
    deposit.frequence = deposit.frequence + frequence
end


if SERVER then
    local allowedMat = {
        [MAT.SNOW] = true,
        [MAT.SAND] = true,
        [MAT.FOLIAGE] = true,
        [MAT.SLOSH] = true,
        [MAT.GRASS] = true,
        [MAT.DIRT] = true,
    }

    -- Caching navareas
    ---@type NavArea[]
    local globalNavAreas = navmesh.getAllNavAreas()


    ---[SERVER] Start generation for deposits
    ---@param count number Deposits to create
    ---@param multiThread boolean? Return corouine
    ---@return function? generate Generate coroutine handler
    function deposit.startGeneration(count, multiThread)
        local depositsLeft = count
        local navAreas = table.copy(globalNavAreas)
        local frequenced = table.copy(deposit.info)
        table.sortByMember(frequenced, "frequence", true)

        ---@return DepositInfo?
        local function selectDeposit(isWater)
            local value = math.rand(0, deposit.frequence)
            local frequenceSum = 0
            for _, dep in pairs(frequenced) do
                if !dep.allowUnderwater and isWater then goto cont end
                frequenceSum = frequenceSum + dep.frequence
                if value < frequenceSum then
                    return dep
                end
                ::cont::
            end
        end

        local function generate()
            while depositsLeft > 0 do
                -- For coroutine
                if multiThread then coroutine.yield() end
                -- If empty, then we can't place any deposit
                if table.isEmpty(navAreas) then return end
                local navarea = table.random(navAreas)
                if !navarea then goto cont end
                local point = navarea:getRandomPoint()
                -- We can spawn this only on allowed materials
                -- TODO: make resources deposit with custom allowed materials
                local tr = trace.line(point, point + Vector(0, 0, -1), nil, MASK_SOLID)
                ---@cast tr TraceResult
                table.removeByValue(navAreas, navarea)
                if !allowedMat[tr.MatType] then goto cont end
                local isWater = bit.band(trace.pointContents(point + Vector(0, 0, 1)), CONTENTS.WATER) == 1 and true or false
                local depositInfo = selectDeposit(isWater)
                if !depositInfo then goto cont end
                -- Generating values for deposit
                local size = math.round(depositInfo.size * math.rand(0.5, 1.5))
                local amount = depositInfo.amount and math.round(depositInfo.amount * math.rand(0.5, 1.5))
                local rate = depositInfo.rate and math.round(depositInfo.rate * math.rand(0.5, 1.5))
                local areas = navmesh.find(point, size, 300, 300)
                for _, v in ipairs(areas) do
                    ---@cast v NavArea
                    table.removeByValue(navAreas, v)
                end
                deposit.inited[#deposit.inited+1] = {
                    resource = depositInfo.resource,
                    position = point,
                    size = size,
                    rate = rate,
                    amount = amount,
                    underwater = isWater
                }
                depositsLeft = depositsLeft - 1
                ::cont::
            end
            return true
        end
        return multiThread and coroutine.wrap(generate) or (generate() and nil)
    end
end


return deposit
