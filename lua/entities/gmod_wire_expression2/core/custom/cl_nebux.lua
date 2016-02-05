local colours = {
	[1] = Color(160,160,160),
	[2] = Color(190,120,190),
	[5] = Color(108,170,197),
	[10] = Color(133,102,220),
	[20] = Color(111,251,177),
	[50] = Color(220,105,96),
	[100] = Color(255,230,0),
}
local colours_i = {}
for amt, colour in pairs(colours) do
	colours_i[string.format("%i %i %i", colour.r, colour.g, colour.b)] = amt
end

hook.Add("Think", "Nebux Overlay", function()
	if not IsValid(LocalPlayer()) then return end
	local ent = LocalPlayer():GetEyeTrace().Entity
	if IsValid(ent) and ent:GetModel() == "models/props/cs_assault/money.mdl" then
		local colour = ent:GetColor()
		local amt = colours_i[string.format("%i %i %i", colour.r, colour.g, colour.b)]
		if amt then
			AddWorldTip( ent:EntIndex(), "$"..amt, 0.5, ent:GetPos(), ent  )
			effects.halo.Add( {ent}, Color( 255, 255, 255, 255 ), 1, 1, 1, true, true )
		end
	end
end)