---@name Model
---@author AstricUnion


---@class ToNetwork
---@field holo Hologram
---@field meshId string?
---@field meshPart string?
---@field materialId string?

---Class to manipulate hologram models with custom meshes and hitboxes
---@class model
---@field registered table<string, ModelInfo>
---@field toNetwork ToNetwork[]
---@field networked ToNetwork[]
---@field mesh table<number, CMesh>
local model = {}
model.registered = {}
model.mesh = {}
model.toNetwork = {}
model.networked = {}
model.rigVisible = false

---@alias modelfun fun(): (Entity?)

---@class MeshPretend
---@field holo Hologram
---@field part string

---Class to create custom mesh for holograms
---@class CMesh
---@field id string
---@field url string? [SERVER] URL of custom mesh to load
---@field data string? [CLIENT] OBJ data of custom mesh
---@field download boolean [CLIENT] Is mesh downloads
---@field mesh Mesh? [CLIENT] Loaded mesh
---@field pretendsToIt MeshPretend[] [CLIENT] Holograms, that pretends to this mesh, when it not loaded
local CMesh = {}
CMesh.__index = CMesh

if SERVER then
    ---[SERVER] Create new custom mesh
    ---@param id string
    ---@param url string URL or file path to mesh
    ---@return CMesh
    function CMesh:new(id, url)
        return setmetatable({ id = id, url = url }, self)
    end

    ---[SERVER] Load CMesh to clients
    function CMesh:load()
        model.mesh[self.id] = self
        net.start("CustomMeshLoad")
            net.writeTable({self})
        net.send(find.allPlayers())
    end
    ---[SERVER] Create new shared mesh (will be initialized on server and sent to clients)
    ---@param id string
    ---@param url string URL or file path to mesh
    ---@return CMesh
    function model.newMesh(id, url)
        return CMesh:new(id, url)
    end

    ---[SERVER] Sync holograms to clients
    ---@param ply Player? Player to send
    function model.sync(ply)
        net.start("NetworkHolograms")
            net.writeTable(model.toNetwork)
        net.send(ply or find.allPlayers())
    end

    hook.add("ClientInitialized", "InitializeHologramsAndCustom", function(ply)
        local meshes = table.add({}, model.mesh)
        net.start("CustomMeshLoad")
            net.writeTable(meshes)
        net.send(ply)
        model.sync(ply)
    end)
else
    local meshLoadCoroutine = coroutine.wrap(function()
        while true do
            coroutine.yield()
            for _, v in pairs(model.mesh) do
                if v.mesh then goto cont end
                if !v.data then
                    if !v.download then
                        http.get(v.url, function(data)
                            v.data = data
                            v.download = false
                        end)
                    end
                    v.download = true
                    goto cont
                end
                v.mesh = mesh.createFromObj(v.data, true)
                for _, pretendent in ipairs(v.pretendsToIt) do
                    pretendent.holo:setMesh(v.mesh[pretendent.part])
                end
                v.pretendsToIt = {}
                ::cont::
            end
        end
    end)

    net.receive("CustomMeshLoad", function()
        local info = net.readTable()
        for _, msh in ipairs(info) do
            msh.pretendsToIt = {}
            model.mesh[msh.id] = setmetatable(msh, CMesh)
        end
    end)

    local getNetworkedHolograms = coroutine.wrap(function()
        while true do
            coroutine.yield()
            for _, v in ipairs(model.networked) do
                if !isValid(v.holo) then goto cont end
                local msh = model.mesh[v.meshId]
                if !msh then goto cont end
                ---@cast msh CMesh
                msh:setTo(v.holo, v.meshPart)
                ::cont::
            end
        end
    end)

    net.receive("NetworkHolograms", function()
        model.networked = net.readTable()
    end)

    hook.add("Think", "CustomMeshLoad", function()
        for _=1, 3 do
            meshLoadCoroutine()
        end
        getNetworkedHolograms()
    end)

    ---[CLIENT] Set this mesh to hologram
    ---@param holo Hologram Hologram to set
    ---@param part string Part to set (mesh table key)
    function CMesh:setTo(holo, part)
        if self.mesh then
            holo:setMesh(self.mesh[part])
            return
        end
        self.pretendsToIt[#self.pretendsToIt+1] = {holo = holo, part = part}
    end
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
        timer.simple(0, function()
            if !isValid(phys) then return end
            phys:setMass(mass)
            phys:setMaterial(mat)
            pr:setNoDraw(!visible)
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

---@class HoloParameters
---@field pos Vector?
---@field ang Angle?
---@field model string?
---@field scale Vector?
---@field size Vector?
---@field submaterial number?
---@field material string?
---@field color Color?
---@field noLight boolean?
---@field mesh string?
---@field meshPart string?
---@field materialId string?

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
    local noLight = tbl.noLight or tbl[9] or false
    local meshId = tbl.mesh or tbl[10]
    local meshPart = tbl.meshPart or tbl[11]
    local materialId = tbl.materialId or tbl[12]
    return function()
        local holo = hologram.create(pos, ang, mdl, scale)
        if !holo then return end
        holo:suppressEngineLighting(noLight)
        if size then holo:setSize(size) end
        if mat then holo:setSubMaterial(submat, mat) end
        holo:setColor(color)
        model.toNetwork[#model.toNetwork+1] = {
            holo = holo,
            meshId = meshId,
            meshPart = meshPart,
            materialId = materialId
        }
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
    model.sync()
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
