include("sh_gaccessconfigeditor.lua")
AddCSLuaFile("gaccesscontrol/lua/sh_gaccessconfig.lua")
include("gaccesscontrol/lua/sh_gaccessconfig.lua")

util.AddNetworkString("gAccessEditor")
hook.Add("PlayerSay", "gKeycard_ConfigOpen", function(ply, text)
    local text = string.lower(text)
    print(ply:GetUserGroup())
    if not gAccessConfig.AllowedRanks[ply:GetUserGroup()] then return end --Uncomment when not testing
    if not string.match(text, "/kconfig") then return end

    local pCoords = ply:GetPos()
    for _, ent in ents.Iterator() do
        if ent:GetClass() != gAccessConfig.ModuleClass  then continue end
        
        if pCoords:Distance2DSqr(ent:GetPos()) < 500 then
            for k, v in pairs(ent.Modules) do
                print(k .. " " .. tostring(v))
            end
            print("Done")

            ent:UpdatePlayer()
            net.Start("gAccessEditor")
            net.WriteEntity(ent)
            net.Send(ply)
        end
    end
end)