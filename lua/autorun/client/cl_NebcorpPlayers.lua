usermessage.Hook("expression2_radio", function(um)
	if E2WebRadio then E2WebRadio:Remove() end
	E2WebRadio = vgui.Create("DHTML")
	E2WebRadio:SetSize(0, 0)
	E2WebRadio:SetVisible( false )
	E2WebRadio:OpenURL(um:ReadString())
end)

local function StopNadio( player, command, arguments )
    if E2WebRadio then E2WebRadio:Remove() end
end
concommand.Add( "stopnadio", StopNadio )

net.Receive("NebcorpE2Descs", function(len) for k,v in pairs(net.ReadTable()) do E2Helper.Descriptions[k] = v end end)

// Tests involving coloured rangers
/*datastream12.Hook( "E2_tracecolor", function(handle,id,encoded,decoded)
	local ret = {}
	ret[0] = decoded[0]
	decoded[0] = nil
	for k=2, #decoded, 2 do
		local temp = render.GetSurfaceColor(Vector(decoded[k-1][1],decoded[k-1][2],decoded[k-1][3]), Vector(decoded[k][1], decoded[k][2], decoded[k][3]))
		ret[k/2] = {temp[1]*255,temp[2]*255,temp[3]*255}
	end
	datastream12.StreamToServer("E2_tracecolor_return", ret)
end )
*/
// HUD


local function E2HudBoxSetup( len )
	LocalPlayer().E2HudBox = net.ReadTable()
end
net.Receive( "E2HudBox", E2HudBoxSetup )

local function E2DrawHudBox()
	if not LocalPlayer().E2HudBox then return end 
	local data = LocalPlayer().E2HudBox
	draw.WordBox( data.BorderSize, data.X, data.Y, data.Text, data.Font, data.BackColor, data.FontColor)
end
hook.Add("HUDPaint", "E2HudBox", E2DrawHudBox)


// HUD TEXT
LocalPlayer().E2HudText = {}
local EHT = LocalPlayer().E2HudText

local function E2HudTextSetup( len )
	local encoded = net.ReadTable()
	local ID = encoded.id
	if !EHT then EHT = {} LocalPlayer().E2HudText = EHT end
	if !ID then print("ERROR: E2HudText with no ID!") return end
	encoded.id = nil
	
	if encoded.remove then
		EHT[ID] = nil
	else
		if encoded.percents then
			encoded.percents = nil
			encoded.pos = {encoded.pos.x * surface.ScreenWidth(), encoded.pos.y * surface.ScreenHeight()}
		end
		EHT[ID] = encoded
	end
end
net.Receive( "E2HudText", E2HudTextSetup )

local function E2DrawText()
	if not EHT or not next(EHT) then return end
	for _,v in pairs(EHT) do
		if v.wpos then
			local lpos = v.wpos:ToScreen()
			if lpos.visible then draw.DrawText( v.text, "DermaDefault", lpos.x, lpos.y, v.color, 1 ) end
		else
			draw.DrawText( v.text, "DermaDefault", v.pos.x, v.pos.y, v.color, 1 )
		end
	end
end
hook.Add("HUDPaint", "E2HudText", E2DrawText)

// Nid shit
local oldtracefunction = util.GetPlayerTrace
usermessage.Hook("expression2_viewpoint", function(um)
	local ent = Entity(um:ReadLong())
	if IsValid(ent) then
		function util.GetPlayerTrace( ply, dir )
			if IsValid(ent) then
				local trace = {}
				trace.start = ent:GetPos() + ent:GetForward() * 5
				trace.endpos = trace.start + ent:GetForward() * 3000
				trace.filter = ent
				return trace
			else
				util.GetPlayerTrace = oldtracefunction
				return util.GetPlayerTrace( ply, dir )
			end
		end
	else util.GetPlayerTrace = oldtracefunction
	end
end)




local function SetPlayerScale(prop,scale)
	local x, y = 16 * scale.x, 16 * scale.y
	prop:SetModelScale((scale.x+scale.y+scale.z)/3,0)
	prop:SetHull(Vector(-x, -y, 0), Vector(x, y, 72 * scale.z))
	prop:SetHullDuck(Vector(-x, -y, 0),Vector(x, y, 36 * scale.z))
	
	prop.OldPlayerScale = scale
end

local fps = 40
local function PlayerScales( len )
	local Scales = net.ReadTable()
	for id,scale in pairs(Scales) do
		local prop = Entity(id)
		local chunks = math.ceil(2*fps)
		local oldscale = prop.OldPlayerScale or Vector(1,1,1)
		prop.PlayerScaleIteration = 0
		timer.Create( "playerscale_overtime"..tostring(id), 2/fps, chunks, function()
			if !prop:IsValid() then return end
			local iteration = prop.PlayerScaleIteration + 1
			local n = iteration/chunks
			local scale = Vector(newscale[1]*n + oldscale[1]*(1-n), newscale[2]*n + oldscale[2]*(1-n), newscale[3]*n + oldscale[3]*(1-n))
			prop.PlayerScaleIteration = iteration
			SetPlayerScale(prop, scale)
		end)
	end
end
net.Receive( "Expression2_PlayerScales", PlayerScales )
