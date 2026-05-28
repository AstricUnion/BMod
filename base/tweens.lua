---@name Tweens
---@author AstricUnion
---@shared

---@alias tweenfun fun(process: number): boolean?

---Class to manipulate tweens
---@class tween
local tween = {}


-- function Param:update(process)
--     self.from = self.from or self.property.get(self.ent)
--     local fromVal = self.from
--     local startValue = isfunction(fromVal) and fromVal() or fromVal
--     local toVal = self.to
--     local endValue = isfunction(toVal) and toVal() or toVal
--     local change = endValue - startValue
--     local eased = self.easing(process / self.duration)
--     local tweened = startValue + change * eased
--     self.property.set(self.ent, tweened)
--     local proc = self.process
--     if proc then
--         proc(eased)
--     end
-- end


---@class ParamProperty
---@field get fun(self: Entity)
---@field set fun(self: Entity, value: any)

---@enum ParamProperties
tween.ParamProperties = {
    NONE = {
        get = function() end,
        set = function() end
    },
    POS = {
        get = function(x) return x:getPos() end,
        set = function(x, set) x:setPos(set) end
    },
    ANGLES = {
        get = function(x) return x:getAngles() end,
        set = function(x, set) x:setAngles(set) end
    },
    LOCALPOS = {
        get = function(x) return x:getLocalPos() end,
        set = function(x, set) x:setLocalPos(set) end
    },
    LOCALANGLES = {
        get = function(x) return x:getLocalAngles() end,
        set = function(x, set) x:setLocalAngles(set) end
    },
    COLOR = {
        get = function(x) return x:getColor() end,
        set = function(x, set) x:setColor(set) end
    },
    SCALE = {
        get = function(x) return x:getScale() end,
        set = function(x, set) x:setScale(set) end
    },
    ANGULARVELOCITY = {
        get = function(x) return x:getAngleVelocity() end,
        set = function(x, set) x:setAngleVelocity(set) end
    },
    -- Only with holograms!
    LOCALANGULARVELOCITY = {
        get = function(x) return x.angular end,
        set = function(x, set)
            if !x.angular then x.angular = Vector() end
            x:setLocalAngularVelocity(set)
            x.angular = set
        end
    },
    VELOCITY = {
        get = function(x) return x:getVelocity() end,
        set = function(x, set) x:setVelocity(set) end
    },
    ADDVELOCITY = {
        get = function(x) return x:getVelocity() end,
        set = function(x, set) x:addVelocity(set) end
    },
}


---@class TweenParam
---@field startAt number?
---@field endAt number?
---@field entity Entity?
---@field property ParamProperty?
---@field from (any|fun(): any)?
---@field to (any|fun(): any)?
---@field easing fun(process: number)?
---@field onStart fun()?
---@field onEnd fun()?


---[SHARED] Create new parameter change
---@param tbl TweenParam
---@return tweenfun
function tween.param(tbl)
    local startAt = tbl.startAt or tbl[1] or 0
    local endAt = tbl.endAt or tbl[2]
    local ent = tbl.entity or tbl[3]
    local property = tbl.property or tbl[4] or tween.ParamProperties.NONE
    local from = tbl.from or tbl[5] or property.get(ent)
    local to = tbl.to or tbl[6]
    local easing = tbl.easing or tbl[7]
    return function(process)
        if process < startAt then return end
        local duration = endAt - startAt
        local fraction = math.min(process / duration, 1)
        from = isfunction(from) and from() or from
        to = isfunction(to) and to() or to
        local change = from - to
        local eased = easing(fraction)
        local tweened = from + change * eased
        property.set(ent, tweened)
        if fraction == 1 then
            return true
        end
    end
end

---[SHARED] Create new tween
---@param tbl tweenfun
---@return tweenfun
function tween.new(tbl)
    return function(process)
        local result = true
        for _, v in tbl do
            if !v(process) then
                result = false
            end
        end
        return result
    end
end

