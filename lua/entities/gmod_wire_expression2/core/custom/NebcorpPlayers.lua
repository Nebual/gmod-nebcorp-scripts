e2function void entity:setDSP(int)
	if !IsValid(this) || !this:IsPlayer() then return end
	this:SetDSP(math.Clamp(int,0,133))
end

/*
__e2setcost(100)
local E2_color_traces = {}
e2function void traceColors(index, array arr)
	arr[0] = index
	datastream12.StreamToClients( self.player, "E2_tracecolor", arr )
end

__e2setcost(5)
e2function number traceColorsReady(index)
	if E2_color_traces[index] then return 1 else return 0 end
end

e2function array traceColorsRet(index)
	local temp = E2_color_traces[index]
	E2_color_traces[index] = nil
	return temp
end

datastream12.Hook("E2_tracecolor_return", function(pl,handler,id,encoded,decoded)
	local id = decoded[0]
	decoded[0] = nil
	E2_color_traces[id] = decoded
end)
hook.Add("AcceptStream", "E2_Accepttracecolors", function(pl,handler) if handler == "E2_tracecolor_return" then return true end end)
*/
__e2setcost(10)

util.AddNetworkString("Expression2_PlayerScales")
local PlayerScales = {}
local function updatePlayerScales()
	if table.Count(PlayerScales) < 1 then return end
	local ToSendScales = {}
	for k,id in ipairs(PlayerScales) do
		local ent = Entity(id)
		if !ent || !ent:IsValid() || !ent:IsPlayer() || !ent.data || !ent.data.PlayerScale then
			table.remove(PlayerScales, k)
		else
			local scale = ent.data.PlayerScale
			local x, y, z = 16 * scale.x, 16 * scale.y, 72 * scale.z
			local len = (scale.x + scale.y ) / 2
			
			ent:SetStepSize(18 * len)
			
			ent:SetHull(Vector(-x, -y, 0), Vector(x, y, z))
			ent:SetHullDuck(Vector(-x, -y, 0),Vector(x, y, z / 2))
			
			if scale.z > 1 then
				ent:SetJumpPower(160 * scale.z)
				ent:SetGravity(1)
			else
				ent:SetJumpPower(160 * (scale.z ^ 0.25)) // 160 90
				ent:SetGravity(scale.z ^ 0.333)
			end
			
			ent:SetViewOffset(Vector(0,0,(64 / 72) * z))
			ent:SetViewOffsetDucked(Vector(0,0,(28 / 72) * z))
			ent:SetWalkSpeed(250 * (len ^ 0.5))
			ent:SetRunSpeed(500 * (len ^ 0.5))
		
			ToSendScales[id] = scale
		end
	end
	net.Start("Expression2_PlayerScales") net.WriteTable(ToSendScales) net.Broadcast()
end
hook.Add("PlayerSpawn", "UpdatePlayerScales", function() timer.Create("UpdatePlayerScales", 0.3, 1, updatePlayerScales) end)

function SetPlayerScale(ply, scale)
	scale = Vector(math.Max(scale.x, 0.02), math.Max(scale.y, 0.02), math.Max(scale.z, 0.02))
	if !ply.data then ply.data = {} end
	ply.data.PlayerScale = scale
	ply.PlayerSpeedMul = ((scale.x + scale.y ) / 2) ^ 0.5
	if !table.HasValue(PlayerScales, ply:EntIndex()) then table.insert(PlayerScales, ply:EntIndex()) end
	updatePlayerScales()
end

--- Sets the scale of player <this> to <vec> [(3,3,3) would make it 3x larger]
e2function void entity:setPlayerScale(vector vec)
	if !IsValid(this) || !this:IsPlayer() then return end
	SetPlayerScale(this,Vector(vec[1],vec[2],vec[3]))
end

e2function void entity:setPlayerSmall()
	if !IsValid(this) || !this:IsPlayer() then return end
	SetPlayerScale(this, Vector(0.16,0.16,0.16))
end

__e2setcost(2)
--- Returns the scale of <this>
e2function vector entity:getPlayerScale()
	local ent = IsValid(this) and this
	if ent && ent.data && ent.data.PlayerScale then return ent.data.PlayerScale else return Vector(1,1,1) end
end

__e2setcost(3)

// ########
// Spawnpoints
// ########

NDesc["setSpawn(e:v)"] = "Makes the player spawn at a different location."
--- Makes player <this> spawn at location <vec>.
e2function void entity:setSpawn(vector vec)
	if !IsValid(this) then return end
	this.customspawn = Vector(vec[1],vec[2],vec[3])
end

NDesc["setSpawn(e:a)"] = "Makes the player spawn at a different angle."
--- Makes player <this> spawn at <ang> angle.
e2function void entity:setSpawn(angle ang)
	if !IsValid(this) then return end
	this.customspawnangle = Angle(ang[1],ang[2],0)
end

NDesc["removeSpawn(e:)"] = "Removes custom player spawn information."
--- Removes custom spawn point information for <this>
e2function void entity:removeSpawn()
	if !IsValid(this) then return end
	this.customspawn = nil
	this.customspawnangle = nil
end


if SERVER then
	local function SpawnPlayer(ply,id)
		if id then timer.Remove("E2CustomSpawn_"..id) end
		if !ply:IsValid() or !ply.customspawn or !util.IsInWorld(ply.customspawn) then return end
        ply:SetPos( ply.customspawn )
		if ply.customspawnangle then ply:SetEyeAngles( ply.customspawnangle ) end
    end
    hook.Add("PlayerSpawn", "E2CustomSpawn", SpawnPlayer)
	hook.Add("PlayerInitialSpawn", "E2CustomSpawn", function(ply) timer.Create("E2CustomSpawn_"..ply:EntIndex(),6,1,function() SpawnPlayer(ply,ply:EntIndex()) end) end)
end

__e2setcost(4)
NDesc["setEyePos(e:v)"] = "Makes the player look at world location"
e2function void entity:setEyePos(vector v)
	if !IsValid(this) || !this:IsPlayer() then return end
	//ang.p = math.Clamp(ang.p, -89.999999, 89.999999)
	this:SetEyeAngles(math.angnorm((Vector(v[1],v[2],v[3]) - this:GetShootPos()):Angle()))
end
NDesc["setEye(e:v)"] = "Makes the player look along a normalized vector"
e2function void entity:setEye(vector v)
	if !IsValid(this) || !this:IsPlayer() then return end
	this:SetEyeAngles(math.angnorm(Vector(v[1],v[2],v[3]):Angle()))
end
e2function void entity:setEye(angle a)
	if !IsValid(this) || !this:IsPlayer() then return end
	this:SetEyeAngles(math.angnorm(Angle(a[1],a[2],a[3])))
end

NDesc["setViewOffset(e:n)"] = "Makes the player's view come from a different z (default 64)"
e2function void entity:setViewOffset(z)
	if !IsValid(this) || !this:IsPlayer() then return end
	this:SetViewOffset(Vector(0,0,z))
end

// ########
// "Radio" live music streaming
// ########
__e2setcost(10)

e2function void radioStart(string website)
	SendUserMessage("expression2_radio", RecipientFilter():AddAllPlayers(), "http://nebtown.info/uploads/videoplay.php?v="..website)
end
e2function void radioStart(string website, entity ply)
	SendUserMessage("expression2_radio", ply, "http://nebtown.info/uploads/videoplay.php?v="..website)
end
e2function void radioYoutube(string youtubecode)
	SendUserMessage("expression2_radio", RecipientFilter():AddAllPlayers(), "http://www.youtube.com/watch?v="..youtubecode)
end
e2function void radioYoutube(string youtubecode, entity ply)
	SendUserMessage("expression2_radio", ply, "http://www.youtube.com/watch?v="..youtubecode)
end

// ########
// Clientside Traces (for the Nid)
// ########

e2function void entity:setTrace(entity ent)
	if !IsValid(this) || !IsValid(ent) || !this:IsPlayer() then return end
	SendUserMessage("expression2_viewpoint", this, ent:EntIndex())
end

e2function void entity:resetTrace()
	if !IsValid(this) || !this:IsPlayer() then return end
	SendUserMessage("expression2_viewpoint", this, -1)
end

// ########
// HUD shit
// ########

util.AddNetworkString("E2HudBox")
__e2setcost(8)
e2function void entity:hudBox(string text, x, y, border, vector backcolor, vector fontcolor)
	if not this:IsPlayer() then return end
	local Data = {
		BorderSize = border,
		X = x,
		Y = y,
		Text = text,
		Font = "Default",
		BackColor = Color( backcolor[1], backcolor[2], backcolor[3], 100 ),
		FontColor = Color( fontcolor[1], fontcolor[2], fontcolor[3], 255 )
	}
	net.Start("E2HudBox") net.WriteTable(Data) net.Send(this)
end

util.AddNetworkString("E2HudText")
registerCallback( 'destruct', function( chip )
	local Data = {}
	Data.remove = true
	for k,v in pairs(chip.entity.hudTextIDs) do
		if v:IsValid() then
			Data.id = tonumber(string.Explode("-", k)[1])
			net.Start("E2HudText") net.WriteTable(Data) net.Send(v)
		end
	end
end )
registerCallback( 'construct', function( chip )
	chip.entity.hudTextIDs = {}
end )

local function hudText(self, ent, id, text, x, y, colour, alpha, wpos, percents)
	if !ent || !ent:IsValid() || !ent:IsPlayer() then return end
	self.entity.hudTextIDs[id .."-" .. ent:EntIndex()] = ent
	local Data = {
		id		= id,
		text 	= text,
		color 	= Color( colour[1], colour[2], colour[3], alpha or 255 )
	}
	//if font then Data["font"] = font end
	if wpos then 
		Data["wpos"] = Vector(wpos[1], wpos[2], wpos[3])
	else
		if percents then 
			Data["percents"] = true
			Data["pos"] = {x=math.Clamp(x/100,0,1),y=math.Clamp(y/100,0,1)}
		else
			Data["pos"] = {x=x,y=y}
		end
	end
	net.Start("E2HudText") net.WriteTable(Data) net.Send(ent)
end

--- Creates a new hud text object on <this>'s client. <id> ID, <text> text, <x> <y> XY positions.
e2function void entity:hudText(id, string text, x, y)
	hudText(self, this, id, text, x, y, {255,255,255})
end

--- Creates a new hud text object on <this>'s client. <id> ID, <text> text, <x> <y> XY positions, <fontcolor> colour.
e2function void entity:hudText(id, string text, x, y, vector fontcolor)
	hudText(self, this, id, text, x, y, fontcolor)
end

--- Creates a new hud text object on <this>'s client. <id> ID, <text> text, <x> <y> XY positions, <fontcolor> colour <alpha> alpha.
e2function void entity:hudText(id, string text, x, y, vector fontcolor, alpha)
	hudText(self, this, id, text, x, y, fontcolor, alpha)
end

--- Creates a new hud text object on <this>'s client. <id> ID, <text> text, <wpos> world pos converted to local XY positions, <fontcolor> colour.
e2function void entity:hudText(id, string text, vector wpos)
	hudText(self, this, id, text, 0, 0, {255,255,255}, nil, wpos)
end
--- Creates a new hud text object on <this>'s client. <id> ID, <text> text, <wpos> world pos converted to local XY positions, <fontcolor> colour.
e2function void entity:hudText(id, string text, vector wpos, vector fontcolor)
	hudText(self, this, id, text, 0, 0, fontcolor, nil, wpos)
end

--- Creates a new hud text object on <this>'s client. <id> ID, <text> text, <wpos> world pos converted to local XY positions, <fontcolor> colour <alpha> alpha.
e2function void entity:hudText(id, string text, vector wpos, vector fontcolor, alpha)
	hudText(self, this, id, text, 0, 0, fontcolor, alpha, wpos)
end

--- Creates a new hud text object on <this>'s client. <id> ID, <text> text, <x> <y> XY positions.
e2function void entity:hudTextPercent(id, string text, x, y)
	hudText(self, this, id, text, x, y, {255,255,255})
end

--- Creates a new hud text object on <this>'s client. <id> ID, <text> text, <x> <y> XY positions, <fontcolor> colour.
e2function void entity:hudTextPercent(id, string text, x, y, vector fontcolor)
	hudText(self, this, id, text, x, y, fontcolor, false, false, true)
end

--- Creates a new hud text object on <this>'s client. <id> ID, <text> text, <x> <y> XY positions, <fontcolor> colour <alpha> alpha.
e2function void entity:hudTextPercent(id, string text, x, y, vector fontcolor, alpha)
	hudText(self, this, id, text, x, y, fontcolor, alpha, false, true)
end

e2function void entity:hudTextRemove(id)
	if !this || !this:IsValid() || !this:IsPlayer() then return end
	net.Start("E2HudText") net.WriteTable({remove = true, id = id}) net.Send(this)
end

// ================
// APC STUFF
// ===================

__e2setcost(2)
--- Returns 1 if <this> is pressing W
e2function number entity:keyW()
	if !this || !this:IsValid() || !this:IsPlayer() then return 0 end
	if this:KeyDown( IN_FORWARD ) then return 1 else return 0 end
end

--- Returns 1 if <this> is pressing A
e2function number entity:keyA()
	if !this || !this:IsValid() || !this:IsPlayer() then return 0 end
	if this:KeyDown( IN_MOVELEFT ) then return 1 else return 0 end
end

--- Returns 1 if <this> is pressing S
e2function number entity:keyS()
	if !this || !this:IsValid() || !this:IsPlayer() then return 0 end
	if this:KeyDown( IN_BACK ) then return 1 else return 0 end
end

--- Returns 1 if <this> is pressing D
e2function number entity:keyD()
	if !this || !this:IsValid() || !this:IsPlayer() then return 0 end
	if this:KeyDown( IN_MOVERIGHT ) then return 1 else return 0 end
end

--- Returns 1 if <this> is pressing Space
e2function number entity:keySpace()
	if !this || !this:IsValid() || !this:IsPlayer() then return 0 end
	if this:KeyDown( IN_JUMP ) then return 1 else return 0 end
end

--- Returns 1 if <this> is pressing R
e2function number entity:keyR()
	if !this || !this:IsValid() || !this:IsPlayer() then return 0 end
	if this:KeyDown( IN_RELOAD ) then return 1 else return 0 end
end

--- Returns 1 if <this> is pressing Control
e2function number entity:keyCtrl()
	if !this || !this:IsValid() || !this:IsPlayer() then return 0 end
	if this:KeyDown( IN_DUCK ) then return 1 else return 0 end
end

--- Returns 1 if <this> is pressing Mouse1
e2function number entity:keyMouse1()
	if !this || !this:IsValid() || !this:IsPlayer() then return 0 end
	if this:KeyDown( IN_ATTACK ) then return 1 else return 0 end
end

--- Returns 1 if <this> is pressing Mouse2
e2function number entity:keyMouse2()
	if !this || !this:IsValid() || !this:IsPlayer() then return 0 end
	if this:KeyDown( IN_ATTACK2 ) then return 1 else return 0 end
end

--- Returns 1 if <this> is pressing Alt
e2function number entity:keyAlt()
	if !this || !this:IsValid() || !this:IsPlayer() then return 0 end
	if this:KeyDown( IN_WALK ) then return 1 else return 0 end
end

--- Returns 1 if <this> is pressing Shift
e2function number entity:keyShift()
	if !this || !this:IsValid() || !this:IsPlayer() then return 0 end
	if this:KeyDown( IN_SPEED ) then return 1 else return 0 end
end

--- Returns 1 if <this> is pressing E
e2function number entity:keyE()
	if !this || !this:IsValid() || !this:IsPlayer() then return 0 end
	if this:KeyDown( IN_USE ) then return 1 else return 0 end
end

--- Returns 1 if <this> is pressing Zoom
e2function number entity:keyG()
	if !this || !this:IsValid() || !this:IsPlayer() then return 0 end
	if this:KeyDown( IN_ZOOM ) then return 1 else return 0 end
end

--- Returns 1 if <this> is in third person (vehicles)
e2function number entity:keyThirdPerson()
	if !this || !this:IsValid() || !this:IsPlayer() then return 0 end
	return this:GetInfoNum("gmod_vehicle_viewmode", 0)
end

--- Returns 1 if <this> is pressing Tab
e2function number entity:keyTab()
	if !this || !this:IsValid() || !this:IsPlayer() then return 0 end
	if this:KeyDown( IN_SCORE ) then return 1 else return 0 end
end

--- Returns 1 if <this> is pressing Bullrush lolwut
e2function number entity:keyBullrush()
	if !this || !this:IsValid() || !this:IsPlayer() then return 0 end
	if this:KeyDown( IN_BULLRUSH ) then return 1 else return 0 end
end
--[[************************************************************************]]--

--- Forces <this> to hold the weapon class <wepon>, assuming they have it
e2function void entity:selectWeapon(string wepon)
	if !IsValid(this) || !this:IsPlayer() then return end
	this:SelectWeapon(wepon)
end

local function SpecialCase( arg )
	if (type(arg) == "table") then
		if (table.IsSequential(arg)) then -- A table with only numerical indexes
			local str = "["
			for k,v in ipairs( arg ) do
				if istable(v) then
					if (k != #arg) then
						str = str .. SpecialCase( v ) .. ","
					else
						str = str .. SpecialCase( v ) .. "]"
					end
				else
					if (k != #arg) then
						str = str .. tostring(v) .. ","
					else
						str = str .. tostring(v) .. "]"
					end
				end
			end
			return str
		else -- Else it's a table with string indexes (which this function can't handle)
			return "[table]"
		end
	end
end

-- Prints <...> like lua's print(...), except to the chat area
e2function void entity:print(...)
	if !IsValid(this) || !this:IsPlayer() then return end
	local args = {...}
	if (#args>0) then
		local text = ""
		for k,v in ipairs( args ) do
			text = text .. (SpecialCase( v ) or tostring(v)) .. "\t"
		end
		if (text and #text>0) then
			this:ChatPrint(text)
		end
	end	
end

__e2setcost(15)

e2function number vector:indoors()
	local vec = Vector(this[1],this[2],this[3])
	if util.TraceLine({start = vec, endpos = vec + Vector(0,0,500)}).Hit then return 1 else return 0 end
end
e2function number entity:indoors(vector vec)
	if !IsValid(this) then return 0 end
	vec = Vector(vec[1],vec[2],vec[3])
	if util.TraceLine({start = vec, endpos = vec + Vector(0,0,500), filter = this}).Hit then return 1 else return 0 end
end
e2function number entity:indoors()
	if !IsValid(this) then return 0 end
	if util.TraceLine({start = this:GetPos(), endpos = this:GetPos() + Vector(0,0,500), filter = this}).Hit then return 1 else return 0 end
end

e2function void entity:slowDown(mul)
	if !IsValid(this) || !this:IsPlayer() then return end
	GAMEMODE:SetPlayerSpeed(this, 250*mul, 500*mul)
end

__e2setcost(nil)