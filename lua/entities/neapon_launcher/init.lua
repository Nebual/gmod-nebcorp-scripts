ENT.PrintName		= "Neapon Launcher"
ENT.Type 			= "anim"
ENT.Base 			= "base_gmodentity"
ENT.Author			= "Nebual"
AddCSLuaFile( "cl_init.lua" )

/*resource.AddFile("materials/models/turretbody/turretbody.vmt")
resource.AddFile("materials/models/turretbarrel/turretbarrel.vmt")
resource.AddFile("materials/models/turretelevator/turretelevator.vmt")
resource.AddFile("models/turretbody.mdl")
resource.AddFile("models/turretbarrel.mdl")
resource.AddFile("models/turretelevator.mdl")*/

function ENT:Initialize()
	if self:GetModel() == "models/error.mdl" then self.Entity:SetModel("models/spacebuild/milcock4_multipod1.mdl") end
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	//self.Entity:DrawShadow( false )
	self.shootent = self.Entity -- Where do bullets come out of (for multi-prop launchers)
	
	local mdl = self:GetModel()
	self.d = {bearing=0,elevation=0,force=vector_origin}
	for k,v in pairs(Neapon.GunModels[mdl]) do self[k] = v end
	for k,v in pairs(Neapon.BulletModels[self.BulletModel] or Neapon.BulletModels["models/Slyfo_2/pss_gasserprojectile.mdl"]) do self[k] = v end
end


if !Neapon then Neapon = {} end

Neapon.GunModels = {
	["models/spacebuild/milcock4_multipod1.mdl"] = {scale=3,shootpos = {Vector(-41,10,0)},shootdir = Vector(-1,0,0),},
	["models/props_phx/box_amraam.mdl"] = {scale=3,shootpos = {Vector(90,0,14)},shootdir = Vector(1,0,0),Setup = function(self)
		WireLib.CreateSpecialInputs(self.Entity,{"Fire","Target"},{"NORMAL","VECTOR"})
	end, LauncherBulletSetup = function(self,launcher)
		self.LastPosition = self:GetPos()
		self.CurAngles = self:GetAngles()
		
		self:GetPhysicsObject():EnableGravity(false)
		self:GetPhysicsObject():EnableDrag(false)
		self:EmitSound("Missile.Accelerate", 500, 70)
		
		timer.Create("neapon_bulletPhysics_"..self:EntIndex(),1,1,function()
			if self:IsValid() then self.PhysicsUpdate = function(self,phys)
				if self.Launcher and self.Launcher.TarPos and !self.StopLocking then
					local AimVec = ( self.Launcher.TarPos - self.LastPosition ):Angle()
					local Dist = math.min((self.Launcher.TarPos - self.LastPosition):Length(), 5000)
					local Mod = math.abs(Dist - 5000)/3000
					
					self.CurAngles.p = math.ApproachAngle(self.CurAngles.p, AimVec.p, 2 + Mod)
					self.CurAngles.r = math.ApproachAngle(self.CurAngles.r, AimVec.r, 2 + Mod)
					self.CurAngles.y = math.ApproachAngle(self.CurAngles.y, AimVec.y, 2 + Mod)
					self.Entity:SetAngles( self.CurAngles )
					
					if (Dist < 200) and !self.Missed then
						/*timer.Simple(math.Rand(0.3, 0.5), function() 
							if IsValid(self.Entity) then
								local phys = self.Entity:GetPhysicsObject()
								phys:EnableGravity(true)
								self.StopLocking = true
							end
						end)*/
						self:StopSound( "Missile.Accelerate" )
						phys:EnableGravity(true)
						self.StopLocking = true
						self.Missed = true
					end
				end
				if (self.Missed) then
					phys:AddAngleVelocity(Vector(math.Rand(-5,5), math.Rand(-5,5), math.Rand(-1,5))) 
				else
					phys:SetVelocity(self.Entity:GetForward()*3100)
				end
				self.LastPosition = self.Entity:GetPos()
			end end
		end)
	end,},
	["models/spacebuild/nova/laser.mdl"] = {scale=3,DamageForce = 100,LaserStart=Vector(52.7,500,-31.3),LaserEnd=Vector(52.7,28,-31.3),AcceptInput = function(self,name,activator,caller) -- Things like E
		if name == "Use" and caller:IsPlayer() and !caller:KeyDownLast(IN_USE) then -- Edge keyE
			self:SetShoot(!IsValid(self.Laser_laser))
		end
	end, Setup = function(self)
		if self.DamageForce then self.Damage = self.DamageForce end
		if not NS3 then self.Resources = {Energy = {1}} self.BufferSize = 1 return end
	
		local ns3_base = scripted_ents.Get( "ns3_base_entity" )
		local ns3_utility = scripted_ents.Get("ns3_utility")
		self.Link = ns3_base.Link
		self.UnLink = ns3_base.UnLink
		self.StoreCollectResources = ns3_base.StoreCollectResources
		self.MergeResource = ns3_base.MergeResource
		self.Requesting = {}
		self.Links = {}
		self.DaisyLinks = {}
		self.Receiving = {}
		self.Priority = 1.5
		self.Resources = table.Copy(NS3.Resources)
		if !self.Environment then self.Environment = {Resources = table.Copy(NS3.Resources), Max = 2000000} end
		self.BufferSize = self.Damage * 10
		local id = self.Entity:EntIndex()
		timer.Create("NS3_Hijack_"..id,1,0,function()
			if !IsValid(self) then timer.Destroy("NS3_Hijack_"..id) return end
			self:StoreCollectResources()
			self.Requesting.Energy = self.BufferSize - self.Resources.Energy[1]
			if self.Resources.Energy[1] / self.BufferSize < 0.5 then self:SetShoot(false) 
			elseif IsValid(self.Laser_laser) then self.Resources.Energy[1] = self.Resources.Energy[1] - self.BufferSize/2 
			end
		end)
	end, SetShoot=function(self,bool)
		if IsValid(self.Laser_laser) != bool then
			if bool and self.Resources.Energy[1] / self.BufferSize > 0.49 then 
				local targ = ents.Create("info_target")
				targ:SetKeyValue("targetname", tostring(targ))
				targ:SetPos(self:LocalToWorld(self.LaserStart))
				targ:Spawn()
				targ:SetParent(self)
				self.Laser_targ = targ
				
				local laser = ents.Create("env_laser")
				laser:SetKeyValue("texture", "sprites/laserbeam.spr")
				laser:SetKeyValue("noiseamplitude", "0")
				laser:SetKeyValue("width", "3")
				laser:SetKeyValue("damage", self.Damage)
				laser:SetKeyValue("spawnflags", "48")
				laser:SetKeyValue("rendercolor", "255 0 0")
				laser:SetKeyValue("lasertarget", tostring(targ))
				laser:SetPos(self:LocalToWorld(self.LaserEnd))
				laser:SetAngles(self:GetAngles())
				laser:Spawn()
				laser:SetParent(self)
				laser:Fire("turnon",0)
				self.Laser_laser = laser
			else
				if self.Laser_laser and self.Laser_laser:IsValid() then self.Laser_laser:Remove() end
				self.Laser_laser = nil
				if self.Laser_targ and self.Laser_targ:IsValid() then self.Laser_targ:Remove() end
				self.Laser_targ = nil
			end
		end
	end},
	["models/slyfo/sat_laser.mdl"] = {scale=3,DamageForce = 38,LaserStart = Vector(407,0,0), LaserEnd = Vector(107,0,0),}, //Functions copied from models/spacebuild/nova/laser.mdl: AcceptInput,SetShoot,Setup
	//["models/turretbody.mdl"] = {scale=3,shootpos = {Vector(3,40,6.3),Vector(3,40,15.5),Vector(-12,40,6.3),Vector(-12,40,15.5)},shootdir = Vector(0,1,0),TarPos = Vector(),Setup = function(self)
	["models/turretbody.mdl"] = {scale=3,shootpos = {Vector(18,42.5,6.3),Vector(18,42.5,15.5),Vector(3,42.5,6.3),Vector(3,42.5,15.5)},shootdir = Vector(0,1,0),Setup = function(self)
		WireLib.CreateSpecialInputs(self.Entity,{"Fire","Target","Bearing","Elevation"},{"NORMAL","VECTOR","NORMAL","NORMAL"})
		self:GetPhysicsObject():EnableMotion(false)
		self:SetPos(self:GetPos() + Vector(0,0,5))
		self:GetPhysicsObject():SetMass(100)
		
		if !self.TBase then
			self.TBase = ents.Create("prop_physics")
			self.TBase:SetModel("models/turretbase.mdl")
			self.TBase:SetPos(self:LocalToWorld(Vector(0.4,0.2,0)))
			self.TBase:SetAngles(self:LocalToWorldAngles(Angle(0,0,0)))
			self.TBase:Spawn()
			self.TBase:GetPhysicsObject():SetMass(50)
			//constraint.Axis(self.TBase,self,0,0,Vector(-4.9151,0.6731,-1.3365),Vector(-4.6233,0.320,11.8363),0,0,0.1,1)
			constraint.Axis(self.TBase,self,0,0,self.TBase:GetPhysicsObject():GetMassCenter(),self:OBBCenter()+Vector(0,0,500),0,0,0.1,1)
			undo.AddEntity( self.TBase )
		end
		-- For nice axises, (E1,E2,0,0,E1:BoxCenter,E2:WorldToLocal(E1:LocalToWorld(E1:BoxCenter)-E1:GetForward()*0.15),0,0,friction)

		if !self.TElevator then 
			self.TElevator = ents.Create("prop_physics")
			self.TElevator:SetModel("models/turretelevator.mdl")
			self.TElevator:SetPos(self:LocalToWorld(Vector(0,-1.5,0)))
			self.TElevator:SetAngles(self:LocalToWorldAngles(Angle(0,0,0)))
			self.TElevator:SetCollisionGroup(COLLISION_GROUP_WORLD)
			self.TElevator:Spawn()
			self.TElevator:GetPhysicsObject():SetMass(30)
			self.TElevator:GetPhysicsObject():EnableGravity(false)
			//self.shootent = self.TElevator
			constraint.Axis(self,self.TElevator,0,0,Vector(-4.7,0.8,10.4),self.TElevator:WorldToLocal(self:LocalToWorld(Vector(-4.7,0.8,10.4))-self:GetForward()*0.15),0,0,0.1)
			undo.AddEntity( self.TElevator )
		end
			
		self.TBarrel1 = ents.Create("prop_physics")
		self.TBarrel1:SetModel("models/turretbarrel.mdl")
		self.TBarrel1:SetPos(self:LocalToWorld(Vector(0,1,0)))
		self.TBarrel1:SetAngles(self:LocalToWorldAngles(Angle(0,0,0)))
		self.TBarrel1:Spawn()
		self.TBarrel1:GetPhysicsObject():SetMass(10)
		self.TBarrel1:SetMaterial("models/turretbarrel/turretbarrel")
		self.TBarrel1:SetParent(self.TElevator)
		//constraint.Weld(self.TElevator,self.TBarrel1)
		undo.AddEntity( self.TBarrel1 )

		self.TBarrel2 = ents.Create("prop_physics")
		self.TBarrel2:SetModel("models/turretbarrel.mdl")
		self.TBarrel2:SetPos(self:LocalToWorld(Vector(-15,1,0)))
		self.TBarrel2:SetAngles(self:LocalToWorldAngles(Angle(0,0,0)))
		self.TBarrel2:Spawn()
		self.TBarrel2:GetPhysicsObject():SetMass(10)
		self.TBarrel2:SetMaterial("models/turretbarrel/turretbarrel")
		self.TBarrel2:SetParent(self.TElevator)
		self.shootent = self.TBarrel2
		//constraint.Weld(self.TElevator,self.TBarrel2)
		undo.AddEntity( self.TBarrel2 )
		
		self:GetPhysicsObject():EnableMotion(true)
		self.TBase:GetPhysicsObject():EnableMotion(false)
	end, Think = function(self)
		local bearing, elevation
		if self.TarPos then
			local pos = WorldToLocal(self.TarPos,Angle(),self:GetPos(),self:GetAngles()+Angle(0,-90,0))
			bearing = 180 / math.pi * math.atan2(pos.y,pos.x)
			pos = self.TElevator:WorldToLocal(self.TarPos)
			elevation = 180 / math.pi * math.asin(pos.z / pos:Length())
		else
			if self.Bearing then 
				//bearing = self.Bearing - self:GetAngles().y 
				local ang = self:GetAngles()
				ang.y = math.NormalizeAngle(self.Bearing - 90)
				self:SetAngles(ang)
			end
			if self.Elevation then 
				local ang = self.TElevator:GetAngles()
				if self.Bearing then ang.y = math.NormalizeAngle(self.Bearing - 90) else ang.y = self:GetAngles().y end
				ang.r = self.Elevation
				self.TElevator:SetAngles(ang)
			end
		end
		
		if bearing then
			local yaw = self:GetForward() * ((bearing - self.d.bearing) * 12 + bearing) * self:GetPhysicsObject():GetMass() * 2
			self:GetPhysicsObject():ApplyForceOffset( self:GetRight() * -1, yaw )
			self:GetPhysicsObject():ApplyForceOffset( self:GetRight(), yaw * -1 )
			self.d.bearing = bearing
		end
		if elevation then
			local roll  = self:GetRight() * ((elevation - self.d.elevation) * 8 + elevation) * self.TElevator:GetPhysicsObject():GetMass()
			self.TElevator:GetPhysicsObject():ApplyForceOffset( self.TElevator:GetUp(), roll )
			self.TElevator:GetPhysicsObject():ApplyForceOffset( self.TElevator:GetUp() * -1, roll * -1 )
			self.d.elevation = elevation
		end
	end},
}
Neapon.GunModels["models/slyfo/sat_laser.mdl"].AcceptInput = Neapon.GunModels["models/spacebuild/nova/laser.mdl"].AcceptInput
Neapon.GunModels["models/slyfo/sat_laser.mdl"].SetShoot = Neapon.GunModels["models/spacebuild/nova/laser.mdl"].SetShoot
Neapon.GunModels["models/slyfo/sat_laser.mdl"].Setup = Neapon.GunModels["models/spacebuild/nova/laser.mdl"].Setup

/*
pos = WorldToLocal(Vector(pos[1],pos[2],pos[3]),Angle(0,0,0),Vector(originpos[1],originpos[2],originpos[3]),Angle(originangle[1],originangle[2],originangle[3]))
	return rad2deg*-atan2(pos.y, pos.x)
	
	*/
Neapon.BulletModels = {
	["models/Slyfo_2/pss_gasserprojectile.mdl"] = {bulletsound = "weapons/crossbow/fire1.wav"},
	["models/props_c17/trappropeller_lever.mdl"] = {bulletsound = "weapons/ar2/ar2_altfire.wav"},
	["models/cerus/weapons/projectiles/pc_proj.mdl"] = {bulletsound = "weapons/ar2/ar2_altfire.wav", bulletangle=Angle(0,-90,0)},
	["models/props_phx/amraam.mdl"] = {bulletsound = "weapons/rpg/rocketfire1.wav",bulletangle=Angle(0,-90,0),bulletSetup = function(self)
		self.HugeExplosion = true
		self.Smoke = 2
		self.Splash = 3
		self.Shake = true
	end},
}
local gunmodels = {}
for k in pairs(Neapon.GunModels) do gunmodels[k] = true end
local bulletmodels = {}
for k in pairs(Neapon.BulletModels) do bulletmodels[k] = true end
util.AddNetworkString("neapon_models")
net.Start("neapon_models") net.WriteTable(gunmodels) net.WriteTable(bulletmodels) net.Broadcast() -- Useful when reloading
hook.Add("PlayerInitialSpawn","Neapon_models",function(ply)
	net.Start("neapon_models") net.WriteTable(gunmodels) net.WriteTable(bulletmodels) net.Send(ply)
end)

function ENT:Setup()
	WireLib.CreateInputs(self.Entity,{"Fire"})
	--self.shootpos = Neapon.GunModels[mdl].shootpos
end

function ENT:AcceptInput(name,activator,caller) -- Things like E
	if name == "Use" and caller:IsPlayer() and !caller:KeyDownLast(IN_USE) then -- Edge keyE
		self:Reload()
		self:SetShoot(true)
		if self.Mode == 3 then -- Automatic
			local hookname="CheckPlyUse_"..self:EntIndex()
			hook.Add("Tick",hookname,function()
				if !IsValid(self.Entity) then hook.Remove("Tick",hookname)
				elseif !caller:IsValid() || !caller:KeyDown(IN_USE) then hook.Remove("Tick",hookname) self:SetShoot(false) end
			end)
		end
	end
end

function ENT:TriggerInput(iname, value) -- Wiremod Inputs
	if iname == "Fire" then self:SetShoot(value != 0)
	elseif iname == "Target" then 
		self.TarPos = value
		self.Elevation = nil self.Bearing = nil
	elseif iname == "Elevation" then 
		if value == 0 then self.Elevation = nil
		else
			self.Elevation = value
			self.TarPos = nil
		end
	elseif iname == "Bearing" then
		if value == 0 then self.Bearing = nil
		else
			self.Bearing = value
			self.TarPos = nil
		end
	end
end

local nextshoot = 0
function ENT:SetShoot(bool)
	if bool then
		if self.Mode == 3 then -- fully automatic, stream of bullets
			timer.Create("Shoot_"..self:EntIndex(),self.Cooldown,0,function() self:Shoot() end)
		end
		self:Shoot()
	else
		timer.Remove("Shoot_"..self:EntIndex())
	end
end

function ENT:Shoot()
	if !self || !IsValid(self.Entity) || nextshoot > CurTime() then return end
	nextshoot = CurTime() + self.Cooldown
	local bullet = ents.Create("neapon_projectile")
	--constraint.NoCollide(bullet,self.Entity,0,0)
	bullet:SetPos(self.shootent:LocalToWorld(table.Random(self.shootpos)+(self.bulletoffset or vector_origin)))
	local dir = self.shootent:LocalToWorld(self.shootdir) - self.shootent:GetPos()
	//bullet:SetAngles((-dir:Angle():Right()):Angle())
	bullet:SetAngles(self.shootent:LocalToWorldAngles((-self.shootdir:Angle():Right()):Angle()+(self.bulletangle or angle_zero)))
	bullet:SetModel(self.BulletModel)
	bullet.Launcher = self
	bullet.Owner = self.SPPOwner
	bullet:Spawn()
	if self.bulletSetup then self.bulletSetup(bullet) end
	if self.LauncherBulletSetup then self.LauncherBulletSetup(bullet,self) end
	bullet.Born = CurTime()
	bullet.Speed = self.Speed
	bullet.Damage = self.Damage
	bullet.Splash = self.Splash
	bullet.Mode	  = self.Mode -- 13.5237 is magic number for gravity
	local force = (dir * self.Speed * 800 + Vector(0,0,600/33))
	bullet:GetPhysicsObject():ApplyForceCenter(force * bullet:GetPhysicsObject():GetMass())
	if self.bulletsound then self.Entity:EmitSound(self.bulletsound) end
end
function ENT:Reload()
	-- nothing here yet boss!
end

function ENT:OnRemove()
	if self.IdleSound then self.Entity:StopSound( self.IdleSound ) end
	if self.IdleSound2 then self.Entity:StopSound( self.IdleSound2 ) end
	if self.SoundSpecial && self.SoundSpecial:IsPlaying() then self.SoundSpecial:Stop() end
	if self.Active && !self.Mute then self.Entity:EmitSound( "Airboat_engine_stop" ) end
	WireLib.Remove(self)
end

function ENT:PreEntityCopy()
	local DupeInfo = WireLib.BuildDupeInfo(self.Entity)
	if DupeInfo then duplicator.StoreEntityModifier( self, "WireDupeInfo", DupeInfo ) end
	if self.TElevator then duplicator.StoreEntityModifier(self,"NeaponLauncherParts",{elevator = self.TElevator:EntIndex(), base = self.TBase:EntIndex()}) end
end
function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
	if !Ent.EntityMods then return end
	if Ent.EntityMods.WireDupeInfo then WireLib.ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, function(id) return CreatedEntities[id] end) end
	local tab = Ent.EntityMods.NeaponLauncherParts
	if tab then
		if tab.elevator then self.TElevator = CreatedEntities[tab.elevator] end
		if tab.base then self.TBase = CreatedEntities[tab.base] end
	end
end
