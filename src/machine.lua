---@class ents
local ents = ents

---@class ResourceInput
---@field type string? Type of resource. Can be nil, if using rateField
---@field rateField string? Rate field. Like SolidFuelInUnit. Can be nil, if using type
---@field maxCount number Max count of this resource
---@field callback? fun(self: BaseMachine, res: Resource, wantToTake: number): boolean? Callback of this input. Return true to prevent input

---@class ResourceOutput
---@field type string? Type of resource to produce. Can be nil, for flex output
---@field maxCount number Max count of this resource

---@class BaseMachine: BModEntity
---@field Inputs table<string, ResourceInput>
---@field Outputs table<string, ResourceOutput>
---@field OutputOffset Vector
---@field WorkCooldown number? Cooldown between works. Default 0
---@field EndlessDeposits boolean Can it mine from endless deposits Default true
---@field LimitedDeposits boolean Can it mine from limited deposits. Default true
---@field private nextThink number Next think. Relative to curtime
---@field private installConstraint Constraint? Is machine installed and constraint to install
local BaseMachine = {}
BaseMachine.Identifier = "base_machine"
BaseMachine.Name = "Base machine"
BaseMachine.Model = ""
BaseMachine.hooks = {}

BaseMachine.EndlessDeposits = true
BaseMachine.LimitedDeposits = true

BaseMachine.Inputs = {}
BaseMachine.Outputs = {}


if SERVER then
    ---[SERVER] Turn machine on. Default on ALT+E. Return true to verify machine state
    ---@param ply Player
    ---@return boolean? turnOn
    function BaseMachine:turnOn(ply) end

    ---[SERVER] Turn machine off. Default on ALT+E, if machine turned on
    ---@param ply Player
    function BaseMachine:turnOff(ply) end

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
        local isWalking = ply:keyDown(IN_KEY.WALK)
        self:onUse(ply, isWalking, ply:keyDown(IN_KEY.SPEED))
        if isWalking then
            local isTurnedOn = self:isTurnedOn()
            if isTurnedOn then
                self:turnOff(ply)
                self:setNWVar("turnedOn", false)
                self:produce()
            else
                local res = self:turnOn(ply)
                self:setNWVar("turnedOn", res)
                if !res then self:produce() end
            end
        end
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
                local count = self:getInput(id)
                local wantToTake = v.maxCount - count
                if makeCallback(v, wantToTake) then goto cont end
                local actual = res:take(wantToTake)
                self:setInput(id, count + actual)
                return
            elseif v.rateField and resMeta[v.rateField] then
                local inUnit = resMeta[v.rateField]
                inUnit = isnumber(inUnit) and inUnit or 1
                local count = self:getInput(id)
                local wantToTake = (v.maxCount - count) / inUnit
                if makeCallback(v, wantToTake) then goto cont end
                local actual = res:take(wantToTake)
                self:setInput(id, count + actual * inUnit)
                return
            elseif !v.type and !v.rateField then
                local count = self:getInput(id)
                local wantToTake = v.maxCount - count
                if makeCallback(v, wantToTake) then goto cont end
                local actual = res:take(wantToTake)
                self:setInput(id, count + actual, resMeta.Identifier)
                v.type = resMeta.Identifier
                return
            end
            ::cont::
        end
    end


    ---[SERVER] Think function. To make machine work
    function BaseMachine.hooks:Think()
        local cur = timer.curtime()
        if !self:isTurnedOn() then return end
        if (self.nextThink or 0) >= cur then return end
        local res = self:work()
        if res == false then
            self:turnOff()
            self:produce()
        end
        self.nextThink = cur + (self.WorkCooldown or 0)
    end


    ---[SERVER] When machine works. Return false to turn machine off
    ---@return false? end
    function BaseMachine:work() end


    ---[SERVER] Install this machine on ground
    function BaseMachine:install()
        if isValid(self.installConstraint) then return end
        local pos = self.ent:getPos()
        local tr = trace.line(pos, pos - Vector(0, 0, 32768), {self.ent}, MASK.SOLID_BRUSHONLY)
        self.ent:setPos(tr.HitPos)
        self.ent:enableMotion(false)
        self.ent:setAngles(self.ent:getAngles():setP(0):setR(0))
        local const = constraint.weld(self.ent, game.getWorld())
        self.installConstraint = const
    end

    ---[SERVER] Uninstall this machine
    function BaseMachine:uninstall()
        if !isValid(self.installConstraint) then return end
        self.installConstraint:remove()
        self.installConstraint = nil
    end


    ---[SERVER] Find deposit under machine to mine
    ---@return boolean found
    function BaseMachine:findDeposit()
        local deposits = deposit.findInSphere(self.ent:getPos(), 0)
        if next(deposits) ~= nil then
            self:setNWVar("deposit", deposits[1].id)
            return true
        end
        return false
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
        local currentCount, currentType = self:getInput(identifier)
        self:setNWVar("input_" .. identifier, math.clamp(count, 0, input.maxCount))
        if !input.type and !input.rateField and type and currentCount == 0 then
            self:setNWVar("input_" .. identifier .. "Type", type)
            input.type = type
        elseif input.type and currentType and count == 0 then
            self:setNWVar("input_" .. identifier .. "Type", nil)
            input.type = nil
        end
    end


    ---[SERVER] Set output resource
    ---@param identifier string Identifier of the output
    ---@param count number Count of output
    ---@param type string? Type of resource for flex. Can be nil
    function BaseMachine:setOutput(identifier, count, type)
        local output = self.Outputs[identifier]
        if !output then
            throw("No such output: " .. identifier)
            return
        end
        local currentCount, currentType = self:getOutput(identifier)
        if count > output.maxCount then
            count = count - output.maxCount
            self:produce()
        end
        self:setNWVar("output_" .. identifier, count)
        if !output.type and type and currentCount == 0 then
            self:setNWVar("output_" .. identifier .. "Type", type)
            output.type = type
        elseif output.type and currentType and count == 0 then
            self:setNWVar("output_" .. identifier .. "Type", nil)
            output.type = nil
        end
    end

    ---[SERVER] Produce outputs
    function BaseMachine:produce()
        ---@type Resources
        local outputs = {}
        for id, output in pairs(self.Outputs) do
            local res, type = self:getOutput(id)
            if !type then goto cont end
            outputs[type or output.type] = res
            self:setOutput(id, 0)
            ::cont::
        end
        resource.produce(self.ent:localToWorld(self.OutputOffset or Vector()), self.ent:getAngles(), outputs)
    end
end


---[SHARED] Get input of machine
---@param identifier string
---@return number count Count of resource
---@return string? type Resource type, if flex
function BaseMachine:getInput(identifier)
    return self:getNWVar("input_" .. identifier, 0), self:getNWVar("input_" .. identifier .. "Type", nil)
end


---[SHARED] Get output of machine
---@param identifier string
---@return number count Count of resource
---@return string? type Resource type, if flex
function BaseMachine:getOutput(identifier)
    return self:getNWVar("output_" .. identifier, 0), self:getNWVar("output_" .. identifier .. "Type", nil)
end

---[SHARED] Get deposit of machine
---@return Deposit? deposit
function BaseMachine:getDeposit()
    return deposit.inited[self:getNWVar("deposit", nil)]
end

---[SHARED] Is machine turned on
---@return boolean isTurnedOn
function BaseMachine:isTurnedOn()
    return self:getNWVar("turnedOn", false)
end



ents.register(BaseMachine)

