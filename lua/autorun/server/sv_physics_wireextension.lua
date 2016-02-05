function WireToolMakeThrustner( self, trace, ply )

	local model			= self:GetModel()
	local soundname		= self:GetClientInfo( "soundname" )
	local oweffect		= self:GetClientInfo( "oweffect" )
	local uweffect		= self:GetClientInfo( "uweffect" )
	local owater		= self:GetClientNumber( "owater" ) ~= 0
	local uwater		= self:GetClientNumber( "uwater" ) ~= 0

	-- If we shot a wire_thruster change its force
	if trace.Entity:IsValid() and trace.Entity:GetClass() == "gmod_wire_thrustner" and trace.Entity.pl == ply then
		trace.Entity:SetDatEffect(uwater, owater, uweffect, oweffect)

		trace.Entity:Setup(oweffect, uweffect, owater, uwater, soundname)

		trace.Entity.soundname	= soundname
		trace.Entity.oweffect	= oweffect
		trace.Entity.uweffect	= uweffect
		trace.Entity.owater		= owater
		trace.Entity.uwater		= uwater

		return true
	end

	if not self:GetSWEP():CheckLimit( "wire_thrusters" ) then return false end
	if not util.IsValidModel( model ) or not util.IsValidProp( model ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local wire_thruster = MakeWireThrustner( ply, trace.HitPos, Ang, model, oweffect, uweffect, owater, uwater, soundname, trace.Entity:IsValid() )

	local min = wire_thruster:OBBMins()
	wire_thruster:SetPos( trace.HitPos - trace.HitNormal * min.z )

	return wire_thruster
end