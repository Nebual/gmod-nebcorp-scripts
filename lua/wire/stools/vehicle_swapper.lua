WireToolSetup.setCategory( "Physics" )
WireToolSetup.open( "vehicle_swapper", "Vehicle Swapper", "gmod_wire_vehicle_swapper", nil, "Vehicle Swappers" )

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"

if CLIENT then
    language.Add( "Tool.wire_vehicle_swapper.name", "Vehicle Swapper	(Wire)" )
    language.Add( "Tool.wire_vehicle_swapper.desc", "Switches the passengers of two vehicles" )
    language.Add( "Tool.wire_vehicle_swapper.0", "Primary: Click on first chair" )
    language.Add( "Tool.wire_vehicle_swapper.1", "Left click on the second chair" )
    language.Add( "Tool.wire_vehicle_swapper.2", "Left click to place the controller" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 10, TOOL.Mode.."s" , "You've hit the Wire "..TOOL.PluralName.." limit!" )

function TOOL:LeftClick( trace )
	if trace.Entity:IsValid() and trace.Entity:IsPlayer() then return end

	// If there's no physics object then we can't constraint it!
	if SERVER and !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local iNum = self:NumObjects()

	if ( iNum > 1 ) then
		if CLIENT then
			self:ClearObjects()
			return true
		end

		local ply = self:GetOwner()
		local Ent1, Ent2, Ent3  = self:GetEnt(1),	 self:GetEnt(2), trace.Entity

		local Ang = trace.HitNormal:Angle()
		Ang.pitch = Ang.pitch + 90
		local controller = MakeWireVehicleSwapperController( ply, trace.HitPos, Ang, self:GetModel() )

		if !IsValid(controller) then
			WireLib.AddNotify( self:GetOwner(), "Vehicle Swapper controller placement failed!", NOTIFY_GENERIC, 7 )
			self:ClearObjects()
			self:SetStage(0)
			return false
		end

		// Send the linked entities over to the controller
		controller:SendVars( Ent1, Ent2 )

		// Finish placing the controller
		local min = controller:OBBMins()
		controller:SetPos( trace.HitPos - trace.HitNormal * min.z )

		local const2 = WireLib.Weld( controller, trace.Entity, trace.PhysicsBone, true )

		undo.Create("WireVehicleSwapper")
			undo.AddEntity( controller )
			undo.SetPlayer( ply )
		undo.Finish()

		self:ClearObjects()
		self:SetStage(0)
	else
		if !IsValid(trace.Entity) or !trace.Entity:IsVehicle() then
			WireLib.AddNotify(self:GetOwner(), "Must select a Vehicle", NOTIFY_GENERIC, 3)
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
	panel:AddControl( "Header", { Text = "#Tool.wire_vehicle_swapper.name", Description = "#Tool.wire_vehicle_swapper.desc" } )
	WireDermaExts.ModelSelect(panel, "wire_vehicle_swapper_model", list.Get( "Wire_Misc_Tools_Models" ), 1)
end
