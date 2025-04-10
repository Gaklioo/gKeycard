include("gaccesscontrol/lua/sh_gaccessconfig.lua")

util.AddNetworkString("gBaseAccess_EditPassword")
net.Receive("gBaseAccess_EditPassword", function()

    print("HI")
    local ply = net.ReadPlayer()
    local ent = net.ReadEntity()
    local password = net.ReadUInt(21)

    if not gAccessConfig.AllowedRanks[ply:GetUserGroup()] then return end
    if not IsValid(ent) or ent:GetClass() != gAccessConfig.ModuleClass then return end
    --Make sure the password is between 0 and 999999
    if gAccessConfig.PasswordCheck["Max"] < password then return end
    if gAccessConfig.PasswordCheck["Min"] > password then return end
    if not ent.Modules["Password"] then return end

    ent:SetNW2Int("gAccess_Password", password)
end)