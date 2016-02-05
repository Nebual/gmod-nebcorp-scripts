
TOOL.Category = "Render"
TOOL.Name = "Colour - Better"

TOOL.ClientConVar[ "r" ] = 255
TOOL.ClientConVar[ "g" ] = 0
TOOL.ClientConVar[ "b" ] = 255
TOOL.ClientConVar[ "a" ] = 255
TOOL.ClientConVar[ "mode" ] = "0"
TOOL.ClientConVar[ "fx" ] = "0"

local function SetColour( Player, Entity, Data )

	--
	-- If we're trying to make them transparent them make the render mode
	-- a transparent type. This used to fix in the engine - but made HL:S props invisible(!)
	--
	if ( Data.Color && Data.Color.a < 255 && Data.RenderMode == 0 ) then
		Data.RenderMode = 1
	end

	if ( Data.Color ) then Entity:SetColor( Color( Data.Color.r, Data.Color.g, Data.Color.b, Data.Color.a ) ) end
	if ( Data.RenderMode ) then Entity:SetRenderMode( Data.RenderMode ) end
	if ( Data.RenderFX ) then Entity:SetKeyValue( "renderfx", Data.RenderFX ) end

	if ( SERVER ) then
		duplicator.StoreEntityModifier( Entity, "colour", Data )
	end
	
end
duplicator.RegisterEntityModifier( "colour", SetColour )

function TOOL:LeftClick( trace )

	local ent = trace.Entity
	if ( IsValid( ent.AttachedEntity ) ) then ent = ent.AttachedEntity end

	if IsValid( ent ) then -- The entity is valid and isn't worldspawn

		if ( CLIENT ) then return true end
	
		local r = self:GetClientNumber( "r", 0 )
		local g = self:GetClientNumber( "g", 0 )
		local b = self:GetClientNumber( "b", 0 )
		local a = self:GetClientNumber( "a", 0 )
		local fx = self:GetClientNumber( "fx", 0 )
		local mode = self:GetClientNumber( "mode", 0 )

		SetColour( self:GetOwner(), ent, { Color = Color( r, g, b, a ), RenderMode = mode, RenderFX = fx } )

		return true
		
	end

end

function TOOL:RightClick( trace )

	local ent = trace.Entity
	if ( IsValid( ent.AttachedEntity ) ) then ent = ent.AttachedEntity end

	if IsValid( ent ) then -- The entity is valid and isn't worldspawn

		if ( CLIENT ) then return true end
	
		SetColour( self:GetOwner(), ent, { Color = Color( 255, 255, 255, 255 ), RenderMode = 0, RenderFX = 0 } )
		return true
	
	end
	
end

function TOOL:Reload( trace )

	local ent = trace.Entity
	if ( IsValid( ent.AttachedEntity ) ) then ent = ent.AttachedEntity end

	if IsValid( ent ) then -- The entity is valid and isn't worldspawn

		if ( CLIENT ) then return true end
	
		local colour = ent:GetColor()
		self:SetClientNumber( "r", colour.r )
		self:SetClientNumber( "g", colour.g )
		self:SetClientNumber( "b", colour.b )
		self:SetClientNumber( "a", colour.a )
		self:SetClientNumber( "mode", ent:GetRenderMode() )
		return true
	end
	
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel( CPanel )

	CPanel:AddControl( "Header", { Description	= "#tool.colour.desc" } )

	CPanel:AddControl( "Color", { Label = "#tool.colour.color", Red = "colour_better_r", Green = "colour_better_g", Blue = "colour_better_b", Alpha = "colour_better_a" } )

	CPanel:AddControl( "ComboBox", { Label = "#tool.colour.mode", Options = list.Get( "RenderModes" ) } )
	CPanel:AddControl( "ComboBox", { Label = "#tool.colour.fx", Options = list.Get( "RenderFX" ) } )

end

list.Set( "RenderModes", "#rendermode.normal", { colour_better_mode = 0 } )
list.Set( "RenderModes", "#rendermode.transcolor", { colour_better_mode = 1 } )
list.Set( "RenderModes", "#rendermode.transtexture", { colour_better_mode = 2 } )
list.Set( "RenderModes", "#rendermode.glow", { colour_better_mode = 3 } )
list.Set( "RenderModes", "#rendermode.transalpha", { colour_better_mode = 4 } )
list.Set( "RenderModes", "#rendermode.transadd", { colour_better_mode = 5 } )
list.Set( "RenderModes", "#rendermode.transalphaadd", { colour_better_mode = 8 } )
list.Set( "RenderModes", "#rendermode.worldglow", { colour_better_mode = 9 } )

list.Set( "RenderFX", "#renderfx.none", { colour_better_fx = 0 } )
list.Set( "RenderFX", "#renderfx.pulseslow", { colour_better_fx = 1 } )
list.Set( "RenderFX", "#renderfx.pulsefast", { colour_better_fx = 2 } )
list.Set( "RenderFX", "#renderfx.pulseslowwide", { colour_better_fx = 3 } )
list.Set( "RenderFX", "#renderfx.pulsefastwide", { colour_better_fx = 4 } )
list.Set( "RenderFX", "#renderfx.fadeslow", { colour_better_fx = 5 } )
list.Set( "RenderFX", "#renderfx.fadefast", { colour_better_fx = 6 } )
list.Set( "RenderFX", "#renderfx.solidslow", { colour_better_fx = 7 } )
list.Set( "RenderFX", "#renderfx.solidfast", { colour_better_fx = 8 } )
list.Set( "RenderFX", "#renderfx.strobeslow", { colour_better_fx = 9 } )
list.Set( "RenderFX", "#renderfx.strobefast", { colour_better_fx = 10 } )
list.Set( "RenderFX", "#renderfx.strobefaster", { colour_better_fx = 11 } )
list.Set( "RenderFX", "#renderfx.flickerslow", { colour_better_fx = 12 } )
list.Set( "RenderFX", "#renderfx.flickerfast", { colour_better_fx = 13 } )
list.Set( "RenderFX", "#renderfx.distort", { colour_better_fx = 15 } )
list.Set( "RenderFX", "#renderfx.hologram", { colour_better_fx = 16 } )
list.Set( "RenderFX", "#renderfx.pulsefastwider", { colour_better_fx = 24 } )
