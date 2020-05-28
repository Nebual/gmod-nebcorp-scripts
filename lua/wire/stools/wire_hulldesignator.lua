WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "hulldesignator", "Hull Designator", "gmod_wire_hulldesignator", nil, "Hull Designator" )

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

if CLIENT then
    language.Add( "Tool.wire_hulldesignator.name", "Hull Designator	(Wire)" )
    language.Add( "Tool.wire_hulldesignator.desc", "Toggles the dangerous Gravity Hull Designator's localized physics" )
    language.Add( "Tool.wire_hulldesignator.0", "Primary: Click on floor prop" )
    language.Add( "Tool.wire_hulldesignator.1", "Left click to place the controller" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

function TOOL:LeftClick( trace )
	if trace.Entity:IsValid() and trace.Entity:IsPlayer() then return end

	if SERVER and not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local iNum = self:NumObjects()

	if ( iNum > 0 ) then
		if CLIENT then
			self:ClearObjects()
			return true
		end

		local ply = self:GetOwner()
		local Ent1 = self:GetEnt(1)

		local Ang = trace.HitNormal:Angle()
		Ang.pitch = Ang.pitch + 90
		local controller = MakeWireHullDesignatorController( ply, trace.HitPos, Ang, self:GetModel() )

		if not IsValid(controller) then
			WireLib.AddNotify( self:GetOwner(), "Hull Designator controller placement failed!", NOTIFY_GENERIC, 7 )
			self:ClearObjects()
			self:SetStage(0)
			return false
		end

		controller:SendVars( Ent1 )

		local min = controller:OBBMins()
		controller:SetPos( trace.HitPos - trace.HitNormal * min.z )

		local const2 = WireLib.Weld( controller, trace.Entity, trace.PhysicsBone, true )

		undo.Create("WireHullDesignator")
			undo.AddEntity( controller )
			undo.SetPlayer( ply )
		undo.Finish()

		self:ClearObjects()
		self:SetStage(0)
	else
		if not IsValid(trace.Entity) then
			WireLib.AddNotify(self:GetOwner(), "Must select a floor prop", NOTIFY_GENERIC, 3)
			return false
		end
		local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
		self:SetObject( iNum + 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )
		self:SetStage( iNum+1 )
	end

	return true
end

function TOOL:Reload( trace )
	self:ClearObjects()
	self:SetStage(0)
end

function TOOL.BuildCPanel( panel )
	panel:AddControl( "Header", { Text = "#Tool.wire_hulldesignator.name", Description = "#Tool.wire_hulldesignator.desc" } )
	WireDermaExts.ModelSelect(panel, "wire_hulldesignator_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
end
