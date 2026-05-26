---@name Model
---@author AstricUnion


---@class ToNetwork
---@field modelId string Identifier of model
---@field originId number Entity index of origin of model to parent (from server)

---Class to manipulate hologram models with custom meshes and hitboxes
---@class model
---@field registered table<string, ModelInfo>
---@field mesh table<string, CMesh>
---@field toNetwork ToNetwork[]
---@field networked ToNetwork[]
---@field materials table<string, Material>
local model = {}
model.registered = {}
model.mesh = {}
model.materials = {}
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
---@field mesh Mesh? [CLIENT] Loaded mesh
---@field material string [CLIENT] Material to set
---@field pretendsToIt MeshPretend[] [CLIENT] Holograms, that pretends to this mesh, when it not loaded
local CMesh = {}
CMesh.__index = CMesh

---Override methods of entity to work with models
---@param ent Entity
local function methodsOverride(ent)
    -- I can use ent, not self, because this is method only for this entity
    ent.__setNoDrawOld = ent.__setNoDrawOld or ent.setNoDraw

    function ent:setNoDraw(state)
        for _, v in ipairs(ent:getChildren()) do
            v:setNoDraw(state)
        end
    end


    if SERVER then
    else
        ent.__drawOld = ent.__drawOld or ent.draw

        function ent:draw(noTint)
            for _, v in ipairs(ent:getChildren()) do
                v:draw(noTint)
            end
        end
    end
end

if SERVER then
    ---[SERVER] Sync holograms to clients
    ---@param ply Player? Player to send
    function model.sync(ply)
        if next(model.toNetwork) == nil then return end
        local newToNetwork = {}
        for _, v in ipairs(model.toNetwork) do
            if !isValid(entity(v.originId)) then goto cont end
            newToNetwork[#newToNetwork+1] = v
            ::cont::
        end
        model.toNetwork = newToNetwork
        net.start("NetworkModels")
            net.writeTable(model.toNetwork)
        net.send(ply or find.allPlayers())
    end

    hook.add("ClientInitialized", "InitializeModels", function(ply)
        if table.isEmpty(model.toNetwork) then return end
        model.sync(ply)
    end)
else
    ---[CLIENT] Set material ID to set for all parts of this mesh
    ---@param id string Identifier of material
    function CMesh:setMaterial(id)
        self.material = id
    end

    ---[CLIENT] Load CMesh
    function CMesh:load()
        model.mesh[self.id] = self
        http.get(self.url, function(data)
            self.data = data
        end)
    end

    ---[CLIENT] Create new mesh
    ---@param id string
    ---@param url string URL or file path to mesh
    ---@return CMesh
    function model.newMesh(id, url)
        return setmetatable({ id = id, pretendsToIt = {}, url = url }, CMesh)
    end

    local meshLoadCoroutine = coroutine.wrap(function()
        while true do
            coroutine.yield()
            for _, v in pairs(model.mesh) do
                if v.mesh then goto cont end
                if !v.data then goto cont end
                v.mesh = mesh.createFromObj(v.data, true)
                for _, pretendent in ipairs(v.pretendsToIt) do
                    if !isValid(pretendent.holo) then goto cont end
                    v:setTo(pretendent.holo, pretendent.part)
                    ::cont::
                end
                v.pretendsToIt = {}
                ::cont::
            end
        end
    end)

    local getNetworkedModels = coroutine.wrap(function()
        while true do
            coroutine.yield()
            local newNetworked = {}
            for _, v in ipairs(model.networked) do
                local addedId = #newNetworked+1
                newNetworked[addedId] = v
                local ent = entity(v.originId)
                if !isValid(ent) then goto cont end
                local mdl = model.registered[v.modelId]
                if ent then
                    mdl:create(ent)
                end
                methodsOverride(ent)
                newNetworked[addedId] = nil
                ::cont::
            end
            model.networked = newNetworked
        end
    end)

    hook.add("EntityRemoved", "ModelRemove", function(ent, fullupdate)
        if isValid(ent) and ent.bones then
            for _, v in pairs(ent.bones) do
                if !isValid(ent) or v == ent then goto cont end
                v:remove()
                ::cont::
            end
        end
    end)

    net.receive("NetworkModels", function()
        model.networked = net.readTable()
    end)

    hook.add("Think", "CustomMeshLoad", function()
        local maxQuota = quotaMax() / 4
        local currentQuota = quotaAverage()
        if currentQuota > maxQuota then return end
        for _=1, math.floor(maxQuota / currentQuota) do
            meshLoadCoroutine()
        end
        getNetworkedModels()
    end)

    ---[CLIENT] Set this mesh to hologram
    ---@param holo Hologram Hologram to set
    ---@param part string Part to set (mesh table key)
    function CMesh:setTo(holo, part)
        if self.mesh then
            holo:setMesh(self.mesh[part])
            local mat = model.materials[self.material]
            if mat then
                holo:setMeshMaterial(mat)
            end
            return
        end
        self.pretendsToIt[#self.pretendsToIt+1] = {holo = holo, part = part}
    end

    ---@alias MaterialShader
    ---| '"UnlitGeneric"'"
    ---| '"VertexLitGeneric"'"
    ---| '"Refract_DX90"'"
    ---| '"Water_DX90"'"
    ---| '"Sky_DX9"'
    ---| '"gmodscreenspace"'
    ---| '"Modulate_DX9"'

    ---[CLIENT] Create new custom material
    ---@param id string
    ---@param shader MaterialShader
    ---@return Material
    function model.newMaterial(id, shader)
        local mat = material.create(shader)
        model.materials[id] = mat
        return mat
    end
end


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


-- TODO: i can set mesh for custom prop. maybe can make less holos
---[SHARED] Create new vertex
---@param tbl HitboxParameters
---@return modelfun
function model.hitbox(tbl)
    if CLIENT then return model.rig(Vector()) end
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
        local toRemove = {}
        for _, fn in ipairs(tbl) do
            if !parent then
                parent = fn()
                goto cont
            end
            local holo = fn()
            if !holo then goto cont end
            holo:setParent(parent)
            toRemove[#toRemove+1] = holo
            ::cont::
        end
        if CLIENT then
            parent.__removeOld = parent.__removeOld or parent.remove
            function parent:remove()
                self:__removeOld()
                for _, v in ipairs(toRemove) do
                    v:remove()
                end
            end
        end
        return parent
    end
end

---@class Clip
---@field [1] Vector Offset of clip, relative to entity
---@field [2] Vector Normal of clip, relative to entity

---@class HoloParameters
---@field pos Vector? Position offset to spawn this holo. Relative to model
---@field ang Angle? Angle offset to spawn this holo. Relative to model
---@field model string? Model of this holo
---@field scale Vector? Scale of this holo
---@field size Vector? Hologram size. Scale multiplies start size of holo, when size sets... size :D
---@field submaterial number? Submaterial append holo to
---@field material string|table? Material to set. Can be identifier for custom material, or material file, or table of submaterials
---@field color Color? Color of holo
---@field noLight boolean? Suppress engine lighting for holo
---@field mesh string? Mesh for holo
---@field meshPart string? Mesh part. You can found this lines in obj file: `o name_of_part`
---@field clips Clip[]? Clips of holo

local emptyFunction = function() end

---[SHARED] Create hologram with extended parameters. On server does nothing
---@param tbl HoloParameters
---@return modelfun
function model.holo(tbl)
    local pos = tbl.pos or tbl[1] or Vector()
    local ang = tbl.ang or tbl[2] or Angle()
    local mdl = tbl.model or tbl[3] or "models/holograms/cube.mdl"
    local scale = tbl.scale or tbl[4]
    local size = tbl.size or tbl[5]
    local submat = tbl.submaterial or tbl[6] or 0
    local matName = tbl.material or tbl[7]
    local color = tbl.color or tbl[8] or Color(255, 255, 255, 255)
    local noLight = tbl.noLight or tbl[9] or false
    local meshId = tbl.mesh or tbl[10]
    local meshPart = tbl.meshPart or tbl[11]
    local clips = tbl.clips or tbl[12] or {}
    local funcToMat = emptyFunction
    if matName then
        local function setMaterial(holo, index, funcMatName)
            local mat = model.materials[funcMatName]
            local matToSet = mat and "!" .. mat:getName() or funcMatName
            -- Submaterial fixes bug with client material reset
            holo:setSubMaterial(index, matToSet)
        end
        if isstring(matName) then
            funcToMat = function(holo) setMaterial(holo, 0, matName) end
        elseif istable(matName) then
            funcToMat = function(holo)
                ---@cast matName table<number, string>
                for index, v in pairs(matName) do
                    setMaterial(holo, index, v)
                end
            end
        end
    end
    return function()
        local holo = hologram.create(pos, ang, mdl, scale)
        if !holo then return end
        holo:suppressEngineLighting(noLight)
        if size then holo:setSize(size) end
        funcToMat(holo)
        holo:setColor(color)
        for i, v in ipairs(clips) do
            holo:setClip(i, true, v[1], v[2], holo)
        end
        if CLIENT then
            local msh = model.mesh[meshId]
            if msh then msh:setTo(holo, meshPart) end
        end
        return holo
    end
end



---@class Bone
---@field parent string
---@field bone modelfun

---@class ModelInfo
---@field origin fun()
---@field bones table<string, Bone>
---@field identifier string
local ModelInfo = {}
ModelInfo.__index = ModelInfo


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


---@param origin Entity? Origin to parent
---@return Entity?
function ModelInfo:create(origin)
    local originHolo = origin or self.origin()
    if !originHolo or !isValid(originHolo) then
        throw("Can't create origin")
        return
    end
    if SERVER then
        model.toNetwork[#model.toNetwork+1] = {
            modelId = self.identifier,
            originId = originHolo:entIndex()
        }
        model.sync()
        return originHolo
    end
    ---@type table<string, Entity>
    local bones = {}
    bones.origin = originHolo
    for name, part in pairs(self.bones) do
        local holo = part.bone()
        if !holo then
            throw("Can't create bone " .. name)
            return
        end
        bones[name] = holo
        local parent = part.parent
        local parentHolo = bones[parent] or !parent and originHolo
        if !parentHolo then
            throw(string.format("Parent \"%s\" for \"%s\" not found! Maybe you placed it in incorrect sequence?", parent, name))
            return
        end
        holo:setPos(parentHolo:localToWorld(holo:getPos()))
        holo:setAngles(parentHolo:localToWorldAngles(holo:getAngles()))
        holo:setParent(parentHolo)
    end
    originHolo.bones = bones
    methodsOverride(originHolo)
    return originHolo
end


---[SHARED] Create new model info
---@param identifier string Identifier of model
---@param origin Vector|modelfun Origin of this entity
---@return ModelInfo
function model.new(identifier, origin)
    local rig = isfunction(origin) and origin or model.rig(origin)
    local obj = setmetatable(
        { origin = rig, bones = {}, identifier = identifier },
        ModelInfo
    )
    model.registered[identifier] = obj
    return obj
end

---[SHARED] Create model by registered model info
---@param identifier string Identifier of the model
---@return Entity?
function model.create(identifier)
    local mdl = model.registered[identifier]
    return mdl:create()
end


return model
