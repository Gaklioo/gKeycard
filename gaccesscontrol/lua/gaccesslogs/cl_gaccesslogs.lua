include("sh_gaccesslogs.lua")

gAccessLogs.StoredInfo = gAccessLogs.StoredInfo or {}
gAccessLogs.Frame = nil

function gAccessLogs.AddFrame(Size, Title)
    local frame = vgui.Create("DFrame")
    frame:SetSize(Size[1], Size[2])
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:Center()
    frame:MakePopup()

    frame.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, Color(0, 0, 0, 180))
        draw.DrawText(Title, "Default", w / 2, h / 50, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)
    end

    return frame
end

function gAccessLogs.CreateScroll(Parent, Dock)
    local scrollPanel = vgui.Create("DScrollPanel", Parent)
    scrollPanel:Dock(Dock)

    return scrollPanel
end

function gAccessLogs.CreatePanel(Parent, Dock, Size, DockMargin)
    local checkBoxPanel = vgui.Create("DPanel", Parent or nil)
    checkBoxPanel:Dock(Dock)
    checkBoxPanel:SetSize(Size[1], Size[2])
    checkBoxPanel:DockMargin(DockMargin[1], DockMargin[2], DockMargin[3], DockMargin[4])

    return checkBoxPanel
end

function gAccessLogs.CreateLabel(parent, Text, Alignment, Color, Pos)
    local label = vgui.Create("DLabel", parent)
    label:SetText(Text)
    label:SetSize(surface.GetTextSize(Text))
    label:SetContentAlignment(Alignment)
    label:SetTextColor(Color)
    label:SetPos(Pos[1], Pos[2])

    return label
end

net.Receive("gAccessLogs_SendClient", function()
    print("recievedc")
    local str = net.ReadString()
    table.insert(gAccessLogs.StoredInfo, str)

    if #gAccessLogs.StoredInfo > 200 then
        table.remove(gAccessLogs.StoredInfo, 1)
        print("Removed earliest access log, to much accessing happening")
    end
end)

hook.Add("OnPlayerChat", "gAccessLogs_ClientView", function(ply, text, teamChat, isDead)
    local text = string.lower(text)

    if isDead then return end
    if text != "/viewaccess" then return end
    --if not gAccessLogs.ViewTeam[ply:GetTeam()] then return end
    if gAccessLogs.Frame then return end

    local x, y = ScrW() / 2, ScrH() / 2
    local w, h = surface.GetTextSize(tostring(gAccessLogs.StoredInfo[1]))
    gAccessLogs.Frame = gAccessLogs.AddFrame({x, y}, "[Site-Sigma Access Logs]")
    local scroll = gAccessLogs.CreateScroll(gAccessLogs.Frame, FILL)

    for i = #gAccessLogs.StoredInfo, 1, -1 do
        local panel = gAccessLogs.CreatePanel(nil, TOP, {w + 10, h + 10}, {5, 5, 5, 5})
        panel:SetBGColor(0, 0, 0, 200)
        local text = gAccessLogs.CreateLabel(panel, gAccessLogs.StoredInfo[i], 5, Color(0, 0, 0, 200), {20, 5})
        text:SetSize(w, h)

        scroll:Add(panel)
    end

    gAccessLogs.Frame.OnClose = function ()
        gAccessLogs.Frame = nil
    end
end)