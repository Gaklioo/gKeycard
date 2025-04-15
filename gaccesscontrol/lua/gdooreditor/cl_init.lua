include("gaccesscontrol/lua/sh_gaccessconfig.lua")

net.Receive("gBaseAccess_UpdateDoors", function()
    local ent = net.ReadEntity()
    local doors = net.ReadTable()

    ent.LinkedDoors = doors
end)

gDoorEditor = gDoorEditor or {}
gDoorEditor.WaitingInput = false
gDoorEditor.Entity = nil

hook.Add("gBaseAccess_EditDoors", "gBaseAccess_StartEditingDoors", function(ent)
    local ply = LocalPlayer()

    if not IsValid(ent) or ent:GetClass() != gAccessConfig.ModuleClass then return end
    if not gAccessConfig.AllowedRanks[ply:GetUserGroup()] then return end

    gDoorEditor.WaitingInput = true 
    gDoorEditor.Entity = ent
end)

hook.Add("PreDrawHalos", "gBaseAccess_DrawDoorHighlight", function()
    if not gDoorEditor.WaitingInput then return end
    local doorsToHighlight = {}
    local ent = gDoorEditor.Entity
    
    if IsValid(ent) and ent.LinkedDoors then
        for _, door in pairs(ent.LinkedDoors) do
            if IsValid(door) then
                table.insert(doorsToHighlight, door)
            end
        end
    end

    if #doorsToHighlight > 0 then
        halo.Add(doorsToHighlight, Color(0, 255, 0), 1, 1, 2, true, true)
    end
end)

hook.Add("PlayerButtonDown", "gBaseAccess_StartDoorToServer", function(ply, button)
    if not gDoorEditor.WaitingInput then return end
    
    timer.Simple(10, function()
        gDoorEditor.Entity = nil 
        gDoorEditor.WaitingInput = false 
        return
    end)

    if button == MOUSE_LEFT then
        local tr = util.TraceLine({
            start = ply:EyePos(),
            endpos = ply:EyePos() + ply:EyeAngles():Forward() * 1000,
            filter = function(entity) return (gAccessConfig.AllowedDoors[entity:GetClass()]) end
        })
    
        local doorEnt = tr.Entity
        if IsValid(doorEnt) and IsValid(gDoorEditor.Entity) then
            net.Start("gBaseAccess_AddDoorServer")
            net.WriteEntity(gDoorEditor.Entity)
            net.WriteEntity(doorEnt)
            net.SendToServer()
        end
        
        gDoorEditor.Entity = nil 
        gDoorEditor.WaitingInput = false 
    end
end)