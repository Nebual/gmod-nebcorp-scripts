/*net.Receive("cltoast",function(len) 
	RunString(net.ReadString())
	print(CurTime()..": CLToast received! Its like Bacon!")
end)*/
local buffer, count = "",0
net.Receive("cltoast",function(len)
	local numpackets = net.ReadUInt(16)
	
	buffer = buffer .. net.ReadString()
	count = count + 1
	
	if numpackets <= count then
		print(CurTime()..": CLToast ("..#buffer..") received! Its like Bacon!")
		RunString(buffer)
		buffer, count = "", 0
	end
end)

killicon.Add("worldspawn", "backpack/weapons/c_models/c_sandwich/c_sandwich_large", Color(255, 255, 255, 255))
language.Add("worldspawn", "Gman")

// =======================================
// For DeathRagdolls
// =======================================
local meta = FindMetaTable("Player")
function meta:CreateRagdoll() return end

//concommand.Add("luaruncl",function(ply,cmd,args) RunString(table.concat(args," ")) end)
RunConsoleCommand("wire_expression2_friendwrite",1)

concommand.Add("jit", function(ply,cmd,args)
	if jit.status() then
		jit.off()
	else
		jit.on()
	end
	jit.flush()
	print("LuaJIT is now "..(jit.status() and "on" or "off").." clientside.")
end )

function OpenSvnCheck()
	local addons = {
		/*{file_check = "models/cebt/sgtbase.mdl",
		name = "Stargate - OPTIONAL",
		svn = "",
		directurl = "http://nebtown.info/fastdl/addons/StargateNC.7z"},*/
		/*{file_check = "models/Madman07/Stargate/base_atlantis.mdl",
		name = "CAP - Stargate Pack",
		svn = "https://carterspack.svn.sourceforge.net/svnroot/carterspack/cap_resources",
		directurl = "http://nebtown.info/fastdl/addons/cap_resources.7z"},*/
		-- ADD NEW ADDONS HERE --
	}
	local function add(file_check, name, svn, directurl) table.insert(addons,{file_check = file_check, name = name, svn = svn, directurl = directurl}) end
	//add("models/beer/wiremod/gate_e2.mdl", "Wire Models - ESSENTIAL, Used by most 'tech' in Gmod", "https://github.com/wiremod/wire/trunk", "http://nebtown.info/fastdl/addons/wire.7z")
	add("models/props_manor/baby_grand_01.mdl", "TF2 Content", "", "Steam, its a free game!")
	add("models/weapons/w_rif_m4a1.mdl", "Counter Strike: Source - ESSENTIAL, Used in many skyboxes and many of their models show up in maps", "", "http://nebtown.info/fastdl/addons/Gmod_CSS.7z")
	add("models/magnusson_device.mdl", "HL2: EP2 - ESSENTIAL, Used by many maps", "", "http://nebtown.info/fastdl/addons/Gmod_EP2.7z")
	//add("models/props_lab/beaker01a.mdl", "Black Mesa Source content", "", "http://nebtown.info/fastdl/addons/Gmod_BlackMesa.7z")
	add("models/SmallBridge/Splitters/sbconvmb.mdl", "(SBMP) SpaceBuildModelPack - OPTIONAL, A collection of ship components", "https://github.com/SnakeSVx/sbep/branches/master", "http://nebtown.info/fastdl/addons/sbmp.7z")
	add("models/sprops/rectangles/size_3/rect_24x120x3.mdl", "SProps, Like PHX, but more!", "http://shadowscions-construction-props.googlecode.com/svn", "http://nebtown.info/fastdl/addons/sprops_2013-07-19.7z")
	
	local missingsomething = false
	for k,v in pairs(addons) do if !file.Exists(v.file_check, "GAME") then missingsomething = true break end end
	if missingsomething then
		local window = vgui.Create( "DFrame" )
		window:SetSize( 450,400 )
		window:Center()
		window:SetTitle( "Addon Checker" )
		window:MakePopup()
		local height = 27
		
		local msg1= vgui.Create("DLabel", window)
		msg1:SetText("Nebtown highly recommends the following model packs, which you are missing.")
		msg1:SizeToContents()
		msg1:Center()
		msg1:SetPos(msg1:GetPos(), height)
		
		height = height + 20
		
		/*local msg2= vgui.Create("DLabel", window)
		msg2:SetText("They're avaliable either by SVN (if you care about updating) or by normal download.")
		msg2:SizeToContents()
		msg2:Center()
		msg2:SetPos(msg2:GetPos(), height)
		height = height + 25*/
		
		local function AddAddonDerma(desc, svn, directdl)
			local addon1 = vgui.Create("DLabel", window)
			addon1:SetText("> "..desc)
			addon1:SizeToContents()
			addon1:SetPos(10, height)
			height = height + 18
			
			/*local addon2 = vgui.Create("DLabel", window)
			addon2:SetText(">> SVN URL:")
			addon2:SizeToContents()
			addon2:SetPos(15, height)
			local textbox1 = vgui.Create("DTextEntry", window)
			textbox1:SetText(svn)
			textbox1:SetSize(window:GetWide() - (45 + addon2:GetWide()),17)
			textbox1:SetPos(18 + addon2:GetWide(), height)
			local sysbutton1 = vgui.Create("DSysButton",window)
			sysbutton1:SetSize(17,17)
			sysbutton1:SetPos(window:GetWide() - 22,height)
			sysbutton1:SetType("tick")
			sysbutton1:SetTooltip("Copy to clipboard!")
			sysbutton1.DoClick = function() 
				SetClipboardText(svn)
			end
			height = height + 19*/
			
			local addon3 = vgui.Create("DLabel", window)
			addon3:SetText(">> Direct HTTP:")
			addon3:SizeToContents()
			addon3:SetPos(15, height)
			local textbox2 = vgui.Create("DTextEntry", window)
			textbox2:SetText(directdl)
			textbox2:SetSize(window:GetWide() - (45 + addon3:GetWide()),17)
			textbox2:SetPos(18 + addon3:GetWide(), height)
			local sysbutton2 = vgui.Create("DButton",window)
			sysbutton2:SetSize(17,17)
			sysbutton2:SetPos(window:GetWide() - 22,height)
			sysbutton2:SetText("O")
			sysbutton2:SetTooltip("Copy to clipboard!")
			sysbutton2.DoClick = function() 
				SetClipboardText(directdl)
			end
			height = height + 25
		end
		for k,v in pairs(addons) do if !file.Exists(v.file_check, "GAME") then 
			AddAddonDerma(v.name,v.svn or "",v.directurl or "")
		end end
		
		local msg3= vgui.Create("DLabel", window)
		msg3:SetText("Install to steam/steamapps/common/GarrysMod/garrysmod/addons and Restart Gmod")
		msg3:SizeToContents()
		msg3:Center()
		msg3:SetPos(msg3:GetPos(), height + 5)
		height = height + 25
		local msg4= vgui.Create("DLabel", window)
		msg4:SetText("You can use the concommand 'svn' to reopen this later")
		msg4:SizeToContents()
		msg4:Center()
		msg4:SetPos(msg4:GetPos(), height + 5)
		height = height + 25
		
		window:SetSize(window:GetWide(),height + 5)
	else
		print("You appear to have most of the addons this server does!")
	end
end
timer.Create("OpenSVNCheck", 8, 1, OpenSvnCheck)
concommand.Add("svn", OpenSvnCheck)

local floor, pos
function NALS_Tick()
	if IsValid(floor) then			
		local wasd = Vector((LocalPlayer():KeyDown(IN_FORWARD) and 1 or 0) - (LocalPlayer():KeyDown(IN_BACK) and 1 or 0), (LocalPlayer():KeyDown(IN_MOVERIGHT) and -1 or 0) + (LocalPlayer():KeyDown(IN_MOVELEFT) and 1 or 0), 0)
		wasd:Rotate(LocalPlayer():GetAimVector():Angle())
		wasd.z = 0
		wasd:Normalize()
		pos = pos + floor:WorldToLocal(floor:GetPos() + wasd * (FrameTime()*33*5))
		print(tostring(floor:WorldToLocal(floor:GetPos() + wasd * (FrameTime()*33))))
		LocalPlayer():SetPos(pos)
	end
end

net.Receive("NALS", function(netlen)
	local bool = net.ReadBit() ~= 0
	if bool then 
		floor = net.ReadEntity()
		pos = net.ReadVector()
		//hook.Add("Think", "NALS_Move", NALS_Tick)
		LocalPlayer():SetMoveType(0)
		LocalPlayer():SetGravity(0.0001)
		LocalPlayer():SetCollisionGroup(COLLISION_GROUP_NONE)
	else 
		//hook.Remove("Think", "NALS_Move")
		LocalPlayer():SetMoveType(2)
		LocalPlayer():SetGravity(1)
		LocalPlayer():SetCollisionGroup(COLLISION_GROUP_PLAYER)
	end
end)
