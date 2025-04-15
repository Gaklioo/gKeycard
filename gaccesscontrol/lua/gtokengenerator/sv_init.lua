include("gaccesscontrol/lua/sh_gaccessconfig.lua")

util.AddNetworkString("gBaseAccess_EditPassword")
net.Receive("gBaseAccess_EditPassword", function(len, ply)
    local ent = net.ReadEntity()
    local password = net.ReadUInt(21)

    if not gAccessConfig.AllowedRanks[ply:GetUserGroup()] then return end
    if not IsValid(ent) or ent:GetClass() != gAccessConfig.ModuleClass then return end
    if not ent.Modules["Password"] then return end
    --Make sure the password is between min and max
    if gAccessConfig.PasswordCheck["Max"] < password then return end
    if gAccessConfig.PasswordCheck["Min"] > password then return end

    ent:SetNW2Int("gAccess_Password", password)
end)

util.AddNetworkString("gBaseAccess_RunClientPasswordCheck")
hook.Add("gAccess_DoPassword", "gBaseAccess_RunPasswordCheck", function(ent, ply, cb)
    if not gAccessConfig.AllowedRanks[ply:GetUserGroup()] then return cb(false) end
    if not IsValid(ent) or ent:GetClass() != gAccessConfig.ModuleClass then return cb(false) end
    if not ent.Modules["Password"] then return cb(false) end

    net.Start("gBaseAccess_RunClientPasswordCheck")
    net.WriteEntity(ent)
    net.Send(ply)

    ply._gAccessCallback = cb
    ent:SetNW2String("Stage", "Password")
end)

util.AddNetworkString("gAccess_GetUserTypedPassword")
net.Receive("gAccess_GetUserTypedPassword", function(len, ply)
    local ent = net.ReadEntity()
    local typedPassword = net.ReadUInt(31)

    if not gAccessConfig.AllowedRanks[ply:GetUserGroup()] then return end
    if not IsValid(ent) or ent:GetClass() != gAccessConfig.ModuleClass then return end
    if not ent.Modules["Password"] then return end

    local entPassword = ent:GetNW2Int("gAccess_Password")

    local success = (entPassword == typedPassword)

    ent:SetNW2String("Stage", "")

    if ply._gAccessCallback then
        ply._gAccessCallback(success)
        ply._gAccessCallback = nil
    end
end)
