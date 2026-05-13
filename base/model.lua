---@name Model
---@author AstricUnion


---Class to manipulate hologram models with custom meshes and hitboxes
---@class model
---@field registered table<string, ModelInfo>
---@field mesh table<number, CMesh>
local model = {}
model.registered = {}
model.mesh = {}
model.rigVisible = false

---@alias modelfun fun(): (Entity?)

---Class to create custom mesh for holograms
---@class CMesh
---@field id number
---@field url string? [SERVER] URL of custom mesh to load
---@field mesh Mesh? [CLIENT] Loaded mesh
local CMesh = {}

if SERVER then
    ---[SERVER] Create new custom mesh
    ---@param url string URL or file path to mesh
    ---@return CMesh
    function CMesh:new(url)
        return setmetatable({ url = url }, self)
    end

    ---[SERVER] Load CMesh to clients
    ---@return number id
    function CMesh:load()
        local id = #model.mesh+1
        model.mesh[id] = self
        self.id = id
        net.start("CustomMeshLoad")
            net.writeTable({self})
        net.send(find.allPlayers())
        return id
    end

    hook.add("ClientInitialized", "CustomMeshLoad", function(ply)
        net.start("CustomMeshLoad")
            net.writeTable(table.add({}, model.mesh))
        net.send(ply)
    end)
else
    net.receive("CustomMeshLoad", function()
        local info = net.readTable()
        for _, msh in ipairs(info) do
            model.mesh[msh.id] = msh
        end
    end)
end


---@class Bone
---@field parent string
---@field bone modelfun

---@class ModelInfo
---@field origin Vector()
---@field bones table<string, Bone>
local ModelInfo = {}
ModelInfo.__index = ModelInfo

---[SHARED] Sets rig visibility on creation. Call before rig()
---@param state boolean
function model.setRigVisible(state)
    model.rigVisible = state
end


local rigScale = Vector(0.2, 0.2, 0.2)
---[SHARED] Create rig hologram (invisible with static model)
---@param pos Vector? Position offset. Default `Vector(0, 0, 0)`
---@param ang Angle? Angle offset. Default `Angle(0, 0, 0)`
---@return modelfun
function model.rig(pos, ang)
    pos = pos or Vector()
    ang = ang or Angle()
    return function()
        local holo = hologram.create(pos, ang, "models/editor/axis_helper_thick.mdl", rigScale)
        if !holo then return end
        holo:suppressEngineLighting(true)
        holo:setNoDraw(!model.rigVisible)
        return holo
    end
end

---[SHARED] Create new model info
---@param origin Vector|modelfun? Origin of this entity
---@return ModelInfo
function model.create(origin)
    local rig = isfunction(origin) and origin or model.rig(origin)
    return setmetatable(
        { origin = rig, bones = {} },
        ModelInfo
    )
end


---[SHARED] Add new bone to model
---@param parent string Identifier of bone to parent
---@param bone string|modelfun Identifier of bone
---@param mdl modelfun? Function to create model
---@return ModelInfo
function ModelInfo:add(parent, bone, mdl)
    local outName
    local outModel
    local outParent
    if !mdl then
        outName = parent
        outModel = bone
    else
        outParent = parent
        outName = bone
        outModel = mdl
    end
    self.bones[outName] = {
        parent = outParent,
        bone = outModel
    }
    return self
end


---@class HoloParameters
---@field pos Vector?
---@field ang Angle?
---@field model string?
---@field scale Vector?
---@field size Vector?
---@field submaterial number?
---@field material string?
---@field color Color?
---@field light boolean?

---@alias VertexType
---| '"cube"'
---| '"custom"'
local VertexType = {
    ["cube"] = {
        Vector(1, 1, 1), Vector(1, -1, 1), Vector(-1, -1, 1), Vector(-1, 1, 1),
        Vector(1, 1, -1), Vector(1, -1, -1), Vector(-1, -1, -1), Vector(-1, 1, -1)
    }
}

---@class VertexParameters
---@field type VertexType?
---@field offset Vector?
---@field angle Angle?
---@field scale Vector?
---@field vertices Vector[]?

local rotMat = {
    x = function(a)
        return {
            Vector(1, 0, 0),
            Vector(0, math.cos(a), -math.sin(a)),
            Vector(0, math.sin(a), math.cos(a)),
        }
    end,
    y = function(a)
        return {
            Vector(math.cos(a), 0, math.sin(a)),
            Vector(0, 1, 0),
            Vector(-math.sin(a), 0, math.cos(a)),
        }
    end,
    z = function(a)
        return {
            Vector(math.cos(a), -math.sin(a), 0),
            Vector(math.sin(a), math.cos(a), 0),
            Vector(0, 0, 1),
        }
    end
}

---[SHARED] Create new vertex
---@param tbl VertexParameters
---@return Vector[]
function model.vertex(tbl)
    local type = tbl.type or tbl[1] or "custom"
    local offset = tbl.offset or tbl[2] or Vector()
    local angle = tbl.angle or tbl[3] or Angle()
    local scale = tbl.scale or tbl[4] or Vector(1, 1, 1)
    local byType = VertexType[type]
    local vertices = byType and table.copy(byType) or tbl.vertices or tbl[5]
    local mats = {
        x = rotMat.x(math.rad(angle.p)),
        y = rotMat.y(math.rad(angle.y)),
        z = rotMat.z(math.rad(angle.r)),
    }
    for vId, v in ipairs(vertices) do
        local pos = v * scale
        local pZ = Vector(mats.z[1]:dot(pos), mats.z[2]:dot(pos), mats.z[3]:dot(pos))
        local pY = Vector(mats.y[1]:dot(pZ), mats.y[2]:dot(pZ), mats.y[3]:dot(pZ))
        local pX = Vector(mats.x[1]:dot(pY), mats.x[2]:dot(pY), mats.x[3]:dot(pY))
        vertices[vId] = pX + offset
    end
    return vertices
end


---@class HitboxParameters
---@field freeze boolean?
---@field mass number?
---@field material string?
---@field visible boolean?


---[SHARED] Create new vertex
---@param tbl HitboxParameters
---@return modelfun
function model.hitbox(tbl)
    local freeze = tbl.freeze or (isbool(tbl[1]) and tbl[1]) or false
    local mass = tbl.mass or (isnumber(tbl[2]) and tbl[2]) or 30
    local mat = tbl.material or (isstring(tbl[3]) and tbl[3]) or ""
    local visible = tbl.visible or (isbool(tbl[4] and tbl[4])) or false
    local vertexes = {}
    for i, v in ipairs(tbl) do
        vertexes[i] = v
    end
    return function()
        local pr = prop.createCustom(Vector(), Angle(), vertexes, true)
        local phys = pr:getPhysicsObject()
        pr:setFrozen(freeze)
        pr:setNoDraw(!visible)
        timer.simple(0, function()
            if !isValid(phys) then return end
            phys:setMass(mass)
            phys:setMaterial(mat)
        end)
        return pr
    end
end


---[SHARED] Create new part - sequence of holos, parented to first in sequence
---@param tbl modelfun[]
---@return modelfun
function model.part(tbl)
    return function()
        local parent
        for _, fn in ipairs(tbl) do
            if !parent then
                parent = fn()
                goto cont
            end
            fn():setParent(parent)
            ::cont::
        end
        return parent
    end
end


---[SHARED] Create hologram with extended parameters
---@param tbl HoloParameters
---@return modelfun
function model.holo(tbl)
    local pos = tbl.pos or tbl[1] or Vector()
    local ang = tbl.ang or tbl[2] or Angle()
    local mdl = tbl.model or tbl[3] or "models/holograms/cube.mdl"
    local scale = tbl.scale or tbl[4]
    local size = tbl.size or tbl[5]
    local submat = tbl.submaterial or tbl[6] or 0
    local mat = tbl.material or tbl[7]
    local color = tbl.color or tbl[8] or Color(255, 255, 255, 255)
    local suppressLight = !(tbl.light or tbl[9] or true)
    return function()
        local holo = hologram.create(pos, ang, mdl, scale)
        if !holo then return end
        holo:suppressEngineLighting(suppressLight)
        if size then holo:setSize(size) end
        if mat then holo:setSubMaterial(submat, mat) end
        holo:setColor(color)
        return holo
    end
end


---@class Model
---@field bones table<string, Entity>
local Model = {}
Model.__index = Model


---@return Model?
function ModelInfo:create()
    local mdl = setmetatable({ bones = {} }, Model)
    local originHolo = self.origin()
    if !originHolo then
        throw("Can't create origin")
        return
    end
    mdl.bones.origin = originHolo
    for name, part in pairs(self.bones) do
        local holo = part.bone()
        if !holo then
            throw("Can't create bone " .. name)
            return
        end
        mdl.bones[name] = holo
        local parent = part.parent
        local parentHolo = mdl.bones[parent] or !parent and originHolo
        if !parentHolo then
            throw(string.format("Parent \"%s\" for \"%s\" not found! Maybe you placed it in incorrect sequence?", parent, name))
            return
        end
        holo:setParent(parentHolo)
    end
    return mdl
end


---[SHARED] Register new model to use it after
---@param identifier string Identifier of the model
---@param info ModelInfo Info
function model.register(identifier, info)
    model.registered[identifier] = info
end

---[SHARED] Get model info
---@param identifier string Identifier of the model
---@return ModelInfo
function model.get(identifier)
    return model.registered[identifier]
end

return model
