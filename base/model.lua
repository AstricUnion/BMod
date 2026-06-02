---@name Model
---@author AstricUnion


---@class ToNetwork
---@field modelId string Identifier of model
---@field params table[] Parameters to set (functions to call)

---Class to manipulate hologram models with custom meshes and hitboxes
---@class model
---@field registered table<string, ModelInfo>
---@field inited table<number, ModelEntity>
---@field mesh table<string, CMesh> Hashmap with mesh to get
---@field meshToLoad CMesh[] List with mesh to load
---@field toNetwork table<number, ToNetwork>
---@field networked table<number, ToNetwork>
---@field materials table<string, Material>
local model = {}
model.registered = {}
model.inited = {}
model.mesh = {}
model.meshToLoad = {}
model.materials = {}
model.toNetwork = {}
model.networked = {}
model.rigVisible = false

---@alias modelfun fun(): (Entity?)

---Override methods of entity to work with models
---@param ent Entity
---@return ModelEntity
local function methodsOverride(ent)
    ---@class ModelEntity
    local ent = ent
    -- I can use ent, not self, because this is method only for this entity
    ent.__setNoDrawOld = ent.__setNoDrawOld or ent.setNoDraw
    function ent:setNoDraw(state)
        ent.noDraw = state
        for _, v in pairs(ent:getChildren()) do
            v:setNoDraw(state)
        end
    end

    ent.__getNoDrawOld = ent.__getNoDrawOld or ent.getNoDraw
    function ent:getNoDraw()
        return ent.noDraw
    end

    ent.__setCullModeOld = ent.__setCullModeOld or ent.setCullMode
    function ent:setCullMode(state)
        for _, v in pairs(ent:getChildren()) do
            v:setCullMode(state)
        end
    end

    ent.__lookupBoneOld = ent.__lookupBoneOld or ent.lookupBone
    ---[SHARED] Lookup for bone in entity
    ---@param name string Name of the bone
    ---@return number? id
    function ent:lookupBone(name)
        return ent.modelInfo.bonesIDs[name]
    end

    ent.__lookupSequenceOld = ent.__lookupSequenceOld or ent.lookupSequence
    ---[SHARED] Lookup for sequence in entity
    ---@param name string Name of the sequence
    ---@return number? id
    function ent:lookupSequence(name)
        return ent.modelInfo.sequencesIDs[name]
    end

    ent.__getSequenceOld = ent.__getSequenceOld or ent.getSequence
    ---[SHARED] Returns current entity sequence
    ---@return number id
    function ent:getSequence()
        return ent.sequence or 0
    end

    local function recursiveFun(origin, fun, ...)
        for _, v in pairs(origin:getChildren()) do
            if isfunction(fun) then
                fun(v, ...)
            else
                if v[fun] then v[fun](v, ...) end
            end
            recursiveFun(v, fun, ...)
        end
    end

    local entId = ent:entIndex()
    local networking = false
    local function sendFunction(func, ...)
        if !SERVER or !ent.modelBones then return end
        local args = {...}
        local toNetwork = model.toNetwork[entId]
        if !toNetwork then return end
        toNetwork.params[#toNetwork.params+1] = {func, args}
        if networking then return end
        networking = true
        timer.simple(0, function()
            if !isValid(ent) then return end
            net.start("ModelCallFunctions")
                net.writeTable(toNetwork.params)
                net.writeEntity(ent)
            net.send(find.allPlayers())
            networking = false
        end)
    end

    ent.__setSequenceOld = ent.__setSequenceOld or ent.setSequence
    ---[SHARED] Set sequence for this entity
    ---@param id number Sequence ID
    function ent:setSequence(id)
        sendFunction("setSequence", id)
        if CLIENT then
            local seq = ent.modelInfo.sequences[id]
            if !seq then return end
            ent.sequence = id
            seq.startFun(ent)
            if seq.duration <= 0 then return end
            ent.sequenceStart = timer.curtime()
        end
    end

    ent.__setSubMaterialOld = ent.__setSubMaterialOld or ent.setSubMaterial
    ---[SHARED] Set submaterial for this model
    ---@param index number Submaterial index. 0 is default for all
    ---@param mat string Material to set
    function ent:setSubMaterial(index, mat)
        sendFunction("setSubMaterial", index, mat)
        recursiveFun(ent, index ~= -1 and function(holo)
            if holo.modelSubmaterial == index then
                holo:setSubMaterial(0, mat)
            end
        end)
    end

    ent.__setMaterialOld = ent.__setMaterialOld or ent.setMaterial
    ---[SHARED] Set main material for this model
    ---@param mat string Material to set
    function ent:setMaterial(mat)
        sendFunction("setMaterial", mat)
        recursiveFun(ent, "setSubMaterial", 0, mat)
    end

    ---[SHARED] Set subcolor for this model
    ---@param index number Color index. 0 is default for all
    ---@param col Color Color to set
    function ent:setSubColor(index, col)
        sendFunction("setSubColor", index, col)
        recursiveFun(ent, function(holo)
            if holo.modelSubcolor == index then
                holo:setColor(col)
            end
        end)
    end

    ent.__setColorOld = ent.__setColorOld or ent.setColor
    ---[SHARED] Set color for this model
    ---@param col Color Color to set
    function ent:setColor(col)
        sendFunction("setColor", col)
        recursiveFun(ent, "setColor", col)
    end

    if CLIENT then
        ent.__drawOld = ent.__drawOld or ent.draw
        function ent:draw(noTint)
            recursiveFun(ent, "draw", noTint)
        end

        ---[CLIENT] Get entity of the bone
        ---@param id number Index of the bone
        ---@return Entity?
        function ent:getBoneEntity(id)
            return ent.modelBones[id]
        end
    end

    return ent
end

if SERVER then
    local networking = false

    ---[SERVER] Sync holograms to clients
    ---@param ply Player? Player to send. False to prevent send (to clear toNetwork)
    function model.sync(ply)
        local newToNetwork = {}
        for id, toNetworkInfo in pairs(model.toNetwork) do
            local origin = entity(id)
            if !isValid(origin) then goto cont end
            newToNetwork[id] = toNetworkInfo
            ::cont::
        end
        model.toNetwork = newToNetwork
        if networking then return end
        networking = true
        timer.simple(0, function()
            if ply and !isValid(ply) then return end
            net.start("NetworkModels")
                net.writeTable(model.toNetwork)
            net.send(ply or find.allPlayers())
            networking = false
        end)
    end

    hook.add("ClientInitialized", "InitializeModels", function(ply)
        if table.isEmpty(model.toNetwork) then return end
        model.sync(ply)
    end)
else
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


    ---[CLIENT] Set material ID to set for all parts of this mesh
    ---@param id string Identifier of material
    function CMesh:setMaterial(id)
        self.material = id
    end

    ---[CLIENT] Load CMesh
    function CMesh:load()
        model.mesh[self.id] = self
        model.meshToLoad[#model.meshToLoad+1] = self
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
            local newToLoad = {}
            for _, v in ipairs(model.meshToLoad) do
                do
                    if v.mesh then goto cont end
                    if !v.data then goto cont end
                    v.mesh = mesh.createFromObj(v.data, true)
                    for _, pretendent in ipairs(v.pretendsToIt) do
                        if !isValid(pretendent.holo) then goto cont end
                        v:setTo(pretendent.holo, pretendent.part)
                        ::cont::
                    end
                    v.pretendsToIt = {}
                    goto cont1
                end
                ::cont::
                newToLoad[#newToLoad+1] = v
                ::cont1::
            end
            model.meshToLoad = newToLoad
        end
    end)

    net.receive("NetworkModels", function()
        model.networked = net.readTable()
    end)

    local function getNetworkedModels()
        for id, toNetworkInfo in pairs(model.networked) do
            local ent = entity(id)
            if !isValid(ent) then goto cont end
            if ent.modelBones then
                model.networked[id] = nil
                return
            end
            local mdl = model.registered[toNetworkInfo.modelId]
            if !mdl then goto cont end
            mdl:create(ent)
            methodsOverride(ent)
            for _, funcTable in ipairs(toNetworkInfo.params) do
                ent[funcTable[1]](ent, unpack(funcTable[2]))
            end
            model.networked[id] = nil
            ::cont::
        end
    end

    hook.add("Think", "CustomMeshLoad", function()
        if next(model.meshToLoad) ~= nil then
            local maxQuota = quotaMax() / 4
            local currentQuota = quotaAverage()
            if currentQuota > maxQuota then return end
            for _=1, math.floor(maxQuota / currentQuota) do
                meshLoadCoroutine()
            end
        end
        if !table.isEmpty(model.networked) then
            getNetworkedModels()
        end
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

    hook.add("RenderOffscreen", "ModelSequences", function()
        local cur = timer.curtime()
        for _, v in pairs(model.inited) do
            if !isValid(v) then goto cont end
            if v.sequenceStart then
                local process = cur - v.sequenceStart
                local seq = v.modelInfo.sequences[v.sequence]
                if process > seq.duration then
                    seq.endFun(v)
                    v.sequenceStart = nil
                    goto cont
                end
                seq.processFun(v, process)
            end
            ::cont::
        end
    end)

    net.receive("ModelCallFunctions", function()
        local funcs = net.readTable()
        net.readEntity(function(ent)
            if !model.inited[ent:entIndex()] then return end
            for _, funcTable in ipairs(funcs) do
                ent[funcTable[1]](ent, unpack(funcTable[2]))
            end
        end)
    end)
end

local function recursiveRemove(ent)
    if !isValid(ent) then return end
    for _, v in pairs(ent:getChildren()) do
        recursiveRemove(v)
    end
    ent:remove()
end

hook.add("EntityRemoved", "ModelRemove", function(ent, fullupdate)
    if CLIENT then
        if isValid(ent) and ent.modelBones then
            for _, v in ipairs(ent.modelBones) do
                if !isValid(v) then goto cont end
                recursiveRemove(v)
                ::cont::
            end
            model.networked[ent:entIndex()] = nil
        end
    else
        model.toNetwork[ent:entIndex()] = nil
    end
end)


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
        if !hologram.canSpawn() then return end
        local holo = hologram.create(pos, ang, "models/editor/axis_helper_thick.mdl", rigScale)
        if !holo then return end
        holo:suppressEngineLighting(true)
        holo:setNoDraw(!model.rigVisible)
        return holo
    end
end

local cylinder = {}

local polygons = 32
for i=1,polygons do
    local ang = math.rad((360 / polygons) * i)
    local x = math.cos(ang)
    local y = math.sin(ang)
    cylinder[#cylinder+1] = Vector(x, y, 1)
    cylinder[#cylinder+1] = Vector(x, y, -1)
end

---@alias VertexType
---| '"cube"'
---| '"custom"'
---| '"wedge"'
---| '"cylinder"'
local VertexType = {
    ["cube"] = {
        Vector(1, 1, 1), Vector(1, -1, 1), Vector(-1, -1, 1), Vector(-1, 1, 1),
        Vector(1, 1, -1), Vector(1, -1, -1), Vector(-1, -1, -1), Vector(-1, 1, -1)
    },
    ["wedge"] = {
        Vector(1, -1, -1), Vector(1, 1, -1),
        Vector(-1, 1, -1), Vector(-1, -1, -1),
        Vector(-1, 1, 1), Vector(-1, -1, 1),
    },
    ["cylinder"] = cylinder
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
---@field buoyancyRatio number?


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
    local buoyancyRatio = tbl.buoyancyRatio or (isnumber(tbl[5]) and tbl[5]) or 0
    local vertexes = {}
    for i, v in ipairs(tbl) do
        vertexes[i] = v
    end
    return function()
        local pr = prop.createCustom(Vector(), Angle(), vertexes, true)
        local phys = pr:getPhysicsObject()
        pr:setFrozen(freeze)
        pr:setNoDraw(!visible)
        pr.buoyancyRatio = buoyancyRatio
        timer.simple(0, function()
            if !isValid(phys) then return end
            phys:setMass(mass)
            phys:setMaterial(mat)
            phys:setBuoyancyRatio(buoyancyRatio)
        end)
        return pr
    end
end

if SERVER then
    local function setBuoyancy(ent)
        local phys = ent:getPhysicsObject()
        if !isValid(phys) then return end
        phys:setBuoyancyRatio(ent.buoyancyRatio)
    end

    hook.add("OnEntityWaterLevelChanged", "HitboxSetBuoyancyInWater", function(ent, old, new)
        if new > 0 and ent.buoyancyRatio then
            setBuoyancy(ent)
        end
    end)

    hook.add("PhysgunDrop", "HitboxSetBuoyancyInWater", function(ply, ent)
        if !ent.buoyancyRatio then return end
        timer.simple(0, function()
            if !isValid(ent) then return end
            if ent:getWaterLevel() > 0 then
                setBuoyancy(ent)
            end
        end)
    end)
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
        if CLIENT and parent then
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
---@field submaterial number? Submaterial append holo to. By default 0 (WIP, not working)
---@field subcolor number? Subcolor append holo to. By default 0. (WIP, not working)
---@field material string|table? Material to set. Can be identifier for custom material, or material file, or table of submaterials
---@field color Color? Color of holo
---@field noLight boolean? Suppress engine lighting for holo
---@field mesh string? Mesh for holo
---@field meshPart string? Mesh part. You can found this lines in obj file: `o name_of_part`
---@field clips Clip[]? Clips of holo
---@field cullmode number? Cull mode of holo

local emptyFunction = function() end

---[SHARED] Create hologram with extended parameters. On server does nothing
---@param tbl HoloParameters
---@return modelfun
function model.holo(tbl)
    local pos = tbl.pos or tbl[1] or Vector()
    local ang = tbl.ang or tbl[2] or Angle()
    local mdl = tbl.model or tbl[3] or "models/holograms/cube.mdl"
    local scale = tbl.scale or tbl[4] or Vector(1, 1, 1)
    local size = tbl.size or tbl[5]
    local submat = tbl.submaterial or tbl[6] or 0
    local subcol = tbl.subcolor or tbl[7] or 0
    local matName = tbl.material or tbl[8]
    local color = tbl.color or tbl[9] or Color(255, 255, 255, 255)
    local noLight = tbl.noLight or tbl[10] or false
    local meshId = tbl.mesh or tbl[11]
    local meshPart = tbl.meshPart or tbl[12]
    local clips = tbl.clips or tbl[13] or {}
    local cullmode = tbl.cullmode or tbl[14] or 0
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
        if !hologram.canSpawn() then return end
        local holo = hologram.create(pos, ang, mdl, scale)
        if !holo then return end
        holo:suppressEngineLighting(noLight)
        holo:setCullMode(cullmode)
        if size then holo:setSize(size) end
        funcToMat(holo)
        holo:setColor(color)
        for i, v in ipairs(clips) do
            holo:setClip(i, true, size and v[1] + size or v[1] * scale, v[2], holo)
        end
        if CLIENT then
            local msh = model.mesh[meshId]
            if msh then msh:setTo(holo, meshPart) end
        end
        holo.modelSubcolor = subcol
        holo.modelSubmaterial = submaterial
        return holo
    end
end



---@class Bone
---@field parent string
---@field bone modelfun
---@field name string

---@class ModelSequence
---@field name string
---@field startFun fun(ent: ModelEntity)
---@field processFun fun(ent: ModelEntity, delta: number)
---@field endFun fun(ent: ModelEntity)
---@field duration number

---@class ModelInfo
---@field origin fun()
---@field bones Bone[]
---@field bonesIDs table<string, number>
---@field sequences ModelSequence[]
---@field sequencesIDs table<string, number>
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
    local id = #self.bones+1
    self.bones[id] = {
        name = outName,
        parent = outParent,
        bone = outModel
    }
    self.bonesIDs[outName] = id
    return self
end

---[SHARED] Add sequence info to model
---@param name string Identifier of sequence
---@param duration number Duration of sequence
---@param startFun fun(ent: ModelEntity) Start function
---@param processFun fun(ent: ModelEntity, process: number) Sequence process
---@param endFun fun(ent: ModelEntity) End function
---@return ModelInfo
function ModelInfo:addSequence(name, duration, startFun, processFun, endFun)
    local id = #self.sequences+1
    self.sequences[id] = {
        startFun = startFun,
        processFun = processFun,
        endFun = endFun,
        duration = duration,
        name = name
    }
    self.sequencesIDs[name] = id
    return self
end


---@class ModelEntity: Entity
---@field identifier string Identifier of model
---@field modelInfo ModelInfo Model info
---@field modelBones Entity[] [CLIENT] Model bones entities, by number
---@field sequence number Current sequence ID
---@field sequenceStart number Relative to curtime


---@param origin Entity? Origin to parent
---@return ModelEntity?
function ModelInfo:create(origin)
    local originHolo = origin or self.origin()
    if !originHolo or !isValid(originHolo) then
        throw("Can't create origin")
        return
    end
    local id = originHolo:entIndex()
    if SERVER then
        model.toNetwork[id] = {
            modelId = self.identifier,
            params = {}
        }
        model.sync()
        originHolo = methodsOverride(originHolo)
        originHolo.identifier = self.identifier
        originHolo.modelBones = {}
        originHolo.modelInfo = self
        originHolo.sequence = 0
        model.inited[id] = originHolo
        return originHolo
    end
    ---@type table<string, Entity>
    local bones = {}
    for i, part in ipairs(self.bones) do
        if !part then goto cont end
        local holo = part.bone()
        if !holo then goto cont end
        bones[i] = holo
        local parent = part.parent
        local parentHolo = bones[self.bonesIDs[parent]] or (!parent and originHolo)
        if !parentHolo then
            throw(string.format("Parent \"%s\" for \"%s\" not found! Maybe you placed it in incorrect sequence?", parent, part.name))
            return
        end
        local pos, ang = localToWorld(holo:getPos(), holo:getAngles(), parentHolo:getPos(), parentHolo:getAngles())
        holo:setPos(pos)
        holo:setAngles(ang)
        holo:setParent(parentHolo)
        ::cont::
    end
    originHolo = methodsOverride(originHolo)
    originHolo.identifier = self.identifier
    originHolo.modelBones = bones
    originHolo.modelInfo = self
    originHolo.sequence = 0
    model.inited[id] = originHolo
    return originHolo
end


---[SHARED] Create new model info
---@param identifier string Identifier of model
---@param origin Vector|modelfun Origin of this entity
---@return ModelInfo
function model.new(identifier, origin)
    local rig = isfunction(origin) and origin or model.rig(origin)
    local obj = setmetatable(
        { origin = rig, bones = {}, bonesIDs = {}, sequences = {}, sequencesIDs = {}, identifier = identifier },
        ModelInfo
    )
    model.registered[identifier] = obj
    return obj
end

---[SHARED] Create model by registered model info
---@param identifier string Identifier of the model
---@return ModelEntity?
function model.create(identifier)
    local mdl = model.registered[identifier]
    return mdl:create()
end


return model
