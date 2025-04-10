include("gaccesscontrol/lua/sh_gaccessconfig.lua")

util.AddNetworkString("gBaseAccess_SetOverride")
net.Receive("gBaseAccess_SetOverride", function()
    local ply = net.ReadPlayer()
    local entity = net.ReadEntity()
    local teamToAdd = net.ReadString()
    local boolValue = net.ReadBool()

    if not IsValid(ply) then return end
    if not gAccessConfig.AllowedRanks[ply:GetUserGroup()] then return end
    if not IsValid(entity) or entity:GetClass() != gAccessConfig.ModuleClass then return end
    if not table.HasValue(gAccessConfig.Teams, teamToAdd) then return end

    entity:AddOverride(teamToAdd, boolValue)
end)