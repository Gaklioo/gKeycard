AddCSLuaFile("sh_shared.lua")
AddCSLuaFile("cl_init.lua")
include("gaccesscontrol/lua/sh_gaccessconfig.lua")
resource.AddFile("materials/gaccesscontrol/scp.jpg")
resource.AddFile("materials/gaccesscontrol/fingerprint.jpg")
include("sh_shared.lua")

function ENT:Initialize()
    self:SetModel("models/maxofs2d/button_04.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()

    if phys:IsValid() then
        phys:Wake()
    end

    self.UseModules = self.UseModules or false
    self.RecordAccess = self.RecordAccess or false
    self.ShouldScan = false

    self.LinkedDoors = self.LinkedDoors or {}
    self.TeamOverride = self.TeamOverride or {}
    self.dnaAccess = self.dnaAccess or {}

    --Ensure that this is not null as it is weird sometimes
    self.Modules = {
        ["DNA"] = false,  
        ["Keycard"] = false,
        ["Password"] = false,
        ["Team Override"] = false,
        --This is used only be the config editor
        ["AccessLevel"] = 0
    }

    hook.Add("PlayerInitialSpawn", "gBaseAccess_SendInfotoPlayer", function(ply)
        timer.Simple(10, function()
            self:SendOverrides()
            self:SendModules()
            self:SendDNA()
            self:SendDoors()
            self:SetNW2Int("AccessLevel", self:GetNW2Int("AccessLevel"))
            self:SetNW2Int("gAccess_Password", self:GetNW2Int("gAccess_Password"))
        end)
    end)
end


function ENT:AddDoor(ent) 
    --We check again incase a third part uses this script and attempts to add a door through the server side function, and not the net message
    if not IsValid(ent) then return end
    if not gAccessConfig.AllowedDoors[ent:GetClass()] then return end

    table.insert(self.LinkedDoors, ent)
    self:SendDoors()
end

function ENT:OpenDoor()
    for _, v in pairs(self.LinkedDoors) do
        if IsValid(v) then
            v:Fire("Unlock")
            v:Fire("Open")

            timer.Simple(gAccess.DoorCloseDelay, function()
                if IsValid(v) then
                    v:Fire("Close")
                    v:Fire("Locked")
                end
            end)
        else
            print("Invalid Door attempted to be opened")
        end
    end
end

function ENT:StartSaveDoor()
    local doorTable = {}

    for _, door in pairs(self.LinkedDoors or {}) do
        if IsValid(door) then
            local entID = door:MapCreationID()

            if entID and entID > 0 then
                table.insert(doorTable, entID)
            end
        end
    end

    return doorTable
end

function ENT:SaveData()
    local pos = self:GetPos()
    local ang = self:GetAngles()
    local class = self:GetClass()
    local accessLevel = self:GetNW2Int("AccessLevel")
    local map = game.GetMap()
    local modules = util.TableToJSON(self.Modules)
    local teamOverride = util.TableToJSON(self.TeamOverride or {})
    local dna = util.TableToJSON(self.dnaAccess or {})
    local savedDoors = util.TableToJSON(self:StartSaveDoor() or {})
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
        local q = string.format("UPDATE %s SET accessLevel = %d, modules = '%s', teamOverride = '%s', dna = '%s', doors = '%s', password = %d, ax = %f, ay = %f, az = %f WHERE abs(x - %f) < %f AND abs(y - %f) < %f AND abs(z - %f) < %f",
            gAccess.Database,
            accessLevel,
            sql.SQLStr(modules, true),
            sql.SQLStr(teamOverride, true),
            sql.SQLStr(dna, true),
            sql.SQLStr(savedDoors, true),
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
        local q = string.format("INSERT INTO %s (class, x, y, z, ax, ay, az, accessLevel, modules, teamOverride, dna, doors, password, map) VALUES ('%s', %f, %f, %f, %f, %f, %f, %d, '%s', '%s', '%s', '%s', %d, '%s');",
            gAccess.Database,
            sql.SQLStr(class, true),
            pos.x, pos.y, pos.z,
            ang.x, ang.y, ang.z,
            accessLevel,
            sql.SQLStr(modules, true),
            sql.SQLStr(teamOverride, true),
            sql.SQLStr(dna, true),
            sql.SQLStr(savedDoors, true),
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

    self:InitializeVariables(data)
end

--Door and password arent properly being sent to player

function ENT:InitializeVariables(data)
    for k, v in pairs(data) do
        --This seems impracticle, and the variable below __SHOULD__ address this
        --But it doesnt, SetNW2Int from the database read values doesnt work, but it does work in this loop. So thats fine for now I guess.
        if k == "password" then
            self:SetNW2Int("gAccess_Password", v)
        end

        if k == "accessLevel" then
            self:SetNW2Int("AccessLevel", v)
        end
    end

    local accessLevel = tonumber(data.accessLevel or 0)
    local modules = util.JSONToTable(data.modules or self.Modules)
    local teamOverride = util.JSONToTable(data.teamOverride or self.TeamOverride)
    local dna = util.JSONToTable(data.dna or self.dnaAccess)
    local password = tonumber(data.password or 0)
    local doors = util.JSONToTable(data.doors or self.LinkedDoors)

    for _, id in pairs(doors) do
        local ent = ents.GetMapCreatedEntity(id)

        if IsValid(ent) then
            table.insert(self.LinkedDoors, ent)
        end
    end

    self.Modules = modules
    self.TeamOverride = teamOverride
    self.dnaAccess = dna
end

function ENT:ModuleCheck(act, callback)
    local modules = self.Modules

    local keys = {}

    for k in pairs(modules) do
        table.insert(keys, k)
    end

    local i = 1

    local function processNext()
        local module = keys[i]
        i = i + 1

        if not module then
            callback(true)
            return
        end

        if not modules[module] then
            return processNext()
        end

        local function fail()
            callback(false)
        end

        if module == "DNA" then
            print("Doing DNA")
            if not self:DoDNA(act) then return fail() end
            return processNext()
        elseif module == "Keycard" or module == "Team Override" then
            if not self:DoKeycard(act) then return fail() end
            return processNext()
        elseif module == "AccessLevel" then
            return processNext()
        elseif module == "Password" then
            self:DoPassword(act, function(success)
                if not success then 
                    self:SetNW2String("Stage", "") 
                    return fail() 
                end

                processNext()
            end)
            return
        else
            return processNext()
        end
    end

    processNext()
end

function ENT:DoDNA(act)
    local valid = hook.Run("gAccess_DoDNA", self, act)
    return valid or false
end

function ENT:DoKeycard(act)
    local valid = hook.Run("gAccess_DoKeycard", self, act)
    return valid or false
end

function ENT:DoPassword(act, cb)
    local valid = hook.Run("gAccess_DoPassword", self, act, cb)
end

function ENT:AddOverride(team, hasAccess)
    if not self.TeamOverride then
        self.TeamOverride = {}
    end

    self.TeamOverride[tostring(team)] = hasAccess

    self:SendOverrides()
end

util.AddNetworkString("gBaseAccess_DrawResponse")
function ENT:SetResponse(act, Response)
    net.Start("gBaseAccess_DrawResponse")
    net.WriteEntity(self)
    net.WriteString(Response)
    net.Send(act)
end

function ENT:Use(act, caller, use, value)
    if not IsValid(act) or not act:IsPlayer() then return end
    local clearenceLevel = self:GetNW2Int("AccessLevel")

    if clearenceLevel == 0 then
        self:LogUsage(act, 0, "Success")
        self:OpenDoor()
        self:SetResponse(act, "true")
        return
    end

    local wep = act:GetActiveWeapon()
    if not IsValid(wep) or act:GetActiveWeapon():GetClass() != gAccessConfig.CardWeaponName then 
        self:LogUsage(act, clearenceLevel, "Failure")
        self:SetResponse(act, "false")
        return 
    end

    if self.TeamOverride[act:GetTeam()] then
        self:ModuleCheck(act, function(success)
            if success then
                self:LogUsage(act, clearenceLevel, "Success")
                self:OpenDoor()
                self:SetResponse(act, "true")
                return
            else
                self:LogUsage(act, clearenceLevel, "Failure")
                self:SetResponse(act, "false")
                return
            end
        end)
    elseif  wep:GetNW2Int("ClearenceLevel") >= clearenceLevel then
        self:ModuleCheck(act, function(success)
            if success then
                self:LogUsage(act, clearenceLevel, "Success")
                self:OpenDoor()
                self:SetResponse(act, "true")
                return
            else
                self:LogUsage(act, clearenceLevel, "Failure")
                self:SetResponse(act, "false")
                return
            end
        end)
    else
        self:LogUsage(act, clearenceLevel, "Failure")
        self:SetResponse(act, "false")
        return
    end
end

function ENT:UpdatePlayer()
    self:SendOverrides()
    self:SendModules()
    self:SendDNA()
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

function ENT:AddDNA(str)
    self.dnaAccess[str] = true
    self:SendDNA()
end

function ENT:RemoveDNA(str)
    self.dnaAccess[str] = nil
    self:SendDNA()
end

util.AddNetworkString("gBaseAccess_UpdateDNA")
function ENT:SendDNA()
    local dna = util.TableToJSON(self.dnaAccess)
    net.Start("gBaseAccess_UpdateDNA")
    net.WriteEntity(self)
    net.WriteString(dna)
    net.Broadcast()
end


util.AddNetworkString("gBaseAccess_UpdateModules")
function ENT:SendModules()
    if not table.IsEmpty(self.Modules) then
        local modules = util.TableToJSON(self.Modules)
        net.Start("gBaseAccess_UpdateModules")
        net.WriteEntity(self)
        net.WriteString(modules)
        net.Broadcast()
    end
end

util.AddNetworkString("gBaseAccess_UpdateOverrides")
function ENT:SendOverrides()
    if not table.IsEmpty(self.TeamOverride) then
        local teamOverride = util.TableToJSON(self.TeamOverride)
        net.Start("gBaseAccess_UpdateOverrides")
        net.WriteEntity(self)
        net.WriteString(teamOverride)
        net.Broadcast()
    end
end

util.AddNetworkString("gBaseAccess_UpdateDoors")
function ENT:SendDoors()
    net.Start("gBaseAccess_UpdateDoors")
    net.WriteEntity(self)
    net.WriteTable(self.LinkedDoors)
    net.Broadcast()
end

function ENT:ChangeLevel(level)
    level = tonumber(level)
    if level > 5 or level < 0 then return false end

    self:SetNW2Int("AccessLevel", level)
    return true
end

util.AddNetworkString("gBaseAccess_AddDNAAccess")
net.Receive("gBaseAccess_AddDNAAccess", function(len, ply)
    local str = net.ReadString()
    local entity = net.ReadEntity()

    if not IsValid(entity) then return end
    if not IsValid(ply) then return end
    if not gAccessConfig.AllowedRanks[ply:GetUserGroup()] then return end
    if entity:GetClass() != gAccessConfig.ModuleClass then return end
    if not entity:HasModule("DNA") then return end

    if string.match(str, "^STEAM_%d:%d+:%d+$") then
        entity:AddDNA(str)
    end
end)

util.AddNetworkString("gBaseAccess_RemoveDNAAccess")
net.Receive("gBaseAccess_RemoveDNAAccess", function(len, ply)
    local str = net.ReadString()
    local entity = net.ReadEntity()

    if not IsValid(entity) then return end
    if not IsValid(ply) then return end
    if not gAccessConfig.AllowedRanks[ply:GetUserGroup()] then return end
    if entity:GetClass() != gAccessConfig.ModuleClass then return end
    if not entity:HasModule("DNA") then return end

    if string.match(str, "^STEAM_%d:%d+:%d+$") then -- AI is pog beacuse i fucking despise regex
        if not entity.dnaAccess[str] then return end
        entity:RemoveDNA(str)
        
        for k, v in pairs(entity.dnaAccess) do
            print(k .. tostring(v))
        end
    end
end)


util.AddNetworkString("gBaseAccess_AddModule")
net.Receive("gBaseAccess_AddModule", function(len, ply)
    local ent = net.ReadEntity()
    local module = net.ReadString()

    if not gAccess.AllowedRanks[ply:GetUserGroup()] then return end
    if not IsValid(ent) then return end
    if ent:GetClass() != gAccessConfig.ModuleClass then return end
    if ent.Modules[module] == nil then return end -- Module doesnt exist
    if ent.Modules[module] then return end -- Module already is added

    ent:AddModule(tostring(module))
end)

util.AddNetworkString("gBaseAccess_RemoveModule")
net.Receive("gBaseAccess_RemoveModule", function(len, ply) 
    if not gAccess.AllowedRanks[ply:GetUserGroup()] then return end

    local ent = net.ReadEntity()
    local module = net.ReadString()

    if not gAccess.AllowedRanks[ply:GetUserGroup()] then return end
    if not IsValid(ent) then return end
    if ent:GetClass() != gAccessConfig.ModuleClass then return end
    if ent.Modules[module] == nil then return end -- Module doesnt exist
    if not ent.Modules[module] then return end -- Module already is not added

    ent:RemoveModule(tostring(module))
end)

util.AddNetworkString("gBaseAccess_EditClearence")
net.Receive("gBaseAccess_EditClearence", function(len, ply)
    local ent = net.ReadEntity()
    local newClearence = net.ReadUInt(3)

    if not gAccess.AllowedRanks[ply:GetUserGroup()] then return end
    if not IsValid(ent) then return end
    if ent:GetClass() != gAccessConfig.ModuleClass then return end
    if not ent:ChangeLevel(newClearence) then return end
end)

util.AddNetworkString("gBaseAccess_AddDoorServer")
net.Receive("gBaseAccess_AddDoorServer", function(len, ply)
    local ent = net.ReadEntity()
    local doorEnt = net.ReadEntity()

    if not gAccess.AllowedRanks[ply:GetUserGroup()] then return end
    if not IsValid(ent) then return end
    if not IsValid(doorEnt) then return end
    if ent:GetClass() != gAccessConfig.ModuleClass then return end
    if not gAccessConfig.AllowedDoors[doorEnt:GetClass()] then return end

    ent:AddDoor(doorEnt)
end)
