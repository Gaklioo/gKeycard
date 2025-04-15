ENT = {}

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "gKeycard Scanner"
ENT.Category = "SCP"
ENT.Author = "Gak"
ENT.Spawnable = true 

gAccess = gAccess or {}
gAccess.Database = "gAccess_EntityStore"
gAccess.DoorCloseDelay = 5

gAccess.AllowedRanks = {
    ["Owner"] = true,
    ["SuperAdmin"] = true
}

gAccess.Stages = {
    "Password", "DNA"
}

--Custom Fields & Explinations
ENT.AccessLevel = 0 -- Minimum clearance level
ENT.InteractionRange = 100 -- How close the player needs to be
ENT.UseModules = true -- Does the entity use other modules to access, 0 means nothing is required
ENT.RecordAccess = true 
ENT.Modules = {
    ["DNA"] = false,
    ["Keycard"] = false,
    ["Password"] = false,
    ["Team Override"] = false,
    --This is used only be the config editor
    ["AccessLevel"] = 0
}

--This will always be empty in this, please do not add shit to it, its added dynamically
ENT.LinkedDoors = {
    
}

ENT.TeamOverride = {

}

ENT.dnaAccess = {

}

function ENT:SetupDataTables()
    self:SetNW2Int("AccessLevel", 0)
    self:SetNW2Int("gAccess_Password", -1)
    self:SetNW2String("Stage", nil)
end

scripted_ents.Register(ENT, "gbaseaccess")
