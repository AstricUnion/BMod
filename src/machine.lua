---@class ents
local ents = ents

---@class ResourceInput
---@field type string? Type of resource. Can be nil, if using rateField
---@field rateField string? Rate field. Like SolidFuelInUnit. Can be nil, if using type
---@field affectedByGrade boolean? Is delta of this input affected by grade of the machine
---@field maxCount number Max count of this resource
---@field callback? fun(self: BaseMachine, res: Resource, wantToTake: number): boolean? Callback of this input. Return true to prevent input

---@class ResourceOutput
---@field type string? Type of resource to produce. Can be nil, for flex output
---@field maxCount number Max count of this resource
---@field affectedByGrade boolean? Is delta of this output affected by grade of the machine

---@class BaseMachine: BModEntity
---@field Inputs table<string, ResourceInput>
---@field Outputs table<string, ResourceOutput>
---@field OutputOffset Vector
---@field FontSize number? Font size of field
---@field WorkCooldown number? Cooldown between works. Default 0
---@field EndlessDeposits boolean Can it mine from endless deposits Default true
---@field LimitedDeposits boolean Can it mine from limited deposits. Default true
---@field private nextThink number Next think. Relative to curtime
---@field private installConstraint Constraint? Is machine installed and constraint to install
---@field private font string Font data for fields
---@field private toProduce Resources Resources to produce, out of outputs
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
    ---@param ply Player?
    ---@return boolean? turnOn
    function BaseMachine:turnOn(ply) end

    ---[SERVER] Turn machine off. Default on ALT+E, if machine turned on
    ---@param ply Player?
    function BaseMachine:turnOff(ply) end

    ---[SERVER] Hook on machine use
    ---@param ply Player
    ---@param isWalking boolean
    ---@param isSprinting boolean
    function BaseMachine:onUse(ply, isWalking, isSprinting) end


    ---[SERVER] [INTERNAL] Turn machine off internally
    ---@param ply Player?
    function BaseMachine:turnOffInternal(ply)
        self:turnOff(ply)
        self:setNWVar("turnedOn", false)
        self:produce()
        BMod.logDebug("(%s) Turned machine off", tostring(self))
    end


    ---[SERVER] [INTERNAL] Turn machine on internally
    ---@param ply Player?
    function BaseMachine:turnOnInternal(ply)
        local res = self:turnOn(ply)
        if res then
            self:setNWVar("turnedOn", true)
            BMod.logDebug("(%s) Turned machine on", tostring(self))
        end
    end


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
                self:turnOffInternal(ply)
            else
                self:turnOnInternal(ply)
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
        local res = self:work(cur)
        if res == false then
            self:turnOffInternal()
        end
        self.nextThink = cur + (self.WorkCooldown or 0)
    end


    ---[SERVER] When machine works. Return false to turn machine off
    ---@param cur number
    ---@return false? end
    function BaseMachine:work(cur) end


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


    ---[SERVER] Hook on setting input
    ---@param identifier string Identifier of input
    ---@param count number Count of resource to set
    ---@param type string? Type of resource for flex. Can be nil
    function BaseMachine:onSetInput(identifier, count, type) end


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
        local isFlex = !input.type and !input.rateField
        local typeToSet
        if isFlex and type and currentCount == 0 then
            self:setNWVar("input_" .. identifier .. "Type", type)
            typeToSet = type
        elseif currentType and count == 0 then
            self:setNWVar("input_" .. identifier .. "Type", nil)
        end
        BMod.logDebug("(%s) Set input %s with type %s to %s", tostring(self), identifier, type or currentType or input.type, count)
        self:onSetInput(identifier, count, typeToSet or currentType)
    end


    ---[SERVER] Hook on setting output
    ---@param identifier string Identifier of input
    ---@param count number Count of resource to set
    ---@param type string? Type of resource for flex. Can be nil
    function BaseMachine:onSetOutput(identifier, count, type) end


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
        local setType = false
        if count > output.maxCount then
            count = count - output.maxCount
            self:produce()
            setType = true
        end
        self:setNWVar("output_" .. identifier, count)
        local typeToSet
        local isFlex = !output.type
        if isFlex and type and (currentCount == 0 or setType) then
            self:setNWVar("output_" .. identifier .. "Type", type)
            typeToSet = type
        elseif isFlex and currentType and count == 0 then
            self:setNWVar("output_" .. identifier .. "Type", nil)
        end
        self:onSetOutput(identifier, count, typeToSet or currentType)
    end


    ---[SERVER] Consume input with modifiers by grade
    ---@param identifier string Identifier of the input
    ---@param delta number Count to consume
    ---@param type string? Type of resource for flex. Can be nil
    ---@return number count Number actually consumed
    function BaseMachine:consumeInput(identifier, delta, type)
        local input = self.Inputs[identifier]
        if !input then
            throw("No such input: " .. identifier)
            return
        end
        local currentCount = self:getInput(identifier)
        local count = currentCount - delta
        if input.affectedByGrade then
            delta = (delta * self:getGradeMultiplier())
            count = currentCount - delta
        end
        self:setInput(identifier, count, type)
        return delta
    end


    ---[SERVER] Add value to output with modifiers by grade
    ---@param identifier string Identifier of the output
    ---@param delta number Count to consume
    ---@param type string? Type of resource for flex. Can be nil
    function BaseMachine:addToOutput(identifier, delta, type)
        local output = self.Outputs[identifier]
        if !output then
            throw("No such output: " .. identifier)
            return
        end
        local currentCount = self:getOutput(identifier)
        local count = currentCount + delta
        if output.affectedByGrade then
            count = currentCount + (delta * self:getGradeMultiplier())
        end
        self:setOutput(identifier, count, type)
    end

    ---[SERVER] Set grade of machine
    ---@param grade number
    function BaseMachine:setGrade(grade)
        self:setNWVar("grade", math.clamp(grade, 1, 5))
    end

    ---[SERVER] Set custom resource to produce 
    ---@param identifier string Identifier of resource
    ---@param count number Count of resource
    function BaseMachine:setCustomProduce(identifier, count)
        self.toProduce = self.toProduce or {}
        self.toProduce[identifier] = count
    end

    ---[SERVER] Get custom resource from produce 
    ---@param identifier string Identifier of resource
    ---@return number count Count of resource to produce
    function BaseMachine:getCustomProduce(identifier)
        if !self.toProduce then return 0 end
        return self.toProduce[identifier] or 0
    end

    ---[SERVER] Produce outputs
    function BaseMachine:produce()
        ---@type Resources
        local outputs = {}
        local entStr = tostring(self)
        for id, output in pairs(self.Outputs) do
            local res, type = self:getOutput(id)
            type = type or output.type
            if !type then goto cont end
            outputs[type] = res
            BMod.logDebug("(%s) Produced %s of %s", entStr, res, type)
            self:setOutput(id, 0, type)
            ::cont::
        end
        if self.toProduce then
            for id, v in pairs(self.toProduce) do
                outputs[id] = v
                BMod.logDebug("(%s) Produced %s of %s", entStr, v, type)
            end
            self.toProduce = nil
        end
        resource.produce(self.ent:localToWorld(self.OutputOffset or Vector()), self.ent:getAngles(), outputs)
    end

    ---[SERVER] Take inputs resource
    function BaseMachine:takeInputs()
        ---@type Resources
        local inputs = {}
        local entStr = tostring(self)
        for id, input in pairs(self.Inputs) do
            local res, type = self:getInput(id)
            if !type then goto cont end
            type = type or input.type
            inputs[type] = res
            BMod.logDebug("(%s) Took %s of %s", entStr, res, type)
            self:setInput(id, 0, type)
            ::cont::
        end
        resource.produce(self.ent:localToWorld(self.OutputOffset or Vector()), self.ent:getAngles(), inputs)
    end
else
    ---[INTERNAL] [CLIENT] Create font for machine
    function BaseMachine:createFont()
        self.FontSize = self.FontSize or 48
        self.font = render.createFont("Roboto",self.FontSize,500,false,false,false,false,0,false,0)
    end

    ---@class DrawField
    ---@field key string
    ---@field value number|string
    ---@field maxValue number? Max value
    ---@field negate boolean? Negate value color
    ---@field percentage boolean? Show percentage
    ---@field oneLine boolean? Draw at one line

    ---[CLIENT] Function to draw field with info
    ---@param x number
    ---@param y number
    ---@param key string
    ---@param value number|string
    ---@param maxValue number? Max value
    ---@param negate boolean? Negate value color
    ---@param percentage boolean? Show percentage
    ---@param oneLine boolean? Draw at one line
    ---@return number w Width of info
    ---@return number h Height of info
    function BaseMachine:drawField(x, y, key, value, maxValue, negate, percentage, oneLine)
        render.setFont(self.font)
        render.enableDepth(false)
        local function setColor()
            local col = Color(120, 100, 50):hsvToRGB()
            if isnumber(value) then
                ---@cast value number
                if maxValue then
                    local percent = (value / maxValue)
                    if percentage then
                        value = percent * 100
                    end
                    local colPercent = negate and (1 - percent) or percent
                    col = Color(colPercent * 120, 100, 50):hsvToRGB()
                end
                value = math.ceil(value)
            end
            render.setColor(col)
        end
        local w, h = 0, 0
        if !oneLine then
            -- local half = self.FontSize / 2
            local w1, h1 = render.drawSimpleTextOutlined(x, y + self.FontSize, string.upper(key), 2, Color(0, 0, 0), TEXT_ALIGN.CENTER, TEXT_ALIGN.TOP)
            setColor()
            local w2, h2 = render.drawSimpleTextOutlined(x, y + self.FontSize * 2, string.upper(value) .. (percentage and "%" or ""), 2, Color(0, 0, 0), TEXT_ALIGN.CENTER, TEXT_ALIGN.TOP)
            w, h = w1 + w2, h1 + h2
        else
            setColor()
            render.drawSimpleTextOutlined(x, y, string.upper(key) .. ": " .. string.upper(value) .. (percentage and "%" or ""), 2, Color(0, 0, 0), TEXT_ALIGN.CENTER, TEXT_ALIGN.TOP)
        end
        render.setFont("Default")
        render.setColor(Color())
        render.enableDepth(true)
        return w, h
    end


    ---[CLIENT] Function to draw fields with info
    ---@param x number Position by X
    ---@param y number Position by Y
    ---@param tbl DrawField[] List of fields to draw
    ---@param horizontal boolean? Draw horizontally
    ---@param gap number? Gap between fields
    function BaseMachine:drawFields(x, y, tbl, horizontal, gap)
        gap = gap or 0
        local xOffset = 0
        local yOffset = 0
        for _, v in ipairs(tbl) do
            local key = v.key or v[1]
            local value = v.value or v[2]
            local maxValue = v.maxValue or v[3]
            local negate = v.negate or v[4]
            local percentage = v.percentage or v[5]
            local oneLine = v.oneLine or v[6]
            local w, h = self:drawField(x + xOffset, y + yOffset, key, value, maxValue, negate, percentage, oneLine)
            if horizontal then
                xOffset = xOffset + w + gap
            else
                yOffset = yOffset + h + gap
            end
        end
    end
end

---[SHARED] Initializing machine
function BaseMachine:initialize()
    self.ent.BModMachine = self.Identifier
    if CLIENT then self:createFont() end
    self:machineInitialize()
end


---[SHARED] Initialize machine hook
function BaseMachine:machineInitialize() end


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

---[SHARED] Get grade of machine
---@return number grade
function BaseMachine:getGrade()
    return self:getNWVar("grade", 1)
end

---[SHARED] Get grade multiplier for resources
---@return number
function BaseMachine:getGradeMultiplier()
    return (1 + ((self:getGrade() - 1) * 0.25)) ^ 2
end



ents.register(BaseMachine)

