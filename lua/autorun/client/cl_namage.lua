if !NamageProps then NamageProps = {} end

net.Receive( "Namage_Props", function(len)
	for k,v in pairs(net.ReadTable()) do
		if v == "-1" then NamageProps[k] = nil 
		else
			local code1, code2 = string.sub(v,-1), string.sub(v,1,-2)
			if code1 == "a" then 
				NamageProps[k] = code2.." (Namage Off)" 
			elseif code1 == "b" then 
				NamageProps[k] = code2.." (Immortal)" 
			elseif code1 == "c" then
				NamageProps[k] = code2.." (Ghostable)"
			else
				NamageProps[k] = v
			end
		end
	end
end )

if !ConVarExists( "namage_on" ) then CreateConVar( "namage_on", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE, FCVAR_REPLICATED} ) end
local font = "ChatFont"
local black, white = Color(0, 0, 0, 150), Color(255, 255, 255, 255)
hook.Add("HUDPaint", "Namage.HUDPaint", function()
	local tr = LocalPlayer():GetEyeTrace()
	if !tr.HitNonWorld then return end
	local ent = tr.Entity
	if ent:IsValid() && !ent:IsPlayer() && NamageProps[ent:EntIndex()] then
		local HealthText = "Health: " .. NamageProps[ent:EntIndex()]
		if GetConVarNumber("namage_on") == 0 then HealthText = "Namage Off" end
		surface.SetFont(font)
		local w, h = surface.GetTextSize(HealthText)
		w = w + 25
		local ypos = ScrH()/2 - 220-h
		draw.RoundedBox(2, ScrW()-(w + 4), ypos, w, h + 4, black)
		draw.SimpleText(HealthText, font, ScrW() - (w / 2) - 8, ypos+12, white, 1, 1)
	end
end)