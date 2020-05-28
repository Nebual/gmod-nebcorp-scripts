SWEP.Author 		= "Nebual"
SWEP.Contact 		= "nebual@nebtown.info"
SWEP.Purpose 		= "Fix shit"
SWEP.Instructions 	= "Left Click to repair Namaged entities\nRight click toggles Namage Immunity (alt for the whole contraption)"
SWEP.Category		= "Nebcorp"

SWEP.Weight		= 15
SWEP.Base 			= "weapon_base"
SWEP.ViewModelFOV	= 62
SWEP.ViewModelFlip	= false
SWEP.ViewModel 		= "models/weapons/v_models/v_wrench_engineer.mdl"
SWEP.WorldModel 	= "models/weapons/w_models/w_wrench.mdl"
SWEP.AnimPrefix		= "python"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.GotPrimary 	= true
SWEP.GotSecondary 	= false

SWEP.Swing = Sound( "weapons/wrench_swing.wav" )
SWEP.HitWorld = Sound( "weapons/wrench_hit_world.wav" )
SWEP.HitFlesh = { Sound( "weapons/cbar_hitbod1.wav" ), Sound( "weapons/cbar_hitbod2.wav" ), Sound( "weapons/cbar_hitbod3.wav" ) }
SWEP.MinDamage = 22
SWEP.MaxDamage = 44
SWEP.DrawDelay = 0.6

SWEP.Primary.ClipSize		= 8					-- Size of a clip
SWEP.Primary.DefaultClip	= 32				-- Default number of bullets in a clip
SWEP.Primary.ShootInWater	= true
SWEP.Primary.Automatic		= true			-- Automatic/Semi Auto
SWEP.Primary.Ammo			= "none"
SWEP.Primary.Reload 		= false

SWEP.Secondary.ClipSize 	= -1
SWEP.Secondary.DefaultClip 	= -1
SWEP.Secondary.Automatic 	= false
SWEP.Secondary.Ammo 		= "none"
SWEP.HoldType = "melee"
SWEP.PrintName 			= "Nebcorp Wrench"
SWEP.Slot 				= 2
SWEP.SlotPos 			= 2
SWEP.LastTime = 0
SWEP.idledelay = 0
SWEP.immune = 2
SWEP.ImmuneMsgs = {"Invulnerable!","Immortal!","Ghostable!","Destructable!"}

AddCSLuaFile( "cl_init.lua" )



function SWEP:PrimaryAttack() Namage.ProcessSwing(self, 1) end
function SWEP:SecondaryAttack() Namage.ProcessSwing(self, 2) end
function SWEP:Reload() 
	if self.Owner:KeyDownLast(IN_RELOAD) then return end
	self.immune = self.immune + 1
	if self.immune > 3 then self.immune = 1 end
	Namage.Hint(self.Owner,"Right clicking will now toggle "..self.ImmuneMsgs[self.immune], 7)
end

function Namage.ProcessSwing(self, mode)
	if self.LastTime > CurTime() then return false else 
		self.LastTime = CurTime() + 0.8 
		self.Weapon:SetNextPrimaryFire( CurTime() + 0.8 )
		self.Weapon:SetNextSecondaryFire( CurTime() + 0.8 )
	end
	self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )
	self.Owner:SetAnimation( PLAYER_ATTACK1 )
	self.Owner:EmitSound( self.Swing, 100, 100 )
	self.idledelay = CurTime() + 0.85
	local timerid = "NCWrench_"..self.Owner:EntIndex()
	timer.Create(timerid, 0.3, 1, function() Namage.ProcessSwing2(self, mode) timer.Destroy(timerid) end)
end
function Namage.ProcessSwing2(self, mode)
	local ply = self.Owner
	if not IsValid(ply) then return end
	local trace = util.QuickTrace(ply:GetShootPos(),ply:GetAimVector()*80,ply)
	if not trace.Hit then return end
	local ent = trace.Entity
	if trace.HitWorld then 
		self:GetTextureDecal(trace)
		self.Owner:EmitSound( self.HitWorld, 100, 100 )
	elseif ent:IsPlayer() or ent:IsNPC() then
		ent:SetHealth(math.min(ent:GetMaxHealth(), ent:Health() + math.random(self.MinDamage, self.MaxDamage)))
		self.Owner:EmitSound( table.Random(self.HitFlesh), 100, 100 )
	elseif ent:IsValid() then
		self:GetTextureDecal(trace)
		self.Owner:EmitSound( self.HitWorld, 100, 100 )
		if mode == 1 then Namage.HealSwing(self,ent)
		elseif mode == 2 then 
			if hook.Call("CanTool",GAMEMODE,self.Owner,trace,"ignite") ~= false then Namage.ImmuneSwing(self,ent) end
		--elseif mode == 3 then Namage.MenuSwing(self,ent)
		end
	end
	
	if mode == 1 then
		local aimpos = trace.HitPos or (ply:GetShootPos() + ply:GetAimVector()*70)
		local found = ents.FindInSphere(aimpos, 10)
		for k,v in pairs(found) do
			if v.Namage and v ~= ent and (v:NearestPoint(aimpos):Distance(aimpos) < 12) then
				Namage.HealSwing(self,v)
			end
		end
	end
end

function Namage.HealSwing(self,ent)
	ReviveCorpse(self.Owner, ent) -- Incase its a corpse/gib
	if ent:IsOnFire() then ent:Extinguish() end
	if ent:GetClass() == "gmod_wire_expression2" and ent.error then ent.error = nil ent:Reset() end
	local tab = ent.Namage
	if tab then 
		tab.FireHP = tab.MaxHP / 8
		if tab.MaxHP - tab.HP < 300 then Namage.UpdateProp(ent,tab.MaxHP) 
		elseif tab.MaxHP < 1000 then Namage.UpdateProp(ent, math.min(tab.HP + tab.MaxHP / 2, tab.MaxHP))
		else Namage.UpdateProp(ent, math.min(tab.HP + tab.MaxHP / 3, tab.MaxHP))
		end
		if tab.Ghosted then
			local msg = "Repaired "
			if tab.HP == tab.MaxHP then 
				tab.Ghosted = nil
				tab.Immune = 3
				local c = tab.Color
				ent:SetColor(c.r,c.g,c.b,c.a)
				-- ent:SetNotSolid(false)
				ent:SetCollisionGroup( ent.Namage.OldCollisions )
				ent.Namage.OldCollisions = nil
				if IsValid(ent:GetPhysicsObject()) then
					ent:GetPhysicsObject():EnableCollisions(true)
				end
			else
				msg = "Starting repairs on "
				if tab.Ghosted == 2 then msg = "Continuing repairs on " elseif tab.Ghosted == 3 then msg = "Still working on repairing that " end
				tab.Ghosted = tab.Ghosted + 1
			end
			Namage.Hint(self.Owner,msg .. string.sub(table.remove(string.Explode("/", ent:GetModel())), 1,-5) .. "["..ent:EntIndex().."]!", 4)
		end
	end
end

function Namage.RunDaemon(ent, tab, id)
	if not IsValid(ent) or not constraint.HasConstraints(ent) then
		for k,v in pairs(tab) do if IsValid(v) and v.Namage then v.Namage.Daemon = nil end end
		timer.Destroy("NamageDaemon_"..id)
	else
		local state = ent.Namage.Immune
		for k,v in pairs(constraint.GetAllConstrainedEntities(ent)) do 
			if v.Namage and v.Namage.Immune ~= state then
				v.Namage.Immune = state 
				Namage.UpdateProp(v) 
			end 
		end
	end
end
function Namage.ImmuneSwing(self,ent)
	local state = self.immune
	if not ent.Namage then Namage.InitProp(ent) state = 4 end
	if not ent.Namage then return end
	local msg = self.ImmuneMsgs[self.immune]
	if ent.Namage.Immune == state then state, msg = 4,"Destructable!" end
	
	if IsValid(ent.Spirit) then ent.Spirit.DeathRagdoll = nil end
	
	if self.Owner:KeyDown( IN_WALK ) and constraint.HasConstraints(ent) then
		local tab,count = constraint.GetAllConstrainedEntities(ent),0
		for _,v in pairs(tab) do
			if not v.Namage then Namage.InitProp(v) end
			if v.Namage then 
				v.Namage.Immune = state
				if v.Namage.Daemon then timer.Destroy("NamageDaemon_"..v:EntIndex()) end
				if state ~= 4 then v.Namage.Daemon = ent:EntIndex() else v.Namage.Daemon = nil end
				Namage.UpdateProp(v)
				count=count+1
			end
		end
		if state ~= 4 then timer.Create("NamageDaemon_"..ent:EntIndex(), 5, 0, function() Namage.RunDaemon(ent, tab, ent:EntIndex()) end) else timer.Destroy("NamageDaemon_"..ent:EntIndex()) end
		Namage.Hint(self.Owner,"This contraption of "..count.." entities is now "..msg, 4)
	else
		Namage.Hint(self.Owner,"This "..string.sub(table.remove(string.Explode("/", ent:GetModel())), 1,-5) .. "["..ent:EntIndex().."] is now "..msg, 4)
	end
	ent.Namage.Immune = state
	Namage.UpdateProp(ent)
end

function SWEP:Draw()
	self.Weapon:SendWeaponAnim(ACT_VM_DRAW)
	timer.Create( "VM_Idle_anim_timer_2" .. self:EntIndex(), self.DrawDelay, 1, function() if IsValid(self) and IsValid( self.Owner ) and self.Owner:GetActiveWeapon( ) == self then self:SendWeaponAnim( ACT_VM_IDLE ) end end )
	return true
end

function SWEP:Think()
	if self.idledelay and CurTime() > self.idledelay then
		self.idledelay = nil
		self:SendWeaponAnim( ACT_VM_IDLE )
	end
end

function SWEP:PlayIdle()
	if IsValid(self) and IsValid(self.Owner) and self.Owner:GetActiveWeapon() == self then
		self.Weapon:SendWeaponAnim( ACT_VM_IDLE )
		self.Owner:SetAnimation( PLAYER_ATTACK1 )
		return true
	else
		return false
	end
end

function SWEP:TranslateActivity( act )

	if ( self.Owner:IsNPC() ) then
		if ( self.ActivityTranslateAI[ act ] ) then
			return self.ActivityTranslateAI[ act ]
		end
		return -1
	end

	if ( self.ActivityTranslate[ act ] ~= nil ) then
		return self.ActivityTranslate[ act ]
	end
	
	return -1

end

function SWEP:GetTextureDecal(trace)
	local texture
	if trace.MatType == 77 then
		texture = "decals/metal/shot" .. math.random(1,5)
		sound.Play( "physics/metal/metal_solid_impact_bullet" .. math.random(1,4) .. ".wav", trace.HitPos )
	elseif trace.MatType == 89 then
		texture = "decals/glass/shot" .. math.random(1,5)
		sound.Play( "physics/glass/glass_impact_bullet" .. math.random(1,4) .. ".wav", trace.HitPos )
	elseif trace.MatType == 87 then
		texture = "decals/wood/shot" .. math.random(1,5)
		sound.Play( "physics/wood/wood_solid_impact_bullet" .. math.random(1,5) .. ".wav", trace.HitPos )
	--elseif trace.MatType == 67 then
	--	texture = "decals/concrete/tf_shot" .. math.random(1,5)
	elseif trace.MatType == 68 then
		texture = "decals/dirtshot" .. math.random(1,4)
	else
		texture = "decals/concrete/shot" .. math.random(1,4)
	end
	local decal = ents.Create( "infodecal" )
	decal:SetPos(trace.HitPos)
	decal:SetKeyValue("texture", texture)
	decal:Spawn()
	decal:Activate()
end