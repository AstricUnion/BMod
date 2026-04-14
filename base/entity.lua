---@name BMod Entity Base
---@author AstricUnion
---@shared

-- TODO make more cool system for nets
-- TODO OOO: optimize, optimize and again optimize

---Class for entities manipulations
---@class ents
---@field inited table<number, BModEntity> Inited and therefore spawned entities
---@field registered table<string, BModEntity> Registrated classes. Index is inner Identifier
---@field hooks table<string, table<string, function>> Registrated hooks in entities.
---Index in outer table is a hook name, in inner is an entity identifier
local ents = {}
ents.inited = {}
ents.registered = {}
ents.hooks = {}


---Base class for entity
---@class BModEntity
-- Public fields
---@field Identifier string Identifier of an entity
---@field Name string Pretty name of an entity
---@field Model (fun(): Entity) | string Model of a resource. Function for custom model logic
---@field hooks table<string, function> Hooks to initialize on this entity
-- Private fields
---@field ent Entity Prop or entity with hooks for interactions. Can be nil on client
local BModEntity = {}
BModEntity.__index = BModEntity
BModEntity.Name = "Base"
BModEntity.Identifier = "base_entity"
BModEntity.Model = "models/hunter/blocks/cube05x05x05.mdl"
BModEntity.hooks = {}

if SERVER then
    ---[SERVER] Create new resource entity
    ---@param pos Vector Position of resource
    ---@param ang Angle Angle of resource
    ---@param freeze boolean Freeze a resource
    ---@return BModEntity
    function BModEntity:new(pos, ang, freeze)
        -- This prop will be like entity for this resource
        local pr = isstring(self.Model) and prop.create(Vector(), Angle(), self.Model, true) or self.Model()
        pr:setPos(pos)
        pr:setAngles(ang)
        pr:setFrozen(freeze)
        local obj = setmetatable({ ent = pr }, self)
        if obj.initialize then obj:initialize() end
        local function init(ply)
            if !pr:isValid() then return end
            net.start("BModInitializeEntity")
                net.writeString(obj.Identifier)
                net.writeEntity(obj.ent)
            net.send(ply)
        end
        -- This hook should initialize resource to new players and
        -- delay it, if creating in same tick with chip
        hook.add("ClientInitialized", "BModInitializeEntity" .. pr:entIndex(), init)
        init(find.allPlayers())
        ents.inited[pr:entIndex()] = obj
        return obj
    end


    ---[SERVER] Remove entity
    function BModEntity:remove()
        self.ent:remove()
        ents.inited[self.ent:entIndex()] = nil
        setmetatable(self, nil)
    end
end


if CLIENT then
    -- Initialize entity on client
    net.receive("BModInitializeEntity", function()
        local identifier = net.readString()
        local self = ents.registered[identifier]
        if !self then return end
        ---@param ent Entity
        net.readEntity(function(ent)
            local obj = setmetatable({ ent = ent }, self)
            if obj.initialize then obj:initialize() end
            ents.inited[ent:entIndex()] = obj
        end)
    end)
end


---[SHARED] Is entity valid
function BModEntity:isValid()
    return self ~= nil and self.ent:isValid()
end

---[SHARED] On initialize entity
function BModEntity:initialize() end


ents.Base = BModEntity


local hookId = "BModEntityHook"

---[SHARED] Register new entity to use it after
---@param class BModEntity
function ents.register(class)
    local id = class.Identifier
    for name, func in pairs(class.hooks) do
        local hooks = ents.hooks[name]
        if !hooks then
            -- This is a system for adding optimized hooks
            -- For all entities we have only one hook
            -- It makes optimization to ~20% on every entity with client Render hooks
            hook.add(name, hookId, function(...)
                local thisHook = ents.hooks[name]
                for _, v in pairs(ents.inited) do
                    local currentHook = thisHook[v.Identifier]
                    if !currentHook then goto cont end
                    currentHook(v, ...)
                    ::cont::
                end
            end)
            ents.hooks[name] = {}
        end
        ents.hooks[name][id] = func
    end
    ents.registered[id] = class
end


if SERVER then
    ---[SERVER] Create new entity
    ---@param pos Vector Init position of resource
    ---@param ang Angle Init angles of resource
    ---@param identifier string Identifier of resource to create
    ---@param freeze boolean Freeze resource entity
    ---@return BModEntity
    function ents.create(pos, ang, identifier, freeze)
        return ents.registered[identifier]:new(pos, ang, freeze)
    end
end

return ents
