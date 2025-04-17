gBaseENT = {}

gBaseENT.Type = "anim"
gBaseENT.Base = "base_gmodentity"
gBaseENT.PrintName = "gKeycard Scanner"
gBaseENT.Category = "SCP"
gBaseENT.Author = "Gak"
gBaseENT.Spawnable = true 

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
gBaseENT.AccessLevel = 0 -- Minimum clearance level
gBaseENT.InteractionRange = 100 -- How close the player needs to be
gBaseENT.UseModules = true -- Does the entity use other modules to access, 0 means nothing is required
gBaseENT.RecordAccess = true 
gBaseENT.Modules = {
    ["DNA"] = false,
    ["Keycard"] = false,
    ["Password"] = false,
    ["Team Override"] = false,
    --This is used only be the config editor
    ["AccessLevel"] = 0
}

--This will always be empty in this, please do not add shit to it, its added dynamically
gBaseENT.LinkedDoors = {
    
}

gBaseENT.TeamOverride = {

}

gBaseENT.dnaAccess = {

}

function gBaseENT:SetupDataTables()
    self:SetNW2Int("AccessLevel", 0)
    self:SetNW2Int("gAccess_Password", -1)
    self:SetNW2String("Stage", nil)
end

scripted_ents.Register(gBaseENT, "gbaseaccess")
