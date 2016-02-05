-- Nebual 2012 (nebual@nebtown.info) presents:
-- NADMOD - Nebcorp Administration Designation Module


if !NADMOD then
	-- Stuff in here will only ever be run once per serverload
	NADMOD = util.JSONToTable(file.Read("nadmod_config.txt","DATA") or "") or {Users = {}, Groups = {}, Bans = {}, PPConfig = {}}
	NADMOD.Version = "1.0"
	
	concommand.Add("nadmod_reload", function(ply,cmd,args) 
		if args[1] == "full" then NADMOD = nil end 
		include("autorun/server/nadmod.lua")
		if file.Exists("autorun/server/nadmod_pp.lua","LUA") then include("autorun/server/nadmod_pp.lua") end
	end) -- For development mostly
	AddCSLuaFile("autorun/client/cl_nadmod.lua")
	
	CreateConVar("nadmod_whisperrange", 400, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
	-- If you wish your server to password itself when it has over nadmod_maxplayers for lag reasons,
	-- so that your regulars may still join an otherwise 'full' server
	CreateConVar("nadmod_maxplayers", 1000, {FCVAR_NOTIFY, FCVAR_ARCHIVE})
	CreateConVar("nadmod_password", "vip", {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_PROTECTED})
	
	util.AddNetworkString("nadmod_pm")
	util.AddNetworkString("nadmod_w")
	util.AddNetworkString("nadmod_say")
	util.AddNetworkString("nadmod_msg")
	util.AddNetworkString("nadmod_maplist")
	util.AddNetworkString("nadmod_menu_download")
	util.AddNetworkString("nadmod_menu_upload")
	util.AddNetworkString("NADMOD.BuildMode")
	
	if not NADMOD.Groups[1] then NADMOD.Groups[1] = {Name="Guest",Color=Color(110,110,110),Permissions = {"Communications"},Loadout = {"GravGun","PhysGun","ToolGun","Camera"}} end
	if table.Count(NADMOD.Groups) == 1 then NADMOD.Groups[25] = {Name="Admin",Color=Color(200,10,10), Permissions = {"Communications","Teleport","SetRank","Cheats","Admin_Status","Annoys","KickBan","MapChange","Weapons","TeleportOthers","PP_All"},Loadout = {"GravGun","PhysGun","ToolGun","Camera","AR2","Crowbar"}} end
	//setmetatable(NADMOD.Groups, {__index = function(t) return t[1] end})
	
	-- Generate us a list of maps, so !maps will list our top 10
	NADMOD.MapsList = util.JSONToTable(file.Read("nadmod_mapslist.txt","DATA") or "{}")
	NADMOD.MapsList[game.GetMap()] = (NADMOD.MapsList[game.GetMap()] or 0) + 1
	for _,v in pairs(file.Find("maps/*.bsp","GAME")) do v = string.sub(v,1,-5) if !NADMOD.MapsList[v] then NADMOD.MapsList[v] = 0 end end
	file.Write("nadmod_mapslist.txt", util.TableToJSON(NADMOD.MapsList))
	
	-- Lets make up a fake player-ish entity so the serverconsole can use chat functions without errors
	local function MakeGman(pos)
		Gman = ents.Create("base_gmodentity")
		Gman:SetModel("models/player/gibs/gibs_balloon.mdl") 
		Gman.Nick = function() return "Gman" end Gman.Namage = {Immune = 1, HP = 9001, MaxHP = 9001} 
		Gman:SetOverlayText("("..NADMOD.PPVersion..") I am Gman, god from the machine.")
		Gman.GetClass = function() return "Omnipresent" end Gman.UniqueID = function() return 666 end
		Gman.IsAdmin = function() return true end
		Gman.UserRank = 50
		Gman.CompareRank = 50
		Gman.UserID = function() return 666 end Gman.AddCount=function() return end Gman.AddCleanup=function() return end Gman.GetAimVector=function() return Vector() end Gman.GetShootPos=function() return Gman:GetPos() end
		Gman.CheckLimit = function() return true end Gman.GetWeapon = function() return NULL end
		Gman.SteamID = function() return "666" end
		if pos then Gman:SetPos(pos) end 
		Gman.OnRemove = function(self) 
			local pos = self.Entity:GetPos() 
			timer.Create("Make Gman", 0.25, 1, function() MakeGman(pos) end) 
		end
		Gman:PhysicsInit( SOLID_VPHYSICS ) Gman:SetMoveType( MOVETYPE_VPHYSICS ) Gman:SetSolid( SOLID_VPHYSICS ) Gman:SetCollisionGroup( COLLISION_GROUP_WEAPON ) Gman:Spawn() 
	end
	timer.Create("Make Gman", 0.4, 1, MakeGman)
	
	-- For loadouts
	NADMOD.Weapons = {
		ToolGun = "gmod_tool",
		Camera = "gmod_camera",
		GravGun = "weapon_physcannon",
		PhysGun = "weapon_physgun",
		Crowbar = "weapon_crowbar",
		Stunstick = "weapon_stunstick",
		Pistol = "weapon_pistol",
		Revolver = "weapon_357",
		SMG = "weapon_smg1",
		Shotgun = "weapon_shotgun",
		Crossbow = "weapon_crossbow",
		AR2 = "weapon_ar2",
		RPG = "weapon_rpg",
		Frag = "weapon_frag",
		Bug_Bait = "weapon_bugbait",
	}
end

// =======================================
// Main Chatcommand Definitions
// =======================================

NADMOD.Permissions = {
	-- HEY PLUGIN WRITERS, if you want to add more chatcommands to this in a seperate file just use
	-- timer.Simple(1,function() table.Merge(NADMOD.Permissions, YourExtraCommandsTableHere) end)
	/* Notes on writing ChatCommands:
		ThisPartIsThePermissionName = {
			lowercase_chatcmd = function(ply,args) ply:SendMessage("Bonk!") return 2, "Boink!" end,
		},
		NADMOD.FindPlayer(string) is a convinence function that returns the ent of the player whose name contains 'string'.
		NADMOD.GuessTarget(ply,args) is a convinence function that attempts to find a target based on args[1], defaults to the ply if none is found, and also returns the next arg
		local tar,hp = NADMOD.GuessTarget(ply,args) // For '!cmd Neb 20' this'll return 'Entity[neb] & 20', while '!cmd 20' returns 'Entity[you] & 20'
		
		RETURN A # AND A "MESSAGE", because everyone likes chat responce to their commands. The # corresponds with what kind of message you want.
		return 1, "This is an --error-- message just to the player."
		return 2, "This is a normal message just to the player."
		return 3, "This is a normal message to all gmodders."
		return 4, "This is a message to IRC & all gmodders."
	*/
	Teleport = {
		goto = function(ply,args)
			local x,y,z = string.match( args[1], "^ *([^%s,]+) *, *([^%s,]+) *, *([^%s,]+) *$" )
			if tonumber(x) and tonumber(y) and tonumber(y) then
				ply:SetPos(Vector(tonumber(x),tonumber(y),tonumber(z)))
				return 3, ply:Nick().." has gone to "..args[1]
			end
			
			local tar = NADMOD.FindPlayer(args[1])
			if !tar then return 1, "Sorry, to whom are you going?" end 
			ply:SetPos(tar:GetPos() + tar:GetAimVector()*-50 + Vector(0,0,80)) 
			return 3, ply:Nick().." has gone to "..tar:Nick()..NADMOD.MightSay(6,1,"!") 
		end,
	},
	TeleportOthers = {
		tp = function(ply,args)
			local tar = ply 
			if args[1] then 
				tar = FindPlayer(args[1]) 
				if !tar then return 1, "I can't find anyone by that name!" end
				if !NADMOD.RankCheck(ply, tar) then return 1, tar:Nick().." outranks you too much." end
			end
			tar:SetPos(ply:GetEyeTraceNoCursor().HitPos + ply:GetEyeTraceNoCursor().HitNormal*20) 
			return 3, tar:Nick().." has gone to "..ply:Nick().."'s view"..NADMOD.MightSay(6,1,"!")
		end,
		bring = function(ply,args) 
			local tar = FindPlayer(args[1]) 
			if !tar then return 1, "I can't find that player." end 
			if !NADMOD.RankCheck(ply, tar) then return 1, tar:Nick().." outranks you too much." end
			local tarPos = ply:GetPos() + ply:GetAimVector()*50 + Vector(0,0,80)
			if tar:Health() <= 0 then tarPos = tar:GetRagdollEntity():GetPos() + Vector(0,0,50) tar:Spawn() end
			tar:SetPos(tarPos)
			return 3, ply:Nick().." has brought "..tar:Nick().." to himself"..NADMOD.MightSay(5,1,"!") 
		end,
		send = function(ply,args)
			local tar, tar2 = FindPlayer(args[1]), FindPlayer(args[2])
			if !tar then return 1, "I can't find that player." end
			if !tar2 then return 1, "Who is the second player?" end
			if !NADMOD.RankCheck(ply, tar) then return 1, tar:Nick().." outranks you too much." end
			if !NADMOD.RankCheck(ply, tar2) then return 1, tar2:Nick().." outranks you too much." end
			tar:SetPos(tar2:GetPos() + tar2:GetAimVector()*50 + Vector(0,0,80))
			return 3, ply:Nick().." has sent "..tar:Nick().." to "..tar2:Nick()..NADMOD.MightSay(5,1,"!")
		end,
	},
	Cheats = {
		god = function(ply,args) 
			local tar = NADMOD.GuessTarget(ply,args)
			if !tar then return 1, "I can't find your god!" end
			local name = tar:Nick()
			if tar.Godded then tar.Godded = false tar:GodDisable() hook.Remove("PlayerSpawn", "God"..name) return 3, ply:Nick().." has ungodded "..name..NADMOD.MightSay(8,1,".")
			else 
				tar.Godded = true 
				tar:GodEnable() 
				hook.Add("PlayerSpawn", "God"..name,function(ply) 
					if !IsValid(tar) then hook.Remove("PlayerSpawn", "God"..name) end
					if ply:Nick() == name then ply:GodEnable() end 
				end) 
				return 3, ply:Nick().." has godded "..name..NADMOD.MightSay(8,1,"!")
			end 
		end,
		health = function(ply,args) 
			local tar,hp = NADMOD.GuessTarget(ply,args)
			if not tonumber(hp) then return 1, "How much health?" end
			tar:SetHealth(tonumber(hp))
			return 3, ply:Nick().." has set "..tar:Nick().."'s health to "..hp
		end,
		armor = function(ply,args) 
			local tar,arm = NADMOD.GuessTarget(ply,args)
			if not tonumber(arm) then return 1, "How much armor?" end
			tar:SetArmor(tonumber(arm))
			return 3, ply:Nick().." has set "..tar:Nick().."'s armor to "..arm
		end,
	},
	Annoys = {
		rocket = function(ply,args)
			local tar,dmg = NADMOD.GuessTarget(ply,args) 
			if !tar then return 1, "I can't find who to rocket!" end
			if !dmg then dmg = 100 end
			tar:SetMoveType(MOVETYPE_WALK)
			tar:SetVelocity(tar:GetUp() * 5500)
			tar:Freeze(true)
			timer.Create("NADMOD-Explode"..tar:Nick(),3,1, function() NADMOD.Explode(tar,dmg) tar:Freeze(false) end)
			return 3, ply:Nick().." has rocketed "..tar:Nick().."! Have a nice trip!"
		end,
		freeze = function(ply,args)
			local tar = NADMOD.GuessTarget(ply,args) if !tar then return 1, "I can't find who's an icecube!" end
			tar.Frozen = !tar.Frozen
			if tar.Frozen then
				tar:Lock(true)
				return 3, ply:Nick().." has frozen "..tar:Nick().."!"
			else
				tar:UnLock(true)
				return 3, ply:Nick().." has unfrozen "..tar:Nick().."!"
			end
		end,
		drunk = function(ply,args) -- I'm sorry this exists
			local tar, dur = NADMOD.GuessTarget(ply,args)
			if !tar then return 1, "I can't find who's having too much to drink!" end
			dur = math.Min(tonumber(dur) or 8, 20)
			NADMOD.Drunk(tar,dur)
			return 3, ply:Nick().." has made "..tar:Nick().." drunk for "..dur.." seconds!"
		end,
		slap = function(ply, args)
			local tar, dmg = NADMOD.GuessTarget(ply,args)
			if !tar then return 1, "I can't find who's getting slapped!" end
			if !dmg then dmg = 10 end
			tar:TakeDamage(dmg)
			tar:EmitSound("/player/damage"..math.random(1,3)..".wav",100,10*math.random(5,15))
			tar:ViewPunch((VectorRand()*5):Angle())
			return 3, ply:Nick().." has just slapped "..tar:Nick().." for "..dmg.." damage!"
		end,
		ragdoll = function(ply,args)
			local tar = NADMOD.GuessTarget(ply,args) if !tar then return 1, "I can't find who's a dolly!" end
			if tar.Ragdoll then
				tar:SetParent() 
				tar:Spawn()
				tar:DrawViewModel( true )
				tar:GodDisable()
				if IsValid(tar.Ragdoll) then 
					local pos = tar.Ragdoll:GetPos() 
					timer.Simple(.05, function() tar:SetPos(pos + Vector(0,0,10)) end) 
					tar.Ragdoll:RemoveCallOnRemove( "playerragdoll" )
					tar.Ragdoll:Remove()
				else tar:SetPos(tar.RagdollSpawnPos)
				end
				tar.RagdollSpawnPos = nil 
				tar.Ragdoll = nil
				return 3, ply:Nick().." has unragdolled "..tar:Nick()..NADMOD.MightSay(4, ", awesome.", "!")
			else 
				local doll = PlayerRagdoll(tar)
				if doll then 
					doll.Namage = false
					tar.Ragdoll = doll 
					tar.RagdollSpawnPos = tar:GetPos() 
					tar:DrawViewModel( false )
					tar:SetParent( doll )
					tar:StripWeapons()
					tar:GodEnable()
					doll:CallOnRemove( "playerragdoll", function() 
						tar:SetParent() 
						tar:Spawn()
						tar:DrawViewModel( true )
						tar:GodDisable()
						local pos = doll:GetPos() 
						timer.Simple(.05, function() tar:SetPos(pos + Vector(0,0,10)) end) 
						tar.RagdollSpawnPos = nil 
						tar.Ragdoll = nil
					end )
				else return 1, "Erm, something went wrong..." end
				return 3, ply:Nick().." has ragdolled "..tar:Nick()..NADMOD.MightSay(3,1, ".")
			end 
		end,
		kill = function(ply,args)
			local tar = FindPlayer(args[1])
			if !tar then return 1, "I can't find that player." end 
			if !NADMOD.RankCheck(ply, tar) then return 1, tar:Nick().." outranks you too much." end
			tar:Kill()
			return 3,ply:Nick().." has slain "..tar:Nick().."!"
		end,
		build = function(ply,args)
			local tar = NADMOD.GuessTarget(ply,args)
			if !tar then return 1, "I can't find that player." end 
			if !NADMOD.RankCheck(ply, tar) then return 1, tar:Nick().." outranks you too much." end
			tar.BuildMode = !tar.BuildMode
			net.Start("NADMOD.BuildMode")
				net.WriteBit(!tar.BuildMode)
			net.Send(tar)
			return 3,ply:Nick().." has "..(tar.BuildMode and "disabled " or "enabled ")..tar:Nick().."'s buildmode!"
		end,
	},
	Communications = {
		me = function(ply,args) NADMOD.GlobalSay(ply:Nick(), string.char(1).."ACTION "..table.concat(args," ")..string.char(1), true) return 3, ply:Nick().." "..table.concat(args, " ") end,
		pm = function(ply,args) 
			local tar,msg = FindPlayer(table.remove(args,1)),table.concat(args, " ")
			if !tar then return 1, "I need a target! (!pm Jake NO MOAR FUNGUS PLZ)" end
			net.Start("nadmod_pm")
				net.WriteColor(ply.UserColor or NADMOD.Groups[1].Color)
				net.WriteString(ply:Nick())
				net.WriteString(msg)
			net.Send({tar,ply})
		end,
		w = function(ply,args)
			local msg,plys = table.concat(args, " "),{}
			for k,v in pairs(player.GetAll()) do if v:GetPos():Distance(ply:GetPos()) < GetConVarNumber("nadmod_whisperrange") then table.insert(plys,v) end end
			net.Start("nadmod_w")
				net.WriteColor(ply.UserColor or NADMOD.Groups[1].Color)
				net.WriteString(ply:Nick())
				net.WriteString(msg)
			net.Send(plys)
		end,
	},
	SetRank = {
		setrank = function(ply,args) NADMOD.SetRank(args[1],args[2],ply) end,
	},
	Admin_Status = { -- This is mostly just to give out Gmod's builtin IsAdmin status
		menu = function(ply,args) ply:ConCommand("nadmod_open") end,
	},
	PP_All = {},
	NoclipAlways = {},
	KickBan = {
		ban = function(ply,args)
			local tar,time,reason,steamid = FindPlayer(args[1]),tonumber(args[2]), "", ""
			for k=3,#args do reason = reason .." "..args[k] end
			if args[1]:sub(1,6) == "STEAM_" then
				if args[2] == ":" then -- In console, args is split along both spaces and :'s unfortunately
					steamid = args[1]..args[2]..args[3]..args[4]..args[5]
					time = tonumber(args[6])
					reason = ""
					for k=7,#args do reason = reason .." "..args[k] end
				else
					steamid = args[1]
				end
			end
			
			if !time then return 1, "I need a target and a time in minutes (!ban Jake 5 NO MOAR FUNGUS PLZ)" end
			if tar then
				if !NADMOD.RankCheck(ply, tar) then return 1, tar:Nick().." outranks you too much." end
				steamid = tar:SteamID()
			elseif !steamid then
				return 1, "I need a target and a time in minutes (!ban Jake 5 NO MOAR FUNGUS PLZ)"
			end
			if time == 0 then time = 60*24*31 end -- month ban
			
			if reason == "" then reason = " no reason" end
			NADMOD.Bans[steamid] = {os.time() + 60*time,reason}
			NADMOD.Save()
			if tar then 
				tar:Kick("Banned for "..time.." mins,"..reason.."!")
				return 4, ply:Nick().." has banned "..tar:Nick().." for "..time.." minutes, for:"..reason.."!"
			else
				return 4, ply:Nick().." has banned "..steamid.." for "..time.." minutes, for:"..reason.."!"
			end
		end,
		kick = function(ply,args)
			local tar,reason = FindPlayer(args[1]),""
			if !tar then return 1, "I need a target! (!kick Jake NO MOAR FUNGUS PLZ)" end
			if !NADMOD.RankCheck(ply, tar) then return 1, tar:Nick().." outranks you too much." end
			for k=2,#args do reason = reason .. args[k].." " end
			if reason == "" then reason = "no reason" end
			tar:Kick(reason.."!")
			return 4, ply:Nick().." has kicked "..tar:Nick().." for: "..reason.."!"
		end,
	},
	MapChange = {
		map = function(ply,args)
			if !args[1] then return 1, "Syntax: !map gm_construct 60" end
			local map,time = string.lower(args[1]),tonumber(args[2])
			for _,v in pairs(file.Find("maps/*.bsp","GAME")) do v = string.sub(v,1,-5) if !NADMOD.MapsList[v] then NADMOD.MapsList[v] = 0 end end
			if !NADMOD.MapsList[map] then for k,v in pairs(NADMOD.MapsList) do if string.find(k,map) then map = k break end end end
			if time then 
				timer.Create("MapChange", time, 1, function() NADMOD.MapChange(map) end)
				timer.Create("MapChangeMumble", 15, math.floor(time/15), function() 
					time = time - 15
					NADMOD.Message("Map changing to "..map.." in "..time.." seconds!")
				end)
				return 4, ply:Nick().." has started a mapchange to "..map.." in "..time.." seconds!"
			else 
				NADMOD.MapChange(map)
			end
		end,
		cancelmap = function(ply,args) 
			if timer.Exists("MapChange") then 
				timer.Destroy("MapChangeMumble") 
				timer.Destroy("MapChange") 
				return 4, ply:Nick().." has cancelled the map change!" 
			else 
				return 1, "There is no map change in progress at the moment."
		end end,
		maps = function(ply,args) 
			for _,v in pairs(file.Find("maps/*.bsp","GAME")) do v = string.sub(v,1,-5) if !NADMOD.MapsList[v] then NADMOD.MapsList[v] = 0 end end
			net.Start("nadmod_maplist")
				net.WriteTable(NADMOD.MapsList)
			net.Send(ply)
		end,
		noclip = function(ply,args) if !args[1] then return 2, "Noclip is currently "..GetConVarNumber("sbox_noclip") else game.ConsoleCommand("sbox_noclip "..tonumber(args[1]).."\n") end end,
		sbox = function(ply,args)
			if !args[1] then return 1, "Syntax: '!sbox noclip 1' or '!sbox maxnpcs' to find the current value" end
			if !tonumber(args[2]) then return 2, "sbox_"..args[1].." is currently: "..GetConVarNumber("sbox_"..args[1]) end
			game.ConsoleCommand("sbox_"..args[1].." "..tonumber(args[2]).."\n")
			return 2, "Running: sbox_"..args[1].." "..tonumber(args[2])
		end,
		jit = function(ply,args)
			if jit.status() then
				jit.off() jit.flush()
				game.ConsoleCommand("wire_expression2_unlimited 2\n")
				return 3, ply:Nick().." disabled LuaJIT serverside."
			else
				jit.on() jit.flush()
				game.ConsoleCommand("wire_expression2_unlimited 0\n")
				return 3, ply:Nick().." reenabled LuaJIT serverside."
			end
		end,
		crashserver = function(ply,args) 
			if !ply.HasBeenWarned then 
				ply.HasBeenWarned = true 
				return 2, "Warning: This will actually crash the server (concommand 'exit') and it may not autorestart. Execute again to confirm." 
			else
				NADMOD.GlobalSay("Okays, I warned him, "..ply:Nick().." ran !crashserver.") 
				timer.Simple(1, function() game.ConsoleCommand("exit\n") end) 
			end 
		end,
	},
	All = {
		help = function(ply) 
			local cmds = ""
			local tab = table.Copy(NADMOD.Groups[ply.UserRank or 1].Permissions)
			if NADMOD.Users[ply:SteamID()] then table.Add(tab, NADMOD.Users[ply:SteamID()].Permissions) end
			table.insert(tab, "All")
			for _,v in ipairs(tab) do 
				for cmd in pairs(NADMOD.Permissions[v]) do cmds = cmds .. "!"..cmd..", " end
				cmds = string.sub(cmds,1,-3) .. " | "
			end
			return 2, "As you are rank "..NADMOD.Groups[ply.UserRank or 1].Name.."["..(ply.UserRank or 1).."], you can use the following chat commands: "..string.sub(cmds,1,-4).."."
		end,
		hint = function(ply) NADMOD.GeneralHint(ply, {}) end,
		setpin = function(ply, args)
			local accounts = util.JSONToTable(file.Read("nebcorp/atm_pins.txt","DATA") or "{}")
			local account, pin = ply:SteamID(), args[1]
			if #args > 1 then account, pin = args[1], args[2] end
			if accounts[account] then
				return 1, "That account already exists."
			end
			accounts[account] = pin
			file.Write("nebcorp/atm_pins.txt", util.TableToJSON(accounts))
			return 2, "Pin set!"
		end,
	},
	Weapons = {
		default = function(ply,args) 
			local tar = NADMOD.GuessTarget(ply,args)
			tar:StripWeapons()
			for _,v in ipairs(NADMOD.GetiTable(tar,"Loadout")) do v = NADMOD.Weapons[v] tar:Give(v) end
			return 3, ply:Nick().." has stripped "..tar:Nick().." down to default weapons!"
		end,
		strip = function(ply,args)
			local tar = NADMOD.GuessTarget(ply,args)
			tar:StripWeapons()
			return 3, ply:Nick().." has stripped "..tar:Nick().."!"
		end,
		give = function(ply, args)
			local tar,wep = NADMOD.GuessTarget(ply,args) if !wep then wep = "a hand" end
			tar:Give(wep)
			return 3, ply:Nick().." has given "..tar:Nick().." "..wep.."!"
		end,
	}
}
NADMOD.PermissionsAlias = {
	-- These aren't shown to clients in the Permissions Settings or in !help, but still function as commands
	-- They're ideally just convinent aliases people might accedentally stumble on
	All = {
		cmds = NADMOD.Permissions.All.help,
	},
	Cheats = {
		ungod = function(ply,args) if NADMOD.GuessTarget(ply,args).Godded then return NADMOD.Permissions.Cheats.god(ply,args) end return 1, "He isn't godded!"..NADMOD.MightSay(3, 2, "!") end,
	},
	Annoys = {
		unragdoll = function(ply,args) if NADMOD.GuessTarget(ply,args).Ragdoll then return NADMOD.Permissions.Annoys.ragdoll(ply,args) end return 1, "He isn't a ragdoll"..NADMOD.MightSay(2, 2, "!") end,
		slay = NADMOD.Permissions.Annoys.kill,
	},
	Weapons = {strip = NADMOD.Permissions.Weapons.default,},
}
timer.Create("Nadmod_Build_Permissions", 3, 1, function()
	timer.Remove("Nadmod_Build_Permissions")
	-- This delay is so any Plugins can load up
	NADMOD.PermissionsFull = table.Copy(NADMOD.Permissions)
	table.Merge(NADMOD.PermissionsFull, NADMOD.PermissionsAlias)
end)

NADMOD.Hints = string.Explode("\n", file.Read("nadmod_generalhints.txt","DATA") or "")
function NADMOD.GeneralHint(ply, hasbeensaid)
	if !ply:IsValid() then return end
	local hint
	for try=1,3 do
		hint = table.Random(NADMOD.Hints)
		if hasbeensaid[hint] then 
			hint = nil 
		else 
			hasbeensaid[hint] = true
			break 
		end
	end
	if hint then WireLib.AddNotify(ply, hint, NOTIFY_HINT, 7, math.random(1,5)) end
end

hook.Add("PlayerInitialSpawn", "NADMOD_InitSpawn", function(ply)
	NADMOD.RefreshRanks(ply)
	if ply:IsBot() then return end
	//print(ply:Nick().." has finished loading!")
	local num,msg = NADMOD.Permissions.All.help(ply)
	NADMOD.Message(msg, ply)
	
	if #NADMOD.Hints > 1 then
		local hasbeensaid = {}
		timer.Create("NADMOD_GeneralHintInit"..ply:EntIndex(), 60, 1, function()
			timer.Create("NADMOD_GeneralHint"..ply:EntIndex(), 7, math.Min(5,#NADMOD.Hints), function() NADMOD.GeneralHint(ply,hasbeensaid) end)
			timer.Destroy("NADMOD_GeneralHintInit"..ply:EntIndex())
		end)
	end
end)

function NADMOD.MapChange(map)
	NADMOD.GlobalSay("Changing map to "..map.."!")
	timer.Create("NADMOD.MapChange",0.5,1,function() game.ConsoleCommand("changelevel "..map.."\n") end)
end

function NADMOD.SetRank(name, group, inflictor)
	local tar, rank = NADMOD.FindPlayer(name), NADMOD.FindGroup(group)
	if tar && rank then
		if IsValid(inflictor) and (inflictor.UserRank or 1) < rank then return NADMOD.Message("---Command failed---: You cannot promote someone past your own rank!", inflictor) end
		local message = ""
		if !tar.UserRank then tar.UserRank = 1 end
		if tar.UserRank < rank then message = "Promoted "..tar:Nick().."'s rank from "..NADMOD.Groups[tar.UserRank].Name.." ["..tar.UserRank.."] to "..NADMOD.Groups[rank].Name.." ["..rank.."]!"
		elseif tar.UserRank > rank then 
			message = "Demoted "..tar:Nick().."'s rank from "..NADMOD.Groups[tar.UserRank].Name.." ["..tar.UserRank.."] to "..NADMOD.Groups[rank].Name.." ["..rank.."]! Throw ovens at him!"
			NADMOD.SpamOvens(tar)
		end
		
		local id = tar:SteamID()
		if !NADMOD.Users[id] then NADMOD.Users[id] = {Rank = rank} else NADMOD.Users[id].Rank = rank end
		NADMOD.RefreshRanks(v)
		NADMOD.Save()
		
		if IsValid(inflictor) then message = inflictor:Nick() .. " " .. message end
		NADMOD.GlobalSay(message)
	elseif !tar then print("Sorry, could not find that person!")
	elseif !rank then print("Sorry, could not find that rank!")
	end
end
concommand.Add("nadmod_setrank", function(ply, cmd, args) if ply:IsValid() && !ply:IsAdmin() then return end NADMOD.SetRank(args[1],args[2]) end)

// NADMOD Helper Functions
function NADMOD.FindGroup(name)
	if tonumber(name) then 
		if NADMOD.Groups[tonumber(name)] then return tonumber(name) end
	else
		name = string.lower(name)
		for k,v in pairs(NADMOD.Groups) do
			if string.find(string.lower(v.Name), name) then return k end
		end
	end
	return false
end
-- Awesome convinence function that returns the player with the given case-insensitive partial name
function NADMOD.FindPlayer(nick) 
	if not nick or nick == "" then return end 
	nick = string.lower(nick)
	local num = tonumber(nick)
	for _,v in pairs(player.GetAll()) do
		if string.lower(v:Nick()) == nick then return v -- Exact name match
		elseif v:UserID() == num then return v 			-- UserID match
		end
	end
	-- If the above two exact searches fail, try doing a partial search
	for _,v in pairs(player.GetAll()) do
		if string.find(string.lower(v:Nick()), nick) then return v end
	end
end
FindPlayer = NADMOD.FindPlayer

function NADMOD.GuessTarget(ply,args)
	local tar,arg
	if args[1] then
		tar,arg= NADMOD.FindPlayer(args[1]), args[2]
	end
	if !tar then tar,arg= ply, args[1] end
	return tar,arg
end
function NADMOD.HasPermission(ply, perm)
	if perm == "All" then return true end
	if !ply:IsValid() then return false end
	local tab = table.Copy(NADMOD.Groups[ply:GetRank()].Permissions)
	if NADMOD.Users[ply:SteamID()] then table.Add(tab, NADMOD.Users[ply:SteamID()].Permissions) end
	for _,v in ipairs(tab) do
		if perm == v then return true end
	end
	return false
end
local meta = FindMetaTable("Player")
function meta:IsAdmin() return NADMOD.HasPermission(self, "Admin_Status") or self:IsSuperAdmin() end // ply:SetUserGroup("admin") seems to have broken in a recent gmod update, so I'll just override IsAdmin with my own :D
function meta:GetRank() return (NADMOD.Users[self:SteamID()] or {Rank=1}).Rank end

function NADMOD.GetiTable(ply,title) 
	local tab = table.Copy(NADMOD.Groups[ply.UserRank or 1][title] or {}) 
	local tab2 = (NADMOD.Users[ply:SteamID()] or {})[title]
	if tab2 then table.Add(tab, tab2) end
	return tab 
end
function NADMOD.GetValue(ply,title)
	local value = (NADMOD.Users[ply:SteamID()] or {})[title]
	if !value then value = NADMOD.Groups[ply.UserRank or 1][title] end
	return value
end
function NADMOD.SpamOvens(ply)
	NADMOD.Message("You just got OVEN'd", ply)
	ply:SetMoveType(2)
	for k=1,3 do
		local ent = ents.Create("prop_physics_multiplayer")
		ent:SetModel("models/props_c17/furnitureStove001a.mdl")
		ent:Spawn()
		ent:SetPos(ply:GetPos() + Vector(0,0,180 + 105*k))
		ent:SetVelocity(Vector(math.random(-5,5),math.random(-5,5),-200 - math.random(100,600)))
		timer.Create(ent:EntIndex().."kill", 15, 1, function() if ent:IsValid() then ent:Remove() end end)
	end
end
function NADMOD.Drunk(ply,dur)
	NADMOD.Message("You just got DRUNK'd",ply)
	if !IsValid(ply) or !ply:IsPlayer() then return end
	timer.Create("NADMOD-Drunk"..ply:Nick(), 1,math.Min(60,dur), function() if ply:IsValid() then ply:ViewPunch((VectorRand()*10):Angle()) end end)
end
function NADMOD.Explode(ply, dmg)
	NADMOD.Message("You just got EXPLOD'd", ply)
	if !IsValid(ply) or !ply:IsPlayer() then return end
	local explosive = ents.Create("env_explosion")
	explosive:SetPos(ply:GetPos())
	explosive:SetOwner(ply)
	explosive:Spawn()
	explosive:SetKeyValue("iMagnitude", "5")
	explosive:Fire("Explode", 0, 0)
	explosive:EmitSound( "ambient/explosions/explode_4.wav", 100, 100)
	util.BlastDamage(ply, ply, ply:GetPos(), ply:BoundingRadius()*1.75, ply:BoundingRadius() / 6)
	ply:TakeDamage(dmg)
end
	
function NADMOD.RankCheck(ply1, ply2)
	return (((ply1.CompareRank or 1) + 2) > (ply2.CompareRank or 1))
end
function NADMOD.MightSay(chance, msg, alternative)
	-- The point of this is to make it really easy to go like
	-- print("You went to Jake's location"..NADMOD.MightSay(6,", you twat.", "."))
	-- Which would give a 1 in 6 chance of adding " you twat" to the end.
	if type(msg) == "table" then
		for _,v in ipairs(msg) do
			if math.random(chance * #msg) == 1 then return v end
		end
	elseif type(msg) == "number" then
		 return NADMOD.MightSay(chance, NADMOD.ChanceResponces[msg], alternative)
	elseif math.random(chance) == 1 then return msg
	end
	return alternative
end
NADMOD.ChanceResponces = {
	{ -- 1 General silly afterthoughts
		", what a silly decision.",
		", I'm not really sure why.",
		", the silly twat.",
		", the weirdo he is.",
		", be that as it may.",
		", not his best decision.",
		", as if that was a good idea.",
		", I wouldn't have!",
		", good luck...",
	},
	{ -- 2 Responces to things like "failed to ungod because isn't godded"
		", though I can't imagine why not.",
		", and you thought he was?!",
	},
}



function NADMOD.RefreshRanks(ply)
	if !ply then 
		local i = 0
		for k=1,50 do if NADMOD.Groups[k] then i = i + 1 NADMOD.Groups[k].CompareRank = i end end
		
		for _,ply in pairs(player.GetHumans()) do
			NADMOD.RefreshRanks(ply)
		end
		return
	end
	
	local steamid = ply:SteamID()
	if NIRC and !ply.UserRank and string.Left(ply:Nick(), 3) != 'Bot' then
		local text = "_finished loading the game_."
		if NADMOD.Users[steamid] && NADMOD.Users[steamid].LastSeen then 
			local hours = (os.time()-NADMOD.Users[steamid].LastSeen)/(60*60)
			if hours > 1 then
				text = text.." Last seen "..math.floor(hours/24).." days and "..math.Round((hours % 24)/10)*10 .." hours ago."
			end
		end
		text = text .. " " .. #player.GetAll().. " players online."
		NIRC.WebSay(ply:Nick(), text)
		ply.UserRank = 1
	end
	
	local tab = NADMOD.Users[steamid]
	if tab then 
		-- We actually have info stored on this guy, so lets refresh it. 
		tab.Nick = ply:Nick()
		
		tab.LastSeen = os.time()
		if !tab.Rank then tab.Rank = 1 end
		ply.UserRank = tab.Rank 
		ply.CompareRank = NADMOD.Groups[ply.UserRank].CompareRank
		if tab.Color then ply.UserColor = tab.Color else ply.UserColor = NADMOD.Groups[ply.UserRank].Color end
		if NADMOD.HasPermission(ply, "Admin_Status") then
			ply:SetUserGroup("admin") -- Tell Gmod he's an admin so ply:IsAdmin works
		end
	end
end
function NADMOD.RefreshPlayer(ply)
	NADMOD.RefreshRanks(ply)
	local id = "NADMOD_Strip_"..ply:Nick()
	timer.Create(id, 0.15, 1, function() 
		timer.Remove(id)
		if ply:IsValid() then ply:StripWeapons() for _,v in ipairs(NADMOD.GetiTable(ply,"Loadout")) do v = NADMOD.Weapons[v] ply:Give(v) ply:GiveAmmo(100,"Grenade") end end 
	end)
end
hook.Add("PlayerSpawn", "NADMOD_RefreshRanks", NADMOD.RefreshPlayer)

function NADMOD.AdjustMaxPlayers()
	if #player.GetHumans() >= GetConVarNumber("nadmod_maxplayers") then RunConsoleCommand("sv_password",GetConVarString("nadmod_password")) else RunConsoleCommand("sv_password","none") end
end
hook.Add("PlayerConnect","NADMOD_AdjustMaxPlayers",NADMOD.AdjustMaxPlayers)
-- It uses EntityRemoved because PlayerDisconnected doesn't catch all disconnects.
hook.Add("EntityRemoved","NADMOD.Disconnected",function(ent)
	if ent:IsValid() and ent:IsPlayer() and not ent:IsBot() then
		NADMOD.Message(ent:Nick().." has left the game.")
		NADMOD.AdjustMaxPlayers()
	end
end)

function NADMOD.Save()
	file.Write("nadmod_config.txt", util.TableToJSON({Users = NADMOD.Users, Groups = NADMOD.Groups, Bans = NADMOD.Bans, PPConfig = NADMOD.PPConfig}))
end
hook.Add("Shutdown","NADMOD.Save",NADMOD.Save)

function NADMOD.PlayerPickup(ply,ent)
	if ent:IsPlayer() && ply.CompareRank && NADMOD.RankCheck(ply,ent) then
		ent:SetMoveType(MOVETYPE_FLY) ent:SetGravity(0.0001)
		hook.Add("Tick","NADMOD_Stopholding_"..ent:EntIndex(), function() if ent:IsValid() && ply:IsValid() && !ply:KeyDown(IN_ATTACK) then ent:SetMoveType(MOVETYPE_WALK) ent:SetGravity(1) hook.Remove("Tick","NADMOD_Stopholding_"..ent:EntIndex()) end end)
		return true
	end
end
hook.Add("PhysgunPickup","NADMOD_Physgunhook",NADMOD.PlayerPickup)

function NADMOD.PlayerShouldTakeDamage(victim, attacker)
	return tobool(!attacker:IsValid() || !attacker:IsPlayer() || (attacker.UserRank && attacker.UserRank > 1))
end
hook.Add( "PlayerShouldTakeDamage", "NADMOD.PlayerShouldTakeDamage", NADMOD.PlayerShouldTakeDamage)

function NADMOD.PlayerSpawnSWEP(ply, class, info)
	if (!ply.UserRank or ply.UserRank == 0) and class != "laserpointer" then
		net.Start("nadmod_msg")
			net.WriteString("Newcomers can't spawn weapons, as this isn't a PVP server. Go wire something!")
		net.Send(ply)
		return false
	end
end
hook.Add( "PlayerSpawnSWEP", "NADMOD.PlayerSpawnSWEP", NADMOD.PlayerSpawnSWEP)
hook.Add( "PlayerGiveSWEP", "NADMOD.PlayerGiveSWEP", NADMOD.PlayerSpawnSWEP)

local colortable = {} colortable[50] = 2 colortable[25] = 4 colortable[10] = 12 colortable[6] = 11 colortable[5] = 4 colortable[4]=3 colortable[2]=10 colortable[1]=14
function NADMOD.IRCName(ply)
	if !ply:IsValid() or !ply:IsPlayer() then return end
	return string.char(2)..string.char(3)..colortable[(NADMOD.Users[ply:SteamID()] or {Rank = 1}).Rank]..ply:Nick()..string.char(2)..string.char(3)
end

function NADMOD.Message(msg, ply)
	net.Start("nadmod_msg")
		net.WriteString(msg)
	if ply then net.Send(ply) else
		net.Broadcast()
		print("Nadmod: "..msg)
	end
end
function NADMOD.GlobalSay(msg, justirc)
	if NIRC then 
		if justirc then NIRC.WebSay(msg) else NIRC.Say(msg) end
	elseif not justirc then
		NADMOD.Message(msg) 
	end
end

function NADMOD.ProcessChat(ply, msg)
	local args = string.Explode(" ", msg)
	local cmd = string.lower(string.sub(table.remove(args, 1), 2))
	local tab = table.Copy(NADMOD.Groups[ply.UserRank or 1].Permissions)
	if NADMOD.Users[ply:SteamID()] then table.Add(tab, NADMOD.Users[ply:SteamID()].Permissions) end
	table.insert(tab, "All")
	for _,v in ipairs(tab) do
		if NADMOD.PermissionsFull[v][cmd] then
			local mode,message = NADMOD.PermissionsFull[v][cmd](ply, args)
			if !mode then return true end
			if mode == 1 then NADMOD.Message("---Command failed---: "..message, ply)
			elseif mode == 2 then NADMOD.Message(message, ply)
			elseif mode == 3 then NADMOD.Message(message)
			elseif mode == 4 then NADMOD.GlobalSay(message) end
			return true
		end
	end
end
function NADMOD.ConsoleCMD(args)
	local cmd = table.remove(args, 1)
	for _,v in pairs(NADMOD.PermissionsFull) do
		if v[cmd] then 
			local mode,message = v[cmd](Gman, args)
			if !mode then return true
			elseif mode == 1 then print("---Command failed---: "..message)
			elseif mode == 2 then print(message)
			elseif mode == 3 then NADMOD.Message(message)
			elseif mode == 4 then NADMOD.GlobalSay(message) end
			return true
		end
	end
end
concommand.Add("!", function(ply,cmd,args) if !ply:IsValid() || ply:IsAdmin() then NADMOD.ConsoleCMD(args) end end)
concommand.Add("nadmod", function(ply,cmd,args) if !ply:IsValid() || ply:IsAdmin() then NADMOD.ConsoleCMD(args) end end)

hook.Add("PlayerSay", "NADMOD_PlayerSay", function(ply, msg, teamchat)
	if string.Left(msg, 1) == "!" then 
		local success, msg = pcall(NADMOD.ProcessChat,ply, msg) 
		if !success then ErrorNoHalt("NADMOD_Chat: "..msg.."\n") end
		return
	end
	
	local nick = ply.Nickname or ply:Nick()
	if !ply:Alive() then nick = "*DEAD*"..nick end
	if teamchat then
		NADMOD.Permissions.Communications.w(ply,string.Explode(" ", msg))
		return true
	else
		net.Start("nadmod_say")
			net.WriteColor(ply.UserColor or NADMOD.Groups[1].Color)
			net.WriteString(nick)
			net.WriteString(msg)
		net.Broadcast()
	end
end)

hook.Add("PlayXIsPermitted", "NADMODPlayXIsPermitted", function(ply)
	return ply.UserRank >= 10
end)

hook.Add("PlayerNoClip","NADMOD.PlayerNoClip",function(ply,on)
	if ply:InVehicle() then return false end
	if ply.BuildMode then return !on end
	if GetConVarNumber("sbox_noclip") > 0 then return true end
	if NADMOD.HasPermission(ply,"NoclipAlways") then return true end
	return !on
end)


concommand.Add("nadmod_menu", function(ply,cmd,args)
	print("NADMOD_Menu from "..ply:Nick().." receieved ["..tostring(ply).."]")
	if ply:IsValid() && !ply:IsAdmin() then print("But he isn't an admin/valid") return end
	local perms = {}
	for k,v in pairs(NADMOD.Permissions) do
		if k != "All" then 
			local contents
			for i in pairs(v) do
				if !contents then contents = "!"..i else contents = contents .. ", !" .. i end
			end
			perms[k] = contents
		end
	end
	perms.PP_All = "Prop Protection Override"
	perms.NoclipAlways = "Can Always Noclip"
	if args[1] == "groups" then
		net.Start("nadmod_menu_download")
			net.WriteTable({"groups",NADMOD.Groups, perms, NADMOD.Weapons})
		net.Send(ply)
	elseif args[1] == "users" then
		net.Start("nadmod_menu_download")
			net.WriteTable({"users",NADMOD.Users, perms, NADMOD.Groups, NADMOD.Weapons})
		net.Send(ply)
	end
end)

net.Receive("nadmod_menu_upload", function(len, ply)
	if !ply:IsAdmin() then return end
	local mode,tab = net.ReadString(), net.ReadTable()
	if mode == "groups" then
		NADMOD.Groups = tab
	elseif mode == "users" then
		NADMOD.Users = tab
	end
	NADMOD.RefreshRanks()
	NADMOD.Save()
end )

hook.Add( "PlayerAuthed", "playerauthed", function(ply, steamid, uniqueid)
	local entry = NADMOD.Bans[steamid]
	if entry then
		if entry[1] > os.time() then 
			ply:Kick("Banned for "..(entry[1] - os.time()) / 60 .." mins, "..entry[2].."!")
			NADMOD.GlobalSay("Kicking "..ply:Nick().." because he is still banned for "..(entry[1] - os.time()) / 60 .." minutes.")
		else NADMOD.Bans[steamid] = nil
		end
	end
end )

concommand.Add("nadmod_maplistchange", function(ply,cmd,args) if !NADMOD.HasPermission(ply,"MapChange") then return end
	local map,time = args[1],args[2]
	timer.Create("MapChange", tonumber(time), 1, function() NADMOD.MapChange(map) end)
	NADMOD.GlobalSay(ply:Nick().." has started a mapchange to "..map.." in "..time.." seconds!")
end)

print("[NADMOD - Nebcorp Administration Designation Modulation Loaded]")