AddCSLuaFile("cl_init.lua")
AddCSLuaFile("sh_shared.lua")
include("gaccesscontrol/lua/sh_gaccessconfig.lua")
include("sh_shared.lua")

function ENT:Initialize()
    self:SetModel("models/maxofs2d/button_04.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    self:SetUseType(SIMPLE_USE)
    print(self:GetClass())

    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
    end

    self.UseModules = self.UseModules or false
    self.RecordAccess = self.RecordAccess or false
    self.ShouldScan = false

    local pos = self:GetPos()
    self.StoredEntity = nil 
    self.StoredCoords = nil

    for _, e in ipairs(ents.FindByClass("func_door")) do
        if IsValid(e) then
            local doorPos = e:GetPos()
            if self.StoredEntity == nil or self.StoredCoords == nil or pos:Distance2DSqr(doorPos) <= pos:Distance2DSqr(self.StoredCoords) then
                self.StoredEntity = e
                self.StoredCoords = doorPos
            end 
        end
    end
end

--For now the door it opens is the closest one that it is located to, we can 
--Hard code a way to link it to a door in the future
function ENT:OpenDoor()
    if IsValid(self.StoredEntity) then
        local ent = self.StoredEntity

        print(ent:GetPos())
        print(self:GetPos())

        ent:Fire("Unlock")
        ent:Fire("Open")

        timer.Simple(gAccess.DoorCloseDelay, function()
            if IsValid(ent) then
                ent:Fire("Close")
            end
        end)
    else
        print("InvalidDoor")
    end
end

function ENT:SaveData()
    local pos = self:GetPos()
    local ang = self:GetAngles()
    local class = self:GetClass()
    local accessLevel = self:GetNW2Int("AccessLevel")
    local map = game.GetMap()
    local modules = util.TableToJSON(self.Modules or {})
    local teamOverride = util.TableToJSON(self.TeamOverride or {})
    local dna = util.TableToJSON(self.dnaAccess or {})
    local retina = util.TableToJSON(self.retina or {})
    local password = self:GetNW2Int("gAccess_Password")

    local tolerance = 0.1
    local q = string.format("SELECT * FROM %s WHERE abs(x - %f) < %f AND abs(y - %f) < %f AND abs(z - %f) < %f", 
        gAccess.Database,
        pos.x, tolerance,
        pos.y, tolerance,
        pos.z, tolerance
    )

    local res = sql.Query(q)

    if res then
        print("Found in database, updating now")
        -- Record exists, update it
        local q = string.format("UPDATE %s SET accessLevel = %d, modules = '%s', teamOverride = '%s', dna = '%s', retina = '%s', password = %d, ax = %f, ay = %f, az = %f WHERE abs(x - %f) < %f AND abs(y - %f) < %f AND abs(z - %f) < %f",
            gAccess.Database,
            accessLevel,
            sql.SQLStr(modules, true),
            sql.SQLStr(teamOverride, true),
            sql.SQLStr(dna, true),
            sql.SQLStr(retina, true),
            password,
            ang.x, ang.y, ang.z,
            pos.x, tolerance,
            pos.y, tolerance,
            pos.z, tolerance
        )

        sql.Query(q)
    else
        print("Failed to find entity in database, Saving new")
        -- New record, insert it
        local q = string.format("INSERT INTO %s (class, x, y, z, ax, ay, az, accessLevel, modules, teamOverride, dna, retina, password, map) VALUES ('%s', %f, %f, %f, %f, %f, %f, %d, '%s', '%s', '%s', '%s', %d, '%s');",
            gAccess.Database,
            sql.SQLStr(class, true),
            pos.x, pos.y, pos.z,
            ang.x, ang.y, ang.z,
            accessLevel,
            sql.SQLStr(modules, true),
            sql.SQLStr(teamOverride, true),
            sql.SQLStr(dna, true),
            sql.SQLStr(retina, true),
            password,
            sql.SQLStr(map, true)
        )

        sql.Query(q)
    end
end

function ENT:LoadData()
    local pos = self:GetPos()
    local tolerance = 0.1
    local q = string.format("SELECT * FROM %s WHERE abs(x - %f) < %f AND abs(y - %f) < %f AND abs(z - %f) < %f LIMIT 1", 
        gAccess.Database,
        pos.x, tolerance,
        pos.y, tolerance,
        pos.z, tolerance
    )

    local res = sql.Query(q)
    if not istable(res) or #res == 0 then
        print("Failure to load data for " .. self:GetClass() .. " at position: " .. tostring(pos))
        print(sql.LastError())
        return
    end

    local data = res[1]
    for k, v in pairs(data) do
        print(k .. " " .. tostring(v))

        if k == "password" then
            self:SetNW2Int("gAccess_Password", v)
        end

        if k == "accessLevel" then
            self:SetNW2Int("AccessLevel", v)
        end
    end

    local accessLevel = tonumber(data.accessLevel)
    local modules = util.JSONToTable(data.modules)
    local teamOverride = util.JSONToTable(data.teamOverride)
    local dna = util.JSONToTable(data.dna)
    local retina = util.JSONToTable(data.retina)
    local password = tonumber(data.password)

    self.Modules = modules
    self.TeamOverride = teamOverride
    self.dnaAccess = dna
    self.retina = retina
end

function ENT:ModuleCheck(act)
    for module, value in pairs(self.Modules) do
        if value then
            local success = false
            if module == "DNA" then
                success = self:DoDNA(act)
            elseif module == "Retina" then
                success = self:DoRetina(act)
            elseif module == "Keycard" then
                success = self:DoKeycard(act)
            elseif module == "Password" then
                success = self:DoPassword(act)
            elseif module == "Team Override" then
                success = self:DoKeycard(act)
            elseif module == "AccessLevel" then
                continue
            end

            -- If any module fails, deny access and return false
            if not success then
                return false
            end
        end
    end

    return true 
end

function ENT:OnRemove()
    self:SaveData()
end


function ENT:DoDNA(act)
    local valid = hook.Run("gAccess_DoDNA", self, act)
    return valid or false
end

function ENT:DoRetina(act)
    local valid = hook.Run("gAccess_DoRetina", self, act)
    return valid or false
end

function ENT:DoKeycard(act)
    local valid = hook.Run("gAccess_DoKeycard", self, act)
    print(tostring(valid))
    return valid or false
end

function ENT:DoPassword(act)
    local valid = hook.Run("gAccess_DoPassword", self, act)
    return valid or false
end

function ENT:AddOverride(team, hasAccess)
    if not self.TeamOverride then
        self.TeamOverride = {}
    end

    self.TeamOverride[tostring(team)] = hasAccess

    self:SendOverrides()
end


function ENT:Use(act, caller, use, value)
    if not IsValid(act) or not act:IsPlayer() then return end
    local clearenceLevel = self:GetNW2Int("AccessLevel")
    print(act:GetPos())

    if clearenceLevel == 0 then
        self:LogUsage(act, 0, "Success")
        return
    end

    local wep = act:GetActiveWeapon()
    if not IsValid(wep) or act:GetActiveWeapon():GetClass() != gAccessConfig.CardWeaponName then 
        self:LogUsage(act, clearenceLevel, "Failure")
        return 
    end

    if self.TeamOverride[act:GetTeam()] then
        if self:ModuleCheck(act) then
            self:LogUsage(act, clearenceLevel, "Success")
            self:OpenDoor()
            return
        else
            self:LogUsage(act, clearenceLevel, "Failure")
            return
        end
    end

    if wep:GetNW2Int("ClearenceLevel") >= clearenceLevel then
        if self:ModuleCheck(act) then
            self:LogUsage(act, clearenceLevel, "Success")
            self:OpenDoor()
            return
        else
            self:LogUsage(act, clearenceLevel, "Failure")
            return
        end
    else
        self:LogUsage(act, clearenceLevel, "Failure")
        return
    end
end

function ENT:UpdatePlayer()
    self:SendOverrides()
    self:SendModules()
    self:SetNW2Int("AccessLevel", self:GetNW2Int("AccessLevel"))
    self:SetNW2Int("gAccess_Password", self:GetNW2Int("gAccess_Password"))
end

function ENT:LogUsage(ply, accessLevel, result)
    --We do this so that all logging can be done in a seperate file
    --So anyone can listen to this hook and write their own storing if they please
    hook.Run("gAccess_LogUsage", ply, accessLevel, result)
end

function ENT:HasModule(type)
    return self.Modules[type] == true
end

function ENT:AddModule(type)
    if self.Modules[type] then return false end
    if self:HasModule(type) then return false end

    self.Modules[type] = true
    self:SendModules()
end

function ENT:RemoveModule(type)
    if not self.Modules[type] then return false end
    if not self:HasModule(type) then return false end

    self.Modules[type] = false
    self:SendModules()
end

util.AddNetworkString("gBaseAccess_UpdateModules")
function ENT:SendModules()
    net.Start("gBaseAccess_UpdateModules")
    net.WriteEntity(self)
    net.WriteTable(self.Modules)
    net.Broadcast()
end

util.AddNetworkString("gBaseAccess_UpdateOverrides")
function ENT:SendOverrides()
    net.Start("gBaseAccess_UpdateOverrides")
    net.WriteEntity(self)
    net.WriteTable(self.TeamOverride)
    net.Broadcast()
end

function ENT:ChangeLevel(level)
    level = tonumber(level)
    if level > 5 or level < 0 then return false end

    self:SetNW2Int("AccessLevel", level)
    return true
end

util.AddNetworkString("gBaseAccess_AddModule")
net.Receive("gBaseAccess_AddModule", function()
    local ply = net.ReadPlayer()
    local ent = net.ReadEntity()
    local module = net.ReadString()

    --if not gAccess.AllowedRanks[ply:GetUserGroup()] then return end
    if not IsValid(ent) then return end
    if ent:GetClass() != "gbaseaccess" then return end
    if ent.Modules[module] == nil then return end -- Module doesnt exist
    if ent.Modules[module] then return end -- Module already is added

    ent:AddModule(tostring(module))
end)

util.AddNetworkString("gBaseAccess_RemoveModule")
net.Receive("gBaseAccess_RemoveModule", function() 
    --if not gAccess.AllowedRanks[ply:GetUserGroup()] then return end

    local ply = net.ReadPlayer()
    local ent = net.ReadEntity()
    local module = net.ReadString()

    --if not gAccess.AllowedRanks[ply:GetUserGroup()] then return end
    if not IsValid(ent) then return end
    if ent:GetClass() != "gbaseaccess" then return end
    if ent.Modules[module] == nil then return end -- Module doesnt exist
    if not ent.Modules[module] then return end -- Module already is not added

    ent:RemoveModule(tostring(module))
end)

util.AddNetworkString("gBaseAccess_EditClearence")
net.Receive("gBaseAccess_EditClearence", function()
    local ply = net.ReadPlayer()
    local ent = net.ReadEntity()
    local newClearence = net.ReadUInt(3)

    --if not gAccess.AllowedRanks[ply:GetUserGroup()] then return end
    if not IsValid(ent) then return end
    if ent:GetClass() != "gbaseaccess" then return end
    if not ent:ChangeLevel(newClearence) then return end
end)
