ENT.PrintName		= "Neapon Projectile"
ENT.Type 			= "anim"
ENT.Base 			= "base_gmodentity"
ENT.Author			= "Nebual"
AddCSLuaFile( "cl_init.lua" )

function ENT:Initialize()
	if self:GetModel() == "models/error.mdl" then self.Entity:SetModel("models/Slyfo_2/pss_gasserprojectile.mdl") end // TODO: Let them change model
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:DrawShadow( false )
	self.Entity:StartMotionController()
	self.CDSIgnore = true
	self.Speed = self.Speed or 500
	self.Damage = self.Damage or 50
	self.SplashRanges = {self:BoundingRadius(), self:BoundingRadius() *2.25,self:BoundingRadius()*4}
	self:SetNotSolid(true)
	local hookname = "Neapon_Projectile_"..self:EntIndex()
	timer.Create(hookname,0.10,1,function() self:SetNotSolid(false) end)
	timer.Create(hookname.."_fade", 16, 1, function() self.Entity:Remove() end)
end

function ENT:PhysicsUpdate()
	-- Accelerate
	local spud = self.Speed * self:Decay(8) * 800
	local dir = self:GetVelocity():GetNormalized()
	local phys = self.Entity:GetPhysicsObject()
	if spud > 4000 then
		local pos = self:GetPos() + dir * ((spud - 4000)/33)
		if !util.IsInWorld(pos) then self:Explode(self.Entity) return end
		self:SetPos(pos)
		spud = 4000
	end
	phys:ApplyForceCenter((dir * (spud - self:GetVelocity():Length()) + Vector(0,0,600/33)*self:Decay(3)) * phys:GetMass())
end
function ENT:Think()
	-- CheckHit
	local ent,pos
	if self.hitentity && (self.hitentity:IsValid() || self.hitentity:IsWorld()) then
		ent = self.hitentity
	else
		local tr = util.QuickTrace(self:GetPos(), self:GetVelocity() /33,self.Entity)
		if tr.Entity && (tr.Entity:IsValid() || tr.Entity:IsWorld()) then
			ent = tr.Entity
			self.Entity:SetPos(tr.HitPos)
		end
	end
	if !ent then return end
	self.PhysicsCollide = nil
	self.Entity:SetParent(ent)
	ent:EmitSound("physics/metal/metal_solid_impact_bullet" .. math.random(1,4) .. ".wav" )
	self:NextThink(CurTime()+1000)
	timer.Create("Neapon_Explode_"..self:EntIndex(),0.08,1,function() self.Entity:Explode() end)
end

function ENT:Decay(amt) -- Asks for amt of time in seconds till decay should complete for this effect
	amt = amt / self.Speed^0.4 -- Decay is faster for speedier bullets
	return math.Max(0, (CurTime() - self.Born - amt)/-amt) -- Returns float for % towards complete decay
end
function ENT:Explode(ent)
	if not IsValid(self) then return end
	if self.Splash then
		local effectdata = EffectData()
		effectdata:SetOrigin( self.Entity:GetPos() )
		util.Effect( "HelicopterMegaBomb", effectdata )	 -- Big flame

		local dmginfo = DamageInfo()
		dmginfo:SetDamageType(DMG_BURN)
		if IsValid(self.Owner) then dmginfo:SetAttacker(self.Owner) end
		for k,v in pairs(ents.FindInSphere(self:GetPos(),self.SplashRanges[self.Splash] or 50)) do
			dmginfo:SetDamage(self.Damage*20)
			v:TakeDamageInfo(dmginfo)
		end
	else
		ent:TakeDamage(self.Damage)
	end
	self.Entity:EmitSound(Sound("HEGrenade.Bounce"))

	if self.Smoke then 
		if self.Smoke == 2 then
			local effectdata = EffectData()
				effectdata:SetOrigin( self.Entity:GetPos() )
				effectdata:SetMagnitude(20)
				effectdata:SetScale(1)
			util.Effect( "Rocket_Explosion", effectdata )	 -- self made effect AWESOME
		else
			local ar2Explo = ents.Create( "env_ar2explosion" )
			if IsValid(self.Owner) then dmginfo:SetOwner(self.Owner) end
			ar2Explo:SetPos( self.Entity:GetPos() )
			ar2Explo:Spawn()
			ar2Explo:Activate()
			ar2Explo:Fire( "Explode", "", 0 )
		end
	end
	
	if self.HugeExplosion then
		local expl=ents.Create("env_explosion") -- The "Boom" Part
		expl:SetPos(self.Entity:GetPos())
		expl:SetName("Missile")
		expl:SetParent(self.Entity)
		expl:SetOwner(self.Entity:GetOwner())
		expl:SetKeyValue("iMagnitude", 400)
		expl:SetKeyValue("iRadiusOverride", 1000)
		expl:SetKeyValue("spawnflags", 64)
		expl:Spawn()
		expl:Activate()
		expl:Fire("explode", "", 0)
		expl:Fire("kill","",0)
		self.Exploded = true
		
		
		local Ambient = ents.Create("ambient_generic") // Sound effect
		Ambient:SetPos(self.Entity:GetPos())
		Ambient:SetKeyValue("message", "ambient/explosions/explode_8.wav")
		Ambient:SetKeyValue("health", 10)
		Ambient:SetKeyValue("preset", 0)
		Ambient:SetKeyValue("radius", 10000)
		Ambient:Spawn()
		Ambient:Activate()
		Ambient:Fire("PlaySound", "", 0)
		Ambient:Fire("kill", "", 4)
		
		/*self.splasheffect = ents.Create("env_splash")
		self.splasheffect:SetKeyValue("scale", 500)
		self.splasheffect:SetKeyValue("spawnflags", 2)
		
		self.light = ents.Create("light")
		self.light:SetKeyValue("_light", 255 + 255 + 255)
		self.light:SetKeyValue("style", 0)*/
		
		local physExplo = ents.Create( "env_physexplosion" )
		physExplo:SetOwner( self.Owner )
		physExplo:SetPos( self.Entity:GetPos() )
		physExplo:SetKeyValue( "Magnitude", 300 )	-- Power of the Physicsexplosion
		physExplo:SetKeyValue( "radius", 700 )	-- Radius of the explosion
		physExplo:SetKeyValue( "spawnflags", 2 + 16 )
		physExplo:Spawn()
		physExplo:Fire( "Explode", "", 0 )
		physExplo:Fire( "Kill", "", 0 )
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
		shake:Fire("Kill","",4)
	end
	
	self.Entity:Remove()
end

function ENT:OnRemove()
	timer.Remove("Neapon_Projectile_"..self:EntIndex())
	timer.Remove("Neapon_Projectile_"..self:EntIndex().."_fade")
	timer.Remove("Neapon_Explode_"..self:EntIndex())
	self:StopSound( "Missile.Accelerate" )
end

/*function ENT:PhysicsSimulate(phys,delta)
	local spud,dir = self.Speed, self:GetVelocity():GetNormalized()
	if spud > 4000 then
		self:SetPos(self:GetPos() + dir * (spud - 4000))
		spud = 4000
	end
	phys:ApplyForceCenter((dir * (spud - self:GetVelocity():Length()) + Vector(0,0,8)) * phys:GetMass())
end*/

function ENT:PhysicsCollide(data,phys)
	--print(" what "..tostring(data.OurOldVelocity:GetNormalized()))
	--if math.abs(data.HitNormal.z + data.OurOldVelocity:GetNormalized().z) > 0.75 then
	--	if data.DeltaTime < 0.1 then self.Entity:EmitSound(Sound("HEGrenade.Bounce")) end -- Boing!
	--	phys:ApplyForceCenter(-data.Speed * data.HitNormal * .4 + (data.OurOldVelocity * -.6))
	--else
	--	self:CheckHit(data.HitEntity)
	self.hitentity = data.HitEntity
	--end
end
