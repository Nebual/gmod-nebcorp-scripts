WireToolSetup.setCategory( "Display" )
WireToolSetup.open( "ncpainting", "NCPainting", "ncpainting", nil, "NCPaintings" )

if CLIENT then
	language.Add( "tool.wire_ncpainting.name", "NCPainting (Wire)" )
	language.Add( "tool.wire_ncpainting.desc", "Spawns an NCPainting, which can be used to draw images." )
	language.Add( "tool.wire_ncpainting.0", "Primary: Create/Update screen" )
end
WireToolSetup.BaseLang()
WireToolSetup.SetupMax( 20, "wire_ncpainting", "You've hit NCPaintings limit!" )

if SERVER then
	function TOOL:GetConVars()
		return self:GetClientInfo("filepath"), self:GetClientInfo("dupepath")
	end
	function TOOL:MakeEnt( ply, model, Ang, trace )
		return MakeNCPainting( ply, trace.HitPos, Ang, model, self:GetConVars() )
	end
	/*function TOOL:LeftClick( trace )
		if not trace.HitPos or trace.Entity:IsPlayer() or trace.Entity:IsNPC() or (SERVER and not util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone )) then return false end
		local ent = self:LeftClick_Make( trace, self:GetOwner() )
		return self:LeftClick_PostMake( ent, self:GetOwner(), trace )
	end*/
end

TOOL.ClientConVar = {
	model      = "models/props_lab/monitor01b.mdl",
	createflat = 0,
	weld       = 1,
	filepath = "",
	dupepath = ""
}

function TOOL.BuildCPanel(panel)
	WireDermaExts.ModelSelect(panel, "wire_ncpainting_model", list.Get( "WireScreenModels" ), 2,true)
	panel:TextEntry("Image Filepath", "wire_ncpainting_filepath")
	panel:TextEntry("Dupename", "wire_ncpainting_dupepath")
	panel:CheckBox("Create Flat to Surface", "wire_ncpainting_createflat")
	panel:CheckBox("Weld", "wire_ncpainting_weld")
end