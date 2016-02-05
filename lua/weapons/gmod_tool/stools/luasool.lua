TOOL.Category		= "Construction"
TOOL.Name			= "#tool.luasool.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "code" ] = ""
TOOL.ClientConVar[ "codename" ] = ""
local LoolList = {}
local maindir = "nebcorp/"

LUASOOLTOOL = TOOL
LUASOOLTOOL.ListBoxParams = { Label = "Public Lools", Height = 125, MenuButton = "0", Options = {} }


if SERVER then
	LuaSoolTables = {}
	util.AddNetworkString("UpdatedLoolList")
	util.AddNetworkString("luasool_save_lool")
	function UpdateLoolList(ply, cmd, args)
		print(ply:Nick().." asked for UpdateLoolList")
		net.Start("UpdatedLoolList") net.WriteString(file.Read("nebcorp/luasools.txt","DATA") or '{"ModelPrint":"say(this:GetModel())"}') net.Send(ply)
	end
	concommand.Add("luasool_update_loollist", UpdateLoolList)

	
	local function SaveLuaSool( netlen, ply )
		if !ply:IsAdmin() then return end
		local lools = util.JSONToTable(file.Read("nebcorp/luasools.txt","DATA") or "{}")
		lools[net.ReadString()] = net.ReadString()
		file.Write("nebcorp/luasools.txt", util.TableToJSON(lools))
	end
	net.Receive( "luasool_save_lool", SaveLuaSool )
	
	local function AcceptLuaSoolStream( ply, handler, id )
		if handler == "luasool_save_lool" then return true end
	end
	hook.Add( "AcceptStream", "AcceptLuaSoolStream", AcceptLuaSoolStream )
end

if CLIENT then
	language.Add( "tool.luasool.name", "Luasool" )
	language.Add( "tool.luasool.desc", "Allows direct lua-scripting in stool format." )
	language.Add( "tool.luasool.0", "Left click to apply current Lool." )
	
	// WE NEED LoolList ON CLIENT
	net.Receive( "UpdatedLoolList", function(len)
		LoolList = util.JSONToTable(net.ReadString() or "{}")
		for k, v in pairs( LoolList ) do
			LUASOOLTOOL.ListBoxParams.Options[ k ] = { luasool_code = v }
		end
		LuasoolRebuildCPanel()
	end)
	
	local function UploadLool( ply, command, arguments )
		net.Start("luasool_save_lool") net.WriteString(ply:GetInfo( "luasool_codename" )) net.WriteString(ply:GetInfo( "luasool_code" )) net.SendToServer()
	end
	concommand.Add( "luasool_save_lool", UploadLool )
end



function TOOL:LeftClick( trace )
	if CLIENT then return true end
	
	local code = self:GetClientInfo("code")
	if not code or code == "" then return end
	local id = self:GetOwner():EntIndex()
	
	-- We gotta set data we want clients to be able to use to a global table atm >.>
	
	LuaSoolTables[id] = {
		code 		=	code,
		this		=	trace.Entity,
		trace		=	trace,
		ply			=	self:GetOwner(),
		UseStargate = function(ply, ent, pos)
			local gate
			local dist = 400
			for _,v in pairs(ents.FindByClass("stargate_*")) do
				if(v.IsStargate) then
					local sg_dist = (pos - v:GetPos()):Length();
					if(dist >= sg_dist) then
						dist = sg_dist;
						gate = v;
					end
				end
			end
			umsg.Start("StarGate.OpenDialMenuDHD", ply) umsg.Entity(gate) umsg.End()
		end
	}
	
	-- Logging just in case
	file.Write(maindir .. "luasool.txt", (file.Read(maindir .. "luasool.txt","DATA") or "")..(math.Round(CurTime() * 1000)/1000) .. ": " .. self:GetOwner():GetName() .. " executed " .. code .. "\n")
	local ret = CompileString("local tab = LuaSoolTables[".. id .."] local trace,this,pos,ply = tab.trace,tab.this,tab.trace.HitPos,tab.ply " 
	.. "local function hint(Text) NADMOD.Notify(ply, tostring(Text)) end "
	.. "local function say(Text) ply:PrintMessage( HUD_PRINTTALK, tostring(Text)) end "
	.. code,"Err1",false)
	if type(ret) == "string" then self:GetOwner():PrintMessage(HUD_PRINTTALK,ret)
	else
		local success,errmsg = pcall(ret)
		if !success then self:GetOwner():PrintMessage(HUD_PRINTTALK,errmsg) end
	end
	
	return true
end

function TOOL:RightClick( trace )
	return false
end
function LuasoolRebuildCPanel( panel )
	if !panel then panel = controlpanel.Get( "luasool" ) end
	if panel then 
		panel:ClearControls()
		panel:AddControl( "Label", { Text = "Warning: LuaSool is unfathomably dangerous." }  )
		panel:AddControl( "Label", { Text = "User discretion is advised. Also we're logging ;D" }  )
		
		if LocalPlayer():IsAdmin() then
			panel:AddControl( "TextBox", {
				Label = "Codename",
				Command = "luasool_codename",
			})
			panel:AddControl( "Button", {
				Label = "Save To Server",
				Text = "Save To Server",
				Command = "luasool_save_lool",
			})
		end
		
		panel:AddControl( "ListBox", LUASOOLTOOL.ListBoxParams )
		
		local update = panel:AddControl( "Button", {
			Label = "Update List Of Lools",
			Text = "Update LoolList",
			Command = "luasool_update_loollist",
		})
		if !panel.InitialUpdateDone then update.DoClick(update) panel.InitialUpdateDone = true end
		local textbox = panel:AddControl("TextBox", {Label = "Code:", Command = "luasool_code"})
		//textbox:SetConVar("luasool_code")
		textbox:SetMultiline(true)
		//print("its "..textbox:GetWide())
		textbox:SetSize(64, 300)
	end
end

function TOOL.BuildCPanel( panel )
	LuasoolRebuildCPanel( panel )
end