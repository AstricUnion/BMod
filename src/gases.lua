---@name BMod gas classes
---@author AstricUnion

---@class gas
local gas = gas


-- Gas effects
if SERVER then
    ---Poisoning with carbon-monooxide. Cough and damage
    ---@class Poisoning: GasEffect
    ---@field nextCough table<Player, number>
    local Poisoning = setmetatable({}, gas.EffectBase)
    Poisoning.__index = Poisoning

    function Poisoning:initialize()
        self.nextCough = {}
    end

    function Poisoning:effect(ply, particle)
        local next = self.nextCough[ply] or 0
        local cur = timer.curtime()
        if next - cur > 0 then return end
    end
end


gas.register(Gas)

if SERVER then
    timer.create("", 0.1, 100, function()
        local posOffset = randVector(-50, 50):setZ(0)
        local part = gas.create("base_gas")
        if !part then return end
        part:setPos(chip():getPos() + posOffset)
        part.velocity = randVector() * math.random(1, 100)
    end)
end
