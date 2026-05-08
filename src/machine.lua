---@class ents
local ents = ents

---@class ResourceInput
---@field identifier string? Identifier of input
---@field type string? Type of resource. Can be nil, if using rateField
---@field rateField string? Rate field. Like SolidFuelInUnit
---@field maxCount number Max count of this resource
---@field callback fun(res: Resource) Callback of this input

---@class BaseMachine: BModEntity
---@field Inputs ResourceInput[]
local BaseMachine = {}
BaseMachine.Identifier = "base_machine"
BaseMachine.Name = "Base machine"
BaseMachine.Model = ""
BaseMachine.hooks = {}
BaseMachine.Inputs = {}

if SERVER then
    function BaseMachine:initialize()
    end

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
        for _, v in ipairs(self.Inputs) do
            if v.type and res.Identifier == v.type then
                local count = self:getNWVar(v.identifier, 0)
                local actual = res:take(v.maxCount - count)
                self:setNWVar(v.identifier, count + actual)
                if v.callback then v.callback(res) end
                return
            elseif v.rateField and res[v.rateField] then
                local inUnit = res[v.rateField]
                local count = self:getNWVar(v.identifier, 0)
                local actual = res:take((v.maxCount - count) / inUnit)
                self:setNWVar(v.identifier, count + actual * inUnit)
            end
        end
    end
end


ents.register(BaseMachine)

