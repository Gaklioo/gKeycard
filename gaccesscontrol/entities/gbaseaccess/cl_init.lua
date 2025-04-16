include("sh_shared.lua")

gModulesRun = gModulesRun or {}
gModulesRun.DoingPassword = false
gModulesRun.DoingDNA = false
gModulesRun.TypedPassword = ""
gModulesRun.ClearenceEnum = {
    [0] = Color(123, 125, 12),
    [1] = Color(0, 89, 255),
    [2] = Color(115, 252, 133, 255),
    [3] = Color(255, 223, 41),
    [4] = Color(255, 0, 0),
    [5] = Color(255, 255, 255)
}

gModulesRun.ColorSuccess = Color(0, 255, 0)
gModulesRun.ColorFailure = Color(255, 0, 0)
gModulesRun.SCPMaterial = Material("gaccesscontrol/scp.jpg")
gModulesRun.FingerprintMaterial = Material("gaccesscontrol/fingerprint.jpg")

function ENT:DrawButton(Text, x, y, w, h, pos, ang, scale, onClick)
    local hovered = false
    
    local tr = LocalPlayer():GetEyeTrace()

    if tr.Entity == self then 
        local hitPos = tr.HitPos
        local localPos = WorldToLocal(hitPos, Angle(0, 0, 0), pos, ang)
        local drawX = localPos.x / scale
        local drawY = -localPos.y / scale

        local hovered = drawX >= x and drawX <= x + w and drawY >= y and drawY <= y + h

        if hovered then
            if (input.IsMouseDown(MOUSE_LEFT) or input.IsKeyDown(KEY_E)) and CurTime() - (self.LastClick or 0) > 0.2 then
                self.LastClick = CurTime()
                onClick()
            end
        end

        surface.SetDrawColor(hovered and Color(255, 100, 100) or Color(100, 100, 100))
        surface.DrawRect(x, y, w, h)
    
        draw.SimpleText(Text, "DermaLarge", x + w / 2, y + h / 2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

function ENT:DrawPasswordInput(pos, ang, scale, w, h)
    local btnSize = 25
    local spacing = 5
    local startX = (w - (btnSize * 3 + spacing * 2)) / 2
    local startY = 25

    cam.Start3D2D(pos, ang, scale)
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(0, 0, w, h)
        draw.DrawText("Enter Password", "Default", 40, 0, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)

        local number = 1
        for row = 0, 2 do
            for col = 0, 2 do
                local x = startX + col * (btnSize + spacing)
                local y = startY + row * (btnSize + spacing)

                self:DrawButton(tostring(number), x, y, btnSize, btnSize, pos, ang, scale, function()
                    gModulesRun.TypedPassword = gModulesRun.TypedPassword .. number
                end)

                number = number + 1
            end
        end

        self:DrawButton("✔", startX + 0 * (btnSize + spacing), startY + 3 * (btnSize + spacing), btnSize, btnSize, pos, ang, scale, function()
            timer.Simple(0.5, function()
                net.Start("gAccess_GetUserTypedPassword")
                net.WriteEntity(self)
                net.WriteUInt(tonumber(gModulesRun.TypedPassword) or 0, 31)
                net.SendToServer()
                self:SetNW2String("Stage", "")
                gModulesRun.TypedPassword = ""
            end)
        end)

    cam.End3D2D()
end

net.Receive("gBaseAccess_DrawResponse", function()
    local ent = net.ReadEntity()
    local str = net.ReadString()

    if str == "true" then
        ent:SetNW2Bool("success", true)
    elseif str == "false" then
        ent:SetNW2Bool("failure", true)
    end
end)

function ENT:DrawBase(pos, ang, scale, w, h)
    local accessLevel = self:GetNW2Int("AccessLevel")

    cam.Start3D2D(pos, ang, scale)
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(0, 0, w, h)

        draw.DrawText("Keycard Scanner", "Default", w / 2, 0, Color(255, 255, 255, 255),TEXT_ALIGN_CENTER)
        if self.Modules["DNA"] then
            surface.SetMaterial(gModulesRun.SCPMaterial)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(w / 10, h / 4, 64, 64)
            surface.SetMaterial(gModulesRun.FingerprintMaterial)
            surface.SetDrawColor(255, 255, 255, 255) 
            surface.DrawTexturedRect(w / 2, h / 4, 64, 64)
        else
            surface.SetMaterial(gModulesRun.SCPMaterial)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(w / 3.5, h / 4, 64, 64)
        end

        draw.DrawText("Clearence Level " .. accessLevel, "Default", w / 2, h / 1.2, gModulesRun.ClearenceEnum[accessLevel], TEXT_ALIGN_CENTER)

        if self:GetNW2Bool("success") then
            self:DrawSuccess(pos, ang, scale, w, h)
        end

        if self:GetNW2Bool("failure") then
            self:DrawFailure(pos, ang, scale, w, h)
        end
    cam.End3D2D()
end

function ENT:DrawSuccess(pos, ang, scale, w, h)
    cam.Start3D2D(pos, ang, scale)
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(0, 0, w, h)

        draw.DrawText("Keycard Scanner", "Default", w / 2, 0, Color(255, 255, 255, 255),TEXT_ALIGN_CENTER)
        surface.SetMaterial(gModulesRun.SCPMaterial)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(w / 3.5, h / 4, 64, 64)

        draw.DrawText("SUCCESS", "Default", w / 2, h / 1.2, gModulesRun.ColorSuccess, TEXT_ALIGN_CENTER)
    cam.End3D2D()

    timer.Simple(2, function()
        self:SetNW2Bool("success", false)
    end)
end

function ENT:DrawFailure(pos, ang, scale, w, h)
    cam.Start3D2D(pos, ang, scale)
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(0, 0, w, h)

        draw.DrawText("Keycard Scanner", "Default", w / 2, 0, Color(255, 255, 255, 255),TEXT_ALIGN_CENTER)
        surface.SetMaterial(gModulesRun.SCPMaterial)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(w / 3.5, h / 4, 64, 64)

        draw.DrawText("FAILURE...", "Default", w / 2, h / 1.2, gModulesRun.ColorFailure, TEXT_ALIGN_CENTER)
    cam.End3D2D()

    timer.Simple(2, function()
        self:SetNW2Bool("failure", false)
    end)
end

function ENT:Draw()
    self:DrawModel()

    local pos = self:GetPos() +
    self:GetUp() * 2.7 +
    self:GetRight() * 15 +
    self:GetForward() * -3
    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Up(), 90)
    local scale = 0.1
    local w, h = 150, 140

    if self:GetNW2String("Stage") == gAccess.Stages[1] then --Password [Password input on keycard, send password]
        self:DrawPasswordInput(pos, ang, scale, w, h)
    else
        self:DrawBase(pos, ang, scale, w, h)
    end
end

function ENT:Initialize()
    print("[Debug] Loaded Entity")
end 

net.Receive("gBaseAccess_RunClientPasswordCheck", function()
    local ent = net.ReadEntity()
    local ply = LocalPlayer()

    if ent:GetClass() != gAccessConfig.ModuleClass then return end
    if not ent.Modules["Password"] then return end

    ent:SetNW2String("Stage", "Password")
end)

net.Receive("gBaseAccess_UpdateModules", function()
    local ent = net.ReadEntity()
    local modules = net.ReadString()
    local tableModules = util.JSONToTable(modules)

    if ent:GetClass() != gAccessConfig.ModuleClass then return end
    if not tableModules then return end

    ent.Modules = tableModules
end)

net.Receive("gBaseAccess_UpdateDNA", function()
    local ent = net.ReadEntity()
    local DNA = net.ReadString()
    local dnaTable = util.JSONToTable(DNA)

    if ent:GetClass() != gAccessConfig.ModuleClass then return end
    if not dnaTable then return end

    ent.dnaAccess = dnaTable
end)

net.Receive("gBaseAccess_UpdateOverrides", function()
    local ent = net.ReadEntity()
    local teams = net.ReadString()
    local teamTable = util.JSONToTable(teams)

    if ent:GetClass() != gAccessConfig.ModuleClass then return end
    if not teamTable then return end

    ent.TeamOverride = teamTable
end)