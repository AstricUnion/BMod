---@name BMod effects
---@author AstricUnion
---@client


---@class beff
local beff = {}
beff.smokes = {
    material.load("particle/smokestack"),
    material.load("particles/smokey"),
    material.load("particle/particle_smokegrenade")
}


function beff.craftEffect(origin, scale)
    local emm = particle.create(origin, false)
    local len = #beff.smokes
    for _=0, 100 do
        local sprite = beff.smokes[math.random(1, len)]
        local size = math.rand(30, 60) * scale
        local particle = emm:add(
            sprite, origin, size, size,
            0, 0, 255, 0, math.rand(1, 2) * scale
        )
        if particle then
            particle:setVelocity(1000 * Vector(math.rand(-1, 1), math.rand(-1, 1), math.rand(-1, 1)) * scale)
            particle:setAirResistance(1000)
            particle:setRoll(math.rand(-3, 3))
            particle:setRollDelta(math.rand(-2, 2))
            particle:setGravity(Vector(0, 0, math.random(-10, -100)))
            particle:setLighting(true)
            local darg = math.rand(200, 255)
            particle:setColor(Color(darg, darg, darg))
            particle:setCollide(false)
        end
    end
    emm:destroy()
end

return beff
