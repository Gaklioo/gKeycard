include("sh_shared.lua")

function ENT:Draw()
    self:DrawModel()
end

net.Receive("gBaseAccess_UpdateModules", function()
    local ent = net.ReadEntity()
    local modules = net.ReadTable()

    if ent:GetClass() != gAccessConfig.ModuleClass then return end
    if not modules then return end

    ent.Modules = modules

    print(tostring(ent:GetPos()))
end)

net.Receive("gBaseAccess_UpdateOverrides", function()
    local ent = net.ReadEntity()
    local teams = net.ReadTable()

    if ent:GetClass() != gAccessConfig.ModuleClass then return end
    if not teams then return end

    ent.TeamOverride = teams
end)