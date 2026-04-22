---Garry's mod entities, but with Starfall
---@name BMod Entity Base
---@author AstricUnion
---@shared

-- TODO make "throw()"
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
---@field networkedVariables table<string, any> Networked variables, to network it
local BModEntity = {}
BModEntity.__index = BModEntity
BModEntity.Name = "Base"
BModEntity.Identifier = "base_entity"
BModEntity.Model = "models/hunter/blocks/cube05x05x05.mdl"
BModEntity.hooks = {}

if SERVER then
    ---[SERVER] Create new entity object
    ---@return BModEntity
    function BModEntity:new()
        local obj = setmetatable({ networkedVariables = {} }, self)
        return obj
    end


    ---@param pos Vector Position of an entity
    ---@param ang Angle Angle of an entity
    ---@param freeze boolean Freeze an entity
    function BModEntity:spawn(pos, ang, freeze)
        -- This prop will be like entity for this resource
        local pr = isstring(self.Model) and prop.create(Vector(), Angle(), self.Model, true) or self.Model()
        pr:setPos(pos)
        pr:setAngles(ang)
        pr:setFrozen(freeze)
        -- Just to identify it, if we have only prop
        pr.BModEntity = self.Identifier
        self.ent = pr
        -- Client initialize. Don't look at strange syntax, I will explain it next
        net.start("BModInitializeEntities")
            net.writeTable({{
                id = self.Identifier,
                variables = self.networkedVariables,
                ent = self.ent
            }})
        net.send(find.allPlayers())
        -- And finally, initialize this entity
        ents.inited[pr:entIndex()] = self
        if self.initialize then self:initialize() end

        return self
    end

    ---This hook should initialize entity to new players and
    ---delay it, if creating in same tick with chip
    hook.add("ClientInitialized", "BModInitializeEntities", function(ply)
        if table.isEmpty(ents.inited) then return end
        local toInit = {}
        for _, v in ents.inited do
            toInit[#toInit+1] = {
                id = v.Identifier,
                variables = v.networkedVariables,
                ent = v.ent,
            }
        end
        net.start("BModInitializeEntities")
            net.writeTable(toInit)
        net.send(ply)
    end)


    ---[SERVER] Remove entity
    function BModEntity:remove()
        self.ent:remove()
        ents.inited[self.ent:entIndex()] = nil
        setmetatable(self, nil)
    end

    ---[SERVER] Set networked variable to entity
    ---@param key string Key of a variable
    ---@param value any Value to network
    function BModEntity:setNWVar(key, value)
        self.networkedVariables[key] = value
        if isValid(self.ent) then
            net.start("BModUpdateNWEntity")
                net.writeTable(self.networkedVariables)
                net.writeEntity(self.ent)
            net.send(find.allPlayers())
        end
    end
end


if CLIENT then
    -- Initialize entity on client
    net.receive("BModInitializeEntities", function()
        local toInit = net.readTable()
        for _, v in ipairs(toInit) do
            -- Get type of this entity
            local self = ents.registered[v.id]
            if !self then goto cont end
            local nwVars = v.networkedVariables
            local obj = setmetatable({ ent = v.ent, networkedVariables = nwVars }, self)
            -- Finally, last step: initialize it on a client
            if obj.initialize then obj:initialize() end
            ents.inited[v.ent:entIndex()] = obj
            ::cont::
        end
    end)

    -- Get networked variables
    net.receive("BModUpdateNWEntity", function()
        local nwVars = net.readTable()
        ---@param ent Entity
        net.readEntity(function(ent)
            local bent = ents.inited[ent:entIndex()]
            if !isValid(bent) then return end
            bent.networkedVariables = nwVars
        end)
    end)
end


---[SHARED] Is entity valid
function BModEntity:isValid()
    return isValid(self.ent)
end

---[SHARED] On initialize entity
function BModEntity:initialize() end

---[SHARED] Get networked variable or give default
---@param name string Name of variable
---@param default any Default variable
---@return any
function BModEntity:getNWVar(name, default)
    return self.networkedVariables[name] or default
end


ents.Base = BModEntity


local hookId = "BModEntityHook"

---[SHARED] Register new entity to use it after
---@param class BModEntity
function ents.register(class)
    local id = class.Identifier
    for name, func in pairs(class.hooks) do
        local hooks = ents.hooks[name]
        if !hooks then
            ents.hooks[name] = {}
            local thisHook = ents.hooks[name]
            -- This is a system to add one hook for all
            -- It makes optimization to ~20% on every entity with client Render hooks
            -- and also bypasses a limits
            hook.add(name, hookId, function(...)
                for _, v in pairs(ents.inited) do
                    if !isValid(v.ent) then goto cont end
                    local currentHook = thisHook[v.Identifier]
                    if !currentHook then goto cont end
                    currentHook(v, ...)
                    ::cont::
                end
            end)
        end
        ents.hooks[name][id] = func
    end
    ents.registered[id] = class
end


if SERVER then
    ---[SERVER] Create new entity
    ---@param identifier string Identifier of resource to create
    ---@return BModEntity
    function ents.create(identifier)
        return ents.registered[identifier]:new()
    end
end

return ents
