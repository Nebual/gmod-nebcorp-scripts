AddCSLuaFile("autorun/client/cl_nebcorp.lua")
AddCSLuaFile("autorun/client/cl_NebcorpPlayers.lua")
hook.Add( "InitPostEntity", "NebcorpInit", function()
	-- Stuff in here will only ever be run once per serverload

	-- Timers don't start till a player joins the server, so lets kick it up a notch with a bot
	if not game.SinglePlayer() then
		game.ConsoleCommand("bot\n")
		timer.Create("KickFirstBot", 0.05, 1, function() if player.GetBots()[1] then game.ConsoleCommand("kick "..player.GetBots()[1]:Nick().."\n") end end)
	end
	CreateConVar("sv_lag", 1, FCVAR_NOTIFY) // An old joke, set this to 0 for "WHAT?! WHY IS THAT A CONVAR AND WHY ISN'T IT ALWAYS AT 0, DAMMIT NEB"
	
	
	NADMOD.Weapons.NCGrenade = "nebcorp_grenade"
	NADMOD.Weapons.Wrench = "nebcorp_wrench"
	NADMOD.Weapons.Hands = "nebcorp_hands"
end )

CreateConVar( "test_server_var", "3", FCVAR_REPLICATED )
CreateConVar( "test_shared_var", "5", FCVAR_REPLICATED )

resource.AddWorkshop("182803531") // SBEP
resource.AddWorkshop("160250458") // Wiremod
resource.AddWorkshop("173482196") // SProps
if game.GetMap() == "gm_excess_construct" then resource.AddWorkshop("104470135") end
if game.GetMap() == "gm_bigcitysideways" then resource.AddWorkshop("296954938") end
if game.GetMap() == "gm_bluehills_test3" then resource.AddWorkshop("243902601") end
if game.GetMap() == "gm_genesis_b24" then resource.AddWorkshop("266666023") end


function resource.AddDir(dir,ext) -- recursively adds everything in a directory to be downloaded by client
	local _,tab = file.Find(dir.."/*","GAME")
	for _, v in pairs(tab) do
		if v != ".svn" then -- don't spam people with useless .svn folders
			resource.AddDir(dir.."/"..v, ext)
		end
	end

	for _,v in pairs(file.Find(dir.."/*","GAME")) do
		if ext then
			if string.Right(v, 4) == ext then
				resource.AddFile(dir.."/"..v)
			end
		else
			resource.AddFile(dir.."/"..v)
		end
	end
end
function resource.AddSkybox(map)
	for _,v in pairs({"bk","ft","up","dn","lf","rt"}) do
		resource.AddFile("materials/skybox/"..map..v..".vmt")
		resource.AddFile("materials/skybox/"..map..v..".vtf")
	end
end

/*resource.AddFile("materials/models/turretbarrel/turretbarrel.vmt")
resource.AddFile("materials/models/turretbody/turretbody.vmt")
resource.AddFile("materials/models/turretelevator/turretelevator.vmt")
resource.AddFile("models/turretbarrel.mdl")
resource.AddFile("models/turretbase.mdl")
resource.AddFile("models/turretbody.mdl")
resource.AddFile("models/turretelevator.mdl")
resource.AddFile("materials/models/turretbolt/turretbolt.vmt")
resource.AddFile("models/turretbolt.mdl")*/

resource.AddDir("data/Expression2/Nebtown", ".txt")
//resource.AddFile("models/Zup/Stargate/stargate_base.mdl")
//resource.AddFile("models/Zup/Stargate/sga_base.mdl")
//resource.AddFile("materials/beer/wiremod/gate_prongs.vmt")
//resource.AddFile("materials/beer/wiremod/gate_base.vmt")
//resource.AddFile("materials/beer/wiremod/gate_e2.vmt")
//resource.AddFile("models/beer/wiremod/gate_e2.mdl")
// Only do this occasionally :P
// resource.AddFile("materials/models/props_foliage/tree_pine_01_branches.vmt")
// resource.AddFile("materials/models/props_foliage/tree_pine_02_branches.vmt")
// resource.AddFile("models/props_foliage/tree_pine_large.mdl")

local map = string.Left(game.GetMap(), 9)
if map ==     "gm_excess" then
	resource.AddSkybox("militia")
	resource.AddSkybox("militia_hdr")
elseif map == "kat_redux" then
	resource.AddSkybox("grimmnight")
elseif map == "sb_new_wo" then
	resource.AddSkybox("new_worlds_")
elseif map == "sb_voyage" then
	resource.AddSkybox("voyages_")
elseif map == "sb_extinc" then
	resource.AddSkybox("starbox_")
	for _,v in pairs({"desolation","desperation","dusty","frosty","kestrel","maldoran","moon","toxic"}) do
		resource.AddFile("models/bynari/"..v..".mdl")
		resource.AddFile("materials/bynari/"..v..".vmt")
	end
	resource.AddFile("materials/Lava/final.vmt")
	resource.AddFile("materials/marssandblend.vmt")
elseif map == "sb_gooniv" then
	timer.Simple(5, function()
		for k, ent in pairs(ents.FindInBox(Vector(9571, -3135, 10207), Vector(10818, -1321, 10933))) do ent:Remove() end
		Msg("Bad Space Station: Deleted The Space Station\n")
	end)
elseif map == "sb_nebspa" then
	resource.AddSkybox("starbox_")
	resource.AddFile("materials/kat/blendkatdirt01.vmt")
	resource.AddFile("materials/kat/blendkatdirt02.vmt")
elseif map == "gm_constr" then
	game.ConsoleCommand("sbox_maxnpcs 3\n")
end

//resource.AddFile("settings/spawnlist/090-useful and explosive.txt")

hook.Add("PlayerSpawnedVehicle","NebcorpVehicleUpgrade",function(ply,vehicle)
	if vehicle:GetClass() == "prop_vehicle_jeep" then
		local seat = ents.Create( 'prop_vehicle_prisoner_pod' )
		seat:SetModel( "models/nova/jeep_seat.mdl" )
		seat:SetPos( vehicle:LocalToWorld(Vector(21,-32,18)) )
		seat:SetAngles( vehicle:LocalToWorldAngles(Angle(0,-3.5,0)) )
		seat:Spawn()
		seat:SetCollisionGroup( COLLISION_GROUP_WORLD )
		seat:SetKeyValue( "limitview", 0 )
		table.Merge( seat, { HandleAnimation = function(_,ply) return ply:SelectWeightedSequence( ACT_HL2MP_SIT ) end } )
		gamemode.Call( "PlayerSpawnedVehicle", ply, seat )
		vehicle.PassengerSeat = seat
		vehicle:DeleteOnRemove(seat)
		constraint.Weld(seat, vehicle)
		seat:SetParent(vehicle)
	end
end)

-- Further queues the datastream system when specifically sending bulk cl_lua
/*
local streams = {}
local nextstream = {}
local function ProcessNebDataStreams()
	local k,v = next(streams)
	if k && (nextstream[v[2] or "all"] or 1) < CurTime() then
		nextstream[v[2] or "all"] = CurTime() + 2
		datastream.StreamToClients(v[2] or player.GetAll(), "nebcorp_cltoast", v[1])
		table.remove(streams,k or 1)
	end
end
timer.Create("ProcessNebDataStreams",1.25,0,ProcessNebDataStreams)
function NebDataStream(handle, data)
	table.insert(streams, {data})
	hook.Add("PlayerInitialSpawn", handle or "reload_cltoast", function(ply) table.insert(streams, {data,ply}) end)
	ProcessNebDataStreams()
end
*/

util.AddNetworkString("E2Ether")
net.Receive("E2Ether", function(netlen, ply)
	net.Start("E2Ether")
		net.WriteData(net.ReadData(math.ceil(netlen/8)), math.ceil(netlen/8))
	net.SendOmit(ply)
end)

-- Awesome convinence function that returns the player with the given case-insensitive partial name
if not FindPlayer then
	function FindPlayer(nick)
		if !nick || nick == "" then return end
		nick = string.lower(nick)
		local num = tonumber(nick)
		for _,v in pairs(player.GetAll()) do
			if string.lower(v:Nick()) == nick then return v
			elseif v:UserID() == num then return v
			end
		end
		for _,v in pairs(player.GetAll()) do
			if string.find(string.lower(v:Nick()), nick) then return v end
		end
	end
end
function MassEmitSound(sound, volume, fade)
	for k,v in pairs(player.GetAll()) do
		v:EmitSound( sound, volume or 80)
	end
	timer.Create("MassSound_"..sound,fade or SoundDuration(sound), 1, function()
		for k,v in pairs(player.GetAll()) do
			v:StopSound( sound )
		end
	end)
end
concommand.Add("emitsound", function(ply,cmd,args) if !IsValid(ply) || ply:IsAdmin() then MassEmitSound(args[1],tonumber(args[2]),tonumber(args[3])) end end)
concommand.Add("nebcorp_reload", function() include("autorun/server/nebcorp.lua") end)
concommand.Add("reloadlevel", function(ply) if !ply:IsValid() || ply:IsAdmin() then NIRC.Say("Reloading "..game.GetMap().."!") game.ConsoleCommand("changelevel "..game.GetMap().."\n") end end)

concommand.Add("cleanplayer", function(ply,cmd,args)
	local ent = FindPlayer(args[1])
	if ent then SPropProtection.DRemove(ent:SteamID(), ent:Nick()) end
end)

util.AddNetworkString("cltoast")
concommand.Add("reload_toast", function(ply) if !ply:IsValid() || ply:IsAdmin() then include("toast.lua") end end)
/*concommand.Add("reload_cltoast", function(ply,cmd,args)
	if ply:IsValid() && !ply:IsAdmin() then return end
	net.Start("cltoast")
		net.WriteString(file.Read("lua/cl_toast.lua","GAME"))
	net.Broadcast()
end)*/
function CLToast(datastr, ply)
	local numpackets = math.ceil(#datastr / 64000)
	for i=1,#datastr, 64000 do
		net.Start("cltoast")
			net.WriteUInt(numpackets,16)
			net.WriteString(datastr:sub(i,i+63999))
		if ply then net.Send(ply) else net.Broadcast() end
	end
end
concommand.Add("reload_cltoast", function(ply,cmd,args)
	if ply:IsValid() && !ply:IsAdmin() then return end
	CLToast(file.Read("lua/cl_toast.lua","GAME"))
end)
concommand.Add("reload_shtoast", function(ply,cmd,args)
	if ply:IsValid() && !ply:IsAdmin() then return end
	include("sh_toast.lua")
	CLToast(file.Read("lua/sh_toast.lua","GAME"))
end)
concommand.Add("cltoast", function(ply,cmd,args)
	if ply:IsValid() && !ply:IsAdmin() then return end
	local tar = FindPlayer(table.remove(args,1))
	local code = table.concat(args," ")
	if IsValid(tar) then 
		if args[1] then CLToast(code, tar)
		else CLToast(file.Read("lua/cl_toast.lua","GAME"), tar)
		end
	end
end)

concommand.Add("reloadent", function(ply,cmd,args) if !ply:IsValid() || ply:IsAdmin() then ReloadEnt(args[1], string.find(args[2] or "","nocli")) end end)
function ReloadEnt(class, noclientside)
	local text, cltext, filepath
	if file.Exists("entities/"..class..".lua","LUA") then
		filepath = "entities/"..class..".lua"
		//local f = file.Open(filepath,"r","LUA")
		//text = f:Read(f:Size())
		text = file.Read(filepath, "LUA")
		text = text:gsub("DEFINE_BASECLAS", "local BaseClass = baseclass.Get")
		text = text:gsub("local BaseClass = baseclass.GetS", "local BaseClass = baseclass.Get")
		cltext = text
	elseif file.Exists("entities/"..class.."/init.lua","LUA") then
		filepath = "entities/"..class.."/cl_init.lua"
		local init = file.Read("entities/"..class.."/init.lua","LUA")
		//if !init then Error("ReloadEnt error: I can't find lua/entities/"..class.."/init.lua!") end
		local shared = file.Read("entities/"..class.."/shared.lua","LUA") or ""
		text = string.gsub(shared .." ".. init,"include%(%pshared.lua%p%)","")
		cltext = string.gsub(shared .." ".. (file.Read("entities/"..class.."/cl_init.lua","LUA") or ""),"include%(%pshared.lua%p%)","")
	else
		Error("ReloadEnt cannot find the entity '"..class.."'!")
	end
	local f1 = string.find(text, "\"", string.find(text, "ENT.Base"))
	local f2 = string.find(text, "\"", f1 + 1)
	local base = string.sub(text, f1+1, f2-1)
	
	if (scripted_ents.Get(class) or {}).BaseClass then
		base = scripted_ents.Get(class).BaseClass.ClassName
	end

	/*if base and file.Exists("entities/"..base..".lua","LUA") then
		base_text = file.Read("entities/"..base..".lua", "LUA")
		text = base_text .. " " .. text
		cltext = base_text .. " " .. cltext
	end*/
	
	RunStringEx("scripted_ents.GetStored(\""..class.."\").t = {} ENT = scripted_ents.Get(\""..class.."\") or {} "..text.."\nscripted_ents.Register(ENT, \""..class.."\")\nbaseclass.Set(\""..class.."\", ENT) ENT = nil",filepath)
	//RunStringEx("local ENT = scripted_ents.Get(\""..base.."\") or scripted_ents.Get(\""..class.."\") or {} ENT.BaseClass = scripted_ents.Get(\""..base.."\") "..text.."\nscripted_ents.Register(ENT, \""..class.."\")",filepath)

	if !noclientside then CLToast("ENT = {Base = \""..base.."\"} local function aaa() "..cltext.." end aaa()\nscripted_ents.Register(ENT, \""..class.."\") ENT = nil\nprint('Registered "..class.."')") end
end

concommand.Add("reloadtool", function(ply,cmd,args) 
	if ply:IsValid() && !ply:IsAdmin() then return end
	local shared = file.Read("lua/weapons/gmod_tool/stools/"..args[1]..".lua",true) or ""
	RunString("local TOOL = weapons.GetStored('gmod_tool').Tool['"..args[1].."'] "..shared)
	local TOOL = weapons.GetStored('gmod_tool').Tool[args[1]]
	for k,v in pairs(player.GetAll()) do
		if v:GetTool() and v:GetTool().SWEP and v:GetTool().SWEP.Tool then
			local plytool = v:GetTool().SWEP.Tool[args[1]]
			for funcname, func in pairs(TOOL) do
				if type(func) == "function" then plytool[funcname] = func end
			end
		end
	end
	CLToast("local TOOL = weapons.GetStored('gmod_tool').Tool['"..args[1].."'] "..shared)/*.."\nif LocalPlayer():GetTool() then local plytool = LocalPlayer():GetTool()['"..args[1].."'] for funcname, func in pairs(TOOL) do if type(func) == 'function' then plytool[funcname] = func end end end") */
end)

concommand.Add("reloadswep", function(ply,cmd,args) if !ply:IsValid() || ply:IsAdmin() then
	local shared = file.Read("lua/weapons/"..args[1].."/shared.lua",true) or ""
	RunString("local SWEP = weapons.Get(\""..args[1].."\") "..shared.."\n"..(file.Read("lua/weapons/"..args[1].."/init.lua",true) or "").."\n weapons.Register(SWEP, \""..args[1].."\", true)")
	CLToast("local SWEP = weapons.Get(\""..args[1].."\") "..shared.."\n"..(file.Read("lua/weapons/"..args[1].."/cl_init.lua",true) or "").."\n weapons.Register(SWEP, \""..args[1].."\", true)")
end end)
CreateConVar("nebcorp_debug",0)
function NebcorpDebug(pos)
	if GetConVarNumber("nebcorp_debug") != 0 then MakeProp(FindPlayer("Neb"),pos,Angle(),"models/props_junk/watermelon01.mdl",{},{}) end
end

function WriteTableToFile(filepath,tab)
	local str = ""
	for k,v in pairs(tab) do
		str = str.."\n"..k..":"
		for funcname, func in pairs(v) do
			str = str.."\n\t"..funcname
		end
	end
	file.Write(filepath,str)
end
function PrintTimers()
	local str, str2 = "", ""
	for k,v in pairs(timer.GetTable()) do
		if !v then str = str..k..": nothing\n"
		elseif v.Status != 0 then str = str..k..":\t\t"..(v.Status or "wat").." "..(v.Delay or "wat").." "..(v.Repetitions or "wat").."\n"
		else str2 = str2..k..":\t\t"..(v.Status or "wat").." "..(v.Delay or "wat").." "..(v.Repetitions or "wat").."\n"
		end
	end
	file.Write("timersdump.txt",str..str2)
end

function SetupCouch(this)
	local ply = this.SPPOwner
	local num = 2
	if this:GetModel() == "models/props/cs_militia/couch.mdl" then num = 3 end
	undo.Create("Couch_Vehicles")
	for k=1,num do
		local E=ents.Create('prop_vehicle_prisoner_pod')
		E:SetModel('models/nova/airboat_seat.mdl')
		local X,Y,Z,Yaw = -2, 13, -3, -90
		if num == 3 then
			if k == 1 then X = 0 elseif k == 2 then X = 30 else X = -30 end
			Y,Z = 2.5, 17.5
			Yaw = 0
		elseif k==2 then
			Y= -13
		end
		E:SetPos(this:LocalToWorld(Vector(X,Y,Z)))
		E:SetAngles(this:LocalToWorldAngles(Angle(0,Yaw,0)))
		E:Spawn()
		E:Activate()
		E:SetKeyValue( "limitview", 0 )

		local r,g,b = E:GetColor()
		E:SetColor(r,g,b,0)
		gamemode.Call( "PlayerSpawnedVehicle", ply, E )
		NADMOD.PlayerMakePropOwner(ply, E)
		undo.AddEntity( E )

		local weld = constraint.Weld(E, this, 0,0,0,true)
		undo.AddEntity( weld )
	end
	undo.SetPlayer( ply )
	undo.Finish()
end

util.AddNetworkString("NALS")
NALS_List = NALS_List or {}
NALS_Sticky = NALS_Sticky or {}
function NALS_Toggle(ply, cmd)
	if !IsValid(ply) || !ply:IsPlayer() then return end
	local id = ply:EntIndex()
	if NALS_List[id] then
		local floor = NALS_List[id][1]
	//	local eye = ply:GetAimVector():Angle()
		ply:SetParent()
		ply:SetGravity(1)
		ply:GetPhysicsObject():EnableGravity(true)
		ply:GetPhysicsObject():SetMass(85)
		ply:SetNotSolid(false)
		ply:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	//	ply:SetPos(floor:LocalToWorld(NALS_List[id][2]))
	//	ply:SetMoveType(NALS_List[id][3])
	//	ply:SetNotSolid(false)
		ply:GodDisable()
		if cmd == "nals_sticky" then NALS_Sticky[id] = nil umsg.Start("NALS_Sticky", ply) umsg.Bool(false) umsg.End() 
		else ply:SetMoveType(2) net.Start("NALS") net.WriteBit(false) net.Send(ply)
		end

	//	eye.r = 0
	//	ply:SetEyeAngles(eye)
		if IsValid(floor) then floor.NALS = nil end
		//umsg.Start("NALS_Move", ply) umsg.Bool(true) umsg.End()
		NALS_List[id] = nil
		if !next(NALS_List) && !next(NALS_Sticky) then
			-- If theres now nothing in the table, kill the hooks
			hook.Remove("EntityRemoved", "NALS_Check")
			//hook.Remove("SetupMove", "NALS_Move")
	//		hook.Remove("Move", "NALS_Move")
			hook.Remove("Tick","NALS_Tick")
			hook.Remove("Think","NALS_Tick")
			//if cmd == "nals_sticky" then hook.Remove("FinishMove", "NALS_EndMove") end
		end
		WireLib.AddNotify(ply,"You are free.",0,4)


	else
		local trace = util.TraceLine({start = ply:GetPos(), endpos = ply:GetPos() - Vector(0,0,25), filter = ply})
		local floor = trace.Entity
		if !IsValid(floor) || floor:IsWorld() then return end
		//if IsValid(trace.Entity:GetParent()) then floor = trace.Entity:GetParent() end
	//	local noclipstatus = ply:GetMoveType()
	//	ply:SetMoveType(MOVETYPE_NONE)
	//	ply:SetNotSolid(true)
	//	local ang = floor:GetAngles()
	//	local eye = floor:WorldToLocalAngles(ply:GetAimVector():Angle())
	//	eye.r = ang.r
	//	ply:SetEyeAngles(eye)
	//	ply:SnapEyeAngles(eye)
		ply:GodEnable()
		ply:SetGravity(0.0001)
		ply:GetPhysicsObject():SetMass(1)
		ply:SetCollisionGroup(COLLISION_GROUP_NONE)
		ply:SetNotSolid(true)
		ply:SetParent(floor)
		floor.NALS = true
		//umsg.Start("NALS_Move", ply) umsg.Bool(false) umsg.End()
		if !next(NALS_List) then
			-- If theres nothing in the table yet, this is first one, init the hooks
			hook.Add("EntityRemoved", "NALS_Check", function(ent)
				if ent.NALS then
					for k,v in pairs(NALS_List) do
						if v[1] == ent then NALS_Toggle(Entity(k)) end
					end
				end
			end)
			//hook.Add("SetupMove", "NALS_Move", NALS_StartMove)
	//		hook.Add("Move", "NALS_Move", NALS_Move)
			//hook.Add("FinishMove", "NALS_EndMove", NALS_EndMove)
			hook.Add("Think","NALS_Tick",NALS_Tick)
		end
		NALS_List[id] = {floor, floor:WorldToLocal(ply:GetPos()), noclipstatus}
		WireLib.AddNotify(ply,"You are now Neatbelt'd.",0,4)

		if cmd == "nals_sticky" then NALS_Sticky[id] = true umsg.Start("NALS_Sticky", ply) umsg.Bool(true) umsg.End() 
		else ply:SetMoveType(0) net.Start("NALS") net.WriteBit(true) net.WriteEntity(floor) net.WriteVector(NALS_List[id][2]) net.Send(ply)
		end
	end
end
//ply:SetMoveType(0) works nicely actually!!
concommand.Add("nals", NALS_Toggle)
concommand.Add("nals_sticky",NALS_Toggle)
function NALS_Move(ply, data)
	local tab = NALS_List[ply:EntIndex()]
	if NALS_Sticky[ply:EntIndex()] then
		//if ply:Nick() == "Nebual" then Msg("-"..data:GetForwardSpeed()) end
		if data:GetForwardSpeed() == 0 && data:GetSideSpeed() == 0 then
			if !tab then NALS_Toggle(ply) end
			return
		else
			if tab then NALS_Toggle(ply) end
			return
		end
	end

	if tab then
		data:SetOrigin(tab[1]:LocalToWorld(tab[2]))
		return data
	end
end

function NALS_Tick()
	for k,v in pairs(NALS_Sticky) do
		local ply = Entity(k)
		if !IsValid(ply) then NALS_Sticky[k] = nil continue end
		if ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_LEFT) or ply:KeyDown(IN_RIGHT) or ply:KeyDown(IN_BACK) then
			if NALS_List[k] then NALS_Toggle(ply) end
		else
			if !NALS_List[k] then NALS_Toggle(ply) end
		end
	end
	for k,v in pairs(NALS_List) do
		//if NALS_Sticky[k] then
			-- FIND OUT IF HE'S MOVING, THEN DO THE TOGGLY STUFF
		//end
		if not Entity(k):IsValid() then NALS_List[k] = nil 
		elseif not v[1]:IsValid() then NALS_Toggle(Entity(k))
		else
			local wasd =Vector((Entity(k):KeyDown(IN_FORWARD) and 1 or 0) - (Entity(k):KeyDown(IN_BACK) and 1 or 0), (Entity(k):KeyDown(IN_MOVERIGHT) and -1 or 0) + (Entity(k):KeyDown(IN_MOVELEFT) and 1 or 0), 0)
			wasd:Rotate(Entity(k):GetAimVector():Angle())
			wasd.z = 0
			wasd:Normalize()
			v[2] = v[2] + v[1]:WorldToLocal(v[1]:GetPos() + wasd*(Entity(k):KeyDown(IN_SPEED) and 3.5 or 1.5))
			Entity(k):SetLocalPos(v[2])
			Entity(k):SetMoveType(0)
		end
	end
	/*
	local tab = NALS_List[ply:EntIndex()]
	if NALS_Sticky[ply:EntIndex()] then
		//if ply:Nick() == "Nebual" then Msg("-"..data:GetForwardSpeed()) end
		if data:GetForwardSpeed() == 0 && data:GetSideSpeed() == 0 then
			if !tab then NALS_Toggle(ply) end
			return
		else
			if tab then NALS_Toggle(ply) end
			return
		end
	end
	*/
end

concommand.Add("nals2", function(ply,cmd,args)
	if not ply.NalsEnt then
		local ent = util.TraceLine({start = ply:GetPos(), endpos = ply:GetPos() - Vector(0,0,25), filter = ply}).Entity
		if IsValid(ent) then
			ply.NalsEnt = ent
			ply:SetMoveType(0)
			ply:SetAngles(ent:GetAngles())
			//ply:SetPos(ent:GetPos() + Vector(0,0,10))
			ply:SetParent(ent)
			ply:SetGravity(0)
			ply:GetPhysicsObject():SetMass(1)
			WireLib.AddNotify(ply,"You are now Neatbelt2'd to "..tostring(ent),0,4)
		end
	else
		ply:SetParent()
		ply:SetMoveType(2)
		ply:SetAngles(ply.NalsEnt:GetAngles())
		//ply:SetPos(ply.NalsEnt:GetPos() + Vector(0,0,10))
		ply:SetGravity(1)
		ply:GetPhysicsObject():SetMass(85)
		ply.NalsEnt = nil
		WireLib.AddNotify(ply,"You are no longer Neatbelt2'd!",0,4)
	end
end)

concommand.Add("nals3", function(ply,cmd,args)
	if not ply.NalsEnt then
		local ent = util.TraceLine({start = ply:GetPos(), endpos = ply:GetPos() - Vector(0,0,25), filter = ply}).Entity
		if IsValid(ent) then
			ply.NalsEnt = ent
			ply:SetMoveType(0)
			ply:SetAngles(ent:GetAngles())
			//ply:SetPos(ent:GetPos() + Vector(0,0,10))
			ply:SetParent(ent)
			ply:SetGravity(0)
			ply:GetPhysicsObject():SetMass(1)
			WireLib.AddNotify(ply,"You are now Neatbelt2'd to "..tostring(ent),0,4)
		end
	else
		ply:SetParent()
		ply:SetMoveType(2)
		ply:SetAngles(ply.NalsEnt:GetAngles())
		//ply:SetPos(ply.NalsEnt:GetPos() + Vector(0,0,10))
		ply:SetGravity(1)
		ply:GetPhysicsObject():SetMass(85)
		ply.NalsEnt = nil
		WireLib.AddNotify(ply,"You are no longer Neatbelt2'd!",0,4)
	end
end)

-- Announce creation pastes
hook.Add("InitPostEntity","NCDelayedArmDupeInit",function()
	net.Receive( "ArmDupe", function( len, client )
		//if not client.UserRank or client.UserRank == 1 then NADMOD.Message("New users are not allowed pasting creations.",client) return end
		local len		= net.ReadUInt( 32 )
		local data		= net.ReadData( len )

		if ( !IsValid( client ) ) then return end

		-- Hook.. can arn dupe..

		local uncompressed = util.Decompress( data )
		if ( !uncompressed ) then 
			MsgN( "Couldn't decompress dupe!" )
		return end

		local Dupe = util.JSONToTable( uncompressed )
		if ( !istable( Dupe ) ) then return end
		if ( !isvector( Dupe.Mins ) ) then return end
		if ( !isvector( Dupe.Maxs ) ) then return end

		client.CurrentDupe = Dupe;
		NADMOD.Message(client:Nick().." is pasting a creation.")

		client:ConCommand( "gmod_tool duplicator" );

		--
		-- Disable the Spawn Button
		--
		net.Start( "CopiedDupe" )
			net.WriteUInt( 0, 1 );
		net.Send( client )
	end )
end)

-- =======================================
-- IPAddress logging (cached)
-- =======================================
function LogIPAddress(name,address)
	/* disabled because json sucks
	print("Logging "..name.." at "..address.."!")
	address = string.match(address,"%d+.%d+.%d+.%d+")
	if !address then print("Scratch that! NEVAH") return end
	local tab = util.JSONToTable(file.Read("nebcorp/ipaddresses.txt","DATA") or "{}")
	local addtab = tab[address] or {}
	local found
	for k,v in ipairs(addtab) do
		if v[1] == name then addtab[k][2] = addtab[k][2] + 1 found = true break end
	end
	if !found then table.insert(addtab,{name,1}) end
	tab[address] = addtab
	file.Write("nebcorp/ipaddresses.txt", util.TableToJSON(tab))
	print("Done logging!")
	*/
end
hook.Add("PlayerConnect","Nebcorp_ConnectPly", LogIPAddress)
function LookupIPAddress(address)
	address = string.sub(address,1,(string.find(address,":") or 0)-1)
	print("LOOKINGUP-"..address.."-")
	local tab = util.JSONToTable(file.Read("nebcorp/ipaddresses.txt","DATA") or "{}")
	table.Merge(tab,util.JSONToTable(file.Read("nebcorp/ipaddressesbig.txt","DATA") or "{}"))
	local addtab = {}
	if !tab[address] then return "Nothing!" end
	for k,v in ipairs(tab[address]) do
		if k == 1 then addtab = {v}
		else
			local found
			for i,inside in ipairs(addtab) do
				if v[2] > (inside or {1,0})[2] then table.insert(addtab, i,v) found = true break end
			end
			if !found then table.insert(addtab,v) end
		end
	end
	local ret = "("..tostring(address)..") "
	for k,v in ipairs(addtab) do
		ret = ret .. v[1] .. " x"..v[2]..", "
		if k > 6 then ret = ret.."and many more..., " break end
	end
	ret = string.sub(ret,1,-3)
	return ret
end
concommand.Add("lookup",function(ply,cmd,args)
	local ret
	if tonumber(string.Left(args[1], 1)) then ret = LookupIPAddress(args[1])
	else ret = LookupIPAddress(FindPlayer(args[1]):IPAddress())
	end
	if ply:IsValid() then ply:ChatPrint("Known names: " .. ret)
	else print("Known names: " .. ret)
	end
end)

-- =======================================
-- LUA Error logging (cached)
-- =======================================
/*
require("luaerror")
CreateConVar("nebcorp_errorlog", 1)
local errorfile = "nebcorp/lua_errors/"..os.date("%y-%m-%d").."-errors.txt"
local errorinit, errorcache, lasterror, errorcount = file.Read(errorfile,"DATA") or "", "Server restarted at "..os.date("[%H:%M]").."\n", "", 1
hook.Add("LuaError", "Nebcorp_ErrorLog", function(err) --Return anything other than nil to stop the standard error display
	if (GetConVar("nebcorp_errorlog"):GetInt() != 0) then
		if err == lasterror then
			errorcount = errorcount + 1
		else
			if errorcount > 1 then errorcache = string.sub(errorcache, 1, string.find(errorcache, "x", string.len(errorcache) - 5))..errorcount.."\n" end
			errorcache = errorcache .. os.date("[%H:%M] ")..string.sub(err,1,-2).." x1\n"
			errorcount = 1
		end
		lasterror = err
	end
end )

local lastcache = ""
timer.Create("Nebcorp_ErrorLogWrite", 3, 0, function()
	if errorcache != lastcache then
		file.Write(errorfile, errorinit..errorcache)
		lastcache = errorcache
	end
end)
*/


-- Falldamage
hook.Add("GetFallDamage", "NebcorpFallDamage", function(ply,speed)
	return (speed - 580) * (100/(1024-580))
end)

-- (reproducable) Random Number Generator
local rndseed = CurTime()
function nebrandom()
	// This function produces fairly random numbers that are reproducable if using the same seed, unlike Garry's broken math.randomseed
	rndseed = util.CRC(rndseed)
	return rndseed/4300000000
end
function nebrandomseed(seed) rndseed = seed end
function nebrandomtable(tab)
	local rk = math.Round(1 + nebrandom() * (table.Count( tab )-1))
	local i = 1
	for k, v in pairs(tab) do 
		if ( i == rk ) then return v end
		i = i + 1 
	end
end
/*local tab = {} // Proof that the random generator is actually random - if inefficient
for k=1,10000 do 
	local i = string.Left(tostring(nebrandom()),3)
	tab[i] = (tab[i] or 0) + 1
end
PrintTable(tab)*/

-- =======================================
-- Deathragdolls, based off Saphira's http://www.garrysmod.org/downloads/?a=view&id=66218
-- =======================================

function PlayerRagdoll(ply)
	if !IsValid(ply) then return end
	local ent = ents.Create("prop_ragdoll")
	ent:SetPos(ply:GetPos())
	ent:SetAngles(ply:GetAngles())
	ent:SetModel(ply:GetModel())
	ent:SetSkin(ply:GetSkin())
	ent:SetColor(ply:GetColor())
	ent:SetMaterial(ply:GetMaterial())
	ent:Spawn()

	if not ent:IsValid() then return end
	if Namage then Namage.InitProp(ent) end

	local plyvel, gravity = ply:GetVelocity(), ply.Gravity != 0
	for i = 1, ent:GetPhysicsObjectCount() do
		local bone = ent:GetPhysicsObjectNum(i)

		if bone and bone.IsValid and bone:IsValid() then
			local bonepos, boneang = ply:GetBonePosition(ent:TranslatePhysBoneToBone(i))

			bone:SetPos(bonepos)
			bone:SetAngles(boneang)

			bone:AddVelocity(plyvel)
			bone:EnableGravity(gravity)
		end
	end

	if ply:IsOnFire() then ent:Ignite(math.Rand(6, 8), 0) end

	ply:SpectateEntity(ent)
	ply:Spectate(OBS_MODE_CHASE)
	return ent
end
local metaplayer = FindMetaTable("Player")
function metaplayer:CreateRagdoll()
	if not (self and self.IsValid and self.IsPlayer and self:IsValid() and self:IsPlayer()) then return Error("No player given.\n") end

	if IsValid(self.DeathRagdoll) then self.DeathRagdoll:Remove() end

	local ent = PlayerRagdoll(self)
	if !IsValid(ent) then return end
	ent.Spirit = self
	self.DeathRagdoll = ent
end
function metaplayer:GetRagdollEntity() return self.DeathRagdoll end

function ReviveCorpse(ply, tar)
	if IsValid(tar) && IsValid(tar.Spirit) && !tar.Spirit:Alive() then
		if (ply.ScrollsLeft or 1) < 1 then
			NADMOD.Message("Sorry bro, you're all out of scrolls!", ply)
			timer.Create("MoreScrolls"..ply:Nick(),math.random(30,120),1,function() if ply:IsValid() then ply.ScrollsLeft = math.random(2,5) end end)
			return
		end

		tar.Spirit:Spawn()
		NADMOD.Message("You have been resurrected by "..ply:Nick().." which cost him 1 [Scroll of Ressurection]"..table.Random({", you should probably pay him back.",", he doesn't have many left.", ", but I mean he has tons of them.", ", how many does he have?!"}), tar.Spirit)
		ply.ScrollsLeft = (ply.ScrollsLeft or math.random(3,7)) - 1
		NADMOD.Message("You resurrected "..tar.Spirit:Nick().." which cost you 1 [Scroll of Ressurection]. You have "..ply.ScrollsLeft.." scrolls left!", ply)
		local tarent,tarpos = tar.Spirit, tar:GetPos()
		
		timer.Create("ReviveCorpse_"..tar.Spirit:Nick(), 0.05,1, function() tarent:SetPos(tarpos + Vector(0,0,10)) end)
		tar:Remove()
	end
end
hook.Add("PlayerSwitchFlashlight", "Ressurect_Corpses", function(ply, bool) if bool then ReviveCorpse(ply, ply:GetEyeTraceNoCursor().Entity) end end)

function AntiStickVehicleStart(ply,ent)
	if ent:GetClass() != "prop_vehicle_prisoner_pod" then return end
	if ent:GetPos():Distance(ply:GetPos()) > 200 then return end -- For Vehicle Swapper
	ply.VehicleEnterPos = ent:WorldToLocal(ply:GetPos())
	ply.VehicleEnterAng = ent:WorldToLocalAngles(ply:EyeAngles())
end
hook.Add("CanPlayerEnterVehicle","NCStart",AntiStickVehicleStart)
function AntiStickVehicleEnd(ply,ent)
	if !ply.VehicleEnterPos then return end
	ply:SetPos(ent:LocalToWorld(ply.VehicleEnterPos or Vector()))
	local ang = ent:LocalToWorldAngles(ply.VehicleEnterAng or Angle())
	ang.r = 0
	ply:SetEyeAngles(ang)
	ply.VehicleEnterPos,ply.VehicleEnterAng = nil,nil
end
hook.Add("PlayerLeaveVehicle","NCEnd",AntiStickVehicleEnd)
-- =======================================
-- Mapwide Autosaver
-- =======================================

function Nebcorp_Dupe(ent)
	if !IsValid(ent) then return end
	-- Let Adv Dupe give us relevent Entity/Constraint data
	local ETable,CTable = AdvDupe.Copy( ent, {}, {}, ent:GetPos() )
	local CRet = {}

	local ecount,ccount = 0, 0
	for k,v in pairs(ETable) do
		ecount = ecount + 1
		if v.Class == "prop_vehicle_prisoner_pod" then
			if v.EntityMods then v.EntityMods["VehicleMemDupe"] = nil end
			if v.VehicleTable && v.VehicleTable.Members then v.VehicleTable.Members["HandleAnimation"] = nil end
		end
	end
	for _,v in pairs(CTable) do
		if v.Type != "" then
			-- The CTable needs to be reorganized, specifically the indexes must be removed and reset to be sequentially numerical.
			ccount = ccount + 1
			table.insert( CRet, v )
		end
	end

	local pos = ent:GetPos()
	local alltab = constraint.GetAllConstrainedEntities(ent)
	table.insert(alltab, ent)
	local trace = util.TraceLine({start = pos,endpos = Vector(pos.x, pos.y, -30000),filter = alltab})

	-- Setup our single savable table
	local Ret = {
		ETable  = ETable,
		CTable  = CRet,
		HeadID  = ent:EntIndex(),
		HeadPos = pos,
		ECount  = ecount,
		CCount  = ccount,
		Height  = pos.z - trace.HitPos.z
	}
	return Ret
end

local folder = "e2storeddata/advdupes/mapsaves/"
file.CreateDir(folder,"DATA")
require"glon"
function Nebcorp_MapSave()
	local props = {}
	for k,v in pairs(ents.FindByClass("prop_physics")) do
		if not NADMOD.Props[v:EntIndex()] then continue end
		local owner = NADMOD.Props[v:EntIndex()].Name
		if !props[v] && owner != "W" and owner != "O" && constraint.HasConstraints(v) then
			local cons = constraint.GetAllConstrainedEntities(v)
			local count = 0
			for _,subent in pairs(cons) do
				props[subent] = true
				count = count + 1
			end
			if count > 5 then
				file.Write(folder ..os.time().." "..game.GetMap().." "..string.gsub(string.gsub(owner, " ", "_"), "[^%w_]", "")..v:EntIndex().." "..count.." props.txt", glon.encode(Nebcorp_Dupe(v)))
			end
		end
	end
	local tab = file.Find(folder .."*"..game.GetMap().."*.txt","DATA")
	table.sort(tab)
	for k=42, #tab do file.Delete(folder .. table.remove(tab, 1)) end
end
timer.Create("Nebcorp_MapSave", 120, 0, Nebcorp_MapSave)


concommand.Add("debuge2s",function(ply,cmd,args)
	for k,v in pairs(ents.FindByClass("gmod_wire_expression2")) do print(NADMOD.Props[v:EntIndex()].Name,v,v.name) end
end)

-- NECTAR
/*
local messages = util.JSONToTable(file.Read("nebcorp/nectar_messages.txt") or "{}")
concommand.Add("RequestNectarMessages", function(ply,cmd,args)
	datastream.StreamToClients(ply,"Nectar_Messages", messages)
end)
datastream.Hook( "Nectar_Message", function(ply,handler,id,encoded,decoded)
	messages[decoded[1]] = decoded[2]
	local tab = {}
	tab[decoded[1]] = decoded[2]
	datastream.StreamToClients(player.GetAll(),"Nectar_Messages", tab)
	file.Write("nebcorp/nectar_messages.txt",util.TableToJSON(messages))
end)
hook.Add( "AcceptStream", "NectarAS", function(ply,handler,id)
	if handler == "Nectar_Message" then return true end
end)*/

hook.Add("AllowPlayerPickup","DisableToolgunE",function(ply,ent)
	return ply:GetActiveWeapon():GetClass() != "gmod_tool" and ply:GetActiveWeapon():GetClass() != "weapon_physgun"
end)

hook.Add("PlayerSpawnNPC","Nebcorp_LimitSomeTypes",function(ply,npctype,npcweapon)
	if npctype == "npc_combinegunship" and #ents.FindByClass(npctype) > 0 then ply:PrintMessage(HUD_PRINTCENTER,"There is already a gunship!") return false end
	if npctype == "npc_combinedropship" and #ents.FindByClass(npctype) > 0 then ply:PrintMessage(HUD_PRINTCENTER,"There is already a dropship!") return false end
	if npctype == "npc_helicopter" and #ents.FindByClass(npctype) > 0 then ply:PrintMessage(HUD_PRINTCENTER,"There is already a helicopter!") return false end
	if npctype == "npc_strider" and #ents.FindByClass(npctype) > 1 then ply:PrintMessage(HUD_PRINTCENTER,"There is already two striders!") return false end
	if npctype == "npc_dog" then ply:PrintMessage(HUD_PRINTCENTER,"Dog leaves behind annoying laser beams!") return false end
end)

local META = FindMetaTable("Angle")

-- Returns the inverse of a rotation
function META:GetInverse()
	local Mp = Matrix()		Mp:Rotate(Angle(-self.p, 0, 0))
	local My = Matrix()		My:Rotate(Angle(0, -self.y, 0))
	local Mr = Matrix()		Mr:Rotate(Angle(0, 0, -self.r))
	
	return (Mr*Mp*My):GetAngle()
end

local function writeTableInternal(t, indent, done, f)
	for key, value in pairs (t) do
		f:Write( string.rep ("\t", indent) )
		if  ( istable(value) && !done[value] ) then
			done [value] = true
			f:Write( tostring(key) .. ":" .. "\n" );
			writeTableInternal (value, indent + 2, done, f)
		else
			f:Write( tostring (key) .. "\t=\t" )
			f:Write( tostring(value) .. "\n" )
		end
	end
end
function WriteTable ( t )
	local f = file.Open("table.txt","w","DATA")
	writeTableInternal(t, 0, {}, f)
	f:Close()
end

--jit.off() jit.flush()
hook.Remove( "PlayerTick", "TickWidgets")

timer.Create("PlayX Permission Setup", 0, 1, function()
	function PlayX.AccessManager(ply)
		return ply.UserRank and ply.UserRank > 4
	end
end)



-- This hook fixes a bug where entering a vehicle that is parented to you, or to an entity that is parented to you, will crash the server.
-- Remember to remove this if it's fixed by team garry or in the engine itself
local nextPrint = {} -- used to prevent message spam
hook.Add( "CanPlayerEnterVehicle", "check vehicle parented to player", function( ply, veh )
    local parent = veh:GetParent()
    while IsValid( parent ) do
        if parent == ply then
            if not nextPrint[ply] or nextPrint[ply] < RealTime() then
                WireLib.AddNotify(ply, "You can't enter this vehicle because it is parented to you.", NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1 ) -- prettier notification
                --ply:ChatPrint( "You can't enter this vehicle because it is parented to you." )
                nextPrint[ply] = RealTime() + 0.3
            end
            return false
        end
        if parent == veh then return end -- parent loop? this should've crashed the server already but okay
        parent = parent:GetParent()
    end
end )

print("[Nebcorp.lua - Nebtown's Misc Scripts Loaded!]")
