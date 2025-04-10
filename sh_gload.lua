gAccess = {}
gAccess.BaseDir = "gaccesscontrol/"

function gAccess.Log(...)
    local time = string.format("[%s]", os.date("%H:%M:%S"))
    local args = {...}

    MsgC(Color(149, 36, 255), "[gAccess Loader] ", Color(255, 255, 255, 255), time .. " " .. table.concat(args, " ") .. "\n")
end

function gAccess.LoadShared(file)
    gAccess.Log("Loading File Shared " .. file)
    if SERVER then
        AddCSLuaFile(file)
        include(file)
    else
        include(file)
    end
end

function gAccess.LoadServer(file)
    gAccess.Log("Loading File Server " .. file)
    if SERVER then
        include(file)
    end
end

function gAccess.LoadClient(file)
    gAccess.Log("Loading File Client " .. file)
    if SERVER then
        AddCSLuaFile(file)
    else
        include(file)
    end
end

function gAccess.LoadEverything(basePath)
    local files, directories = file.Find(basePath .. "*", "LUA")

    for k, v in pairs(files) do
        local path = basePath .. v

        if string.find(path, "cl_") then
            gAccess.LoadClient(path)            
        elseif string.find(path, "sv_") then
            gAccess.LoadServer(path)
        else
            gAccess.LoadShared(path)
        end
    end

    for _, dir in ipairs(directories) do
        gAccess.LoadEverything(basePath .. dir .. "/")
    end
end

gAccess.LoadEverything(gAccess.BaseDir)