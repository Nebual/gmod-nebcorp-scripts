// =======================================
// NADMOD - Nebcorp Administration Designation Module - Clientside
// =======================================

CreateConVar("nadmod_whisperrange", 400, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
net.Receive("nadmod_pm",function(len) chat.AddText(Color(net.ReadUInt(8),net.ReadUInt(8),net.ReadUInt(8)),net.ReadString(),Color(130,150,255), " [PM]: "..net.ReadString()) end)
net.Receive("nadmod_w",function(len) chat.AddText(Color(net.ReadUInt(8),net.ReadUInt(8),net.ReadUInt(8)),net.ReadString(),Color(200,200,255), " whispers: "..net.ReadString()) end)
net.Receive("nadmod_say",function(len) chat.AddText(Color(net.ReadUInt(8),net.ReadUInt(8),net.ReadUInt(8)),net.ReadString(),Color(255,255,255), ": "..net.ReadString()) end)
net.Receive("nadmod_msg",function(len) chat.AddText(Color(240,180,60),"Gman",Color(255,255,255), ": "..net.ReadString()) end)
hook.Add("OnPlayerChat", "NADMOD_BlankItOut", function(a,b,c) return true end)

net.Receive("NADMOD.BuildMode",function(len) 
	if net.ReadBit() != 0 then
		hook.Remove("SpawnMenuOpen", "NADMOD.BuildDisable")
		timer.Remove("NADMOD.BuildDisableThink")
	else
		hook.Add( "SpawnMenuOpen", "NADMOD.BuildDisable", function() return false end)
		timer.Create("NADMOD.BuildDisableThink",1,0,function()
			if LocalPlayer():GetActiveWeapon().ClassName == "gmod_tool" then RunConsoleCommand("gmod_tool","balloon") end
		end)
	end
end)

//local lastWhisper = 0
local function drawWhisperTargets()
	//if lastWhisper + 15 < CurTime() then hook.Remove("HUDPaint", "NADMOD_WhisperTargets") return end
	local nearbyplayers = "In whisper range: "
	for k,v in pairs(player.GetAll()) do if v:GetPos():Distance(LocalPlayer():GetPos()) < GetConVarNumber("nadmod_whisperrange") then nearbyplayers = nearbyplayers .. v:Nick() .. ", " end end
	draw.DrawText(string.sub(nearbyplayers, 0, -3), "ScoreboardDefault", 35, ScrH() * 0.83, Color(25,25,75,220))
end
local whisperon
local function hookWhisperTargets(teamchat)
	if !teamchat then 
		if whisperon then 
			whisperon = false
			hook.Remove("PostRenderVGUI", "NADMOD_WhisperTargets")
			hook.Remove("FinishChat", "NADMOD_WhisperTargets")
		end
	else
		whisperon = true
		hook.Add("PostRenderVGUI", "NADMOD_WhisperTargets", drawWhisperTargets)
		hook.Add("FinishChat", "NADMOD_WhisperTargets", hookWhisperTargets)
	end
end
hook.Add("StartChat", "NADMOD_WhisperTargets", hookWhisperTargets)

net.Receive("nadmod_maplist",function(len) 
	local DermaPanel = vgui.Create( "DFrame" )
	DermaPanel:SetSize( 500, 700 )
	DermaPanel:MakePopup()
	DermaPanel:Center()
	DermaPanel:SetTitle( "ChangeMap Selection" )
	DermaPanel:SetVisible( true )
	DermaPanel:SetDraggable( true )
	DermaPanel:ShowCloseButton( true )
	
	local DermaListView = vgui.Create("DListView")
	DermaListView:SetParent(DermaPanel)
	DermaListView:SetPos(10, 35)
	DermaListView:SetSize(480, 615)
	DermaListView:SetMultiSelect(false)
	DermaListView:AddColumn("Map Name")
	DermaListView:AddColumn("Times Played")
	DermaListView:SortByColumn(2)
	local mapname = false
	local oldOnClickLine = DermaListView.OnClickLine
	
	function DermaListView:OnClickLine(Line, bClear )
		oldOnClickLine(DermaListView,Line,bClear)
		mapname = Line:GetValue(1)
	end
	
	for k,v in pairs(net.ReadTable()) do
		DermaListView:AddLine(k,v)
	end
	
	local NumSlider = vgui.Create( "DNumSlider", DermaPanel )
	NumSlider:SetPos( 20,660 )
	NumSlider:SetWide( 200 )
	NumSlider:SetText( "Countdown to Mapchange" )
	NumSlider:SetMin( 0 ) -- Minimum number of the slider
	NumSlider:SetMax( 120 ) -- Maximum number of the slider
	NumSlider:SetDecimals( 0 ) -- Sets a decimal. Zero means it's a whole number
	
	local button = vgui.Create("Button")
	button:SetParent(DermaPanel)
	button:SetSize( 200,30 )
	button:SetPos(250, 660)
	button:SetText( "Changemap!" )
	button:SetVisible( true )
	button.DoClick = function()
		if mapname then 
			RunConsoleCommand("nadmod_maplistchange", mapname, tostring(NumSlider:GetValue() or 5))
			DermaPanel:Remove()
		end
	end
end )

concommand.Add("nadmod_open", function(ply)
	if !ply:IsAdmin() then return end
	
	//local window = vgui.Create("DFrame") window:SetSize(500,500) window:Center() window:MakePopup() local color=vgui.Create("DColorCube",window) color:SetSize(400,400) timer.Simple(5,function() window:Close() end)
	local window = vgui.Create( "DFrame" )
	window:SetSize( 215,70 )
	window:Center()
	window:SetTitle( "NADMOD Menu" )
	window:MakePopup()
 
	local button1 = vgui.Create( "DButton", window )
	button1:SetSize( 100, 38 )
	button1:SetPos( 5, 27 )
	button1:SetText( "Groups" )
	button1.DoClick = function( button1 )
		RunConsoleCommand("nadmod_menu", "groups")
		window:Close()
	end
	local button2 = vgui.Create( "DButton", window )
	button2:SetSize( 100, 38 )
	button2:SetPos( 110, 27 )
	button2:SetText( "User Accounts" )
	button2.DoClick = function( button2 )
		RunConsoleCommand("nadmod_menu", "users")
		window:Close()
	end
end)

net.Receive("nadmod_menu_download", function( len ) 
	local decoded = net.ReadTable()
	local ret,perms = decoded[2], decoded[3]
	if decoded[1] == "groups" then
		local weps = decoded[4]
		local color = Color(125,125,125)
		local checkbox_ignore = true
		local currank = 1
	
		local window = vgui.Create( "DFrame" )
		window:SetSize( 960,432 )
		window:Center()
		window:SetTitle( "NADMOD Groups Menu" )
		window:MakePopup()
		
		-- PERMISSIONS
		local PermsPanel = vgui.Create( "DPanelList", window)
		PermsPanel:SetPos(640, 27)
		PermsPanel:SetSize(195, 400)
		PermsPanel:SetSpacing(10)
		PermsPanel:SetPadding(10)
		PermsPanel:EnableHorizontal(false)
		PermsPanel:EnableVerticalScrollbar(true)
		local PermsBoxes = {}
		for k,v in pairs(perms) do
			local checkbox = vgui.Create("DCheckBoxLabel")
			checkbox:SetText(k..": "..v)
			checkbox:SizeToContents()
			checkbox.OnChange = function()
				if checkbox_ignore then return end
				local bool = checkbox:GetChecked()
				if bool then table.insert(ret[currank].Permissions, k)
				else
					for i,name in ipairs(ret[currank].Permissions) do
						if name == k then table.remove(ret[currank].Permissions,i) end
					end
				end
			end
			PermsPanel:AddItem(checkbox)
			PermsBoxes[k] = checkbox
		end
		-- Weapon Loadouts
		local WepsPanel = vgui.Create( "DPanelList", window)
		WepsPanel:SetPos(840, 27)
		WepsPanel:SetSize(115, 400)
		WepsPanel:SetSpacing(10)
		WepsPanel:SetPadding(10)
		WepsPanel:EnableHorizontal(false)
		WepsPanel:EnableVerticalScrollbar(true)
		local WepsBoxes = {}
		for k,v in pairs(weps) do
			local checkbox = vgui.Create("DCheckBoxLabel")
			checkbox:SetText(k)
			checkbox:SizeToContents()
			checkbox.OnChange = function()
				if checkbox_ignore then return end
				local bool = checkbox:GetChecked()
				if bool then table.insert(ret[currank].Loadout, k)
				else
					for i,name in ipairs(ret[currank].Loadout) do
						if name == k then table.remove(ret[currank].Loadout,i) end
					end
				end
			end
			WepsPanel:AddItem(checkbox)
			WepsBoxes[k] = checkbox
		end
		
		-- COLOR SELECTOR
		local ColorCube = vgui.Create("DColorCube", window)
		local RGBBar = vgui.Create( "DRGBPicker", window )
		local lred = vgui.Create("DLabel", window)
		local tred = vgui.Create("DTextEntry", window)
		local lgreen = vgui.Create("DLabel", window)
		local tgreen = vgui.Create("DTextEntry", window)
		local lblue = vgui.Create("DLabel", window)
		local tblue = vgui.Create("DTextEntry", window)
		local lexample = vgui.Create("DLabel", window)
		local function UpdateColor(c)
			color = c
			RGBBar:SetRGB(c)
			ColorCube:SetBaseRGB(c)
			ColorCube:SetColor( c )
			tred:SetText(c.r)
			tgreen:SetText(c.g)
			tblue:SetText(c.b)
			lexample:SetTextColor(c)
			ret[currank].Color = c
		end
		RGBBar:SetSize(40,365)
		RGBBar:SetPos(225,27)
		RGBBar.OnChange = function( ctrl, changedcolor )
			UpdateColor(changedcolor)
		end
		ColorCube:SetSize(365,365)
		ColorCube:SetPos(270,27)
		ColorCube.OnUserChanged = function() 
			UpdateColor(ColorCube:GetRGB())
		end
		
		lred:SetText("R:")
		lred:SizeToContents()
		lred:SetPos(250, 402)
		tred:SetSize(40, 20)
		tred:SetPos(270, 407)
		tred.OnEnter = function() color.r = tonumber(tred:GetValue()) UpdateColor(color) end
		lgreen:SetText("G:")
		lgreen:SizeToContents()
		lgreen:SetPos(315, 402)
		tgreen:SetSize(40, 20)
		tgreen:SetPos(335, 407)
		tgreen.OnEnter = function() color.g = tonumber(tgreen:GetValue()) UpdateColor(color) end
		lblue:SetText("B:")
		lblue:SizeToContents()
		lblue:SetPos(380, 402)
		tblue:SetSize(40, 20)
		tblue:SetPos(400, 407)
		tblue.OnEnter = function() color.b = tonumber(tblue:GetValue()) UpdateColor(color) end
		lexample:SetText("Test Name:")
		lexample:SetFont("ChatFont")
		lexample:SizeToContents()
		lexample:SetPos(445, 402)
		-- END COLOR SELECTOR
		

		local DermaListView = vgui.Create("DListView",window)
		DermaListView:SetPos(5, 27)
		DermaListView:SetSize(110, 365)
		DermaListView:SetMultiSelect(false)
		local column1 = DermaListView:AddColumn("Rank") -- Add column
		column1:SetMinWidth( 32 )
		column1:SetMaxWidth( 32 )
		DermaListView:AddColumn("Name")
		DermaListView.OnClickLine = function(parent, line, isselected)
			line:SetSelected( true )
			-- ===========
			-- This is the main "selected a different rank"
			-- ===========
			currank = line:GetValue(1)
			DermaListView:ClearSelection()
			UpdateColor( ret[currank].Color )
			checkbox_ignore = true
			for k,v in pairs(PermsBoxes) do
				v:SetValue(0)
				for _,perm in ipairs(ret[currank].Permissions) do
					if perm == k then v:SetValue(1) end
				end
			end
			for k,v in pairs(WepsBoxes) do
				v:SetValue(0)
				for _,wep in ipairs(ret[currank].Loadout) do
					if wep == k then v:SetValue(1) end
				end
			end
			checkbox_ignore = false
		end
		for k,v in pairs(ret) do
			DermaListView:AddLine(k,v.Name) -- Add lines
		end
		
		local button1 = vgui.Create( "DButton", window )
		button1:SetSize( 95, 30 )
		button1:SetPos( 120, 397 )
		button1:SetText( "Save and Upload" )
		button1.DoClick = function( button1 )
			ret[1] = decoded[2][1]
			net.Start("nadmod_menu_upload")
				net.WriteString("groups")
				net.WriteTable(ret)
			net.SendToServer()
			window:Close()
		end
		
		local button2 = vgui.Create( "DButton", window )
		button2:SetSize( 95, 30 )
		button2:SetPos( 120, 362 )
		button2:SetText( "Cancel" )
		button2.DoClick = function( button2 )
			window:Close()
		end
		
		local button3 = vgui.Create( "DButton", window )
		button3:SetSize( 110, 30 )
		button3:SetPos( 5, 397 )
		button3:SetText( "New Class" )
		button3.DoClick = function( button3 )
			local tempframe = vgui.Create( "DFrame" )
			tempframe:SetSize( 190,62 )
			tempframe:Center()
			tempframe:SetTitle( "Rank Maker" )
			tempframe:MakePopup()
			
			local label = vgui.Create("DLabel", tempframe)
			label:SetText("New Rank #:")
			label:SizeToContents()
			label:SetPos(5, 37)
			
			local temprank,tempname
			local function TestBoth()
				if temprank && tempname then
					ret[temprank] = {Name = tempname, Color = Color(110,110,110), Permissions = {}, Loadout = {"GravGun","PhysGun","ToolGun","Camera"}}
					DermaListView:AddLine(temprank, tempname)
					tempframe:Close()
				end
			end
			
			local textrank = vgui.Create("DTextEntry", tempframe)
			textrank:SetSize(20, 30)
			textrank:SetPos(75, 27)
			textrank.OnEnter = function() 
				local value = tonumber(textrank:GetValue())
				if !ret[value] then
					temprank = value
					TestBoth()
				end
			end
			
			local textname = vgui.Create("DTextEntry", tempframe)
			textname:SetSize(85, 30)
			textname:SetPos(100, 27)
			textname.OnEnter = function() 
				tempname = textname:GetValue() 
				TestBoth() 
			end
		end
		
		local button4 = vgui.Create( "DButton", window )
		button4:SetSize( 80, 20 )
		button4:SetPos( 20, 366 )
		button4:SetText( "Delete Class" )
		button4.DoClick = function( button4 )
			ret[currank] = nil
			currank = 1
			DermaListView:Clear()
			for k,v in pairs(ret) do
				DermaListView:AddLine(k,v.Name) -- Add lines
			end
		end
elseif decoded[1] == "users" then
		local Groups,weps = decoded[4], decoded[5]
		local color = Color(125,125,125)
		local checkbox_ignore = true
		local curid = "temp"
		ret[curid] = {}
		local currank = 1
	
		local window = vgui.Create( "DFrame" )
		window:SetSize( 1060,432 )
		window:Center()
		window:SetTitle( "NADMOD Players Menu" )
		window:MakePopup()
		
		local DermaListView = vgui.Create("DListView",window)
		local buttonSave = vgui.Create( "DButton", window )
		local buttonCancel = vgui.Create( "DButton", window )
		local rankLabel = vgui.Create("DLabel", window)
		local rankSelect = vgui.Create( "DComboBox", window )
		local buttonResetColor = vgui.Create( "DButton", window )
		local buttonResetPerms = vgui.Create( "DButton", window )
		local buttonResetWeps = vgui.Create( "DButton", window )
		local ColorCube = vgui.Create("DColorCube", window)
		local RGBBar = vgui.Create( "DRGBPicker", window )
		local lred = vgui.Create("DLabel", window)
		local tred = vgui.Create("DTextEntry", window)
		local lgreen = vgui.Create("DLabel", window)
		local tgreen = vgui.Create("DTextEntry", window)
		local lblue = vgui.Create("DLabel", window)
		local tblue = vgui.Create("DTextEntry", window)
		local lexample = vgui.Create("DLabel", window)
		local PermsPanel = vgui.Create( "DPanelList", window)
		local PermsBoxes = {}
		local WepsPanel = vgui.Create( "DPanelList", window)
		local WepsBoxes = {}
		
		local function UpdateColor(c)
			color = c
			RGBBar:SetRGB(c)
			ColorCube:SetBaseRGB(c)
			ColorCube:SetColor( c )
			tred:SetText(c.r)
			tgreen:SetText(c.g)
			tblue:SetText(c.b)
			lexample:SetTextColor(c)
			if c != Groups[currank].Color then 
				ret[curid].Color = c 
				buttonResetColor:SetText( "* Reset Color" )
			else 
				ret[curid].Color = nil
				buttonResetColor:SetText( "Reset Color" )
			end
		end
		
	------ LIST OF PLAYERS
		DermaListView:SetPos(5, 27)
		DermaListView:SetSize(230, 365)
		DermaListView:SetMultiSelect(false)
		local column1 = DermaListView:AddColumn("SteamID") -- Add column
		column1:SetMinWidth( 70 )
		column1:SetMaxWidth( 70 )
		local column2 = DermaListView:AddColumn("Rank") -- Add column
		column2:SetMinWidth( 55 )
		column2:SetMaxWidth( 55 )
		DermaListView:AddColumn("Name")
		DermaListView.OnClickLine = function(parent, line, isselected)
			line:SetSelected( true )
			-- ===========
			-- This is the main "selected a different user"
			-- ===========
			curid = "STEAM_0:" .. line:GetValue(1)
			currank = ret[curid].Rank
			DermaListView:ClearSelection()
			UpdateColor( ret[curid].Color or Groups[currank].Color )
			checkbox_ignore = true
			for k,v in pairs(PermsBoxes) do
				v:SetValue(0)
				for _,perm in ipairs(ret[curid].Permissions or {}) do
					if perm == k then v:SetValue(1) end
				end
				for _,perm in ipairs(Groups[currank].Permissions) do
					if perm == k then v:SetValue(1) end
				end
			end
			for k,v in pairs(WepsBoxes) do
				v:SetValue(0)
				for _,perm in ipairs(ret[curid].Loadout or {}) do
					if perm == k then v:SetValue(1) end
				end
				for _,perm in ipairs(Groups[currank].Loadout) do
					if perm == k then v:SetValue(1) end
				end
			end
			checkbox_ignore = false
			if ret[curid].Permissions then buttonResetPerms:SetText("* Reset Perms") else buttonResetPerms:SetText("Reset Perms") end
			if ret[curid].Loadout then buttonResetWeps:SetText("* Reset Weps") else buttonResetWeps:SetText("Reset Weps") end
			rankSelect:SetText("["..currank.."] "..Groups[currank].Name)
		end
		for k,v in pairs(ret) do
			if k != "temp" then DermaListView:AddLine(string.sub(k, 9), Groups[v.Rank].Name, v.Nick or "-Outdated-") end
		end
		
	------ BUTTONS
		
		buttonSave:SetSize( 115, 30 )
		buttonSave:SetPos( 120, 397 )
		buttonSave:SetText( "Save and Upload" )
		buttonSave.DoClick = function()
			ret.temp = nil
			net.Start("nadmod_menu_upload")
				net.WriteString("users")
				net.WriteTable(ret)
			net.SendToServer()
			window:Close()
		end

		buttonCancel:SetSize( 110, 30 )
		buttonCancel:SetPos( 5, 397 )
		buttonCancel:SetText( "Cancel" )
		buttonCancel.DoClick = function() window:Close() end
		
		rankLabel:SetText("Rank Adjuster:")
		rankLabel:SizeToContents()
		rankLabel:SetPos(245, 27)
		rankSelect:SetSize(80,25)
		rankSelect:SetPos( 240, 45 )
		rankSelect.OnSelect = function(i,value,data) 
			currank = tonumber(string.sub(data,2,string.find(data,"]")-1))
			ret[curid].Rank = currank
			if !ret[curid].Color then UpdateColor(Groups[currank].Color) end
			checkbox_ignore = true
			for k,v in pairs(PermsBoxes) do
				v:SetValue(0)
				for _,perm in ipairs(ret[curid].Permissions or {}) do
					if perm == k then v:SetValue(1) end
				end
				for _,perm in ipairs(Groups[currank].Permissions) do
					if perm == k then v:SetValue(1) end
				end
			end
			checkbox_ignore = false
		end
		for k,v in pairs(Groups) do
			rankSelect:AddChoice("["..k.."] "..v.Name)
		end
		
		buttonResetColor:SetSize( 80, 30 )
		buttonResetColor:SetPos( 240, 77 )
		buttonResetColor:SetText( "Reset Color" )
		buttonResetColor.DoClick = function()
			UpdateColor(Groups[currank].Color)
		end
		
		buttonResetPerms:SetSize( 80, 30 )
		buttonResetPerms:SetPos( 240, 112 )
		buttonResetPerms:SetText( "Reset Perms" )
		buttonResetPerms.DoClick = function(  )
			ret[curid].Permissions = nil
			checkbox_ignore = true
			for k,v in pairs(PermsBoxes) do
				v:SetValue(0)
				for _,perm in ipairs(Groups[currank].Permissions) do
					if perm == k then v:SetValue(1) end
				end
			end
			checkbox_ignore = false
			buttonResetPerms:SetText("Reset Perms")
		end
		buttonResetWeps:SetSize( 80, 30 )
		buttonResetWeps:SetPos( 240, 147 )
		buttonResetWeps:SetText( "Reset Weps" )
		buttonResetWeps.DoClick = function(  )
			ret[curid].Loadout = nil
			checkbox_ignore = true
			for k,v in pairs(WepsBoxes) do
				v:SetValue(0)
				for _,perm in ipairs(Groups[currank].Loadout) do
					if perm == k then v:SetValue(1) end
				end
			end
			checkbox_ignore = false
			buttonResetWeps:SetText("Reset Weps")
		end
		
	------ COLOR SELECTOR
		RGBBar:SetSize(40,365)
		RGBBar:SetPos(325,27)
		RGBBar.OnChange = function( ctrl, changedcolor )
			UpdateColor(changedcolor)
		end
		ColorCube:SetSize(365,365)
		ColorCube:SetPos(370,27)
		ColorCube.OnUserChanged = function() 
			UpdateColor(ColorCube:GetRGB())
		end
		
		lred:SetText("R:")
		lred:SizeToContents()
		lred:SetPos(375, 402)
		tred:SetSize(40, 20)
		tred:SetPos(395, 402)
		tred.OnEnter = function() color.r = tonumber(tred:GetValue()) UpdateColor(color) end
		lgreen:SetText("G:")
		lgreen:SizeToContents()
		lgreen:SetPos(440, 402)
		tgreen:SetSize(40, 20)
		tgreen:SetPos(460, 402)
		tgreen.OnEnter = function() color.g = tonumber(tgreen:GetValue()) UpdateColor(color) end
		lblue:SetText("B:")
		lblue:SizeToContents()
		lblue:SetPos(505, 402)
		tblue:SetSize(40, 20)
		tblue:SetPos(525, 402)
		tblue.OnEnter = function() color.b = tonumber(tblue:GetValue()) UpdateColor(color) end
		lexample:SetText("Test Name:")
		lexample:SetFont("ChatFont")
		lexample:SizeToContents()
		lexample:SetPos(570, 402)
		-- END COLOR SELECTOR
		
	------ PERMISSIONS CHECKBOXES
		PermsPanel:SetPos(740, 27)
		PermsPanel:SetSize(195, 400)
		PermsPanel:SetSpacing(10)
		PermsPanel:SetPadding(10)
		PermsPanel:EnableHorizontal(false)
		PermsPanel:EnableVerticalScrollbar(true)
		for k,v in pairs(perms) do
			local checkbox = vgui.Create("DCheckBoxLabel")
			checkbox:SetText(k..": "..v)
			checkbox:SizeToContents()
			checkbox.OnChange = function()
				if checkbox_ignore then return end
				local bool = checkbox:GetChecked()
				if bool then 
					ret[curid].Permissions = ret[curid].Permissions or {}
					table.insert(ret[curid].Permissions, k)
				else
					checkbox_ignore = true
					for _,perm in ipairs(Groups[currank].Permissions) do
						-- Make sure they don't turn off any permissions inherited from their Rank
						if perm == k then checkbox:SetValue(1) checkbox_ignore = false return end
					end
					checkbox_ignore = false
					for i,name in ipairs(ret[curid].Permissions) do
						if name == k then table.remove(ret[curid].Permissions,i) end
					end
					if !next(ret[curid].Permissions) then ret[curid].Permissions = nil end
				end
				if ret[curid].Permissions then buttonResetPerms:SetText("* Reset Perms") else buttonResetPerms:SetText("Reset Perms") end
			end
			PermsPanel:AddItem(checkbox)
			PermsBoxes[k] = checkbox
		end
		
		-- Weapon Loadouts
		
		WepsPanel:SetPos(940, 27)
		WepsPanel:SetSize(115, 400)
		WepsPanel:SetSpacing(10)
		WepsPanel:SetPadding(10)
		WepsPanel:EnableHorizontal(false)
		WepsPanel:EnableVerticalScrollbar(true)
		for k,v in pairs(weps) do
			local checkbox = vgui.Create("DCheckBoxLabel")
			checkbox:SetText(k)
			checkbox:SizeToContents()
			checkbox.OnChange = function()
				if checkbox_ignore then return end
				local bool = checkbox:GetChecked()
				if bool then 
					ret[curid].Loadout = ret[curid].Loadout or {}
					table.insert(ret[curid].Loadout, k)
				else
					checkbox_ignore = true
					for _,perm in ipairs(Groups[currank].Loadout) do
						-- Make sure they don't turn off any Loadouts inherited from their Rank
						if perm == k then checkbox:SetValue(1) checkbox_ignore = false return end
					end
					checkbox_ignore = false
					for i,name in ipairs(ret[curid].Loadout) do
						if name == k then table.remove(ret[curid].Loadout,i) end
					end
					if !next(ret[curid].Loadout) then ret[curid].Loadout = nil end
				end
				if ret[curid].Loadout then buttonResetWeps:SetText("* Reset Weps") else buttonResetWeps:SetText("Reset Weps") end
			end
			WepsPanel:AddItem(checkbox)
			WepsBoxes[k] = checkbox
		end
	end
end)
