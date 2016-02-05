TOOL.Category		= "Construction"
TOOL.Name			= "#tool.weldgroup_enabler.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if CLIENT then
	language.Add( "tool.weldgroup_enabler.name", "Weldgroups Enabler" )
	language.Add( "tool.weldgroup_enabler.desc", "Disables collisions between entities of a contraption." )
	language.Add( "tool.weldgroup_enabler.0", "Click on a contraption to disable inter-contraption collisions. Right click to disable weldgroups on a single prop. Reload to disable weldgroups on a contraption." )
end

function TOOL:LeftClick( trace )
	if not IsValid(trace.Entity) or trace.Entity:IsPlayer() then return end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then
		return true 
	end
	
	RefreshWeldGroup(constraint.GetAllConstrainedEntities(trace.Entity))
	for k,v in pairs(constraint.GetAllConstrainedEntities(trace.Entity)) do 
		v:SetCustomCollisionCheck(true)
		duplicator.StoreEntityModifier(v,"SetCustomCollisionCheck",{})
	end
		
	return true
end

if SERVER then
	duplicator.RegisterEntityModifier( "SetCustomCollisionCheck", function(ply, ent, data) 
		ent:SetCustomCollisionCheck(true)
	end)
end

function TOOL:RightClick( trace )
	if not IsValid(trace.Entity) or trace.Entity:IsPlayer() then return end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then
		return true 
	end
	
	trace.Entity:SetCustomCollisionCheck(false)
	
	return true
end

function TOOL:Reload( trace )
	if not IsValid(trace.Entity) or trace.Entity:IsPlayer() then return end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	if (CLIENT) then
		return true 
	end
	
	for k,v in pairs(constraint.GetAllConstrainedEntities(trace.Entity)) do 
		v:SetCustomCollisionCheck(false)
		duplicator.ClearEntityModifier(v, "SetCustomCollisionCheck")
	end
		
	return true
end

function TOOL.BuildCPanel( CPanel )
end
