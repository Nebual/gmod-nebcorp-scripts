TOOL.Category		= "Constraints"
TOOL.Name			= "#tool.ropedetail.name"
TOOL.Command		= nil
TOOL.ConfigName		= nil

TOOL.ClientConVar[ "addlength" ] = "0"
TOOL.ClientConVar[ "material" ] = "cable/rope"
TOOL.ClientConVar[ "width" ] = "2"
TOOL.ClientConVar[ "rigid" ] = "0"
TOOL.ClientConVar[ "hasphysics" ] = "1"

if CLIENT then
	language.Add( "tool.ropedetail.name", "Rope - Detail" )
	language.Add( "tool.ropedetail.desc", "Makes ropes without physics, just visual" )
	language.Add( "tool.ropedetail.0", "Left click the first point for the rope." )
	language.Add( "tool.ropedetail.1", "Left click the second point for the rope." )
end

function TOOL:LeftClick( trace )
	if ( trace.Entity:IsValid() && trace.Entity:IsPlayer() ) then return end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	local iNum = self:NumObjects()

	local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
	self:SetObject( iNum + 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )

	if ( iNum > 0 ) then
	
		if ( CLIENT ) then
		
			self:ClearObjects()
			return true
			
		end
		
		// Get client's CVars
		local addlength	 = self:GetClientNumber( "addlength" )
		local material 	 = self:GetClientInfo( "material" )
		local width 	 = self:GetClientNumber( "width" ) 
		local rigid	 	= self:GetClientNumber( "rigid" ) == 1
		
		// Get information we're about to use
		local Ent1,  Ent2  = self:GetEnt(1),	 self:GetEnt(2)
		local Bone1, Bone2 = self:GetBone(1),	 self:GetBone(2)
		local WPos1, WPos2 = self:GetPos(1),	 self:GetPos(2)
		local LPos1, LPos2 = self:GetLocalPos(1),self:GetLocalPos(2)
		local length = ( WPos1 - WPos2):Length()

		length = length + addlength - (WPos1-WPos2):Length()
		
		local kv = { 
			Slack 		= length, 
			Collide 	= 1
		}
		if ( rigid ) then kv.Type = 2 end
		
		local rope = constraint.CreateKeyframeRope( WPos1, width, material, nil, Ent1, LPos1, Bone1, Ent2, LPos2, Bone2, kv )
		if ( IsValid( rope ) ) then
			rope:SetTable({
				Type 		= "Rope",
				Ent1 		= Ent1,		Ent2 		= Ent2,
				Bone1 		= Bone1,	Bone2 		= Bone2,
				LPos1 		= LPos1,	LPos2 		= LPos2,
				length 		= (WPos1 - WPos2):Length(),
				addlength 	= addlength,
				forcelimit 	= forcelimit,
				width 		= width,
				material 	= material,
				rigid		= rigid
			})
			constraint.AddConstraintTable( Ent1, rope, Ent2 )
		end

		self:ClearObjects()
		
		undo.Create("Rope")
		undo.AddEntity( rope )
		undo.SetPlayer( self:GetOwner() )
		undo.Finish()
	
		self:GetOwner():AddCleanup( "ropeconstraints", rope )
	else
		self:SetStage( iNum+1 )
	end

	return true
end

function TOOL:RightClick( trace )
	self:LeftClick(trace)
	local iNum = self:NumObjects()
	self:SetObject( iNum + 1, trace.Entity, trace.HitPos, trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone ), trace.PhysicsBone, trace.HitNormal )
	self:SetStage( iNum+1 )
end
function TOOL.BuildCPanel( panel )
	panel:AddControl( "Slider", {Label = "#RopeTool_addlength", Description = "RopeTool_addlength_desc", Type = "Float", Min = "-1000",Max="1000",Command="ropedetail_addlength"})
	panel:AddControl( "Slider", {Label = "#RopeTool_ropewidth", Type = "Float", Min = "0.25",Max="20",Command="ropedetail_width"})
	panel:AddControl( "RopeMaterial", {Label = "#RopeTool_material", ConVar="ropedetail_material"})
	panel:AddControl( "CheckBox", { Label = "#RopeTool_rigid", Description = "#RopeTool_rigid_desc", Command = "ropedetail_rigid" }  )
end