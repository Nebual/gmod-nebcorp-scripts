TOOL.Category		= "Construction"
TOOL.Name			= "#tool.nocollide2.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "type" ] = "0"

cleanup.Register( "nocollide" )


if CLIENT then
	language.Add( "tool.nocollide2.name", "No Collide (Adv)" )
	language.Add( "tool.nocollide2.desc", "Ignores collisions between two entities" )
	language.Add( "tool.nocollide2.0", "Click on 2 objects to make them not collide or right click to toggle various collisions" )
	language.Add( "tool.nocollide2.1", "Now click on something else" )
	/*timer.Create("RemoveNocollideTool",0,1,function()
		local toollist = g_SpawnMenu.ToolMenu.ToolPanels[1].List:GetItems()[2].Contents
		for k,v in pairs(toollist:GetItems()) do if v.Name == 'nocollide' then toollist:RemoveItem(v) break end end
	end)*/
end

function TOOL:LeftClick( trace )

	if (!trace.Entity ) then return end
	if (!trace.Entity:IsValid()) then return end
	if (trace.Entity:IsPlayer()) then return end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	local iNum = self:NumObjects()
	
	local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
	self:SetObject( iNum + 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )
	
	if (CLIENT) then
	
		if ( iNum > 0 ) then
			self:ClearObjects()
		end
		
		return true 
		
	end
	
	if ( iNum > 0 ) then
		
		local Ent1,  Ent2  = self:GetEnt(1),	self:GetEnt(2)
		local Bone1, Bone2 = self:GetBone(1),	self:GetBone(2)

		local constraint = constraint.NoCollide(Ent1, Ent2, Bone1, Bone2)
	
		undo.Create("NoCollide")
		undo.AddEntity( constraint )
		undo.SetPlayer( self:GetOwner() )
		undo.Finish()
		
		self:GetOwner():AddCleanup( "nocollide", constraint )
		
		self:ClearObjects()
	
	else
		
		self:SetStage( iNum+1 )
	
	end
		
	return true
	
end

if SERVER then 
	//duplicator.RegisterEntityModifier( "CollisionGroup", function(ply, ent, data) ent:SetCollisionGroup( data.t or COLLISION_GROUP_WORLD ) end)
	duplicator.RegisterEntityModifier( "DisableCollisions", function(ply, ent, data) ent:GetPhysicsObject():EnableCollisions(false) end)
end

function TOOL:RightClick( trace )
	local ent = trace.Entity
	if !IsValid(ent) || ent:IsPlayer() || ent:IsNPC() then return end
	if ( CLIENT ) then return true end
	
	local nctype = self:GetClientNumber( "type" )
	if nctype == 0 then
		if ( ent:GetCollisionGroup() == COLLISION_GROUP_WORLD ) then
			ent:SetCollisionGroup( COLLISION_GROUP_NONE )
			//duplicator.ClearEntityModifier(ent,"CollisionGroup")
		else
			ent:SetCollisionGroup( COLLISION_GROUP_WORLD )
			//duplicator.StoreEntityModifier(ent,"CollisionGroup",{t=COLLISION_GROUP_WORLD})
		end
	elseif nctype == 1 then
		if IsValid(ent:GetPhysicsObject()) then
			if ent:GetPhysicsObject():IsCollisionEnabled() then
				ent:GetPhysicsObject():EnableCollisions(false)
				duplicator.StoreEntityModifier(ent,"DisableCollisions",{})
			else
				ent:GetPhysicsObject():EnableCollisions(true)
				duplicator.ClearEntityModifier(ent,"DisableCollisions")
			end
		end
	elseif nctype == 2 then
		if ( ent:GetCollisionGroup() == COLLISION_GROUP_WEAPON ) then
			ent:SetCollisionGroup( COLLISION_GROUP_NONE )
			//duplicator.ClearEntityModifier(ent,"CollisionGroup")
		else
			ent:SetCollisionGroup( COLLISION_GROUP_WEAPON )
			//duplicator.StoreEntityModifier(ent,"CollisionGroup",{t=COLLISION_GROUP_WEAPON})
		end
	elseif nctype == 3 then
		if IsValid(ent:GetPhysicsObject()) then
			if !ent:GetPhysicsObject():IsCollisionEnabled() && ent:GetCollisionGroup() == COLLISION_GROUP_WEAPON then
				ent:SetCollisionGroup( COLLISION_GROUP_NONE )
				ent:GetPhysicsObject():EnableCollisions(true)
				//duplicator.ClearEntityModifier(ent,"CollisionGroup")
				duplicator.ClearEntityModifier(ent,"DisableCollisions")
			else
				ent:SetCollisionGroup( COLLISION_GROUP_WEAPON )
				ent:GetPhysicsObject():EnableCollisions(false)
				//duplicator.StoreEntityModifier(ent,"CollisionGroup",{t=COLLISION_GROUP_WEAPON})
				duplicator.StoreEntityModifier(ent,"DisableCollisions",{})
			end
		end
	end
	return true
end

function TOOL:Reload( trace )
	if (!trace.Entity:IsValid() || trace.Entity:IsPlayer() ) then return false end
	if ( CLIENT ) then return true end
	
	local  bool = constraint.RemoveConstraints( trace.Entity, "NoCollide" )
	return bool
end

function TOOL.BuildCPanel( CPanel )
	CPanel:Help( "Right Click Style:" )
	local ctrl = vgui.Create( "CtrlListBox", CPanel )
	ctrl:AddOption("Disable prop/player collisions", {nocollide2_type = 0})
	ctrl:AddOption("Disable prop/world collisions", {nocollide2_type = 1})
	ctrl:AddOption("Disable player collisions", {nocollide2_type = 2})
	ctrl:AddOption("Disable prop/world/player collisions", {nocollide2_type = 3})
	ctrl:SetText( ctrl:GetOptionText(GetConVarNumber("nocollide2_type") or 0) or "" )
	CPanel:AddPanel( ctrl )
end
