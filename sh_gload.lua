gAccess = {}
gAccess.BaseDir = "gaccesscontrol/lua/"
gAccess.EntityDir = "gaccesscontrol/entities/"

function gAccess.Log(...)
    local time = string.format("[%s]", os.date("%H:%M:%S"))
    local args = {...}

    MsgC(Color(149, 36, 255), "[gAccess Loader] ", Color(255, 255, 255, 255), time .. " " .. table.concat(args, " ") .. "\n")
end

function gAccess.LoadShared(f)
    gAccess.Log("Loading File Shared " .. f)
    if SERVER then
        AddCSLuaFile(f)
        include(f)
    else
        include(f)
    end
end

function gAccess.LoadServer(f)
    gAccess.Log("Loading File Server " .. f)
    if SERVER then
        include(f)
    end
end

function gAccess.LoadClient(f)
    gAccess.Log("Loading File Client " .. f)
    if SERVER then
        AddCSLuaFile(f)
    else
        include(f)
    end
end

function gAccess.LoadEverything(basePath)
    local files, directories = file.Find(basePath .. "*", "LUA")

    for k, v in pairs(files) do
        local path = basePath .. v
      
        if string.find(path, "sh_") then
            gAccess.LoadShared(path)
        elseif string.find(path, "sv_") then
            gAccess.LoadServer(path)
        elseif string.find(path, "cl_") then
            gAccess.LoadClient(path)      
        end
    end

    for _, dir in ipairs(directories) do
        gAccess.LoadEverything(basePath .. dir .. "/")
    end
end

gAccess.LoadEverything(gAccess.BaseDir)
gAccess.LoadShared("gaccesscontrol/entities/gbaseaccess/sh_shared.lua")
gAccess.LoadServer("gaccesscontrol/entities/gbaseaccess/sv_init.lua")
gAccess.LoadClient("gaccesscontrol/entities/gbaseaccess/cl_init.lua")