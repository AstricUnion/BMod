---@class ents
local ents = ents

---@class ResourceInput
---@field type string? Type of resource. Can be nil, if using rateField
---@field rateField string? Rate field. Like SolidFuelInUnit. Can be nil, if using type
---@field maxCount number Max count of this resource
---@field callback? fun(self: BaseMachine, res: Resource, wantToTake: number): boolean? Callback of this input. Return true to prevent input

---@class BaseMachine: BModEntity
---@field Inputs table<string, ResourceInput>
local BaseMachine = {}
BaseMachine.Identifier = "base_machine"
BaseMachine.Name = "Base machine"
BaseMachine.Model = ""
BaseMachine.hooks = {}
BaseMachine.Inputs = {}

if SERVER then
    ---[SERVER] Hook on machine use
    ---@param ply Player
    ---@param isWalking boolean
    ---@param isSprinting boolean
    function BaseMachine:onUse(ply, isWalking, isSprinting) end

    ---[SERVER] KeyPress hook to get when using machine
    ---@param self BaseMachine
    ---@param ply Player
    ---@param key number
    function BaseMachine.hooks.KeyPress(self, ply, key)
        if key ~= IN_KEY.USE then return end
        local tr = ply:getEyeTrace()
        ---@cast tr TraceResult
        if tr.Entity ~= self.ent then return end
        if ply:getShootPos():getDistance(tr.HitPos) > 96 then return end
        self:onUse(ply, ply:keyDown(IN_KEY.WALK), ply:keyDown(IN_KEY.SPEED))
    end


    ---[SERVER] Interaction of resource
    ---@param self BaseMachine
    ---@param res Resource
    ---@param ent Entity
    function BaseMachine.hooks.BModResourceInteracted(self, res, ent)
        if ent ~= self.ent then return end
        local function makeCallback(input, want)
            local result = false
            if input.callback then result = input.callback(self, res, want) end
            return result
        end
        local resMeta = getmetatable(res)
        for id, v in pairs(self.Inputs) do
            if v.type and resMeta.Identifier == v.type then
                local count = self:getNWVar(id, 0)
                local wantToTake = v.maxCount - count
                if makeCallback(v, wantToTake) then goto cont end
                local actual = res:take(wantToTake)
                self:setNWVar(id, count + actual)
                return
            elseif v.rateField and resMeta[v.rateField] then
                local inUnit = resMeta[v.rateField]
                inUnit = isnumber(inUnit) and inUnit or 1
                local count = self:getNWVar(id, 0)
                local wantToTake = (v.maxCount - count) / inUnit
                if makeCallback(v, wantToTake) then goto cont end
                local actual = res:take(wantToTake)
                self:setNWVar(id, count + actual * inUnit)
                return
            elseif !v.type and !v.rateField then
                local count = self:getNWVar(id, 0)
                local wantToTake = v.maxCount - count
                if makeCallback(v, wantToTake) then goto cont end
                local actual = res:take(wantToTake)
                self:setNWVar(id, count + actual)
                self:setNWVar(id .. "Type", resMeta.Identifier)
                v.type = resMeta.Identifier
                return
            end
            ::cont::
        end
    end


    ---[SERVER] Set input resource count
    ---@param identifier string Identifier of input
    ---@param count number Count of resource to set
    ---@param type string? Type of resource for flex. Can be nil
    function BaseMachine:setInput(identifier, count, type)
        local input = self.Inputs[identifier]
        if !input then
            throw("No such input: " .. identifier)
            return
        end
        local currentCount = self:getNWVar(identifier, 0)
        local currentType = self:getNWVar(identifier .. "Type", nil)
        self:setNWVar(identifier, math.clamp(count, 0, input.maxCount))
        if !input.type and !input.rateField and type and currentCount == 0 then
            self:setNWVar(identifier .. "Type", type)
            input.type = type
        elseif input.type and currentType and count == 0 then
            self:setNWVar(identifier .. "Type", nil)
            input.type = nil
        end
    end
end


---[SHARED] Get input of machine
---@param identifier string
---@return number count Count of resource
---@return string? type Resource type
function BaseMachine:getInput(identifier)
    return self:getNWVar(identifier, 0), self:getNWVar(identifier .. "Type", nil)
end


ents.register(BaseMachine)

