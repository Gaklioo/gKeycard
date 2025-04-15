include("gaccesscontrol/lua/sh_gaccessconfig.lua")

hook.Add("gAccess_DoDNA", "gBaseAccess_ReturnDNAModule", function(entity, act)
    if not IsValid(entity) then return end
    if not IsValid(act) then return end
    if not entity:GetClass() != gAccessConfig.ModuleClass then return end

    for _, id in pairs(entity.dnaAccess) do
        if id == act:SteamID() then return true end
    end

    return false
end)