if SERVER then
    local ow = owner()
    hook.add("PlayerSay", "Commands", function(ply, text)
        if ply ~= ow then return end
        local command = string.gsub(string.split(text, " ")[1], "%!", "")
        if command == "binv" then
            net.start("BModInventory")
            net.send(ply)
            return ""
        elseif command == "bcreate" then
            local args = string.gsub(text, "%!" .. command .. " ", "")
            local entToCreate = ents.registered[args]
            if !entToCreate then
                print("No such ent: " .. args)
                return
            end
            local ent = entToCreate:new()
            local angs = ply:getEyeAngles()
            local shootPos = ply:getShootPos()
            local pos = trace.line(shootPos, shootPos + angs:getForward() * 64, {ply}).HitPos
            ent:spawn(pos, Angle(), false)
        end
    end)
else
    ---@class bguiElements
    local bguiElements = bguiElements
    net.receive("BModInventory", function()
        bguiElements.inventory()
    end)
end
