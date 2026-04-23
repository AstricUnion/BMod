---Remote lib to send net-like requests to other chips
---@name BMod Remote
---@author AstricUnion
---@server


---Class to receive and send requests to other chips
---@class remote
local remote = {}
remote.callbacks = {}


---[SERVER] Receive request from other chip
---@param id string Identifier of this request. Will be lower
---@param callback fun(sender: Entity, owner: Player, payload: table) Callback for request
function remote.receive(id, callback)
    remote.callbacks[string.lower(id)] = callback
end


---[SERVER] Send new requrest
---@param id string Identifier of this request. Will be lower
---@param payload table Payload to send
---@param recipient Entity? Recepient of this request. If nil, then all recepients
function remote.send(id, payload, recipient)
    payload = table.copy(payload)
    payload.hookId = id
    hook.runRemote(recipient, payload)
end


hook.add("Remote", "BModReceiveRemote", function(sender, owner, payload)
    if !payload.hookId then return end
    local id = string.lower(payload.hookId)
    payload.id = nil
    local callback = remote.callbacks[id]
    if !callback then return end
    callback(sender, owner)
end)
