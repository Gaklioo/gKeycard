gAccessConfig = gAccessConfig or {}
gAccess = gAccess or {}

gAccess.Database = "gAccess_EntityStore"

/*
    id: Autoincrementing value
    class: Class of Entity
    x : Pos.x
    y : Pos.y
    z : Pos.z
    ax : Ang.x
    ay : Ang.y
    az : Ang.z
    accessLevel : Access Level of the scanner
    modules : Modules the keycard has
    teamOverride : Teams that have override access to the card
    dna : Teams that have DNA Access
    password : Password Addressed to the card
    map : Map the keycard is saved on
*/

-- if sql.TableExists(gAccess.Database) then
--     print("Bye Bye")
--     sql.Query("DROP TABLE IF EXISTS gAccess_EntityStore")
-- end

if not sql.TableExists(gAccess.Database) then
    print("Creating Database")
    sql.Begin()
        local str = string.format("CREATE TABLE %s (id INTEGER PRIMARY KEY AUTOINCREMENT, class TEXT, x REAL, y REAL, z REAL, ax REAL, ay REAL, az REAL, accessLevel INTEGER, modules TEXT, teamOverride TEXT, dna TEXT, doors TEXT, password INTEGER, map TEXT);", gAccess.Database)
        sql.Query(str)
    sql.Commit()
end

--include("gaccesscontrol/lua/sh_gaccessconfig.lua")

--Ranks that are allowed to edit the keypads
gAccessConfig.AllowedRanks = {
    ["Owner"] = true,
    ["SuperAdmin"] = true,
    ["SeniorAdmin"] = true
}

gAccessConfig.Teams = {
    "Ethics", 
    "Omega-1", 
    "O5", 
    "Alpha-1"
}

gAccessConfig.AllowedDoors = {
    ["func_door"] = true
}

gAccessConfig.PasswordCheck = {
    ["Max"] = 999999,
    ["Min"] = 0 
}

gAccessConfig.ModuleClass = "gbaseaccess"
gAccessConfig.CardWeaponName = "gaccesscard"
