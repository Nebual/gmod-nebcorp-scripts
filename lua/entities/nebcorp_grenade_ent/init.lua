ENT.PrintName	= "Multipurpose Grenade"
ENT.Type 		= "anim"
ENT.Base 		= "base_gmodentity"
ENT.Author		= "Nebual"
AddCSLuaFile( "cl_init.lua" )

/*---------------------------------------------------------
Initialize
---------------------------------------------------------*/
function ENT:Initialize()

	self.Entity:SetModel("models/weapons/w_eq_fraggrenade.mdl")
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:DrawShadow( false )
	//self.CDSIgnore = true
	self.ExplosionFire = true
	
	-- Don't collide with the player
	self.Entity:SetCollisionGroup( COLLISION_GROUP_WEAPON )
	local timerid = "NCGrenade.ChangeCollisions_"..self.Entity:EntIndex()
	timer.Create(timerid,0.13,1,function() if IsValid(self.Entity) then self:SetCollisionGroup( COLLISION_GROUP_NONE ) end timer.Destroy(timerid) end)
	if self.Entity.CPPISetOwnerless then self.Entity:CPPISetOwnerless( true ) end
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	self.Entity:SetGravity(self.Gravity or 0.3)
	
	NebcorpGrenades[self.Kind or "Frag"](self)
	if self.Sticky then
		self.PhysicsCollide = function(self,data,phys)
			self.Entity:EmitSound(Sound("HEGrenade.Bounce"))
			local ent = data.HitEntity
			timer.Create("Weld_"..self.Entity:EntIndex(), 0, 1, function()
				if (!IsValid(ent) && !ent:IsWorld()) || !IsValid(self.Entity) then return end
				if !ent:IsPlayer() && !ent:IsNPC() then constraint.Weld(self.Entity, ent, 0, 0, 0, true)
				else self.Entity:SetParent(ent) 
				end
			end)
		end
	end
	
	if math.random(1,100) == 100 then self.Timer = 360 end // "What? This grenade never exploded, its been like 5 minu-BOOM"
	local timerid = "NCGrenade.Explode_"..self:EntIndex()
	timer.Create(timerid, self.Timer or 3, 1, function() if IsValid(self) then self:Explode() end timer.Destroy(timerid) end)
end


/*---------------------------------------------------------
Explosion
---------------------------------------------------------*/
function ENT:Explode()

	if self.ExplosionFire then -- On by default
		local effectdata = EffectData()
		effectdata:SetOrigin( self.Entity:GetPos() )
		util.Effect( "HelicopterMegaBomb", effectdata )	 -- Big flame
	end
	
	if self.Shake then
		local shake = ents.Create( "env_shake" )
		shake:SetOwner( self.Owner )
		shake:SetPos( self.Entity:GetPos() )
		shake:SetKeyValue( "amplitude", "2000" )	-- Power of the shake
		shake:SetKeyValue( "radius", "900" )	-- Radius of the shake
		shake:SetKeyValue( "duration", "2.5" )	-- Time of shake
		shake:SetKeyValue( "frequency", "255" )	-- How har should the screenshake be
		shake:SetKeyValue( "spawnflags", "4" )	-- Spawnflags( In Air )
		shake:Spawn()
		shake:Activate()
		shake:Fire( "StartShake", "", 0 )
	end
	
	if self.Smoke then 
		local ar2Explo = ents.Create( "env_ar2explosion" )
		ar2Explo:SetOwner( self.Owner )
		ar2Explo:SetPos( self.Entity:GetPos() )
		ar2Explo:Spawn()
		ar2Explo:Activate()
		ar2Explo:Fire( "Explode", "", 0 )
	end
	if self.ExplosionDamage then
		local explo = ents.Create( "env_explosion" )
		explo:SetOwner( self.Owner )
		explo:SetPos( self.Entity:GetPos() )
		explo:SetKeyValue( "iMagnitude", tostring(self.ExplosionPower or 150) )
		explo:Spawn()
		explo:Activate()
		explo:Fire( "Explode", "", 0 )
	end
	
	if self.Unfreeze then
		for k, v in pairs ( ents.FindInSphere( self.Entity:GetPos(), 250 ) ) do
			v:Fire( "EnableMotion", "", math.random( 0, 0.5 ) )
		end
	end
	
	if self.Special then self:Special() end
	//if self.RemoveTimer then timer.Create("RemoveGrenade_"..self.Entity:EntIndex(),self.RemoveTimer,1,function() self:Remove() end) else self:Remove() end
	self:Remove()
end

/*---------------------------------------------------------
PhysicsCollide
---------------------------------------------------------*/
function ENT:PhysicsCollide(data,phys)
	if data.Speed > 50 then
		self.Entity:EmitSound(Sound("HEGrenade.Bounce"))
	end
	
	local impulse = -data.Speed * data.HitNormal * .4 + (data.OurOldVelocity * -.6)
	phys:ApplyForceCenter(impulse)
end


//ENT.BonkTimes = {SoSmall={3,4},Scout={2,3},Sandvich={2,3},Building={3,4},Ball={0.9,1.1}}
ENT.AllBonks = {
	SoSmall = {
		"vo/demoman_dominationscout05.wav",
		"vo/demoman_dominationscout06.wav",
		"vo/demoman_dominationscout08.wav",
		"vo/engineer_dominationscout03.wav",
		"vo/heavy_domination01.wav",
		"vo/heavy_domination03.wav",
		"vo/heavy_domination04.wav",
		"vo/heavy_domination05.wav",
		"vo/heavy_domination06.wav",
		"vo/heavy_domination07.wav",
		"vo/heavy_domination10.wav",
		"vo/heavy_domination13.wav",
		"vo/heavy_domination16.wav",
		"vo/heavy_meleedare10.wav",
		"vo/heavy_meleedare13.wav",
		"vo/heavy_meleedare09.wav",
		"vo/heavy_meleedare09.wav",
		"vo/heavy_jeers07.wav",
		"vo/heavy_yell9.wav",
		"vo/heavy_yell10.wav",
		"vo/heavy_yell11.wav",
	},
	Scout = {
		"vo/scout_domination02.wav",
		"vo/scout_domination03.wav",
		"vo/scout_domination06.wav",
		"vo/scout_domination07.wav",
		"vo/scout_domination09.wav",
		"vo/scout_domination12.wav",
		"vo/scout_domination14.wav",
		"vo/scout_domination15.wav",
		"vo/scout_domination21.wav",
		"vo/scout_dominationeng01.wav",//build
		"vo/scout_dominationeng02.wav",//build
		"vo/scout_dominationeng03.wav",//build
		"vo/scout_dominationeng04.wav",//build
		"vo/spy_DominationScout01.wav", -- mother
		"vo/spy_DominationScout01.wav",
		"vo/scout_misc02.wav",
		"vo/scout_misc07.wav",
		"scout_positivevocalization04.wav",
	},
	Sandvich = {
		"vo/scout_dominationhvy02.wav",
		"vo/scout_dominationhvy05.wav",
		"vo/scout_dominationhvy07.wav",
		"vo/sandwicheat09.wav",
		"vo/scout_specialcompleted01.wav",
	},
	Building = {
		"vo/sniper_DominationEngineer05.wav",
		"vo/sniper_DominationEngineer06.wav",
		"vo/scout_dominationeng01.wav",//build
		"vo/scout_dominationeng02.wav",//build
		"vo/scout_dominationeng03.wav",//build
		"vo/scout_dominationeng04.wav",//build
		"vo/spy_DominationEngineer04.wav",
		"vo/soldier_DominationEngineer03.wav",
		"vo/soldier_DominationEngineer05.wav",
		"vo/soldier_DominationScout05.wav",
		"vo/scout_specialcompleted10.wav",
	},
	Ball = {
		"vo/scout_battlecry01.wav",
		"vo/scout_specialcompleted02.wav",
		"vo/scout_specialcompleted03.wav",
	},
}
for k=1,9 do table.insert(ENT.AllBonks.Sandvich, "vo/heavy_sandwichtaunt0"..k..".wav") end
for k=10,17 do table.insert(ENT.AllBonks.Sandvich, "vo/heavy_sandwichtaunt"..k..".wav") end
for k=1,5 do table.insert(ENT.AllBonks.Ball, "vo/scout_stunballpickup0"..k..".wav") end
//for k,v in pairs(ENT.AllBonks) do table.insert(v, "vo/scout_specialcompleted02.wav") table.insert(v, "vo/scout_specialcompleted03.wav") end