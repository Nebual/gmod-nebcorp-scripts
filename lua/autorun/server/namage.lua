-- Nebual 2010 (nebual@nebtown.info) presents:
-- Namage - Nebcorp's Global Damage System

if not Namage then
	-- Namage Init, stuff put in here will only run on map load, not subsequent 'namage_reload'
	concommand.Add("namage_reload", function() include("autorun/server/namage.lua") end)
	CreateConVar("namage_on", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
	CreateConVar("namage_fire", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
	CreateConVar("namage_debug", 0, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
	CreateConVar("namage_default", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
	CreateConVar("namage_physicspain", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
	CreateConVar("namage_plyscale", 0.25, {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED})
	util.AddNetworkString("Namage_Props")
	Namage = {
		Props = {},
		PropsSmall = {},
		GibSounds = {},
		Gibs = {},
		UpdatePlayers = function() local v end, PlayerHeal = function() local v end,
		Hint = function(ply,msg,dur) WireLib.AddNotify(ply,msg,0,dur) end,
	}
end
local namage_default = GetConVar("namage_default")

if not Namage.ModifiedSetMaterial then
	Namage.ModifiedSetMaterial = true
	local meta = FindMetaTable( "Entity" )
	local OldSetMaterial = meta.SetMaterial
	meta.SetMaterial = function(ent,str)
		OldSetMaterial(ent,str)
		if ent.Namage then ent.Namage.Type = Namage.Material(ent) end
	end
end

local round = math.Round
function Namage.InitProp(ent)
	-- Note: This is run on every entity ever, even constraints and players
	if not IsValid(ent) or ent:EntIndex() == 0 or not IsValid(ent:GetPhysicsObject()) or not ent:GetPhysicsObject():GetVolume() or ent:IsNPC() or ent:IsPlayer() or not ent:GetModel() or ent.CDSIgnore or ent:GetClass() == "gmod_ghost" or string.sub(ent:GetClass(), 1, 4) == "func" then return end
	 -- This should filter out most bad things
	local maxhp = round(ent:GetPhysicsObject():GetVolume()^0.4 * 2.93) -- <3 formula, makes PHX 1x1: 100hp, PHX 4x4: 300hp.
	ent.Namage = ent.Namage or {
		MaxHP = maxhp,
		HP = maxhp,
		FireHP = maxhp / 8,
		Immune = 4, --1: Namage off (no .Namage also works), 2:Namage On but Immortal (Prometheus though), 3:NS3 (ghosting upon death, immortal), 4:Namage On Fully
		Type = Namage.Material(ent)
	}
	if ent.Namage.Type == "explosive" then ent.Namage = nil return end
	Namage.UpdateProp(ent)
end
local function NamageInitPropHooker(ent)
	if not namage_default:GetBool() then return end
	local id = "InitNamage_"..ent:EntIndex()
	timer.Create(id,0.12,1,function() if ent:IsValid() and not ent.Namage then Namage.InitProp(ent) end end)
end
timer.Create("NamageHookOnEntityCreated",10,1, function() hook.Add("OnEntityCreated", "NamageInitProp", NamageInitPropHooker) end)
-- Deciding to make namage opt-in

-- This should be used to change ents HP, as it updates the clientside display of current health
function Namage.UpdateProp(ent, hp)
	if hp then ent.Namage.HP = hp else hp = ent.Namage.HP end
	hp = round(hp)
	local id = ent:EntIndex()
	if id == 0 then return end
	local imm = ent.Namage.Immune
	if imm == 1 then hp = hp.."a" elseif imm == 2 then hp = hp .. "b" elseif imm == 3 then hp = hp .. "c" else hp = tostring(hp) end
	if hp ~= Namage.Props[id] then
		Namage.Props[id] = hp
		Namage.PropsSmall[id] = hp
	end
end

hook.Add("PlayerInitialSpawn", "NamagePlyInit", function(ply) net.Start("Namage_Props") net.WriteTable(Namage.Props) net.Send(ply) end)
function Namage.UpdatePlayers()
	-- Update clientside cache of HP's on a 2.5 second timer. 'next' is the simplist check to see if theres stuff in a table
	if next(Namage.PropsSmall) then --GetConVarNumber("namage_on") == 1 and
		net.Start("Namage_Props") 
			net.WriteTable(Namage.PropsSmall)
		net.Broadcast()
		Namage.PropsSmall = {}
	end
end
timer.Create("Namage_Tick", 2.5, 0, Namage.UpdatePlayers)

function Namage.PlayerHeal(ply,time)
	if IsValid(ply) and ply:Health() < 100 then ply:SetHealth(ply:Health() + 1) else timer.Destroy("Heal_"..ply:EntIndex()) return end
	time = math.max(time / 1.15,0.10)
	timer.Adjust("Heal_"..ply:EntIndex(),time, 0, function() Namage.PlayerHeal(ply, time) end)
end

Namage.Materials = {explosive = "explosive", glass = "glass"}
Namage.PhysMaterials = {
	floating_metal_barrel = "explosive",
	metal = "metal", metal_barrel = "metal", metalpanel = "metal", solidmetal = "metal", porcelain = "metal",
	--plastic = "plastic", tile = "plastic", plastic_box = "plastic", dirt = "plastic",
	wood = "wood",
	flesh = "flesh",
	watermelon = "watermelon"
}
function Namage.Material(ent)
	for k,v in pairs(Namage.Materials) do
		if string.find(ent:GetMaterial(), k) then return v end
		if string.find(ent:GetModel(), k) then return v end
	end
	return Namage.PhysMaterials[ent:GetPhysicsObject():GetMaterial()] -- This will be nil if its plastic or unknown, thats k
	--return "plastic"
end

-- ===================
-- Main Damage Processing Function
-- ===================
local floor = math.floor
function Namage.Hurt(ent, dmginfo)
	local inflictor,initamt = dmginfo:GetInflictor(),dmginfo:GetDamage()
	if ent:IsOnFire() and ent:WaterLevel() > 0 then ent:Extinguish() end -- Best place to throw this; makes water extinguish fire :D
	if dmginfo:IsDamageType(DMG_BUCKSHOT) then dmginfo:ScaleDamage(3) end
	if ent:IsPlayer() then
		timer.Create("Heal_"..ent:EntIndex(), 10, 3, function() Namage.PlayerHeal(ent, 2) end)
		if dmginfo:GetDamageType() ~= 0 and dmginfo:GetDamageType() ~= DMG_FALL and dmginfo:GetDamageType() ~= DMG_BURN then dmginfo:ScaleDamage(GetConVarNumber("namage_plyscale")) end
		if dmginfo:GetDamageType() == DMG_FALL then
			dmginfo:ScaleDamage(0.4)
			if dmginfo:GetDamage() >= ent:Health() and ent:Health() > 5 and math.random() < 0.33 then dmginfo:SetDamage(ent:Health() - 1) end
		end
		if dmginfo:GetDamageType() == DMG_CRUSH then
			dmginfo:ScaleDamage(0.6)
			if GetConVarNumber("namage_physicspain") == 0 then dmginfo:SetDamage(0) end
		end
		if GetConVarNumber("namage_debug") == 1 then print("Namage: "..ent:Nick() .. " ["..ent:EntIndex().."]".." just got hit by "..inflictor:EntIndex().." for "..dmginfo:GetDamage().."["..initamt.."] of type "..dmginfo:GetDamageType()) end
		return
	end
	local tab = ent.Namage
	if not tab or GetConVarNumber("namage_on") == 0 or tab.Immune == 1 then return end
	if tab.ProxyEntity then dmginfo:SetDamage(tab.ShieldEntity:ReduceDamage(dmginfo:GetDamage())) end
	--if math.floor(dmginfo:GetDamageType() / 268435456) == 1 then -- Its fire damage
	local mat = tab.Type -- This info is also metaupdated when material is changed ;D
	if mat == "metal" then
		dmginfo:ScaleDamage(0.5)
		--if dmginfo:IsDamageType(268435456) then dmginfo:ScaleDamage(0.5) end
		if dmginfo:IsDamageType(2) or dmginfo:IsDamageType(8) or dmginfo:IsDamageType(268435456) then dmginfo:ScaleDamage(0.66) end
		if dmginfo:IsDamageType(8) or dmginfo:IsDamageType(64) or dmginfo:IsDamageType(268435456) then ent:Extinguish() end
	elseif mat == "wood" then
		dmginfo:ScaleDamage(1.75)
	end
	if GetConVarNumber("namage_fire") == 1 and dmginfo:IsDamageType(8) or dmginfo:IsDamageType(64) or dmginfo:IsDamageType(268435456) then Namage.Nire(ent,dmginfo:GetDamage() or 0,tab) end
	if dmginfo:GetDamageType() == 1 and inflictor:IsPlayer() then dmginfo:SetDamage(0) end


	local hp = tab.HP - dmginfo:GetDamage()
	ent:TakePhysicsDamage(dmginfo)
	if (hp / tab.MaxHP) < 0.15 and ent:GetPhysicsObject():IsValid() then ent:GetPhysicsObject():EnableMotion(true) ent:GetPhysicsObject():Wake() end
	if hp <= 0  then
		Namage.UpdateProp(ent, 0)
		if tab.Immune ~= 2 then Namage.Kill(ent) end
	else Namage.UpdateProp(ent, hp)
	end
	if GetConVarNumber("namage_debug") == 1 then print("Namage: "..string.sub(table.remove(string.Explode("/", ent:GetModel() or "No model!")), 1,-5) .. " ["..ent:EntIndex().."]".." just got hit by "..inflictor:EntIndex().." for "..dmginfo:GetDamage().."["..initamt.."] of type "..dmginfo:GetDamageType()) end
	return true
end
hook.Add("EntityTakeDamage", "Namage", Namage.Hurt)

function Namage.Nire(ent,dmg,tab)
	if tab.FireHP > dmg then tab.FireHP = tab.FireHP - dmg 
	else
		if not ent:IsOnFire() then
			ent:Ignite(tab.MaxHP,0)
		else
			timer.Create("Namage_Fire_"..ent:EntIndex(),0.33,0,function() Namage.Nire2(ent,ent:EntIndex()) end)
		end
		tab.FireHP = tab.MaxHP / 8
	end
end
function Namage.Nire2(ent,id)
	if not IsValid(ent) or not ent:IsOnFire() then timer.Destroy("Namage_Fire_"..id) return end
	local vec,rad = ent:LocalToWorld(ent:OBBCenter()), ent:BoundingRadius()*2.1
	for k,v in pairs(ents.FindInSphere(vec,rad)) do
		if v.Namage then
			local dmginfo = DamageInfo()
			dmginfo:SetDamage( (v:GetPos():Distance(vec) / rad)^0.6 )
			dmginfo:SetDamageType( DMG_BURN )
			dmginfo:SetAttacker( ent )
			v:TakeDamageInfo(dmginfo)
		end
	end
end

function Namage.Kill(ent)
	if ent.Namage.Immune == 3 then
		ent.Namage.Immune = 1
		ent.Namage.Ghosted = 1
		-- ent:SetNotSolid(true)
		ent.Namage.OldCollisions = ent:GetCollisionGroup()
		ent:SetCollisionGroup( COLLISION_GROUP_WEAPON )
		if IsValid(ent:GetPhysicsObject()) then
			ent:GetPhysicsObject():EnableCollisions(false)
		end
		ent.Namage.Color = ent:GetColor()
		ent:SetColor(Color(255, 155, 155, 100))
		return -- End!
	end
	local flavor,instakill = "Flesh",false
	local id = ent:EntIndex()
	if ent:GetClass() == "prop_ragdoll" then
		local Gibs = {}
		local pos = ent:GetPos()
		local vel = ent:GetVelocity()
		local spirit = ent.Spirit
		if vel:Length() < 300 then vel = vel + Vector(0,0,250) end
		for k=1, math.min(math.Round(ent:BoundingRadius() / 5), 20) do
			local gib = ents.Create("prop_physics_multiplayer")
			gib:SetModel(table.Random(Namage.Gibs.Ragdoll))
			gib:SetPos(pos)
			gib:Spawn()
			Namage.InitProp(gib)
			gib:SetSkin(math.random(1,2))
			gib.Spirit = spirit
			gib.latervel = vel + Vector(math.Rand(-25,25),math.Rand(-25,25),math.Rand(-25,25))
			Gibs[k] = gib
		end
		local timerid = id.."_"..Gibs[1]:EntIndex()
		timer.Create("Namage.RagGibVel_"..timerid, 0.1, 3, function()
			for _,v in pairs(Gibs) do if IsValid(v) then v:GetPhysicsObject():SetVelocity(v.latervel) end end
		end)
		timer.Create("Namage.RagGibRemove_"..timerid, 15, 0, function()
			if not IsValid(spirit) or spirit:Alive() then 
				for _,v in pairs(Gibs) do if IsValid(v) then v:Remove() end end
				timer.Destroy("Namage.RagGibRemove_"..timerid)
				timer.Destroy("Namage.RagGibVel_"..timerid)
			end
		end)
		if IsValid(spirit) and not spirit:Alive() then
			spirit.DeathRagdoll = Gibs[1]
			spirit:Spectate( OBS_MODE_CHASE ) 
			spirit:SpectateEntity(Gibs[1])
			Gibs[1]:CallOnRemove("unspirit",function(_,ply) if ply:IsValid() and not ply:Alive() then ply:Spectate(OBS_MODE_FIXED) end end,spirit)
		end
		flavor,instakill = "Flesh", true
	elseif ent:GetClass() == "gmod_wire_expression2" then
		ent:SetOverlayText("Expression 2\n" .. (ent.name or "Bonk!") .. "\n(has shut down due to\n"..table.Random(porblumlist)..")")
		ent:SetColor(255, 0, 0, ent:GetColor().a)
		ent:PCallHook('destruct')
		ent.error = 1
		timer.Create("RemoveE2_"..ent:EntIndex(),30,1,function()
			if IsValid(ent) and tobool(ent.error) then ent:Remove() end
		end)
		return
	elseif ent.Namage.Type == "wood" then
		local offsets,model
		if ent:GetModel() == "models/props_phx/construct/wood/wood_panel1x1.mdl" then offsets,model = {-19.75, -11.9,-4.05,3.8,11.65,19.5},"models/props_phx/construct/wood/wood_boardx1.mdl"
		elseif ent:GetModel() == "models/props_phx/construct/wood/wood_panel2x2.mdl" then offsets,model = {-19.75, -11.9,-4.05,3.8,11.65,19.5,27.35,35.2,43.05,50.9,58.75,66.6},"models/props_phx/construct/wood/wood_boardx2.mdl"
		elseif ent:GetModel() == "models/props_phx/construct/wood/wood_panel1x2.mdl" then offsets,model = {-19.75, -11.9,-4.05,3.8,11.65,19.5,27.35,35.2,43.05,50.9,58.75,66.6},"models/props_phx/construct/wood/wood_boardx1.mdl"
		end
		if offsets and not ent:IsOnFire() then
			undo.Create("WoodDivide")
			undo.SetPlayer( ply )
			
			local owner = E2Lib.getOwner({},ent)
			local col = ent:GetColor()
			local oldparts = constraint.FindConstraints(ent, "Weld")
			for _,y in pairs(offsets) do
				local part = ents.Create( "prop_physics" )
				part:SetModel(model)
				part:SetPos(ent:LocalToWorld(Vector(0,y,0)))
				part:SetAngles(ent:GetAngles())
				--part:SetOwner(E2Lib.getOwner({},ent))
				part:Spawn()
				part:Activate()
				gamemode.Call("PlayerSpawnedProp",owner, model, part)
				owner:AddCleanup( "props", part )
				if not ent:GetPhysicsObject():IsMoveable() then part:GetPhysicsObject():EnableMotion(false) end
				if ent:GetMaterial() ~= "" then part:SetMaterial(ent:GetMaterial()) end
				part:SetColor(col)
				--cleanup.Add(E2Lib.getOwner({},ent)
				undo.AddEntity( part )
				for k,v in pairs(oldparts) do
					if v.Ent1 == ent then v = v.Ent2 else v = v.Ent1 end
					undo.AddEntity( constraint.Weld(part, v, 0, 0, 0, true) )
				end
			end
			
			undo.Finish()
		end
		flavor,instakill = "wood",true
	elseif ent.Namage.Type == "glass" then
		flavor,instakill = "glass", true
		ent:SetModel("models/props_phx/construct/glass/glass_plate2x2.mdl")
		ent:GibBreakClient(Vector())
	elseif ent.Namage.Type == "watermelon" then
		flavor,instakill = "watermelon", true
		ent:GibBreakClient(Vector())
	end

	ent:EmitSound(table.Random(Namage.GibSounds[flavor]))
	ent.Namage = nil
	ent:TakeDamage(99999) -- Lets try to kill it just through natural damage (with Namage off) cause then it has perfect gibs

	if instakill then -- Instakill if we have custom gibs for it :D
		ent:Remove()
	else
		-- Otherwise this is our "generic" kill effect for if we don't have anything better
		if IsValid(ent:GetPhysicsObject()) then ent:GetPhysicsObject():EnableGravity(false) end
		local col = ent:GetColor()
		col.r = col.r-120
		col.g = col.g-120
		col.b = col.b-120
		ent:SetColor(col)
		SetScale(ent,Vector(0.01,0.01,0.01),0.8)
		timer.Create("Namagekill_"..id, 1, 1, function() if IsValid(ent) then ent:Remove() end end)
	end
end

function Namage.RemoveProp(ent)
	Namage.Props[ent:EntIndex()] = nil
	Namage.PropsSmall[ent:EntIndex()] = "-1"
end
hook.Add("EntityRemoved", "NamageRemoveProp", Namage.RemoveProp)

local function addSounds(kind, path, number)
	if not Namage.GibSounds[kind] then Namage.GibSounds[kind] = {} end
	if(number) then
		for k=1, number do table.insert(Namage.GibSounds[kind], path..k..".wav") end
	else
		table.insert(Namage.GibSounds[kind], path)
	end
end
Namage.GibSounds.Flesh = {
	"physics/flesh/flesh_bloody_break.wav",
	"physics/flesh/flesh_bloody_impact_hard1.wav",
}
addSounds("Flesh","physics/flesh/flesh_squishy_impact_hard", 4)
Namage.GibSounds.glass = {
}
addSounds("glass","physics/glass/glass_impact_bullet", 4)
addSounds("glass","physics/glass/glass_sheet_break", 3)
addSounds("glass","physics/glass/glass_pottery_break", 4)
addSounds("glass","physics/glass/glass_pottery_break", 3)
addSounds("wood","physics/wood/wood_box_impact_hard",3)
addSounds("wood","physics/wood/wood_box_impact_bullet",3)
addSounds("wood","physics/wood/wood_crate_break",5)
addSounds("wood","physics/wood/wood_furniture_break",2)
addSounds("wood","physics/wood/wood_plank_break",4)
addSounds("watermelon", "Watermelon.Scrape")

Namage.Gibs.Ragdoll = {
	"models/player/gibs/heavygib001.mdl",
	"models/player/gibs/heavygib002.mdl",
	"models/player/gibs/heavygib005.mdl",
	"models/player/gibs/heavygib005.mdl",
	"models/player/gibs/heavygib007.mdl",
	"models/player/gibs/medicgib001.mdl",
	"models/player/gibs/medicgib002.mdl",
	"models/player/gibs/scoutgib009.mdl",
	"models/player/gibs/soldiergib007.mdl",
	"models/player/gibs/snipergib007.mdl",
}
for _,class in ipairs({"demo","engineer","spy","sniper","soldier"}) do
	for k=1,6 do table.insert(Namage.Gibs.Ragdoll, "models/player/gibs/"..class.."gib00"..k..".mdl") end
end
for _,class in ipairs({"soldier","medic","scout"}) do for k=1,2 do table.insert(Namage.Gibs.Ragdoll, "models/player/gibs/"..class.."gib008.mdl") end end

print("[Namage - Nebcorp's Global Damage System Loaded]")
