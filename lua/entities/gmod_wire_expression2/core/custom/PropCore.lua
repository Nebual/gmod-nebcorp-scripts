__e2setcost(20)

e2function entity propSpawn(string model, vector pos)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	return PropCore.CreateProp(self,model,Vector(pos[1],pos[2],pos[3]),self.entity:GetAngles(),1)
end

e2function entity propSpawn(string model, vector pos, angle rot)
	if not PropCore.ValidAction(self, nil, "spawn") then return nil end
	return PropCore.CreateProp(self,model,Vector(pos[1],pos[2],pos[3]),Angle(rot[1],rot[2],rot[3]),1)
end

NDesc["collisionSpawn(vv)"] = "Spawns an entity with the collision box v, at position v2"
e2function entity collisionSpawn(vector size, vector pos)
	local ent = ents.Create("nebcorp_phys")
	ent.size = Vector(size[1],size[2],size[3])
	ent:SetPos(Vector(pos[1],pos[2],pos[3]))
	ent:Spawn()
	self.player:AddCleanup( "props", ent )
	undo.Create("E2 Spawned Collision Prop") //e2_spawned_collision
		undo.AddEntity( ent )
		undo.SetPlayer( self.player )
	undo.Finish()
	return ent
end
e2function entity collisionSpawnSphere(radius, vector pos)
	local ent = ents.Create("nebcorp_phys")
	ent.radius = radius
	ent:SetPos(Vector(pos[1],pos[2],pos[3]))
	ent:Spawn()
	self.player:AddCleanup( "props", ent )
	undo.Create("E2 Spawned Collision Prop") //e2_spawned_collision
		undo.AddEntity( ent )
		undo.SetPlayer( self.player )
	undo.Finish()
	return ent
end
local function collisionSpawnPlanet(self,radius,pos,mDiscMat,mSphereDualMat,mSphereMat,mSphere2Mat)
	local ent = ents.Create("nebcorp_phys")
	ent:SetNWBool("planet",true)
	//ent:SetNWString("mDiscMat",mDiscMat)
	ent:SetNWString("mDiskMat",mDiskMat)
	ent:SetNWString("mSphereMat",mSphereMat)
	ent:SetNWString("mSphere2Mat",mSphere2Mat)
	ent:SetNWString("mSphereDualMat",mSphereDualMat)
	ent.radius = radius
	ent:SetPos(pos)
	ent:Spawn()
	self.player:AddCleanup( "props", ent )
	undo.Create("E2 Spawned Collision Prop") //e2_spawned_collision
		undo.AddEntity( ent )
		undo.SetPlayer( self.player )
	undo.Finish()
	return ent
end
util.AddNetworkString("NCPhys_Vars")
e2function entity collisionSpawnPlanet(radius, vector pos) return collisionSpawnPlanet(self,radius,Vector(pos[1],pos[2],pos[3])) end
e2function entity collisionSpawnPlanet(radius, vector pos,string mDiscMat,string mSphereDualMat, string mSphereMat, string mSphere2Mat) return collisionSpawnPlanet(self,radius,Vector(pos[1],pos[2],pos[3]), mDiscMat,mSphereDualMat,mSphereMat,mSphere2Mat) end
e2function void entity:updatePlanet(table tab) net.Start("NCPhys_Vars") net.WriteEntity(this) net.WriteTable(tab.s) net.Broadcast() end
//Functions are in entities/nebcorp_holo/init.lua
__e2setcost(40)
e2function string holoCompile(entity baseprop, array entities) return util.TableToJSON(holoCompile(baseprop, entities)) end
e2function entity holoPaste(string holodata, vector pos) return holoSpawn(util.JSONToTable(holodata), Vector(pos[1],pos[2],pos[3]),self.player) end

__e2setcost(10)

e2function void propSpawnPersist(number DEPRECATED)
	self.player:ChatPrint("[DeprecationWarn] propSpawnPersist -> propSpawnUndo (official)")
	self.data.propSpawnUndo = DEPRECATED ~= 0
end

--- Teleports all entities in <this> to <pos>
e2function string array:reposition(vector pos)
	self.player:ChatPrint("[DeprecationWarn] R:reposition -> e:setPos (official)")
	if !this then return "No array!" end
	local v = Vector(pos[1], pos[2], pos[3])
	local _, ent = next(this)
	local v2 = ent:WorldToLocal(v)
	for _,v in ipairs(this) do
		if IsValid(v) then
			local vec = ent:LocalToWorld(ent:WorldToLocal(v:GetPos()) + v2)
			local phys = v:GetPhysicsObject()
			if v:IsPlayer() || v:IsNPC() then
				if util.IsInWorld(vec) then v:SetPos(vec) end
			elseif !IsValid(phys) then v:SetPos(vec)
			else
				phys:SetPos(vec)
				phys:Wake()
				if !phys:IsMoveable() then
					phys:EnableMotion(true)
					phys:EnableMotion(false)
				end
			end
		end
	end
end

--- Teleports <this> to <pos> *differently*
e2function string entity:reposition2(vector pos)
	local ent = IsValid(this) and this
	local vec = Vector(pos[1], pos[2], pos[3])
	if !util.IsInWorld( vec ) then return "Thats outside the world!" end
	if ent && (ent:IsPlayer() || ent:IsNPC()) then
		ent:SetPos( vec )
	elseif ent && validPhysics(ent) then
		local phys = ent:GetPhysicsObject()
		phys:SetPos( Vector(pos[1], pos[2], pos[3]) )
		phys:Wake()
		if !phys:IsMoveable() then
			phys:EnableMotion(true)
			phys:EnableMotion(false)
		end
	else return "Ent is invalid or has invalid physics. Try forceReposition if you dare"
	end
end

--- Ignores validity checking
e2function void entity:forceReposition(vector pos)
	if !this then return end
	local phys = this:GetPhysicsObject()
	phys:SetPos( Vector(pos[1], pos[2], pos[3]) )
	phys:Wake()
	if !phys:IsMoveable() then
		phys:EnableMotion(true)
		phys:EnableMotion(false)
	end
end

--- Ignores validity checking
e2function void entity:forceReangle(angle ang)
	if !this then return end
	local phys = this:GetPhysicsObject()
	phys:SetAngles( Angle(ang[1], ang[2], ang[3]) )
	phys:Wake()
	if !phys:IsMoveable() then
		phys:EnableMotion(true)
		phys:EnableMotion(false)
	end
end

e2function void entity:setPosL(vector pos)
	if not IsValid(this) or not this:GetParent() then return end
	this:SetLocalPos(Vector(pos[1], pos[2], pos[3]))
end

e2function void entity:setAngL(angle ang)
	if not IsValid(this) or not this:GetParent() then return end
	this:SetLocalAngles(Angle(ang[1], ang[2], ang[3]))
end

--- Disregards validity checking
e2function void entity:forceParentTo(entity father)
	if this && father then this:SetParent( father ) end
end

--- Makes <this> ownerless, according to SimplePropProtection
e2function void entity:setOwnerless()
	local ent = IsValid(this) and this
	if ent then ent:CPPISetOwnerless( true ) end
end

//		---------------------------------------------------		USE SUPPORT
local InUseBy = nil
local InUseEnt = NULL
 
/*registerCallback("construct", function(self)
	self.entity:SetUseType( SIMPLE_USE )
end)*/

--- Makes the chip "Use"able. Only needs to be called once
e2function void hookUse(value)
	if value != 0 then
		self.entity:SetUseType( SIMPLE_USE )
		self.entity.Use = function(self,activator)
			InUseBy = activator
			InUseEnt = self
			self:Execute()
			InUseEnt = NULL
			InUseBy = nil
		end
	else 
		self.entity.Use = nil
	end
end

--- Returns the entity who is using the chip
e2function entity inUseBy()
	return InUseBy
end

--- Returns 1 if the chip was executed by being used
e2function number inUse()
	return InUseBy and 1 or 0
end


-- only works on ents, not prop_physics
--- Makes the chip "Use"able. Only needs to be called once
e2function void entity:hookUse(value)
	if !IsValid(this) then return end
	if value != 0 then
		local e2 = self
		this:SetUseType( SIMPLE_USE )
		if !this.OldUse then
			this.OldUse = this.Use
		end
		this.Use = function(prop,activator, c, d, e)
			prop:OldUse(activator, c, d, e)
			if e2 and IsValid(e2.entity) then
				InUseBy = activator
				InUseEnt = prop
				e2.entity:Execute()
				InUseEnt = NULL
				InUseBy = nil
			end
		end
	else
		if this.OldUse then
			this.Use = this.OldUse
		end
		this.OldUse = nil
	end
end

--- Returns the entity being used
e2function entity inUseEnt()
	return InUseEnt
end

/*
----------------------------------------------------------------- Custom Class Ent ---------------------------------------------------------------------------
*/
__e2setcost(20)
local function MakeClassProp( ply, Class, Pos, Ang, model )
	
	local Prop = ents.Create( Class )
	if !Prop || !Prop:IsValid() then return end -- Class failed
	Prop:SetPos(Pos)
	Prop:SetAngles(Ang)
	if model && model != "" then Prop:SetModel(model) end
	if Class == "base_gmodentity" then Prop:PhysicsInit( SOLID_VPHYSICS ) end
	Prop:Spawn()

	// Tell the gamemode we just spawned something
	gamemode.Call( "PlayerSpawnedProp", ply, model, Prop )
	return Prop
end

local function createclasspropsfromE2(self,model,class,pos,angles)
	if not PropCore.ValidSpawn(self.player, model, false) then return NULL end
	class = string.lower(class)
	if string.Left(class or "", 4) == "info" then WireLib.ClientError("You tried to make an info-class'd entity! This crashes the server!", self.player) return nil end
	prop = MakeClassProp( self.player, class, pos, angles, model )
	if !prop then WireLib.ClientError("You tried to make an invalid class'd entity! :O", self.player) return nil end
	prop:Activate()
	if validPhysics(prop) then prop:GetPhysicsObject():Wake() end
	
	self.player:AddCleanup( "props", prop )
	if self.data.propSpawnUndo then
		undo.Create("e2_spawned_prop")
			undo.AddEntity( prop )
			undo.SetPlayer( self.player )
		undo.Finish()
	end
	prop:CallOnRemove( "wire_expression2_propcore_remove",
		function( prop )
			self.data.spawnedProps[ prop ] = nil
			E2totalspawnedprops = E2totalspawnedprops - 1
		end
	)
	self.data.spawnedProps[ prop ] = self.data.propSpawnUndo
	
	E2totalspawnedprops = E2totalspawnedprops+1
	E2tempSpawnedProps = E2tempSpawnedProps+1
	return prop
end

--- Spawns an entity with class <class> ontop of the E2
e2function entity entitySpawn(string class)
	return createclasspropsfromE2(self,"",class,self.entity:GetPos()+self.entity:GetUp()*25,self.entity:GetAngles())
end

--- Spawns an entity with class <class>, model <model>, at <pos>
e2function entity entitySpawn(string class, vector pos)
	return createclasspropsfromE2(self, "", class, Vector(pos[1],pos[2],pos[3]), self.entity:GetAngles())
end

--- Spawns an entity with class <class> at <pos> and <ang>
e2function entity entitySpawn(string class, vector pos, angle ang)
	return createclasspropsfromE2(self, "", class, Vector(pos[1],pos[2],pos[3]), Angle(ang[1],ang[2],ang[3]))
end

--- Spawns an entity with class <class>, model <model>
e2function entity entitySpawn(string class, string model)
	return createclasspropsfromE2(self, model, class, self.entity:GetPos()+self.entity:GetUp()*25,self.entity:GetAngles())
end

--- Spawns an entity with class <class>, model <model>, at <pos>
e2function entity entitySpawn(string class, string model, vector pos)
	return createclasspropsfromE2(self, model, class, Vector(pos[1],pos[2],pos[3]), self.entity:GetAngles())
end

--- Spawns an entity with class <class>, model <model>, at <pos> and <ang>
e2function entity entitySpawn(string class, string model, vector pos, angle ang)
	return createclasspropsfromE2(self, model, class, Vector(pos[1],pos[2],pos[3]), Angle(ang[1],ang[2],ang[3]))
end
/*
----------------------------------------------------------------- Effects Ent ---------------------------------------------------------------------------
*/

local function createeffect(self,name,start,origin,entity,vnormal,radius,scale,magnitude)
	
	local effectdata = EffectData()
	if start && start != Vector(0,0,0) 		then effectdata:SetStart( start ) end
	if origin && origin != Vector(0,0,0) 	then effectdata:SetOrigin( origin ) end
	if entity && entity:IsValid() 			then effectdata:SetEntity( entity ) end
	if radius && radius != 0 				then effectdata:SetRadius( radius ) end
	if vnormal && vnormal != Vector(0,0,0) 	then effectdata:SetNormal( vnormal ) end
	if scale && scale != 0 					then effectdata:SetScale( scale ) end
	if magnitude && magnitude != 0 			then effectdata:SetMagnitude( magnitude ) end
	util.Effect( name, effectdata )
end

--- Test Splash
e2function void effectSplash(vector pos, size)
	local effectdata = EffectData()
		effectdata:SetOrigin( Vector(pos[1],pos[2],pos[3]) )
		effectdata:SetNormal( Vector(0,0,1) )
		effectdata:SetRadius( size )
		effectdata:SetScale( size )
	util.Effect( "watersplash", effectdata )
end

--- Spawns an effect <name> at location <pos> probably.
e2function void effectSpawn(string name, vector pos)
	return createeffect(self, name, Vector(pos[1],pos[2],pos[3]), Vector(0,0,0), self.entity, Vector(0,0,0), 1, 1, 1)
end

--- Spawns an effect <name> at location <pos>, with the destination <dest> probably.
e2function void effectSpawn(string name, vector pos, vector dest)
	return createeffect(self, name, Vector(pos[1],pos[2],pos[3]), Vector(dest[1],dest[2],dest[3]), self.entity, Vector(0,0,0), 1, 1, 1)
end

--- Spawns an effect <name> at location <pos>, with the destination <dest>, attached to <ent> probably.
e2function void effectSpawn(string name, vector pos, vector dest, entity ent)
	return createeffect(self, name, Vector(pos[1],pos[2],pos[3]), Vector(dest[1],dest[2],dest[3]), ent, Vector(0,0,0), 1, 1, 1)
end

--- Spawns an effect <name> at location <pos>, with the destination <dest>, attached to <ent>, at an angle of <vnormal>, with <radius> radius, <scale> scale, and <magnitude> magnitude, probably.
e2function void effectSpawn(string name, vector pos, vector dest, entity ent, vector vnormal, radius, scale, magnitude)
	return createeffect(self, name, Vector(pos[1],pos[2],pos[3]), Vector(dest[1],dest[2],dest[3]), ent, Vector(vnormal[1],vnormal[2],vnormal[3]), radius, scale, magnitude)
end


/* NPC Spawning */
local function InternalSpawnNPC(self, variant, pos, ang, customspawnflags )
	local NPCData = list.Get( "NPC" )[variant]
	
	-- Don't let them spawn this entity if it isn't in our NPC Spawn list.
	-- We don't want them spawning any entity they like!
	if ( !NPCData ) then return end
	
	local bDropToFloor = !NPCData.OnCeiling
	local Normal = Vector(0,0,1)
	if NPCData.OnCeiling then Normal = Vector(0,0,-1) end
	-- This NPC has to be spawned on a ceiling ( Barnacle )
	//if ( NPCData.OnCeiling && Vector( 0, 0, -1 ):Dot( Normal ) < 0.95 ) then return end

	-- This NPC has to be spawned on a floor ( Turrets )
	//if ( NPCData.OnFloor && Vector( 0, 0, 1 ):Dot( Normal ) < 0.95 ) then return end
	if ( NPCData.NoDrop ) then bDropToFloor = false end
	
	
	local NPC = ents.Create( NPCData.Class )
	if ( !IsValid( NPC ) ) then return end

	NPC:SetPos( pos + Normal * (NPCData.Offset or 32) )
	
	if !ang then ang = Angle() end
	if ( NPCData.Rotate ) then ang = ang + NPCData.Rotate end
	NPC:SetAngles( ang )
	
	--
	-- This NPC has a special model we want to define
	--
	if ( NPCData.Model ) then NPC:SetModel( NPCData.Model ) end
	
	-- Spawn Flags
	local SpawnFlags = bit.bor(SF_NPC_FADE_CORPSE, SF_NPC_ALWAYSTHINK)
	if ( NPCData.SpawnFlags ) then SpawnFlags = bit.bor(SpawnFlags, NPCData.SpawnFlags) end
	if customspawnflags then Spawnflags = bit.bor(SpawnFlags, customspawnflags) end
	if ( NPCData.TotalSpawnFlags ) then SpawnFlags = NPCData.TotalSpawnFlags end
	NPC:SetKeyValue( "spawnflags", SpawnFlags )
	
	--
	-- Optional Key Values
	--
	if ( NPCData.KeyValues ) then
		for k, v in pairs( NPCData.KeyValues ) do
			NPC:SetKeyValue( k, v )
		end		
	end
	if ( NPCData.Skin ) then NPC:SetSkin( NPCData.Skin ) end
	
	/*if ( Equipment ) then
		NPC:SetKeyValue( "additionalequipment", Equipment )
		NPC.Equipment = Equipment 
	end*/
	
	DoPropSpawnedEffect( NPC )
	NPC:Spawn()
	NPC:Activate()
	
	if NPCData.Weapons then
		for k,v in pairs(NPCData.Weapons) do
			local weapon = NPC:GetActiveWeapon()
			if (weapon:IsValid()) then
				if (weapon:GetClass() == "weapon_" .. rv2) then continue end
				weapon:Remove()
			end

			NPC:Give( "ai_" .. v )
		end
	end
	
	if ( bDropToFloor && !NPCData.OnCeiling ) then NPC:DropToFloor() end


	gamemode.Call("PlayerSpawnedNPC", self.player, NPC)
	self.player:AddCleanup("npcs", NPC)
	if self.data.propSpawnUndo then
		undo.Create("NPC")
			undo.AddEntity(NPC)
			undo.SetPlayer(self.player)
		undo.Finish("NPC (" .. tostring(variant) .. ")")
	end
	NPC:CallOnRemove("wire_expression2_propcore_remove", function(NPC)
		self.data.spawnedProps[ NPC ] = nil
		E2totalspawnedprops = E2totalspawnedprops - 1
	end)
	self.data.spawnedProps[ NPC ] = self.data.propSpawnUndo

	E2totalspawnedprops = E2totalspawnedprops+1
	E2tempSpawnedProps = E2tempSpawnedProps+1
	
	return NPC
end
e2function entity npcSpawn(string variant, vector pos)//, angle ang, customspawnflags
	return InternalSpawnNPC(self, variant,Vector(pos[1],pos[2],pos[3]))
end
e2function entity npcSpawn(string variant, vector pos, angle ang)
	return InternalSpawnNPC(self, variant,Vector(pos[1],pos[2],pos[3]),Angle(ang[1],ang[2],ang[3]))
end
e2function entity npcSpawn(string variant, vector pos, angle ang, customspawnflags)
	return InternalSpawnNPC(self, variant,Vector(pos[1],pos[2],pos[3]),Angle(ang[1],ang[2],ang[3]), customspawnflags)
end
e2function array npcSpawnables()
	local ret = {}
	for k,v in pairs(list.Get("NPC")) do table.insert(ret,k) end
	return ret
end


e2function void entity:setOverlayText(string str) this:SetOverlayText(str) end
