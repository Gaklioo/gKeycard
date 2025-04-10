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
    wang:SetMin(min)
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

function gAccessConfig.BuildFrame()
    local entity = gAccessConfig.CurrentEnt
    gAccessConfig.Frame = gAccess.CreateFrame({500, 700}, "")

    gAccessConfig.Frame.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, Color(0, 0, 0, 220))
        draw.SimpleText("Keycard Config", "Default", 250, 5, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    end 

    local scrollPanel = gAccess.CreateScroll(gAccessConfig.Frame, FILL)

    for k, v in pairs(entity.Modules) do
        print(k .. " " .. tostring(v))    
    end

    for modules, value in pairs(entity.Modules) do
        local panel = scrollPanel:Add("DPanel")
        panel:SetBGColor(0, 0, 0, 230)
        panel:Dock(TOP)
        panel:DockMargin(0, 0, 0, 5)

        local textPanel = gAccess.CreateLabel(panel, modules, 5, Color(0, 0, 0, 255), {10, 0})

        if value then
            local add = gAccess.CreateButton(panel, "Remove", RIGHT)

            add.DoClick = function()
                net.Start("gBaseAccess_RemoveModule")
                net.WritePlayer(LocalPlayer())
                net.WriteEntity(entity)
                net.WriteString(modules)
                net.SendToServer()

                gAccessConfig.Frame:Close()
                timer.Simple(0.1, function()
                    if IsValid(entity) then
                        gAccess.RebuildFrame(entity)
                    end
                end)
            end

            if modules == "AccessLevel" then
                local edit = gAccess.CreateButton(panel, "Edit", RIGHT)

                edit.DoClick = function()
                    local editFrame = gAccess.CreateFrame({300, 400}, "Edit Module: " .. modules) 
                    local numberChanger = gAccess.CreateWang(editFrame, 0, 5, TOP, entity:GetNW2Int("AccessLevel"))
                    local changeAccessLevel = gAccess.CreateButton(editFrame, "Submit", TOP)

                    changeAccessLevel.DoClick = function()
                        local accessValue = numberChanger:GetValue()

                        net.Start("gBaseAccess_EditClearence")
                        net.WritePlayer(LocalPlayer())
                        net.WriteEntity(entity)
                        net.WriteUInt(accessValue, 3)
                        net.SendToServer()

                        gAccessConfig.Frame:Close()
                        timer.Simple(0.1, function()
                            if IsValid(entity) then
                                editFrame:Close()
                                gAccess.RebuildFrame(entity)
                            end
                        end)
                    end
                end
            end

            if not gAccessConfig.ModuleEditor[modules] then continue end

            local edit = gAccess.CreateButton(panel, "Edit", RIGHT) 

            if gAccessConfig.ModuleEditor[modules] then
                edit.DoClick = function()
                    local editFrame = gAccess.CreateFrame({300, 400}, "Edit Module: " .. modules) 

                    local checkBoxPanel = gAccess.CreatePanel(editFrame, TOP, {150, 200}, {10, 10, 10, 10})

                    local selectedOptions = {}

                    local options = gAccessConfig.ModuleEditor[modules]
                    for _, option in ipairs(options) do
                        local arr = gAccessConfig.ModuleEditor[modules]

                        if modules == "Password" then
                            local checkBox = gAccess.CreateButton(checkBoxPanel, option, TOP) 

                            if option == arr[1] then
                                checkBox.DoClick = function()
                                    checkBox:SetEnabled(false)
                                    local passwordBox = gAccess.CreateWang(checkBoxPanel, 0, 999999, TOP)
                                    passwordBox:SetSize(45, 26)

                                    local passwordAccept = gAccess.CreateButton(checkBoxPanel, "Submit Password", BOTTOM)
                                    
                                    passwordAccept.DoClick = function()
                                        local password = passwordBox:GetValue()

                                        net.Start("gBaseAccess_EditPassword")
                                        net.WritePlayer(LocalPlayer())
                                        net.WriteEntity(entity)
                                        net.WriteUInt(password, 21)
                                        net.SendToServer()

                                        gAccessConfig.Frame:Close()
                                        timer.Simple(0.1, function()
                                            if IsValid(entity) then
                                                editFrame:Close()
                                                gAccess.RebuildFrame(entity)
                                            end
                                        end)
                                    end
                                end
                            elseif option == arr[2] then
                                print(entity:GetNW2Int("gAccess_Password"))
                            end
                        end

                        if modules == "Team Override" then
                            local checkBox = gAccess.CreateButton(checkBoxPanel, option, TOP)

                            if option == arr[1] then
                                checkBox.DoClick = function()
                                    local teamList = gAccess.CreateScroll(checkBoxPanel, FILL)

                                    local teamsToAdd = gAccessConfig.Teams
                                    for _, team in pairs(teamsToAdd) do
                                        local teamCheckBox = gAccess.CreateLabel(teamList, team, 5, Color(0, 0, 0, 255), {10, 0})
                                        teamCheckBox:Dock(TOP)
                                        teamCheckBox:DockMargin(5, 5, 5, 0)

                                        local checkBox = vgui.Create("DCheckBox", teamCheckBox)
                                        checkBox:Dock(RIGHT)

                                        if entity.TeamOverride then
                                            if entity.TeamOverride[team] then
                                                checkBox:SetChecked(true)
                                            end
                                        end

                                        checkBox.OnChange = function(self, val)
                                            net.Start("gBaseAccess_SetOverride")
                                            net.WritePlayer(LocalPlayer())
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
                    end
                end
            end
        else
            local add = gAccess.CreateButton(panel, "Add", RIGHT)

            add.DoClick = function()
                net.Start("gBaseAccess_AddModule")
                net.WritePlayer(LocalPlayer())
                net.WriteEntity(entity)
                net.WriteString(modules)
                net.SendToServer()

                gAccessConfig.Frame:Close()
                timer.Simple(0.1, function()
                    if IsValid(entity) then
                        gAccess.RebuildFrame(entity)
                    end
                end)
            end
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
