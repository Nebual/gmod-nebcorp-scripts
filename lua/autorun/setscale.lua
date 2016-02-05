if SERVER then
	AddCSLuaFile("autorun/setscale.lua")
	
	util.AddNetworkString("Expression2_Scales")
	if not ScaleEnts then ScaleEnts = {} end
	function updateScales(ply)
		if !next( ScaleEnts ) then return end
		local ToSendScales = {}
		for k,id in pairs(ScaleEnts) do
			local ent = Entity(id)
			if !ent || !ent:IsValid() || !ent.data || !ent.data.Scale then
				table.remove(ScaleEnts, k)
			else
				ToSendScales[id] = ent.data.Scale
			end
		end
		net.Start("Expression2_Scales")
			net.WriteTable(ToSendScales)
			net.WriteTable({})
		net.Send(ply)
	end
	hook.Add("PlayerSpawn", "UpdateEntScales2", updateScales)
	hook.Add("PlayerInitialSpawn", "UpdateEntScales3", function(ply) timer.Create("InitialSetScale_"..ply:SteamID(),15,1, function() updateScales(ply) end) end)

	local ScaleEntsFast = {}
	local ScaleEntsFastChanged = false
	local function sendScales()
		if !ScaleEntsFastChanged then return end 
		local ToSendScales, ToSendSpeeds = {}, {}
		for k,id in ipairs(ScaleEntsFast) do
			local ent = Entity(id)
			if !ent || !ent:IsValid() || !ent.data || !ent.data.Scale then
				table.remove(ScaleEntsFast, k)
			else
				ToSendScales[id] = ent.data.Scale
				ToSendSpeeds[id] = ent.data.ScaleSpeed
			end
		end
		net.Start("Expression2_Scales")
			net.WriteTable(ToSendScales)
			net.WriteTable(ToSendSpeeds)
		net.Broadcast()
		ScaleEntsFast = {}
		ScaleEntsFastChanged = false
	end
	timer.Create("Expression2SendScales",0.5,0,sendScales)
	
	function SetScale(ent, scale, time)
		if !IsValid(ent) then return end
		if !ent.data then ent.data = {} end
		ent.data.ScaleSpeed = time
		scale = Vector(math.floor(scale.x*1000)/1000, math.floor(scale.y*1000)/1000, math.floor(scale.z*1000)/1000)
		if ent.data.Scale != scale then
			ent.data.Scale = scale
			duplicator.StoreEntityModifier(ent,"NebcorpScale",{Scale = scale})
			local id = ent:EntIndex()
			if !table.HasValue(ScaleEnts, id) then table.insert(ScaleEnts, id) end
			table.insert(ScaleEntsFast, id)
			ScaleEntsFastChanged = true
		end
	end
	
	hook.Add("InitPostEntity", "NebcorpScale", function()
		duplicator.RegisterEntityModifier( "NebcorpScale", function(ply, ent, data) SetScale(ent, data.Scale, 0.5) end)
	end)
end
if CLIENT then
	function SetScale(prop,scale)
		if prop.EnableMatrix then
			local mat = Matrix()
			mat:Scale(scale)
			prop:EnableMatrix("RenderMultiply", mat)
			local propmx = prop:OBBMaxs()
			local propmn = prop:OBBMins()
			propmx.x = scale.x*propmx.x
			propmx.y = scale.y*propmx.y
			propmx.z = scale.z*propmx.z
			propmn.x = scale.x*propmn.x
			propmn.y = scale.y*propmn.y
			propmn.z = scale.z*propmn.z
			prop:SetRenderBounds( propmx, propmn )
		else
			prop:SetModelScale((scale.x+scale.y+scale.z)/3,0)
		end
		prop.OldScale = scale
	end
	
	-- Severe lagspikes can detach the source entity from its lua, so we need to reapply things when its reattached
	hook.Add("NetworkEntityCreated", "nebcorp_rescale", function(ent)
		if ent.OldScale then
			-- ent.OldScale isn't present on newly created props, only old ones that've been hit by a lagspike
			SetScale(ent, ent.OldScale)
		end
	end)
	
	local SetScale = SetScale
	local fps = 60
	local function WorkScale(id, scale, speed)
		local prop = Entity(id)
		if !prop:IsValid() then return end
		//prop.ExtraRBoxPoints = prop.ExtraRBoxPoints or {}
		
		if tobool(speed) then
			local chunks = math.ceil(speed*fps)
			local oldscale = prop.OldScale or Vector(1,1,1)
			prop.ScaleIteration = 0
			timer.Create( "scale_overtime"..tostring(id), 1/fps, chunks, function()
				if !prop:IsValid() then return end
				prop.ScaleIteration = prop.ScaleIteration + 1
				local n = prop.ScaleIteration/chunks
				SetScale(prop, Vector(scale[1]*n + oldscale[1]*(1-n), scale[2]*n + oldscale[2]*(1-n), scale[3]*n + oldscale[3]*(1-n)))
			end)
		else
			SetScale(prop,scale)
		end
		
		timer.Remove( "spawn_delay"..tostring(id) )
	end

	net.Receive("Expression2_Scales", function(len)
		local Scales, Speeds = net.ReadTable(), net.ReadTable()
		for id,scale in pairs(Scales) do
			local speed = Speeds[id]
			local prop = Entity(id)
			if !prop:IsValid() then
				timer.Create( "spawn_delay"..tostring(id), 0.35, 3, function() WorkScale(id, scale, speed) end)
			else
				WorkScale(id, scale, speed)
			end
		end
	end)
end