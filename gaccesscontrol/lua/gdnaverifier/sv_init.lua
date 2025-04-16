include("gaccesscontrol/lua/sh_gaccessconfig.lua")

hook.Add("gAccess_DoDNA", "gBaseAccess_ReturnDNAModule", function(ent, act)
    if not IsValid(ent) then print("Invalid Ent")return end
    if not IsValid(act) then print("Invalid Actor") return end
    if ent:GetClass() != gAccessConfig.ModuleClass then return end
    
    for id, _ in pairs(ent.dnaAccess) do
        if id == act:SteamID() then print("Yay") return true end
    end

    return false
end)