---@class ents
local ents = ents

---@class Plug: BModEntity
---@field outputFrom BaseMachine
---@field inputTo BaseMachine?
---@field rope Constraint
local Plug = {}
Plug.Identifier = "electric_plug"
Plug.Name = "Plug"
Plug.Model = "models/props_lab/tpplug.mdl"
Plug.hooks = {}

if SERVER then
    function Plug:initialize()
        self.ent:addCollisionListener(function(colData)
            if self.inputTo or colData.HitSpeed:getLength() < 500 then return end
            local ent = colData.HitEntity
            if !ent.BModMachine or ent == self.ent then return end
            local entInfo = ents.registered[ent.BModMachine]
            ---@cast entInfo BaseMachine
            if !entInfo.Inputs["power"] then return end
            self.ent:setPos(self.ent:getPos() - self.ent:getForward() * 16)
            self.ent:setParent(ent)
            self.ent:setNoDraw(true)
            self.inputTo = ents.inited[ent:entIndex()]
        end)
    end

    ---[SERVER] Set machine to output power
    ---@param machine BaseMachine
    function Plug:setOutputFrom(machine)
        self.outputFrom = machine
        self.rope = constraint.rope(self.ent:entIndex(), machine.ent, self.ent, 0, 0, Vector(), Vector(12, 0, 0), 512, 10, 100, 2, "cable/cable2")
    end

    ---@param self Plug
    ---@param ent Entity
    function Plug.hooks.EntityRemoved(self, ent)
        if ent == self.inputTo or !isValid(self.rope) then
            self.ent:remove()
        end
    end
end


ents.register(Plug)


---@class ResourceInput
---@field type string? Type of resource. Can be nil, if using rateField
---@field rateField string? Rate field. Like SolidFuelInUnit. Can be nil, if using type
---@field affectedByGrade boolean? Is delta of this input affected by grade of the machine
---@field gradePower number? Power of grade. By default is 2
---@field maxCount number Max count of this resource
---@field callback? fun(self: BaseMachine, res: Resource, wantToTake: number): boolean? Callback of this input. Return true to prevent input

---@class ResourceOutput
---@field type string? Type of resource to produce. Can be nil, for flex output
---@field maxCount number Max count of this resource
---@field affectedByGrade boolean? Is delta of this output affected by grade of the machine
---@field gradePower number? Power of grade. By default is 2

---@class BaseMachine: BModEntity
---@field Inputs table<string, ResourceInput>
---@field Outputs table<string, ResourceOutput>
---@field OutputOffset Vector
---@field FontSize number? Font size of field
---@field Display boolean Turn on display for this machine
---@field DisplayOffset Vector Display offset
---@field DisplayAngle Angle Display angles
---@field WorkCooldown number? Cooldown between works. Default 0
---@field WorkSound string? Work sound
---@field InstallOffset Vector Offset to install machine
---@field Anchorage number Anchorage of this machine (weld force)
---@field Armor number Armor of this machine. By default is 2
---@field MaxDurability number Maximum of durability for this machine
---@field plugs Plug[] Plugs to output resources
---@field physgunPickedUp Player? Is machine picked up by physgun
---@field private nextThink number Next think. Relative to curtime
---@field private installConstraint Constraint? Is machine installed and constraint to install
---@field private font string Font data for fields
---@field private toProduce Resources Resources to produce, out of outputs
---@field private workSound Sound Sound when work
local BaseMachine = {}
BaseMachine.Identifier = "base_machine"
BaseMachine.Name = "Base machine"
BaseMachine.Model = ""
BaseMachine.hooks = {}

BaseMachine.Inputs = {}
BaseMachine.Outputs = {}
BaseMachine.Display = false
BaseMachine.DisplayOffset = Vector()
BaseMachine.DisplayAngle = Angle()
BaseMachine.InstallOffset = Vector()
BaseMachine.MaxDurability = 1200
BaseMachine.Armor = 2


local function brokenSparks(pos)
    local eff = effect.create()
    eff:setMagnitude(5)
    eff:setScale(2)
    eff:setRadius(2)
    eff:setOrigin(pos)
    eff:play("Sparks")
end


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
        if !self:isTurnedOn() then return end
        self:turnOff(ply)
        self:setNWVar("turnedOn", false)
        if self.workSound then
            self.workSound:stop()
        end
        self:produce()
        BMod.logDebug("(%s) Turned machine off", tostring(self))
    end


    ---[SERVER] [INTERNAL] Turn machine on internally
    ---@param ply Player?
    function BaseMachine:turnOnInternal(ply)
        if self:isBroken() and ply then
            BMod.hintMessage(ply, "Machine is broken. You can repair it with toolbox")
            return
        end
        if self:isTurnedOn() then return end
        local res = self:turnOn(ply)
        if res then
            self:setNWVar("turnedOn", true)
            if self.WorkSound then
                local workSound = sound.create(self.ent, self.WorkSound)
                workSound:play()
                self.workSound = workSound
            end
            BMod.logDebug("(%s) Turned machine on", tostring(self))
        end
    end


    ---[SERVER] On remove. Implements turn off
    function BaseMachine:onRemove()
        local ow = self.ent:getOwner()
        ---@cast ow Player
        self:turnOffInternal(ow)
    end


    ---[SERVER] Physgun pickup to restrict use
    ---@param self BaseMachine
    ---@param ply Player
    ---@param ent Entity
    function BaseMachine.hooks.PhysgunPickup(self, ply, ent)
        self.physgunPickedUp = self.ent == ent and ply or nil
    end


    ---[SERVER] Physgun drop to unrestrict use
    ---@param self BaseMachine
    ---@param _ Player
    ---@param ent Entity
    function BaseMachine.hooks.PhysgunDrop(self, _, ent)
        self.physgunPickedUp = (self.ent ~= ent and self.physgunPickedUp) or (self.ent == ent and nil)
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
        if self.physgunPickedUp or ply:getShootPos():getDistance(tr.HitPos) > 96 then return end
        local isWalking = ply:keyDown(IN_KEY.WALK)
        local isSprinting = ply:keyDown(IN_KEY.SPEED)
        self:onUse(ply, isWalking, isSprinting)
        if isWalking and !isSprinting then
            local isTurnedOn = self:isTurnedOn()
            if isTurnedOn then
                self:turnOffInternal(ply)
            else
                self:turnOnInternal(ply)
            end
        elseif !isWalking and isSprinting and self.Outputs["power"] then
            local plug = ents.create("electric_plug")
            ---@cast plug Plug
            plug:spawn(tr.HitPos, Angle(), false)
            plug:setOutputFrom(self)
            self.plugs[plug.ent:entIndex()] = plug
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
                self.ent:emitSound(resMeta.Sounds.Merge)
                return
            elseif v.rateField and resMeta[v.rateField] then
                local inUnit = resMeta[v.rateField]
                inUnit = isnumber(inUnit) and inUnit or 1
                local count = self:getInput(id)
                local wantToTake = (v.maxCount - count) / inUnit
                if makeCallback(v, wantToTake) then goto cont end
                local actual = res:take(wantToTake)
                self:setInput(id, count + actual * inUnit)
                self.ent:emitSound(resMeta.Sounds.Merge)
                return
            elseif !v.type and !v.rateField then
                local count = self:getInput(id)
                local wantToTake = v.maxCount - count
                if makeCallback(v, wantToTake) then goto cont end
                local actual = res:take(wantToTake)
                self:setInput(id, count + actual, resMeta.Identifier)
                self.ent:emitSound(resMeta.Sounds.Merge)
                return
            end
            ::cont::
        end
    end


    ---[SERVER] Durability mechanics
    ---@param self BaseMachine
    ---@param target Entity
    function BaseMachine.hooks.PostEntityTakeDamage(self, target, _, _, amount, _, pos, force)
        if target ~= self.ent then return end
        local hp = self:getDurability() - amount * (1 / self.Armor)
        if hp <= 0 then
            self.ent:emitSound("Breakable.Metal")
            self:onDestroy()
            self:remove()
            return
        elseif !self:isBroken() and hp < self.MaxDurability * (2/3) then
            self.ent:emitSound("Breakable.Metal")
            self:onBreak()
            self:turnOffInternal()
            brokenSparks(pos)
        end
        self:setDurability(hp)
        self.ent:applyForceOffset(force, pos)
    end


    ---[SERVER] Hook on machine destroy
    function BaseMachine:onDestroy() end

    ---[SERVER] Hook on machine break
    function BaseMachine:onBreak() end


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
    ---@param onWater boolean? Install machine on water also?
    ---@return TraceResult? tr Trace to install
    function BaseMachine:install(onWater)
        if isValid(self.installConstraint) then return end
        local pos = self.ent:getPos()
        if onWater then
            pos = trace.line(pos, pos + Vector(0, 0, 32768), {self.ent}, MASK.SOLID_BRUSHONLY).HitPos
        end
        local tr = trace.line(pos, pos - Vector(0, 0, 32768), {self.ent}, MASK.SOLID_BRUSHONLY + (onWater and MASK.WATER or 0))
        self.ent:setPos(tr.HitPos + self.InstallOffset)
        self.ent:enableMotion(false)
        self.ent:setAngles(self.ent:getAngles():setP(0):setR(0))
        local const = constraint.weld(self.ent, game.getWorld())
        self.installConstraint = const
        return tr
    end

    ---[SERVER] Uninstall this machine
    function BaseMachine:uninstall()
        if !isValid(self.installConstraint) then return end
        self.installConstraint:remove()
        self.installConstraint = nil
        self.ent:enableMotion(true)
    end


    ---[SERVER] Find deposit under machine to mine
    ---@return Deposit? found
    function BaseMachine:findDeposit()
        local deposits = deposit.findInSphere(self.ent:getPos(), 0)
        if next(deposits) ~= nil then
            self:setNWVar("deposit", deposits[1].id)
            return deposits[1]
        end
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
            delta = (delta * self:getGradeMultiplier(input.gradePower))
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
            count = currentCount + (delta * self:getGradeMultiplier(output.gradePower))
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
        local power = outputs["power"]
        if power then
            local toOutput = {}
            for id, v in pairs(self.plugs) do
                if !isValid(v) then
                    self.plugs[id] = nil
                    goto cont
                end
                toOutput[#toOutput+1] = {plug = v, count = v.inputTo:getInput("power")}
                ::cont::
            end
            table.sortByMember(toOutput, "count", true)
            for _, v in ipairs(toOutput) do
                local inputTo = v.plug.inputTo
                local current = v.count
                local max = inputTo.Inputs["power"].maxCount
                local toConsume = math.min(power, max - current)
                inputTo:setInput("power", current + toConsume)
                power = power - toConsume
                if power <= 0 then break end
            end
            outputs["power"] = power
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

    ---[SERVER] Set durability of machine
    ---@param durability number
    function BaseMachine:setDurability(durability)
        self.ent:setHealth(math.clamp(durability, 0, self.MaxDurability))
    end
else
    ---Cached fonts by size
    ---@type table<number, string>
    local fonts = {}

    ---[INTERNAL] [CLIENT] Create font for machine
    function BaseMachine:createFont()
        self.FontSize = self.FontSize or 48
        local font = fonts[self.FontSize] or render.createFont("Roboto",self.FontSize,500,false,false,false,false,0,false,0)
        fonts[self.FontSize] = font
        self.font = font
    end

    ---@class DrawField
    ---@field key string
    ---@field value number|string
    ---@field maxValue number? Max value
    ---@field negate boolean? Negate value color
    ---@field percentage boolean? Show percentage
    ---@field oneLine boolean? Draw at one line

    local Color = Color
    local enableDepth = render.enableDepth
    local setFont = render.setFont
    local setColor = render.setColor
    local drawSimpleTextOutlined = render.drawSimpleTextOutlined
    local ceil = math.ceil
    local upper = string.upper
    local outlineColor = Color(0, 0, 0)
    local defColor = Color(120, 100, 50):hsvToRGB()

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
        setColor(Color())
        local function setPercentColor()
            local col = defColor
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
                value = ceil(value)
            end
            setColor(col)
        end
        local w, h = 0, 0
        if !oneLine then
            -- local half = self.FontSize / 2
            local w1, h1 = drawSimpleTextOutlined(x, y + self.FontSize, upper(key), 2, outlineColor, TEXT_ALIGN.CENTER, TEXT_ALIGN.TOP)
            setPercentColor()
            local w2, h2 = drawSimpleTextOutlined(x, y + self.FontSize * 2, upper(value) .. (percentage and "%" or ""), 2, outlineColor, TEXT_ALIGN.CENTER, TEXT_ALIGN.TOP)
            w, h = w1 + w2, h1 + h2
        else
            setPercentColor()
            drawSimpleTextOutlined(x, y, upper(key) .. ": " .. upper(value) .. (percentage and "%" or ""), 2, outlineColor, TEXT_ALIGN.CENTER, TEXT_ALIGN.TOP)
        end
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
        setFont(self.font)
        enableDepth(false)
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
        setFont("Default")
        setColor(defColor)
        enableDepth(true)
    end

    local Ply = player()
    local filt = {Ply}
    hook.add("PostDrawTranslucentRenderables", "BModMachineDrawDisplay", function()
        local shootPos = Ply.getShootPos(Ply)
        local angs = Ply.getEyeAngles(Ply)
        local tr = trace.line(shootPos, shootPos + angs:getForward() * 196, filt, MASK.SOLID)
        ---@cast tr TraceResult
        local ent = tr.Entity
        if !isValid(ent) or !ent.BModMachine then return end
        local entInfo = ents.inited[ent:entIndex()]
        ---@cast entInfo BaseMachine
        if !entInfo.Display or entInfo:isBroken() then return end
        ---@cast entInfo BaseMachine
        BMod.displayEnt(ent, entInfo.DisplayOffset, entInfo.DisplayAngle, function()
            entInfo:drawDisplay()
        end)
    end)

    ---[CLIENT] Function to draw display on entity. You can offset this display with DisplayOffset and DisplayAngle
    function BaseMachine:drawDisplay() end
end

---[SHARED] Initializing machine
function BaseMachine:initialize()
    self.ent.BModMachine = self.Identifier
    self.plugs = {}
    if CLIENT then self:createFont() end
    if SERVER then
        self.ent:setMaxHealth(self.MaxDurability)
        self.ent:setHealth(self.MaxDurability)
        ---@param colData CollisionData
        self.ent:addCollisionListener(function(colData)
            if !isValid(self) then return end

            if colData.Speed <= 80 then return end
            self.ent:emitSound("Metal_Box.ImpactSoft")

            if colData.Speed <= 150 then return end
            self.ent:emitSound("Metal_Box.ImpactHard")

            if colData.Speed <= 500 then return end
            local phys = self.ent:getPhysicsObject()
            local ent = colData.HitEntity
            local world = game.getWorld()
            local colDir = colData.OurOldVelocity - colData.TheirOldVelocity
            local multiplier = ((colDir:getLength() / 16) * 0.3048) ^ 2
            local theirForce
            local mass = phys:getMass()
            if ent == world then
                theirForce = 0.5 * mass * multiplier
            else
                theirForce = 0.5 * colData.HitObject:getMass() * multiplier
                local forceThreshold = phys:getMass() * (self.Anchorage or 1000)
                if (theirForce >= forceThreshold) then
                    self:turnOffInternal()
                    self:uninstall()
                end
            end
            local physDamage = math.floor(theirForce / mass)
            self.ent:applyDamage(physDamage, ent or world, ent, DAMAGE.CRUSH, colData.HitPos)
            brokenSparks(colData.HitPos)
        end)
    end
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
---@param power number? Power for grade. By default 2
---@return number
function BaseMachine:getGradeMultiplier(power)
    return (1 + ((self:getGrade() - 1) * 0.25)) ^ (power or 2)
end

---[SHARED] Get durability of machine
---@return number durability
function BaseMachine:getDurability()
    return self.ent:getHealth()
end

---[SHARED] Is machine broken
---@return boolean broken
function BaseMachine:isBroken()
    return self:getDurability() < self.MaxDurability * (2/3)
end

---[SHARED] Is machine destroyed
---@return boolean destroyed
function BaseMachine:isDestroyed()
    return self:getDurability() <= 0
end


ents.register(BaseMachine)

