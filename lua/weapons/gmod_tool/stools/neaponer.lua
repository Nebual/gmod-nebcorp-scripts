TOOL.Category		= "Construction"
TOOL.Name			= "#tool.neaponer.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar["gunmodel"]		= "models/spacebuild/milcock4_multipod1.mdl"
TOOL.ClientConVar["bulletmodel"]	= "models/Slyfo_2/pss_gasserprojectile.mdl"
TOOL.ClientConVar["cooldown"]		= "1"
TOOL.ClientConVar[ "damagefactor" ]	= "1"
TOOL.ClientConVar[ "splash" ]		= "0"
TOOL.ClientConVar[ "speed" ]		= "1"
TOOL.ClientConVar[ "firemode" ]		= "2"
TOOL.ClientConVar["weld"]			= "1"


/*if SERVER then
	function TOOL:Hint(msg)
		self:GetOwner():SendLua("GAMEMODE:AddNotify(\""..msg.."\", NOTIFY_GENERIC, 5); surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")")
	end
end*/

if CLIENT then
	language.Add( "tool.neaponer.name", "Neapon Spawner" )
	language.Add( "tool.neaponer.desc", "Configures and Spawns Namage Weapons" )
	language.Add( "tool.neaponer.0", "Left click to spawn or update shit" )
	--language.Add( "tool.neaponer.1", "Right click another ent to create the link." )

	language.Add( "Undone_neapon_launcher", "Undone Nebcorp Weapon" )
end
cleanup.Register( "neapon_launcher" )

function neaponerLC( self, trace )
	local tar = trace.Entity
	if !tar || tar:IsPlayer() then return false end
	if CLIENT then return true end

	local ply = self:GetOwner()
	local doweld		= (self:GetClientNumber("weld") != 0)
	local gunmodel		= self:GetClientInfo("gunmodel")
	local bulletmodel	= self:GetClientInfo("bulletmodel")
	local cooldown 		= self:GetClientNumber("cooldown")
	local damage		= self:GetClientNumber("damagefactor")
	local speed			= self:GetClientNumber("speed")--*800
	local splash		= self:GetClientNumber("splash")
	local firemode		= self:GetClientNumber("firemode")
	// For balance, the 0.1-10 vars should be "1 is normal, higher is enhanced, lower is worse", so 1 speed is alright

	-- We shot an existing ent - just change its values
	if IsValid(tar) && tar:GetClass() == "neapon_launcher" then
		tar.Cooldown,tar.Damage,tar.Speed,tar.Splash,tar.Mode = cooldown,damage,speed,splash,firemode
		tar.BulletModel = bulletmodel
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	undo.Create("neapon_launcher")
	local ent = MakeNeaponLauncher(ply, trace.HitPos, Ang, gunmodel,bulletmodel,cooldown,damage,speed,splash,firemode)
	if !ent then return false end
	ent:SetPos( trace.HitPos - trace.HitNormal * ent:OBBMins().z )
	ply:AddCleanup( "neapon_launcher", ent )
	undo.AddEntity( ent )
	if doweld and IsValid(tar) then
		local weld = constraint.Weld( tar, ent, trace.PhysicsBone, 0, 0, !tar:IsWorld() )
		weld:CallOnRemove("TempSleep", function(_,id)
			if IsValid(ent) && IsValid(ent:GetPhysicsObject()) then
				ent:GetPhysicsObject():EnableMotion(false)
				timer.Create(id.."Wakeup", 1, 1, function() if IsValid(ent) then ent:GetPhysicsObject():EnableMotion(true) end end)
			end
		end, ent:EntIndex())
		undo.AddEntity( weld )
		ply:AddCleanup( "neapon_launcher", weld )
	end
	if tar:IsWorld() then ent:GetPhysicsObject():EnableMotion(false) end

	undo.SetPlayer( ply )
	undo.Finish()
	ent:GetPhysicsObject():Sleep()
	
	return true
end
function TOOL:LeftClick(trace) return neaponerLC( self, trace ) end

function MakeNeaponLauncher(ply, Pos, Ang, gunmodel,bulletmodel,cooldown,damage,speed,splash,firemode)
	//if ( !pl:CheckLimit( "ns3_storage" ) ) then return false end

	local ent = ents.Create( "neapon_launcher" )
	if !IsValid(ent) then return false end
	ent:SetModel( gunmodel )

	--if Model == "models/slyfo/sat_rfg.mdl" then Ang.r = math.angnorm(Ang.r + 90) end
	ent:SetAngles( Ang )
	ent:SetPos( Pos )
	ent.Cooldown,ent.Damage,ent.Speed,ent.Splash,ent.Mode = cooldown,damage,speed,splash,firemode
	ent.GunModel,ent.BulletModel = gunmodel,bulletmodel
	ent:Spawn()
	ent:Setup()
	ent:SetPlayer( ply )

	return ent
end
duplicator.RegisterEntityClass("neapon_launcher", MakeNeaponLauncher, "Pos", "Ang", "GunModel", "BulletModel","Cooldown","Damage","Speed","Splash","Mode")


function neaponerRC( self, trace )
	local tar = trace.Entity
	if !IsValid(tar) || tar:IsPlayer() then return false end

	if CLIENT then return true end

	//?
end
function TOOL:RightClick( trace ) return neaponerRC(self,trace) end

function neaponerReload( self, trace )
	local tar = trace.Entity
	if tar && tar:IsPlayer() then return false end
	if CLIENT then return true end

	self.Owner:ChatPrint("Reload doesn't do anything! Stupid!")
end
function TOOL:Reload( trace ) return neaponerReload(self,trace) end

function BuildneaponerCPanel(self,CPanel)
	if !CPanel then CPanel = controlpanel.Get( "neaponer" ) end
	CPanel:ClearControls()
	//local text = CPanel:AddControl("Label",{Text = "All of Neapons is still very much a work in progress. If you have\
	// any complaints or suggestions please tell Nebual either in chat or via '!report Neb guns don't shoot :('"})
	CPanel:Help("All of Neapons is still very much a work in progress. If you have any complaints or suggestions please tell Nebual either in chat or via '!report Neb guns don't shoot :('")
	CPanel:CheckBox("Weld","neaponer_weld")
	CPanel:NumSlider("Firing Cooldown", "neaponer_cooldown", 0.1, 10, 2)
	CPanel:NumSlider("Damage Factor", "neaponer_damagefactor", 0.1, 10, 2)
	CPanel:NumSlider("Projectile speed", "neaponer_speed", 0.1, 10, 2)
	CPanel:NumSlider("Splash range", "neaponer_splash", 0, 3, nil)
	CPanel:AddControl( "ComboBox", {Label = "Firing Mode", MenuButton=1,Folder="wat",Options={Manual = {neaponer_firemode=1},["Semi Automatic"] = {neaponer_firemode=2},["Fully Automatic"] = {neaponer_firemode=3}}, CVars = {"neaponer_firemode"}})
	WireDermaExts.ModelSelect(CPanel, "neaponer_gunmodel", Neapon.GunModels, 2,true)
	WireDermaExts.ModelSelect(CPanel, "neaponer_bulletmodel", Neapon.BulletModels, 2,true)
end

-- Reload the CPanel every time the tool is switched to, for development only
function TOOL.BuildCPanel( panel )
	BuildneaponerCPanel(self, panel)
end
TOOL.LastUpdated = 0
function TOOL:Deploy()
	if CLIENT then
		if self.LastUpdated > CurTime() then return end
		self.LastUpdated = CurTime() + 1
		BuildneaponerCPanel(self)
	end
end

function TOOL:UpdateGhost( ent, ply )
	if !IsValid(ent) then return end

	local trace = ply:GetEyeTrace()
	if !trace.Hit || (IsValid(trace.Entity) && (trace.Entity:GetClass() == "neapon_launcher" || trace.Entity:IsPlayer())) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	ent:SetAngles( Ang )
	ent:SetPos( trace.HitPos - trace.HitNormal * ent:OBBMins().z )

	ent:SetNoDraw( false )
end

function neaponerThink(self)
	local model = self:GetClientInfo( "gunmodel" )
	if model == "" then return end
	if !util.IsValidProp(model) then util.PrecacheModel( model ) return end
	if SERVER then return end
	if !IsValid(self.GhostEntity) || self.GhostEntity:GetModel() != model then
		self:MakeGhostEntity( model, Vector(0,0,0), Angle(0,0,0) )
		--if NS3.EntMaterials[model] then self.GhostEntity:SetMaterial(NS3.EntMaterials[model]) end
	end

	self:UpdateGhost( self.GhostEntity, self:GetOwner() )
end
function TOOL:Think() return neaponerThink(self) end
