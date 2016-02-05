local Clamp = math.Clamp
local floor = math.floor

__e2setcost(1)

e2function void entity:setKeyValue(string key, string value)
	if IsValid(this) then this:SetKeyValue( key, value ) end
end

e2function void entity:setKeyValue(string key, value)
	if IsValid(this) then this:SetKeyValue( key, value ) end
end

e2function void entity:fireValue(string key, value)
	if IsValid(this) then this:Fire( key, value, 0) end
end

e2function void entity:fireValue(string key, string value)
	if IsValid(this) then this:Fire( key, value, 0) end
end

e2function string entity:namageType()
	if !IsValid(this) then return "" end
	if !this.Namage then Namage.InitProp(this) if !this.Namage then return "" end end
	return this.Namage.Type
end
e2function number entity:namage(string key)
	if !IsValid(this) then return 0 end
	if !this.Namage then Namage.InitProp(this) if !this.Namage then return 0 end end
	return this.Namage[key] or 0
end

e2function array array:sortByDistance(vector vec)
	vec = Vector(vec[1],vec[2],vec[3])
	local distfunc,IsValid = vec.Distance, IsValid
	table.sort(this, function(a,b)
		if !IsValid(a) then return false end
		if !IsValid(b) then return true end
		return distfunc(vec,a:GetPos()) < distfunc(vec,b:GetPos())
	end)
	return this
end

e2function number entity:getConvexCount()
	if !IsValid(this) || !this:GetPhysicsObject():IsValid() then return 0 end
	return GetConvexCount(this)//to nebcorp.lua so I can require the module in the right spot
end
e2function array entity:getConvexMesh(num)
	if !IsValid(this) || !this:GetPhysicsObject():IsValid() then return {} end
	return GetConvexMesh(this, math.Min(num, this:GetPhysicsObject():GetConvexCount() - 1)) //to nebcorp.lua so I can require the module in the right spot
end

e2function string entity:toast(vector vec, angle ang)
	if E2Toast and IsValid(this) then return E2Toast(this, vec, ang) end
end

porblumlist = {
	"Missing ';': @name at line 1, char 1",
	"a tragic soldering accident",
	"a malfunction of the lowest significance",
	"sound card driver mismatches",
	"Bank of Nebcorp fraud suspicion",
	"UNDEFINED_PORBLUM",
	"your mom being a nil value",
	"lua_underflow in lua_string_tables",
	"insufficient vespane gas",
	"being an ant in a previous life",
	"trying that stupid recursion trick",
	"ERROR CODE: 0",
	"defying spacetime restrictions",
	"violating international trade agreements",
	"Neon-based DRM limitations",
	"your WinRAR 30 day free trial expiring",
	"enduser trying 'the towel trick'"}

--- Errors the e2 chip. 
e2function void redChip()
	self.entity:SetOverlayText(self.entity.name .. "\n(has shut down due to\n"..table.Random(porblumlist)..")")
	local r,g,b,a = self.entity:GetColor()
	self.entity:SetColor(255, 0, 0, a)
	self.entity:PCallHook('destruct')
	self.entity.error = 1
end

--- Checks if an E2 has errored.
e2function number entity:isRed()
	if IsValid(this) && tobool(this.error) then return 1 else return 0 end
end

--- Resets an E2 chip
e2function void entity:reset()
	if this && this:IsValid() && this:GetClass() == "gmod_wire_expression2" then this:Reset() end
end

__e2setcost(2)

--- Short for entity():isWeldedTo()
e2function entity welded()
	local con = constraint.FindConstraint(self.entity, "Weld")
	if !con then return nil end
	if con.Ent1 == self.entity then return con.Ent2 else return con.Ent1 end
end

--- Plays scene (voice clip + face posing) <scene> on ent <ent>
e2function void entity:playScene(string scene)
	if !this || !this:IsValid() then return end
	this:PlayScene(string.gsub(scene, ".vcd", ""))
end

__e2setcost(15)
e2function number entity:canSee(entity ent2, vector vec)
	if !IsValid(this) or !IsValid(ent2) then return 0 end
	local pos = this:GetPos()
	if this:IsPlayer() then pos = this:GetShootPos() end
	if !util.TraceLine({start = pos, endpos = Vector(vec[1],vec[2],vec[3]), filter = {this, ent2}}).Hit then return 1 else return 0 end
end
e2function number entity:canSee(entity ent2)
	if !IsValid(this) || !IsValid(ent2) then return 0 end
	local pos = this:GetPos()
	if this:IsPlayer() then pos = this:GetShootPos() end
	if !util.TraceLine({start = pos, endpos = ent2:NearestPoint(pos), filter = {this, ent2}}).Hit then return 1 else return 0 end
end

e2function void entity:setOwner(entity ply)
	if !IsValid(this) or !IsValid(ply) or !ply:IsPlayer() then return end
	NADMOD.PlayerMakePropOwner(ply,this)
	this.Owner = ply
end

/*
// JAKN DELAGGER
e2function void entity:setCannotSee(array sendlist)
	if !this || !this:IsValid() then return end
	datastream12.StreamToClients( this, "NoDrawSelectEnts", sendlist )
end
e2function void entity:setCanSee(array sendlist)
	if !this || !this:IsValid() then return end
	datastream12.StreamToClients( this, "DrawSelectEnts", sendlist )
end
*/
--[[***********************************
Animation Control Functions
By: Jeremydeath
8-21-08
*************************************]]
e2function void entity:sequenceSet(number Sequence)
	if not IsValid(this) then return end
	if Sequence < 0 then return end
	if not this.AutomaticFrameAdvance then
		this.AutomaticFrameAdvance = true
	end
	this:SetSequence(floor(Sequence))
end
/*
e2function void entity:sequenceReset(number Sequence)
	if not IsValid(this) then return end
	if Sequence < 0 then return end
	if not this.AutomaticFrameAdvance then
		this.AutomaticFrameAdvance = true
	end
	this:ResetSequence(floor(Sequence))
end
*/
e2function void entity:sequenceSet(number Sequence, number Speed)
	if not IsValid(this) then return end
	if Sequence < 0 then return end
	if not this.AutomaticFrameAdvance then
		this.AutomaticFrameAdvance = true
	end
	this:SetSequence(floor(Sequence))
	this:SetPlaybackRate( math.max(Speed,0) )
end
/*
e2function void entity:sequenceReset(number Sequence, number Speed)
	if not IsValid(this) then return end
	if Sequence < 0 then return end
	if not this.AutomaticFrameAdvance then
		this.AutomaticFrameAdvance = true
	end
	this:ResetSequence(floor(Sequence))
	this:SetPlaybackRate( math.max(Speed,0) )
end

e2function number entity:sequenceGet()
	if not IsValid(this) then return 0 end
	return this:GetSequence() or 0
end
*/
e2function number entity:sequenceLookup(string SequenceName)
	if not IsValid(this) then return 0 end
	if(string.Trim(SequenceName) == "") then
		return 0
	else
		return this:LookupSequence(string.Trim(self.AnimationName)) or 0
	end
end

e2function entity entity:effectEnt()
	if !IsValid(this) then return else return this.AttachedEntity end
end


--  xxxxxxxxxx
-- CHAIR MODULE
--  xxxxxxxxxx

__e2setcost(10)

registerCallback( 'destruct', function( context )
    if context.entity.seat and context.entity.seat:IsValid() then context.entity.seat:Remove() end
end )

e2function entity spawnVehicle(string model, vector pos, angle rot) = e2function entity seatSpawn(string model, vector pos, angle rot)

--- Spawns a temporary vehicle with <model> model, at location <pos>, at angle <ang> that is destroyed when the chip is.
e2function entity spawnTempVehicle(string model, vector pos, angle ang)
	if self.entity.seat && self.entity.seat:IsValid() then return self.entity.seat end
	local position = Vector(pos[1], pos[2], pos[3])
	if !util.IsInWorld( position ) then return nil end
	if model == '' then model = 'models/Nova/airboat_seat.mdl' end
	local seat = ents.Create( 'prop_vehicle_prisoner_pod' )
	seat:SetModel( model )
	seat:SetPos( position )
	seat:SetAngles( Angle(ang[1], ang[2], ang[3]) )
	seat:Spawn()
	seat:SetKeyValue( "limitview", 0 )
	table.Merge( seat, { HandleAnimation = function(_,ply) return ply:SelectWeightedSequence( ACT_HL2MP_SIT ) end } )
	self.entity.seat = seat
	gamemode.Call( "PlayerSpawnedVehicle", self.player, seat )

	return seat
end

--  xxxxxxxxxx
-- 
--  xxxxxxxxxx

__e2setcost(10)

e2function entity spawnWheel(entity ent, vector pos, angle ang, string model, torque, friction, direction)
	if !ent || !ent:IsValid() then return end
	local ply = self.player
	local wheel = MakeWireWheel(ply, Vector(pos[1], pos[2], pos[3]), Angle(ang[1],ang[2],ang[3]), model, 0, 0, 0, 1, -1, 0, torque, direction)

	-- Set the hinge Axis perpendicular to the trace hit surface
	local LPos1 = wheel:GetPhysicsObject():WorldToLocal( wheel:GetPos() + wheel:GetForward() )
	local LPos2 =   ent:GetPhysicsObject():WorldToLocal( Vector(pos[1], pos[2], pos[3]) )
	local constraint, axis = constraint.Motor( wheel, ent, 0, 0, LPos1,	LPos2, friction, torque, 0, 1, false, ply, 0 )
	
	if self.data.propSpawnUndo then
		undo.Create("WireWheel")
			undo.AddEntity( axis )
			undo.AddEntity( constraint )
			undo.AddEntity( wheel )
			undo.SetPlayer( ply )
		undo.Finish()
	else
		table.insert(self.data.spawnedProps,wheel)
	end
	
	ply:AddCleanup( "wire_wheels", axis )
	ply:AddCleanup( "wire_wheels", constraint )
	ply:AddCleanup( "wire_wheels", wheel )
	
	wheel:SetWheelBase(ent)
	wheel:SetMotor( constraint )
	wheel:SetDirection( constraint.direction )
	wheel:SetAxis( wheel:GetForward() )
	if direction == -1 then wheel:Use(ply,ply,USE_ON,0) end
end

--- Creates a turret at <pos> <ang> with <damage> damage, <delay> delay, <numbullets> bullets per shot, <spread> spread, <force> impact force, <soundid> sound id (0-6), <tracerid> tracer id (1-4)
e2function entity spawnTurret(vector pos, angle ang, damage, delay, numbullets, spread, force, soundid, tracerid)
	local position = Vector(pos[1],pos[2],pos[3])
	local angle = Angle(ang[1],ang[2],ang[3])

	local damage = Clamp(damage, 0, 500)
	local delay = Clamp(delay, 0.02, 10)
	local numbullets = Clamp(numbullets, 1, 10)
	local spread = Clamp(spread, 0, 0.9)
	local force = Clamp(force, 0, 5000)
	local sound = "Weapon_SMG1.Single"
	if soundid == 0 then sound = ""
	elseif soundid == 1 then sound = "Weapon_Pistol.Single"
	elseif soundid == 2 then sound = "Weapon_SMG1.Single"
	elseif soundid == 3 then sound = "Weapon_AR2.Single"
	elseif soundid == 4 then sound = "Weapon_Shotgun.Single"
	elseif soundid == 5 then sound = "Airboat.FireGunHeavy"
	elseif soundid == 6 then sound = "ambient.electrical_zap_3"
	end
	local tracer = "Tracer"
	if tracerid == 2 then tracer = "AR2Tracer"
	elseif tracerid == 3 then tracer = "AirboatGunHeavyTracer"
	elseif tracerid == 4 then tracer = "LaserTracer"
	end

	local turret = WireLib.MakeWireEnt( self.player, {Class = "gmod_wire_turret", Pos=position, Angle=angle, Model="models/weapons/w_smg1.mdl"}, delay, damage, force, sound, numbullets, spread, tracer )
	if self.data.propSpawnUndo then
		undo.Create("e2_spawned_prop")
			undo.AddEntity( turret )
			undo.SetPlayer( self.player )
		undo.Finish()
	else
		table.insert(self.data.spawnedProps,turret)
	end
	
	return turret
end

--- Sets <this> (better be a turret) to have <damage> damage, <delay> delay, <numbullets> bullets per shot, <spread> spread, <force> impact force, <soundid> sound id (0-6), <tracerid> tracer id (1-4)
e2function void entity:setTurret(damage, delay, numbullets, spread, force, soundid, tracerid)
	local ent = IsValid(this) and this
	if !ent || ent:GetClass() != "gmod_wire_turret" then return end
	local damage = Clamp(damage, 0, 500)
	local delay = Clamp(delay, 0.02, 10)
	local numbullets = Clamp(numbullets, 1, 10)
	local spread = Clamp(spread, 0, 0.9)
	local force = Clamp(force, 0, 5000)
	local sound = "Weapon_SMG1.Single"
	if soundid == 0 then sound = ""
	elseif soundid == 1 then sound = "Weapon_Pistol.Single"
	elseif soundid == 2 then sound = "Weapon_SMG1.Single"
	elseif soundid == 3 then sound = "Weapon_AR2.Single"
	elseif soundid == 4 then sound = "Weapon_Shotgun.Single"
	elseif soundid == 5 then sound = "Airboat.FireGunHeavy"
	elseif soundid == 6 then sound = "ambient.electrical_zap_3"
	end
	local tracer = "Tracer"
	if tracerid == 2 then tracer = "AR2Tracer"
	elseif tracerid == 3 then tracer = "AirboatGunHeavyTracer"
	elseif tracerid == 4 then tracer = "LaserTracer"
	end

	ent.damage = damage
	ent.delay = delay
	ent.numbullets = numbullets
	ent.spread = spread
	ent.force = force
	ent.sound = sound
	ent.tracer = tracer
	ent.tracernum = 1
end

__e2setcost(2)
e2function void entity:setTurretSound(string sound)
	local ent = IsValid(this) and this
	if !ent || ent:GetClass() != "gmod_wire_turret" then return end
	ent.sound = sound
end

-- =========================
-- Entity Visual-Scaling
-- =========================
__e2setcost(10)

--- Sets the visual (NOT COLLISION) scale of <this> to <vec> [(3,3,3) would make it 3x larger]
e2function void entity:setScale(vector vec)
	if !IsValid(this) then return end
	SetScale(this, Vector(math.Max(vec[1], 0.01), math.Max(vec[2], 0.01), math.Max(vec[3], 0.01)))
end

--- Sets the visual (NOT COLLISION) scale of <this> to <vec> [(3,3,3) would make it 3x larger], over <speed> seconds.
e2function void entity:setScale(vector vec, speed)
	if !IsValid(this) then return end
	SetScale(this, Vector(math.Max(vec[1], 0.01), math.Max(vec[2], 0.01), math.Max(vec[3], 0.01)), speed)
end

e2function void entity:setScaleUnits(vector vec)
	if !IsValid(this) then return end
	local propsize = this:OBBMaxs() - this:OBBMins()
	SetScale(this, Vector(math.Max(vec[1] / propsize.x, 0.01), math.Max(vec[2] / propsize.y, 0.01), math.Max(vec[3] / propsize.z, 0.01)))
end

e2function void entity:setScaleUnits(vector vec, speed)
	if !IsValid(this) then return end
	local propsize = this:OBBMaxs() - this:OBBMins()
	SetScale(this, Vector(math.Max(vec[1] / propsize.x, 0.01), math.Max(vec[2] / propsize.y, 0.01), math.Max(vec[3] / propsize.z, 0.01)), speed)
end

__e2setcost(2)
--- Returns the scale of <this>
e2function vector entity:getScale()
	if !IsValid(this) then return end
	if this && this.data && this.data.Scale then return this.data.Scale else return Vector(1,1,1) end
end

--- Sends scaledata just to a specific person [obscure]

e2function void entity:setScale(entity ply, vector vec, spud)
	if !IsValid(this) || !IsValid(ply) || !ply:IsPlayer() then return end
	local Scale, Speed = {}, {}
	local id = this:EntIndex()
	Scale[id] = Vector(vec[1],vec[2],vec[3])
	Speed[id] = spud
	net.Start("Expression2_Scales")
		net.WriteTable(Scale)
		net.WriteTable(Speed)
	net.Send(ply)
end

hook.Add("InitPostEntity", "NebcorpNotSolid", function()
	duplicator.RegisterEntityModifier( "NebcorpNotSolid", function(ply, ent, data) ent:SetNotSolid(true) end)
end)

// End scaling section
// ====================

__e2setcost(2)

e2function vector pos()
	return self.entity:GetPos()
end

/*
e2function void entity:addCam(id, vector pos, angle angles, vector topleft, vector bottomright)
	if !this || !this:IsPlayer() then return end
	datastream12.StreamToClients( this, "E2Camera", {id = id, pos = pos, angles = angles, topleft = topleft, bottomright = bottomright} )
end

e2function void entity:removeCam(id)
	if !this || !this:IsPlayer() then return end
	datastream12.StreamToClients( this, "E2CameraRemove", {id = id} )
end
*/
__e2setcost(2)
--- "Respawns" <this>
e2function entity entity:spawn()
	local ent = IsValid(this) and this
	if ent then return ent:Spawn() end
end

// ====================
// Igniting
__e2setcost(1)

--- Extinguishes <this>
e2function void entity:extinguish()
	local ent = IsValid(this) and this
	if ent then ent:Extinguish() end
end

--- Lights <this> on fire for 60 seconds
e2function void entity:ignite()
	local ent = IsValid(this) and this
	if ent then ent:Ignite(60, 25) end
end

__e2setcost(2)
--- Lights <this> on fire for <dur> seconds
e2function void entity:ignite(dur)
	local ent = IsValid(this) and this
	if ent then ent:Ignite(math.Clamp(dur, 0, 600), 25) end
end

--- Lights <this> on fire for <dur> seconds, that ignites other ents within <radius> garries.
e2function void entity:ignite(dur, radius)
	local ent = IsValid(this) and this
	if ent then ent:Ignite(math.Clamp(dur, 0, 600), math.Clamp(radius, 0, 1000)) end
end

__e2setcost(1)
--- Sets <this>'s model to <model>
e2function void entity:setModel(string model)
	local ent = IsValid(this) and this
	if ent then ent:SetModel(model) end
end


NDesc["setModelPhysics(e:s)"] = "Changes the ent's model to be str, and refreshes its physics"
e2function void entity:setModelPhysics(string model)
	local ent = IsValid(this) and this
	if ent then 
		local tab = table.Copy(constraint.GetTable(ent))
		constraint.RemoveAll(ent)
		constraint.ForgetConstraints(ent)
		ent:SetModel(model)
		ent:PhysicsInit(6)
		BuildConstraintsFromTable(ent,tab)
	end
end

function BuildConstraintsFromTable(ent,tab)
	for k,v in pairs(tab) do
		if v.Ent1:EntIndex() == ent:EntIndex() then v.Ent1 = ent else v.Ent2 = ent end
		if v.Type == "Weld" then
			v.Constraint:Remove()
			constraint.Weld(v.Ent1, v.Ent2)
		elseif v.Type == "Rope" then
			constraint.Rope(v.Ent1, v.Ent2, v.Bone1, v.Bone2, v.LPos1, v.LPos2, v.length, v.addlength, v.forcelimit, v.width, v.material, v.rigid )
		elseif v.Type == "Elastic" then
			constraint.Elastic(v.Ent1, v.Ent2, v.Bone1, v.Bone2, v.LPos1, v.LPos2, v.constant, v.damping, v.rdamping, v.material, v.width, v.stretchonly )
		elseif v.Type == "Elastic" then
			constraint.Elastic(v.Ent1, v.Ent2, v.Bone1, v.Bone2, v.LPos1, v.LPos2, v.constant, v.damping, v.rdamping, v.material, v.width, v.stretchonly )
		elseif v.Type == "Slider" then
			constraint.Slider(v.Ent1, v.Ent2, v.Bone1, v.Bone2, v.LPos1, v.LPos2, v.width )
		elseif v.Type == "Axis" then
			constraint.Axis(v.Ent1, v.Ent2, v.Bone1, v.Bone2, v.LPos1, v.LPos2, v.forcelimit, v.torquelimit, v.friction, v.nocollide, v.LocalAxis, v.DontAddTable )
		elseif v.Type == "AdvBallsocket" then
			constraint.AdvBallsocket(v.Ent1, v.Ent2, v.Bone1, v.Bone2, v.LPos1, v.LPos2, v.forcelimit, v.torquelimit, v.xmin, v.ymin, v.zmin, v.xmax, v.ymax, v.zmax, v.xfric, v.yfric, v.zfric, v.onlyrotation, v.nocollide)
		elseif v.Type == "NoCollide" then
			constraint.NoCollide(v.Ent1, v.Ent2, v.Bone1, v.Bone2 )
		elseif v.Type == "Motor" then
			constraint.Motor( v.Ent1, v.Ent2, v.Bone1, v.Bone2, v.LPos1, v.LPos2, v.friction, v.torque, v.forcetime, v.nocollide, v.toggle, v.pl, v.forcelimit, v.numpadkey_fwd, v.numpadkey_bwd, v.direction, v.LocalAxis )
		elseif v.Type == "Pulley" then
			constraint.Pulley( v.Ent1, v.Ent4, v.Bone1, v.Bone4, v.LPos1, v.LPos4, v.WPos2, v.WPos3, v.forcelimit, v.rigid, v.width, v.material )
		elseif v.Type == "Ballsocket" then
			constraint.Ballsocket( v.Ent1, v.Ent2, v.Bone1, v.Bone2, v.LPos, v.forcelimit, v.torquelimit, v.nocollide )
		elseif v.Type == "Winch" then
			constraint.Winch(v.pl, v.Ent1, v.Ent2, v.Bone1, v.Bone2, v.LPos1, v.LPos2, v.width, v.fwd_bind, v.bwd_bind, v.fwd_speed, v.bwd_speed, v.material, v.toggle )
		elseif v.Type == "Hydraulic" then
			constraint.Hydraulic( v.pl, v.Ent1, v.Ent2, v.Bone1, v.Bone2, v.LPos1, v.LPos2, v.Length1, v.Length2, v.width, v.key, v.fixed, v.speed )
		elseif v.Type == "Muscle" then
			constraint.Muscle( v.pl, v.Ent1, v.Ent2, v.Bone1, v.Bone2, v.LPos1, v.LPos2, v.Length1, v.Length2, v.width, v.key, v.fixed, v.period, v.amplitude )
		end
	end
end

--- Sets <this>'s skin to <skin>
e2function void entity:setSkin(skin)
	local ent = IsValid(this) and this
	if ent then ent:SetSkin(skin) end
end

--- Returns <this>'s skin number
e2function number entity:getSkin()
	local ent = IsValid(this) and this
	if ent then return ent:GetSkin() end
end


__e2setcost(2)

--- Returns <this>'s health (NPCs, wooden/glass props)
e2function number entity:getHealth()
	if !IsValid(this) then return 0 end
	if this.Namage then 
		if this.Namage.Skip == 2 then return 9001 else return this.Namage.HP end
	end
	return this:Health() or 0
end

e2function void entity:setNamage(hp)
	if !IsValid(this) then return end
	if !this.Namage then Namage.InitProp(this) if !this.Namage then return end end
	if this.Namage.MaxHP < hp then this.Namage.MaxHP = hp end
	Namage.UpdateProp(this, hp)
end
e2function void entity:setNamageImmune(kind)
	if !IsValid(this) then return end
	if !this.Namage then Namage.InitProp(this) if !this.Namage then return end end
	this.Namage.Immune = math.Clamp(kind,1,4)
	Namage.UpdateProp(this)
end
NDesc["damage(e:n)"] = "Applies damage to an ent (negative numbers to give health)"
--- Applies <damage> damage to <this> (use negative numbers to give health)
e2function void entity:damage(damage)
	if !IsValid(this) then return end
	if damage > 0 then this:TakeDamage(damage)
	elseif damage < 0 then 
		if this:IsPlayer() or this:IsNPC() then this:SetHealth(this:Health() - damage) end
		if this.Namage then Namage.UpdateProp(this, this.Namage.HP - damage) end
	end
end
e2function void entity:setDamage(damage) = e2function void entity:damage(damage)
NDesc["damage(e:nn)"] = "Applies damage with a kind enumeration (8: burn 2: bullet)"
--- Applies <damage> damage to <this> (use negative numbers to give health)
e2function void entity:damage(damage, kind)
	if !IsValid(this) then return end
	if damage > 0 then 
		local dmginfo = DamageInfo()
		dmginfo:SetDamage( damage )
		dmginfo:SetDamageType( kind )
		dmginfo:SetAttacker( self.entity )
		this:TakeDamageInfo(dmginfo)
	elseif damage < 0 then 
		if this:IsPlayer() or this:IsNPC() then this:SetHealth(this:Health() - damage) end
		if this.Namage then Namage.UpdateProp(this, this.Namage.HP - damage) end
	end
end

e2function void entity:dissolve(kind)
	if !IsValid(this) || this:IsPlayer() || (this.Namage && this.Namage.Skip != 4) then return end
	local Dissolver = ents.Create( "env_entity_dissolver" )
	Dissolver:SetKeyValue( "dissolvetype", kind or 0 )
	Dissolver:SetKeyValue( "magnitude", 0 )
	Dissolver:SetPos( this:GetPos() )
	//Dissolver:SetPhysicsAttacker( attacker )
	Dissolver:Spawn()
	this:SetName("dissolve"..this:EntIndex())
	Dissolver:Fire( "Dissolve", "dissolve"..this:EntIndex(), 0 )
	Dissolver:Fire( "Kill", "", 0.1 )
end

--- Gibs <this>
e2function void entity:gib()
	local ent = IsValid(this) and this
	if ent then ent:GibBreakClient(ent:GetPos()) end
end

__e2setcost(10)

--- Woodgibs <this>
e2function void entity:woodGib()
	if !IsValid(this) then return end
	if !this:IsPlayer() && !this:IsNPC() then 
		this:SetModel("models/props_c17/FurnitureDresser001a.mdl")
		this:GibBreakClient(this:GetPos()) 
		this:GibBreakClient(this:GetPos()) 
		this:Remove()
	elseif (this:IsPlayer() and this:Alive()) || (this:IsNPC() and this:Health() > 0) then
		local wood = ents.Create( "prop_physics" )
		wood:SetPos( this:GetPos() )
		wood:SetOwner( self.player )
		wood:SetModel("models/props_c17/FurnitureDresser001a.mdl")
		wood:Spawn()
		wood:GibBreakClient(this:GetPos()) 
		wood:GibBreakClient(this:GetPos()) 
		wood:Remove()
		this:TakeDamage(99999)
	end
end

local function lotsagibs(this)
	this:GibBreakClient(this:GetPos()) 
	this:GibBreakClient(this:GetPos()) 
	this:GibBreakClient(this:GetPos() + Vector(0,0,200)) 
	this:GibBreakClient(this:GetPos() + Vector(0,200,0)) 
	this:GibBreakClient(this:GetPos() + Vector(200,0,0)) 
	this:GibBreakClient(this:GetPos() + Vector(0,0,-200)) 
	this:GibBreakClient(this:GetPos() + Vector(0,-200,0)) 
	this:GibBreakClient(this:GetPos() + Vector(-200,0,0)) 
end

--- Woodgibs <this> alot
e2function void entity:woodGibBig()
	if !IsValid(this) then return end
	if !this:IsPlayer() && !this:IsNPC() then 
		this:SetModel("models/props_c17/FurnitureDresser001a.mdl")
		lotsagibs(this)
		this:Remove()
	elseif (this:IsPlayer() and this:Alive()) || (this:IsNPC() and this:Health() > 0) then
		local wood = ents.Create( "prop_physics" )
		wood:SetPos( this:GetPos() )
		wood:SetOwner( self.player )
		wood:SetModel("models/props_c17/FurnitureDresser001a.mdl")
		wood:Spawn()
		wood:GibBreakClient(this:GetPos()) 
		wood:GibBreakClient(this:GetPos()) 
		wood:Remove()
		this:TakeDamage(99999)
	end
end

--- Makes <ent> explode into a large lovely pile of woodgibs
e2function void entity:woodGibHuge()
	if !IsValid(this) then return end
	if !this:IsPlayer() && !this:IsNPC() then 
		this:SetModel("models/props_c17/FurnitureDresser001a.mdl")
		lotsagibs(this)
		this:SetModel("models/props_phx/construct/wood/wood_panel4x4.mdl")
		lotsagibs(this)
		this:Remove()
	elseif (this:IsPlayer() and this:Alive()) || (this:IsNPC() and this:Health() > 0) then
		local wood = ents.Create( "prop_physics" )
		wood:SetPos( this:GetPos() )
		wood:SetOwner( self.player )
		wood:SetModel("models/props_c17/FurnitureDresser001a.mdl")
		wood:Spawn()
		wood:GibBreakClient(this:GetPos()) 
		wood:GibBreakClient(this:GetPos()) 
		wood:Remove()
		this:TakeDamage(99999)
	end
	return
end

--- Makes <ent> explode in a lovely pile of woodgibs  + exploison effect
e2function void entity:explodeWood()
	if !IsValid(this) then return end
	local explosive = ents.Create( "env_explosion" )
	explosive:SetPos( this:GetPos() )
	explosive:SetOwner( self.player )
	explosive:Spawn()
	explosive:SetKeyValue( "iMagnitude", "1" )
	explosive:Fire( "Explode", 0, 0 )
	explosive:EmitSound( "ambient/explosions/explode_4.wav", 100, 100 )
	util.BlastDamage( this, self.player, this:GetPos(), this:BoundingRadius()*1.75, 10 + this:BoundingRadius() / 6 )
	if !this:IsPlayer() && !this:IsNPC() then 
		this:SetModel("models/props_c17/FurnitureDresser001a.mdl")
		this:GibBreakClient(this:GetPos()) 
		this:GibBreakClient(this:GetPos()) 
		this:Remove()
	elseif (this:IsPlayer() and this:Alive()) || (this:IsNPC() and this:Health() > 0) then
		this:TakeDamage(99999)
		local wood = ents.Create( "prop_physics" )
		wood:SetPos( this:GetPos() )
		wood:SetOwner( self.player )
		wood:SetModel("models/props_c17/FurnitureDresser001a.mdl")
		wood:Spawn()
		wood:GibBreakClient(this:GetPos()) 
		wood:GibBreakClient(this:GetPos()) 
		wood:Remove()
	end
end

--- Makes <ent> explode.
e2function void entity:explode()
	if !IsValid(this) then return end
	local explosive = ents.Create( "env_explosion" )
	explosive:SetPos( this:GetPos() )
	explosive:SetOwner( self.player )
	explosive:Spawn()
	explosive:SetKeyValue( "iMagnitude", "1" )
	explosive:Fire( "Explode", 0, 0 )
	explosive:EmitSound( "ambient/explosions/explode_4.wav", 100, 100 )
	util.BlastDamage( this, self.player, this:GetPos(), this:BoundingRadius()*1.75, 10 + this:BoundingRadius() / 6 )
	if !this:IsPlayer() && !this:IsNPC() then 
		this:Remove()
	elseif (this:IsPlayer() and this:Alive()) || (this:IsNPC() and this:Health() > 0) then
		this:TakeDamage(99999)
	end
end

__e2setcost(2)
--- Returns how submerged (0-3) <this> is
e2function number entity:waterLevel()
	if IsValid(this) then return this:WaterLevel() end
end

--- Makes <this> not render at all
e2function void entity:propNoDraw(number drawDisable)
	if not PropCore.ValidAction(self, this, "draw") then return end
	this:SetNoDraw( drawDisable ~= 0 )
end

--- Makes <this>'s shadow not render at all
e2function void entity:setNoShadow(num)
	if IsValid(this) then this:DrawShadow( num == 0 ) end
end

--- Disables gravity on <this>
e2function void entity:setDisableGravity(num)
	if !IsValid(this) then return end
	local boolean = num == 0
	if this:IsPlayer() then 
		this:SetMoveType(boolean and MOVETYPE_FLY or MOVETYPE_WALK)
		this:SetMoveCollide(boolean and MOVECOLLIDE_FLY_BOUNCE or MOVECOLLIDE_DEFAULT)
		this:SetGravity(boolean and 0 or 1)
	elseif this:GetPhysicsObjectCount() > 1 then
		for x=0,this:GetPhysicsObjectCount()-1 do this:GetPhysicsObjectNum(x):EnableGravity( boolean ) end
	elseif validPhysics(this) then this:GetPhysicsObject():EnableGravity( boolean )
	end
end

--- Returns if <this> has gravity.
e2function number entity:hasGravity()
	if IsValid(this) then return (this:GetMoveType() != MOVETYPE_FLY) and 1 or 0 end
end

--- Makes <this> not solid. Super no-collide. No traces (bullets, toolgun) or collisions with anything.
e2function void entity:setNotSolid(num)
	if IsValid(this) then this:SetSolid( num ~= 0 and SOLID_NONE or SOLID_VPHYSICS ) end
	if num != 0 then
		duplicator.StoreEntityModifier(this,"NebcorpNotSolid",{})
	else
		duplicator.ClearEntityModifier(this,"NebcorpNotSolid")
	end
end

--- Makes every entity in <this> not solid.
e2function void array:setNotSolid(num)
	if !this || this == {} then return end
	local boolean = num != 0
	for _,v in ipairs(this) do
		self.prf = self.prf + 0.25
		if IsValid(v) then v:SetNotSolid( boolean ) end
	end
end

--- Makes <this> not collide with world or props BUT it DOES collide with players :D
e2function void entity:setNoCollisions(num)
	if IsValid(this) && validPhysics(this) then this:GetPhysicsObject():EnableCollisions( num == 0 ) end
end

--- Makes every entity in <this> not collide with world or props BUT they DO collide with players :D
e2function void array:setNoCollisions(num)
	if !this || this == {} then return end
	local boolean = num == 0
	for _,v in ipairs(this) do
		self.prf = self.prf + 0.25
		if IsValid(v) && validPhysics(v) then v:GetPhysicsObject():EnableCollisions( boolean ) end
	end
end

--- Toggles "Drag" (??) on <this>
e2function void entity:setNoDrag(num)
	if IsValid(this) && validPhysics(this) then this:GetPhysicsObject():EnableDrag( num == 0 ) end
end

--- Freezes <this>, like the physgun
e2function void entity:freeze(num)
	if IsValid(this) && validPhysics(this) then this:GetPhysicsObject():EnableMotion( num == 0 ) this:GetPhysicsObject():Wake() end
end

--- Makes every entity in <this> frozen, like the physgun
e2function void array:freeze(num)
if !this || this == {} then return end
	local boolean = num == 0
	for _,v in ipairs(this) do
		self.prf = self.prf + 0.25
		if IsValid(v) && validPhysics(v) then v:GetPhysicsObject():EnableMotion( boolean ) end
	end
end

__e2setcost(2)
// Type 8 allows for nocollide with all but World and Players, along with no movement short of 
// physgun, but also incompatible with constraints
--- Sets <this>'s Movetype enumeration
e2function void entity:setMoveType(int)
	local ent = IsValid(this) and this
	if ent then ent:SetMoveType(int) end
end

--- Sets <this>'s CollisionGroup enumeration
e2function void entity:setCollisionGroup(int)
	local ent = IsValid(this) and this
	if ent then ent:SetCollisionGroup(int) end
end

function math.angnorm(ang)
	if type(ang) == "number" then
		return (ang + 180) % 360 - 180
	else
		return Angle((ang.p + 180) % 360 - 180, (ang.y + 180) % 360 - 180, (ang.r + 180) % 360 - 180)
	end
end

__e2setcost(2)

--- Kills an NPC/Player
e2function void entity:kill()
	if IsValid(Ent) && ((ent:IsPlayer() && ent:Alive()) || (ent:IsNPC() && ent:Health() > 1)) then ent:Kill() end
end

--- Displays a hint popup to <this> with message <text> for <duration> seconds (<duration> being clamped between 0.7 and 7).
e2function void entity:hint(string text, duration)
	if !IsValid(this) || !this:IsPlayer() then return end
	WireLib.AddNotify(this, text, NOTIFY_GENERIC, Clamp(duration,0.7,7))
end

e2function number entity:validPhysics() = e2function number entity:isValidPhysics()

--- Sets view :D?
e2function void entity:setViewAngles(angle ang)
	if !IsValid(this) and this || !this:IsPlayer() then return end
	this:SnapEyeAngles(Angle(ang[1],ang[2],ang[3]))
end

// =======================
// RESOURCE Distribution STUFFZ
// =======================
/*
if CAF then
	local RD = CAF.GetAddon("Resource Distribution")

	--- Makes the chip "Link"able. Only needs to be called once
	e2function void resSetup(value)
		if value != 0 then
			RD.RegisterNonStorageDevice(self.entity)
		else 
			RD.RemoveRDEntity(self.entity)
		end
	end

	--- Might link it to that network?
	e2function void resLink(netid)
		RD.Link(self.entity, netid)
	end

	--- Might link it to that network?
	e2function void entity:resLink(netid)
		RD.Link(this, netid)
	end

	--- Consumes teh resources
	e2function void resConsume(string resource, amount)
		RD.ConsumeResource(self.entity, resource, math.abs(amount))
	end

	e2function void entity:resConsume(string resource, amount)
		RD.ConsumeResource(this, resource, math.abs(amount))
	end

	--- Returns teh resources
	e2function number resDisplay(string resource)
		return RD.GetResourceAmount(self.entity, resource)
	end
	
		--- Returns an array of planet/sun entities.
	e2function array sbPlanets()
		if !CAF then return end
		return SB_E2_Planets
	end

	--- Returns an array of tables pertaining to the useful information from planets/suns.
	e2function array sbPlanetsData()
		local planets = SB_E2_Planets
		local k = 0
		retarray = {}
		for _,v in ipairs(planets) do
			k = k + 1
			retarray[k] = v.sbenvironment
		end
		return retarray
	end

	--- Returns a table of information relating to the planet/sun with the entid <id>
	e2function table sbPlanetData(id)
		local ent = ents.GetByIndex(id)
		if ent && ent:IsValid() then return ent.sbenvironment else return {} end
	end

	--- Returns a table of information relating to <ent> planet/sun.
	e2function table sbPlanetData(entity ent)
		if ent && ent:IsValid() then return ent.sbenvironment else return {} end
	end
else
	e2function void resSetup(value) end
	e2function void resLink(netid) end
	e2function void entity:resLink(netid) end
	e2function void resConsume(string resource, amount) end
	e2function void entity:resConsume(string resource, amount) end
	e2function number resDisplay(string resource) return -2 end
	e2function array sbPlanets() return {} end
	e2function array sbPlanetsData() return {} end
	e2function table sbPlanetData(id) return {} end
	e2function table sbPlanetData(entity ent) return {} end
end
*/

e2function void holoModelCustom(index, string model)
	local Holo = self.data.holos[index]
	if not Holo or not IsValid(Holo.ent) then return end
	
	Holo.ent:SetModel(Model(model))
end

e2function void entity:setPhys(string mat)
	if !IsValid(this) then return end
	local phys = this:GetPhysicsObject()
	if IsValid(phys) then phys:SetMaterial(mat) end
end

registerOperator("mul", "sn", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return string.rep(rv1,rv2)
end)

registerOperator("mul", "ns", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return string.rep(rv2,rv1)
end)

registerOperator("sub", "ss", "s", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self, op1), op2[1](self, op2)
	return string.Replace(rv1,rv2,"")
end)

// Is RV2 inside the bounds of RV1
// All vector inputs should be World.	

//TODO:
//Add array support for tables of entities (both sides)
//done//Add +- 10 to all objectsizes, to reduce collisions further
/*
registerFunction("isIn", "e:r", "n", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
    	if !checkEntity(rv1) then return 0 end
	local v1maxx, v1minx, v1maxy, v1miny, v1maxz, v1minz = 0, 0, 0, 0, 0, 0
	local e1mins, e1maxs = rv1:LocalToWorld(rv1:OBBMins()), rv1:LocalToWorld(rv1:OBBMaxs())

	if (e1mins.x * 1.08) > (e1maxs.x * 1.08) then v1maxx = (e1mins.x * 1.08) v1minx = (e1maxs.x * 1.08) else v1maxx = (e1maxs.x * 1.08) v1minx = (e1mins.x * 1.08) end
	if (e1mins.y * 1.08) > (e1maxs.y * 1.08) then v1maxy = (e1mins.y * 1.08) v1miny = (e1maxs.y * 1.08) else v1maxy = (e1maxs.y * 1.08) v1miny = (e1mins.y * 1.08) end
	if (e1mins.z * 1.08) > (e1maxs.z * 1.08) then v1maxz = (e1mins.z * 1.08) v1minz = (e1maxs.z * 1.08) else v1maxz = (e1maxs.z * 1.08) v1minz = (e1mins.z * 1.08) end

	local v2maxx, v2minx, v2maxy, v2miny, v2maxz, v2minz = 0, 0, 0, 0, 0, 0
	local e2mins, e2maxs
	for k,v in ipairs(rv2) do
		local entity
		if isnumber(v) then
			entity = Entity(v)
		else entity = v end
		
		
		e2mins, e2maxs = entity:LocalToWorld(entity:OBBMins()), entity:LocalToWorld(entity:OBBMaxs())
		if (e2mins.x * 1.08) > (e2maxs.x * 1.08) then v1maxx = (e2mins.x * 1.08) v1minx = (e2maxs.x * 1.08) else v1maxx = (e2maxs.x * 1.08) v1minx = (e2mins.x * 1.08) end
		if (e2mins.y * 1.08) > (e2maxs.y * 1.08) then v1maxy = (e2mins.y * 1.08) v1miny = (e2maxs.y * 1.08) else v1maxy = (e2maxs.y * 1.08) v1miny = (e2mins.y * 1.08) end
		if (e2mins.z * 1.08) > (e2maxs.z * 1.08) then v1maxz = (e2mins.z * 1.08) v1minz = (e2maxs.z * 1.08) else v1maxz = (e2maxs.z * 1.08) v1minz = (e2mins.z * 1.08) end


		if v1maxx > v2minx && v1minx < v2maxx && v1maxy > v2miny && v1miny < v2maxy && v1maxz > v2minz && v1minz < v2maxz then
			return entity 
		end
	end
end)

registerFunction("isIn", "e:e", "n", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
    	if !checkEntity(rv1) || !checkEntity(rv2) then return 0 end
	local v1maxx, v1minx, v1maxy, v1miny, v1maxz, v1minz, v2maxx, v2minx, v2maxy, v2miny, v2maxz, v2minz = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	local e1mins, e1maxs, e2mins, e2maxs = rv1:LocalToWorld(rv1:OBBMins()), rv1:LocalToWorld(rv1:OBBMaxs()), rv2:LocalToWorld(rv2:OBBMins()), rv2:LocalToWorld(rv2:OBBMaxs())

	if (e1mins.x * 1.08) > (e1maxs.x * 1.08) then v1maxx = (e1mins.x * 1.08) v1minx = (e1maxs.x * 1.08) else v1maxx = (e1maxs.x * 1.08) v1minx = (e1mins.x * 1.08) end
	if (e1mins.y * 1.08) > (e1maxs.y * 1.08) then v1maxy = (e1mins.y * 1.08) v1miny = (e1maxs.y * 1.08) else v1maxy = (e1maxs.y * 1.08) v1miny = (e1mins.y * 1.08) end
	if (e1mins.z * 1.08) > (e1maxs.z * 1.08) then v1maxz = (e1mins.z * 1.08) v1minz = (e1maxs.z * 1.08) else v1maxz = (e1maxs.z * 1.08) v1minz = (e1mins.z * 1.08) end

	if (e2mins.x * 1.08) > (e2maxs.x * 1.08) then v1maxx = (e2mins.x * 1.08) v1minx = (e2maxs.x * 1.08) else v1maxx = (e2maxs.x * 1.08) v1minx = (e2mins.x * 1.08) end
	if (e2mins.y * 1.08) > (e2maxs.y * 1.08) then v1maxy = (e2mins.y * 1.08) v1miny = (e2maxs.y * 1.08) else v1maxy = (e2maxs.y * 1.08) v1miny = (e2mins.y * 1.08) end
	if (e2mins.z * 1.08) > (e2maxs.z * 1.08) then v1maxz = (e2mins.z * 1.08) v1minz = (e2maxs.z * 1.08) else v1maxz = (e2maxs.z * 1.08) v1minz = (e2mins.z * 1.08) end


	if v1maxx > v2minx && v1minx < v2maxx && v1maxy > v2miny && v1miny < v2maxy && v1maxz > v2minz && v1minz < v2maxz then
		return 1
	else return 0 end
end)

e2function number vector:isIn(entity ent)
	if !IsValid(ent) || !this || this == {0,0,0} then return end
	local v1maxx, v1minx, v1maxy, v1miny, v1maxz, v1minz
	local e1mins, e1maxs = ent:LocalToWorld(ent:OBBMins()), ent:LocalToWorld(ent:OBBMaxs())
	
	if e1mins.x > e1maxs.x then v1maxx = e1mins.x v1minx = e1maxs.x else v1maxx = e1maxs.x v1minx = e1mins.x end
	if e1mins.y > e1maxs.y then v1maxy = e1mins.y v1miny = e1maxs.y else v1maxy = e1maxs.y v1miny = e1mins.y end
	if e1mins.z > e1maxs.z then v1maxz = e1mins.z v1minz = e1maxs.z else v1maxz = e1maxs.z v1minz = e1mins.z end
	
	if v1maxx > this[1] && v1minx < this[1] && v1maxy > this[2] && v1miny < this[2] && v1maxz > this[3] && v1minz < this[3] then
		return 1
	else return 0 
	end
end

e2function number vector:isIn(vector tv1, vector tv2)
	if !this || this == {0,0,0} then return end
	local v1maxx, v1minx, v1maxy, v1miny, v1maxz, v1minz
	local e1mins, e1maxs = Vector(tv1[1],tv1[2],tv1[3]), Vector(tv2[1],tv2[2],tv2[3])
	
	if e1mins.x > e1maxs.x then v1maxx = e1mins.x v1minx = e1maxs.x else v1maxx = e1maxs.x v1minx = e1mins.x end
	if e1mins.y > e1maxs.y then v1maxy = e1mins.y v1miny = e1maxs.y else v1maxy = e1maxs.y v1miny = e1mins.y end
	if e1mins.z > e1maxs.z then v1maxz = e1mins.z v1minz = e1maxs.z else v1maxz = e1maxs.z v1minz = e1mins.z end
	
	if v1maxx > this[1] && v1minx < this[1] && v1maxy > this[2] && v1miny < this[2] && v1maxz > this[3] && v1minz < this[3] then
		return 1
	else return 0 
	end
end

registerFunction("isIn", "e:v", "n", function(self,args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
    	if !checkEntity(rv1) || !rv2 then return 0 end
	local v1maxx, v1minx, v1maxy, v1miny, v1maxz, v1minz= 0, 0, 0, 0, 0, 0
	local e1mins, e1maxs = rv1:LocalToWorld(rv1:OBBMins()), rv1:LocalToWorld(rv1:OBBMaxs())

	if e1mins.x > e1maxs.x then v1maxx = e1mins.x v1minx = e1maxs.x else v1maxx = e1maxs.x v1minx = e1mins.x end
	if e1mins.y > e1maxs.y then v1maxy = e1mins.y v1miny = e1maxs.y else v1maxy = e1maxs.y v1miny = e1mins.y end
	if e1mins.z > e1maxs.z then v1maxz = e1mins.z v1minz = e1maxs.z else v1maxz = e1maxs.z v1minz = e1mins.z end

	if v1maxx > rv2[1] && v1minx < rv2[1] && v1maxy > rv2[2] && v1miny < rv2[2] && v1maxz > rv2[3] && v1minz < rv2[3] then
		return 1
	else return 0 end
end)

registerFunction("isIn", "e:vv", "n", function(self,args)
	local op1, op2, op3 = args[2], args[3], args[4]
	local rv1, rv2, rv3 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3)
    	if !checkEntity(rv1) || !rv2 || !rv3 then return 0 end
	local v1maxx, v1minx, v1maxy, v1miny, v1maxz, v1minz, v2maxx, v2minx, v2maxy, v2miny, v2maxz, v2minz = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	local e1mins, e1maxs = rv1:LocalToWorld(rv1:OBBMins()), rv1:LocalToWorld(rv1:OBBMaxs())

	if e1mins.x > e1maxs.x then v1maxx = e1mins.x v1minx = e1maxs.x else v1maxx = e1maxs.x v1minx = e1mins.x end
	if e1mins.y > e1maxs.y then v1maxy = e1mins.y v1miny = e1maxs.y else v1maxy = e1maxs.y v1miny = e1mins.y end
	if e1mins.z > e1maxs.z then v1maxz = e1mins.z v1minz = e1maxs.z else v1maxz = e1maxs.z v1minz = e1mins.z end

	if rv2[1] > rv3[1] then v2maxx = rv2[1] v2minx = rv3[1] else v2maxx = rv3[1] v2minx = rv2[1] end
	if rv2[2] > rv3[2] then v2maxy = rv2[2] v2miny = rv3[2] else v2maxy = rv3[2] v2miny = rv2[2] end
	if rv2[3] > rv3[3] then v2maxz = rv2[3] v2minz = rv3[3] else v2maxz = rv3[3] v2minz = rv2[3] end

	if v1maxx > v2minx && v1minx < v2maxx && v1maxy > v2miny && v1miny < v2maxy && v1maxz > v2minz && v1minz < v2maxz then
		return 1
	else return 0 end
end)

registerFunction("isIn", "vvvv", "n", function(self,args)
    local op1, op2, op3, op4 = args[2], args[3], args[4], args[5]
    local rv1, rv2, rv3, rv4 = op1[1](self,op1), op2[1](self,op2), op3[1](self,op3), op4[1](self,op4)
	if !rv1 || !rv2 || !rv3 || !rv4 then return 0 end
	local v1maxx, v1minx, v1maxy, v1miny, v1maxz, v1minz, v2maxx, v2minx, v2maxy, v2miny, v2maxz, v2minz = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

	if rv1[1] > rv2[1] then v1maxx = rv1[1] v1minx = rv2[1] else v1maxx = rv2[1] v1minx = rv1[1] end
	if rv1[2] > rv2[2] then v1maxy = rv1[2] v1miny = rv2[2] else v1maxy = rv2[2] v1miny = rv1[2] end
	if rv1[3] > rv2[3] then v1maxz = rv1[3] v1minz = rv2[3] else v1maxz = rv2[3] v1minz = rv1[3] end

	if rv3[1] > rv4[1] then v2maxx = rv3[1] v2minx = rv4[1] else v2maxx = rv4[1] v2minx = rv3[1] end
	if rv3[2] > rv4[2] then v2maxy = rv3[2] v2miny = rv4[2] else v2maxy = rv4[2] v2miny = rv3[2] end
	if rv3[3] > rv4[3] then v2maxz = rv3[3] v2minz = rv4[3] else v2maxz = rv4[3] v2minz = rv3[3] end

	if v1maxx > v2minx && v1minx < v2maxx && v1maxy > v2miny && v1miny < v2maxy && v1maxz > v2minz && v1minz < v2maxz then
		return 1
	else return 0 end
end)*/

e2function number entity:timeConnected()
	if not IsValid(this) then return 0 end
	if(this:IsPlayer()) then return this:TimeConnected() else return 0 end
end

e2function entity grenadeSpawn(string kind)
	local ent = ents.Create("nebcorp_grenade_ent")
	ent.Kind = kind -- Set its type
	
	ent:SetPos( self.entity:GetPos() + Vector(0,0,100) )
	ent:SetAngles(Angle( math.Rand(-180, 180), math.Rand(-180, 180), math.Rand(-180, 180) ))
	ent:SetPlayer(self.player)
	ent.Owner = self.player
	ent:Spawn()
	ent:EmitSound(Sound("grenade_"..math.random(1,7)..".mp3"))
	
	local phys = ent:GetPhysicsObject()
	phys:AddAngleVelocity(Vector(math.random(-500,500),math.random(-500,500),math.random(-500,500)))
	return ent
end

--
-- Deprecated sheet
--
e2function void entity:setNoDraw(number DEPRECATED)
	self.player:ChatPrint("[DeprecationWarn] setNoDraw -> propDraw (official)")
	this:SetNoDraw( DEPRECATED ~= 0 )
end
e2function number entity:validPhysics()
	self.player:ChatPrint("[DeprecationWarn] validPhysics -> isValidPhysics (official)")
	return E2Lib.validPhysics(this) and 1 or 0
end
e2function void runOnKeys(entity DEPRECATED)
	self.player:ChatPrint("[DeprecationERROR] runOnKeys(e) -> runOnKeys(e,n) (official)")
end
e2function void entity:reangle(angle DEPRECATED)
	self.player:ChatPrint("[DeprecationWarn] reangle -> isValidPhysics (official)")
	if not IsValid(this) or not validPhysics(this) then return end
	if not NADMOD.PlayerCanTouch(self.player, this) then return end
	local phys = this:GetPhysicsObject()
	phys:SetAngles( Angle(DEPRECATED[1], DEPRECATED[2], DEPRECATED[3]) )
	phys:Wake()
	if !phys:IsMoveable() then
		phys:EnableMotion(true)
		phys:EnableMotion(false)
	end
end

__e2setcost(nil)
