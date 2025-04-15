include("sh_gaccessconfigeditor.lua")
include("gaccesscontrol/lua/sh_gaccessconfig.lua")

function gAccess.RebuildFrame()
    if IsValid(gAccessConfig.Frame) then
        gAccessConfig.Frame:Remove()
    end
    gAccessConfig.BuildFrame()
end

gAccessConfig.CurrentEnt = nil

--Take a step back and think, This is going to turn into fucking shit code the more we add new shit. What we are going to now do: Start making functions modular

function gAccess.CreateButton(parent, Text, DockPos)
    local button = vgui.Create("DButton", parent)
    button:SetText(Text)
    button:Dock(DockPos)

    return button
end

function gAccess.CreateLabel(parent, Text, Alignment, Color, Pos)
    local label = vgui.Create("DLabel", parent)
    label:SetText(Text)
    label:SetSize(surface.GetTextSize(Text))
    label:SetContentAlignment(Alignment)
    label:SetTextColor(Color)
    label:SetPos(Pos[1], Pos[2])

    return label
end

function gAccess.CreateFrame(Size, Title)
    local frame = vgui.Create("DFrame")
    frame:SetSize(Size[1], Size[2])
    frame:Center()
    frame:SetDraggable(false)
    frame:SetTitle(Title)
    frame:MakePopup()

    return frame
end

function gAccess.CreateWang(Parent, Min, Max, Dock, Value)
    local wang = vgui.Create("DNumberWang", Parent or nil)
    wang:Dock(Dock)
    wang:SetMin(Min)
    wang:SetMax(Max)
    wang:SetValue(Value or 0)

    return wang
end

function gAccess.CreateScroll(Parent, Dock)
    local scrollPanel = vgui.Create("DScrollPanel", Parent)
    scrollPanel:Dock(Dock)

    return scrollPanel
end

function gAccess.CreatePanel(Parent, Dock, Size, DockMargin)
    local checkBoxPanel = vgui.Create("DPanel", Parent or nil)
    checkBoxPanel:Dock(Dock)
    checkBoxPanel:SetSize(Size[1], Size[2])
    checkBoxPanel:DockMargin(DockMargin[1], DockMargin[2], DockMargin[3], DockMargin[4])

    return checkBoxPanel
end

function gAccess.DoAccessLevel(panel, modules, entity)
    local edit = gAccess.CreateButton(panel, "Edit", RIGHT)

    edit.DoClick = function()
        local editFrame = gAccess.CreateFrame({300, 400}, "Edit Module: " .. modules) 
        local numberChanger = gAccess.CreateWang(editFrame, 0, 5, TOP, entity:GetNW2Int("AccessLevel"))
        local changeAccessLevel = gAccess.CreateButton(editFrame, "Submit", TOP)

        changeAccessLevel.DoClick = function()
            local accessValue = numberChanger:GetValue()

            if accessValue < 0 or accessValue > 5 then
                gAccessConfig.Frame:Close()
                timer.Simple(0.1, function()
                    if IsValid(entity) then
                        editFrame:Close()
                        gAccess.RebuildFrame()
                    end
                end)
            end

            net.Start("gBaseAccess_EditClearence")
            net.WriteEntity(entity)
            net.WriteUInt(accessValue, 3)
            net.SendToServer()

            gAccessConfig.Frame:Close()
            timer.Simple(0.1, function()
                if IsValid(entity) then
                    editFrame:Close()
                    gAccess.RebuildFrame()
                end
            end)
        end
    end
end

function gAccess.DoEditClick(entity, modules)
    local editFrame = gAccess.CreateFrame({300, 400}, "Edit Module: " .. modules) 

    local checkBoxPanel = gAccess.CreatePanel(editFrame, TOP, {150, 200}, {10, 10, 10, 10})

    local selectedOptions = {}

    local options = gAccessConfig.ModuleEditor[modules]
    for _, option in ipairs(options) do
        if modules == "Password" then
            gAccess.DoPassword(checkBoxPanel, editFrame, option, options, entity)
        end

        if modules == "Team Override" then
            gAccess.DoTeamOverride(checkBoxPanel, option, options, entity)
        end
                
            --Works, when people are removed it doesnt wrok
        if modules == "DNA" then
            gAccess.DoDNA(checkBoxPanel, entity, editFrame)
        end
    end
end

function gAccess.DoPassword(checkBoxPanel, editFrame, option, options, entity)
    local checkBox = gAccess.CreateButton(checkBoxPanel, option, TOP) 

    if option == options[1] then
        checkBox.DoClick = function()
            checkBox:SetEnabled(false)
            local passwordBox = gAccess.CreateWang(checkBoxPanel, 0, 999999, TOP)
            passwordBox:SetSize(45, 26)

            local passwordAccept = gAccess.CreateButton(checkBoxPanel, "Submit Password", BOTTOM)
                
            passwordAccept.DoClick = function()
                local password = passwordBox:GetValue()

                net.Start("gBaseAccess_EditPassword")
                net.WriteEntity(entity)
                net.WriteUInt(password, 21)
                net.SendToServer()

                gAccessConfig.Frame:Close()
                timer.Simple(0.1, function()
                    if IsValid(entity) then
                        editFrame:Close()
                        gAccess.RebuildFrame()
                    end
                end)
            end
        end
    elseif option == options[2] then
        print(entity:GetNW2Int("gAccess_Password"))
    end
end

function gAccess.DoTeamOverride(checkBoxPanel, option, options, entity)
    local checkBox = gAccess.CreateButton(checkBoxPanel, option, TOP)

    if option == options[1] then
        checkBox.DoClick = function()
            local teamList = gAccess.CreateScroll(checkBoxPanel, FILL)

            local teamsToAdd = gAccessConfig.Teams
            for _, team in pairs(teamsToAdd) do
                local teamCheckBox = gAccess.CreateLabel(teamList, team, 5, Color(0, 0, 0, 255), {10, 0})
                teamCheckBox:Dock(TOP)
                teamCheckBox:DockMargin(5, 5, 5, 0)

                local checkBox = vgui.Create("DCheckBox", teamCheckBox)
                checkBox:Dock(RIGHT)

                if entity.TeamOverride and entity.TeamOverride[team] then
                    checkBox:SetChecked(true)
                end

                checkBox.OnChange = function(self, val)
                    net.Start("gBaseAccess_SetOverride")
                    net.WriteEntity(entity)
                    net.WriteString(team)
                    net.WriteBool(val)
                    net.SendToServer()
                end

                teamList:Add(teamCheckBox)
            end
        end
    end
end

function gAccess.DoDNA(checkBoxPanel, entity, editFrame)
    local dnaList = gAccess.CreateScroll(checkBoxPanel, FILL)

    for sID, bool in pairs(entity.dnaAccess) do
        local panel = gAccess.CreatePanel(dnaList, TOP, {150, 15}, {10, 10, 10, 10})

        local label = gAccess.CreateLabel(panel, sID, 5, Color(0, 0, 0, 255), {10, 0})
        local checkBoxDNA = vgui.Create("DCheckBox", panel)
        checkBoxDNA:Dock(RIGHT)
        checkBoxDNA:SetChecked(bool)

        checkBoxDNA.OnChange = function()
            net.Start("gBaseAccess_RemoveDNAAccess")
            net.WriteString(label:GetText())
            net.WriteEntity(entity)
            net.SendToServer()

            gAccessConfig.Frame:Close()
            timer.Simple(0.1, function()
                if IsValid(entity) then
                    dnaList:Refresh()
                    editFrame:Close()
                    gAccess.RebuildFrame()
                end
            end)
        end

        dnaList:Add(panel)
    end

    local addBox = gAccess.CreateButton(editFrame, "Add", BOTTOM)

    addBox.DoClick = function()
        local text = vgui.Create("DTextEntry", checkBoxPanel)
        text:Dock(TOP)

        text.OnEnter = function(self)
            local str = self:GetValue()

            if string.match(str, "^STEAM_%d:%d+:%d+$") then
                net.Start("gBaseAccess_AddDNAAccess")
                net.WriteString(str)
                net.WriteEntity(entity)
                net.SendToServer()

                gAccessConfig.Frame:Close()
                timer.Simple(0.1, function()
                    if IsValid(entity) then
                        editFrame:Close()
                        gAccess.RebuildFrame()
                    end
                end)
            end
        end
    end
end

function gAccessConfig.BuildFrame()
    local entity = gAccessConfig.CurrentEnt
    gAccessConfig.Frame = gAccess.CreateFrame({500, 700}, "")

    gAccessConfig.Frame.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, Color(0, 0, 0, 220))
        draw.SimpleText("Keycard Config", "Default", 250, 5, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end 

    local scrollPanel = gAccess.CreateScroll(gAccessConfig.Frame, FILL)

    local doorPanel = scrollPanel:Add("DPanel")
    doorPanel:SetBGColor(0, 0, 0, 230)
    doorPanel:Dock(TOP)
    doorPanel:DockMargin(0, 0, 0, 5)

    local doorTextPanel = gAccess.CreateLabel(doorPanel, "Edit Door Linkage", 5, Color(0, 0, 0, 255), {10, 0})

    local changeDoors = gAccess.CreateButton(doorPanel, "Edit", RIGHT)

    changeDoors.DoClick = function()
        hook.Run("gBaseAccess_EditDoors", entity)
        gAccessConfig.Frame:Close()
    end

    for modules, value in pairs(entity.Modules) do
        local panel = scrollPanel:Add("DPanel")
        panel:SetBGColor(0, 0, 0, 230)
        panel:Dock(TOP)
        panel:DockMargin(0, 0, 0, 5)

        local textPanel = gAccess.CreateLabel(panel, modules, 5, Color(0, 0, 0, 255), {10, 0})

        if not value then
            local add = gAccess.CreateButton(panel, "Add", RIGHT)

            add.DoClick = function()
                net.Start("gBaseAccess_AddModule")
                net.WriteEntity(entity)
                net.WriteString(modules)
                net.SendToServer()

                gAccessConfig.Frame:Close()
                timer.Simple(0.1, function()
                    if IsValid(entity) then
                        gAccess.RebuildFrame()
                    end
                end)
            end

            continue
        end

        local remove = gAccess.CreateButton(panel, "Remove", RIGHT)

        remove.DoClick = function()
            net.Start("gBaseAccess_RemoveModule")
            net.WriteEntity(entity)
            net.WriteString(modules)
            net.SendToServer()

            gAccessConfig.Frame:Close()
            timer.Simple(0.1, function()
                if IsValid(entity) then
                    gAccess.RebuildFrame()
                end
            end)
        end

        if modules == "AccessLevel" then
            gAccess.DoAccessLevel(panel, modules, entity)
        end

        if not gAccessConfig.ModuleEditor[modules] then continue end

        local edit = gAccess.CreateButton(panel, "Edit", RIGHT) 

        edit.DoClick = function()
            gAccess.DoEditClick(entity, modules)
        end
    end
end

net.Receive("gAccessEditor", function()
    if not gAccessConfig.AllowedRanks[LocalPlayer():GetUserGroup()] then return end

    local entity = net.ReadEntity()
    if not IsValid(entity) or entity:GetClass() != gAccessConfig.ModuleClass then return end

    gAccessConfig.CurrentEnt = entity
    gAccessConfig.BuildFrame()
end)
