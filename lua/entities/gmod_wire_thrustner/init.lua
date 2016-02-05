
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Thrustner"

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetCollisionGroup( COLLISION_GROUP_WORLD )
	
	self:DrawShadow( false )

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end

	local max = self:OBBMaxs()
	local min = self:OBBMins()

	self.ThrustOffset 	= Vector( 0, 0, max.z )
	self.ThrustOffsetR 	= Vector( 0, 0, min.z )
	self.ForceAngle		= self.ThrustOffset:GetNormalized() * -1

	self.OWEffect = "fire"
	self.UWEffect = "same"

	self:SetOffset( self.ThrustOffset )
	//self:StartMotionController()

	self.LastThink = CurTime()

	self:SetSpeedTar(0)
	self:SetAccel(1.5)
	self:SetFrict(true)
	self.Throttle = 0
	
	local function ent1or2(ent,con)
		if not con then return ent end
		if con.Ent1==ent then return con.Ent2 end
		return con.Ent1
	end
	timer.Create("Thrustner_InitMainProp_"..self:EntIndex(),0.1,1,function()
		self.MainProp = ent1or2(self.Entity,constraint.FindConstraint(self.Entity, "Weld"))
		self.MainPhys = self.MainProp:GetPhysicsObject()
		self.OrigMainProp = self.MainProp
		self.TotalMass = 5
		for k,v in pairs(constraint.GetAllConstrainedEntities(self.MainProp)) do self.TotalMass = self.TotalMass + v:GetPhysicsObject():GetMass() end
	end)
		
	WireLib.CreateSpecialInputs(self.Entity, { "Speed", "Accel", "Prop","NoFriction" }, { "NORMAL", "NORMAL" , "ENTITY","NORMAL" })
	WireLib.CreateSpecialOutputs(self.Entity, { "Thrust","InternalSpeed" }, { "NORMAL","NORMAL"})
	//self.Inputs = Wire_CreateInputs(self, { "Speed","Accel" })

	self.SoundName = Sound( "PhysicsCannister.ThrusterLoop" )
end

function ENT:SetDatEffect(uwater, owater, uweffect, oweffect)
	if self:WaterLevel() > 0 then
		if not uwater then
			self:SetEffect("none")
			return
		end

		if uweffect == "same" then
			self:SetEffect(oweffect)
			return
		else
			self:SetEffect(uweffect)
			return
		end
	else
		if not owater then
			self:SetEffect("none")
			return
		end
		self:SetEffect(oweffect)
		return
	end
end

function ENT:Setup(oweffect, uweffect, owater, uwater, soundname)
	self:SetDatEffect(uwater, owater, uweffect, oweffect)

	self.OWEffect = oweffect
	self.UWEffect = uweffect
	self.OWater = owater
	self.UWater = uwater

	if (!soundname) then soundname = "" end
	
	-- Preventing client crashes
	local BlockedChars = '["?]'
	if ( string.find(soundname, BlockedChars) ) then
		self:StopSound( self.SoundName )
		soundname = ""
	end

	if (soundname == "") then
		self:StopSound( self.SoundName )
	end

	self.SoundName = Sound( soundname )
end

function ENT:TriggerInput(iname, value)
	if iname == "Speed" then 
		if value != self.SpeedTar then
			local speedvec = self.MainPhys:GetVelocity() * -self:GetUp()
			speed = speedvec:Length() * 0.09144 * ((speedvec.x+speedvec.y+speedvec.z) > 0 and 1 or -1)// 0.09144 converts garries/s to km/h
			
			self.Throttle = math.Clamp(speed / (value+0.0001),-2,2) // 0.0001 cause we don't want to divide by zero, but zero should make Throttle maxed out, so near zero works!
			self:SetSpeedTar(value)
			
			self.TotalMass = 0
			for k,v in pairs(constraint.GetAllConstrainedEntities(self.MainProp)) do self.TotalMass = self.TotalMass + v:GetPhysicsObject():GetMass() end
		end
	elseif iname == "Accel" then self:SetAccel(value)
	elseif iname == "Prop" then 
		if IsValid(value) && IsValid(value:GetPhysicsObject()) then self.MainProp = value
		else self.MainProp = self.OrigMainProp
		end
		self.MainPhys = self.MainProp:GetPhysicsObject()
	elseif iname == "NoFriction" then 
		self:SetFrict(value == 0)
	end
end

function ENT:Think()
	local throttlespeed = (CurTime() - self.LastThink) / (self.Accel / (self.Throttle > 0 and 1 or 3))
	if self.Friction or self.SpeedTar != 0 then 
		self.Throttle = math.Approach(self.Throttle,1,throttlespeed)
		if self.MainPhys:IsValid() then 
			local speedvec = self.MainPhys:GetVelocity() * -self:GetUp()
			local speed = speedvec:Length() * 0.09144 * ((speedvec.x+speedvec.y+speedvec.z) > 0 and 1 or -1)// 0.09144 converts garries/s to km/h
			local force = -16 * (self.SpeedTar*self.Throttle - speed) * self.MainPhys:GetMass()
			
			self.MainPhys:ApplyForceCenter(self:GetUp() * force)
			Wire_TriggerOutput(self.Entity, "Thrust", force)
			Wire_TriggerOutput(self.Entity, "InternalSpeed", speed)
		end
	else self.Throttle = math.Approach(self.Throttle,0,throttlespeed)
	end
	
	self.LastThink = CurTime()
	self:NextThink(CurTime() + 0.05)
	return true
end

function ENT:OnRestore()
	local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()
	end

	local max = self:OBBMaxs()
	local min = self:OBBMins()

	self.ThrustOffset 	= Vector( 0, 0, max.z )
	self.ThrustOffsetR 	= Vector( 0, 0, min.z )
	self.ForceAngle		= self.ThrustOffset:GetNormalized() * -1

	self:SetOffset( self.ThrustOffset )

	self.BaseClass.OnRestore(self)
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
end

function ENT:OnRemove()
	self.BaseClass.OnRemove(self)

	if (self.SoundName and self.SoundName != "") then
		self:StopSound(self.SoundName)
	end
end


function MakeWireThrustner( pl, Pos, Ang, model, oweffect, uweffect, owater, uwater, soundname, nocollide )
	if not pl:CheckLimit( "wire_thrusters" ) then return false end

	local wire_thruster = ents.Create( "gmod_wire_thrustner" )
	if not wire_thruster:IsValid() then return false end
	wire_thruster:SetModel( model )

	wire_thruster:SetAngles( Ang )
	wire_thruster:SetPos( Pos )
	wire_thruster:Spawn()

	wire_thruster:Setup(oweffect, uweffect, owater, uwater, soundname)
	wire_thruster:SetPlayer( pl )

	if nocollide == true then wire_thruster:GetPhysicsObject():EnableCollisions( false ) end

	local ttable = {
		soundname   = soundname,
		pl			= pl,
		oweffect	= oweffect,
		uweffect	= uweffect,
		owater		= owater,
		uwater		= uwater,
		nocollide	= nocollide
	}
	table.Merge(wire_thruster:GetTable(), ttable )

	pl:AddCount( "wire_thrusters", wire_thruster )

	return wire_thruster
end

duplicator.RegisterEntityClass("gmod_wire_thrustner", MakeWireThrustner, "Pos", "Ang", "Model", "oweffect", "uweffect", "owater", "uwater", "soundname", "nocollide")

