
TOOL.Category = "Constraints"
TOOL.Name = "#tool.slider2.name"

if CLIENT then
	language.Add( "tool.slider2.name", "Slider 2 - Offset Axis" )
	language.Add( "tool.slider2.desc", "Creates a slider based on offset axises" )
	language.Add( "tool.slider2.0", "Click on the child object." )
	language.Add( "tool.slider2.1", "Now click on the base object." )
	language.Add( "tool.slider2.2", "Now select a direction of movement (hitnormal)." )
	language.Add( "tool.slider2.3", "Now select an offset direction (hitnormal)." )
	language.Add( "tool.slider.offsetsize", "Slider Offset Size" )
	language.Add( "tool.slider.offsetsize.help", "Smaller means more stable, but more significant path curve" )
end

TOOL.ClientConVar[ "width" ] = "1.5"
TOOL.ClientConVar[ "material" ] = "cable/cable"
TOOL.ClientConVar[ "hingefriction" ] = 0
TOOL.ClientConVar[ "nocollide" ] = 0
TOOL.ClientConVar[ "offsetsize" ] = 2500

function TOOL:LeftClick( trace )

	if ( IsValid( trace.Entity ) && trace.Entity:IsPlayer() ) then return end
	
	-- If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	
	local iNum = self:NumObjects()

	local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
	self:SetObject( iNum + 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )
	self:SetOperation( 1 )
	
	if ( iNum > 1 ) then
		
		if iNum == 2 and self:GetOwner():KeyDown(IN_SPEED) then
			self:SetStage( iNum + 1 )
			return true
		end

		if ( CLIENT ) then
			self:ClearObjects()
			return true
		end
		
		-- Get client's CVars
		local width = self:GetClientNumber( "width", 1.5 )
		local material = self:GetClientInfo( "material" )
		local friction = self:GetClientNumber( "hingefriction", 0 )
		local nocollide = self:GetClientNumber( "nocollide", 0 )
		local offsetsize = self:GetClientNumber( "offsetsize", 2500 )
		
		-- Get information we're about to use
		local Ent1, Ent2 = self:GetEnt( 1 ), self:GetEnt( 2 )
		local Bone1, Bone2 = self:GetBone( 1 ), self:GetBone( 2 )
		local Norm1, Norm2 = self:GetNormal( 1 ), self:GetNormal( 2 )
		local LPos1, LPos2 = self:GetLocalPos( 1 ), self:GetLocalPos( 2 )
		local WPos1, WPos2 = self:GetPos( 1 ), self:GetPos( 2 )
		local Phys1, Phys2 = self:GetPhys( 1 ), self:GetPhys( 2 )
		
		local offset1= ((self:NumObjects() == 3) and (self:GetNormal( 3 ):Angle():Right()) or (self:GetNormal( 4 )))
		local offset2 = self:GetNormal( 3 ):Cross(offset1)
		LPos1 = Phys1:WorldToLocal( WPos2 + offset1*offsetsize + offset2 )
		LPos2 = Phys2:WorldToLocal( WPos2 + offset1*offsetsize )
		//E1=welded(),E2=owner():aimEntity(),axis(E2,E2:toLocal(E1:pos()+vec(0,1,20000)),E1,E1:toLocal(E1:pos()+vec(0,0,20000)))

		local axis = constraint.Axis( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, 0, 0, friction, nocollide )
		local rope = constraint.CreateKeyframeRope( WPos1, width, material, axis, Ent1, self:GetLocalPos( 1 ), Bone1, Ent2, self:GetLocalPos( 2 ), Bone2, {Collide = 0, Type = 2, Subdiv = 1,} )

		undo.Create( "Slider" )
			undo.AddEntity( axis )
			if ( IsValid( rope ) ) then undo.AddEntity( rope ) end
			undo.SetPlayer( self:GetOwner() )
		undo.Finish()
		
		self:GetOwner():AddCleanup( "ropeconstraints", axis )
		self:GetOwner():AddCleanup( "ropeconstraints", rope )

		-- Clear the objects so we're ready to go again
		self:ClearObjects()
		
	else
	
		self:SetStage( iNum + 1 )
		
	end
	
	return true

end

function TOOL:RightClick( trace )

	if ( self:GetOperation() == 1 ) then return false end

	local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
	self:SetObject( 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )
	
	local tr = {}
	tr.start = trace.HitPos
	tr.endpos = tr.start + ( trace.HitNormal * 16384 )
	tr.filter = {}
	tr.filter[ 1 ] = self:GetOwner()
	if ( IsValid( trace.Entity ) ) then
		tr.filter[ 2 ] = trace.Entity
	end
	
	local tr = util.TraceLine( tr )
	if ( !tr.Hit ) then
		self:ClearObjects()
		return
	end
	
	-- Don't try to constrain world to world
	if ( trace.HitWorld && tr.HitWorld ) then
		self:ClearObjects()
		return
	end
	
	if ( IsValid( trace.Entity ) && trace.Entity:IsPlayer() ) then
		self:ClearObjects()
		return
	end
	if ( IsValid( tr.Entity ) && tr.Entity:IsPlayer() ) then
		self:ClearObjects()
		return
	end
	
	local Phys = tr.Entity:GetPhysicsObjectNum( tr.PhysicsBone )
	self:SetObject( 2, tr.Entity, tr.HitPos, Phys, tr.PhysicsBone, tr.HitNormal )
	
	return self:LeftClick(tr)
end

function TOOL:Reload( trace )

	if ( !IsValid( trace.Entity ) || trace.Entity:IsPlayer() ) then return false end
	if ( CLIENT ) then return true end

	return constraint.RemoveConstraints( trace.Entity, "Axis" )
	
end

function TOOL:Holster()

	self:ClearObjects()

end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel( CPanel )

	CPanel:AddControl( "Header", { Description = "#tool.slider.help" } )
	
	CPanel:AddControl( "ComboBox", { MenuButton = 1, Folder = "slider", Options = { [ "#preset.default" ] = ConVarsDefault }, CVars = table.GetKeys( ConVarsDefault ) } )

	CPanel:AddControl( "Slider", { Label = "#tool.slider.width", Command = "slider2_width", Type = "Float", Min = 0, Max = 10 } )
	CPanel:AddControl( "RopeMaterial", { Label = "#tool.slider.material", ConVar = "slider2_material" } )
	CPanel:AddControl( "Slider", { Label = "#tool.hingefriction", Command = "slider2_hingefriction", Type = "Float", Min = 0, Max = 200, Help = true } )
	CPanel:CheckBox("Nocollide", "slider2_nocollide")
	CPanel:AddControl( "Slider", { Label = "#tool.slider.offsetsize", Command = "slider2_offsetsize", Type = "Float", Min = 25, Max = 20000, Help = true } )

end
