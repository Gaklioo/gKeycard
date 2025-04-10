include("gaccesscontrol/lua/sh_gaccessconfig.lua")

hook.Add("gAccess_DoKeycard", "gAccessServer_DoKeycard", function(ent, act)
    if not IsValid(ent) then return end
    if not IsValid(act) then return end
    if not IsValid(act:GetActiveWeapon()) then return end
    if act:GetActiveWeapon():GetClass() != gAccessConfig.CardWeaponName then return end

    local entityClearenceLevel = ent:GetNW2Int("AccessLevel")
    local playerClearenceLevel = act:GetNW2Int("AccessLevel")

    if not entityClearenceLevel then return end
    if not playerClearenceLevel then return end

    if ent.TeamOverride[act:GetTeam()] then
        return true 
    end

    if entityClearenceLevel > playerClearenceLevel then
        return false 
    end
end)