language.Add("Undone_e2_spawned_prop", "E2 Spawned Prop")
language.Add("Undone_e2_spawned_collision", "E2 Spawned Collision Prop")

/*
local function E2CameraSetup( ply, handle, id, encoded, decoded )
	if !LocalPlayer().E2Camera then LocalPlayer().E2Camera = {} end
	LocalPlayer().E2Camera[encoded.id] = encoded
end
datastream12.Hook( "E2Camera", E2CameraSetup )

local function E2Camera()
	if not LocalPlayer().E2Camera then return end 
	//surface.SetDrawColor( 0, 0, 0, 255 )
	//surface.DrawRect( 0, 0, ScrW(), ScrH() )
	//for i = 1, 6 do
		if LocalPlayer().E2Camera[1] then
			encoded = LocalPlayer().E2Camera[1]
			local cam = {}
			cam.angles = encoded.angles
			cam.origin = encoded.pos
			local topleft = encoded.topleft
			local screenv = Vector(topleft[1], topleft[2], topleft[3]):ToScreen()
			cam.x = screenv["x"]
			cam.y = screenv["y"]
			local bottomright = encoded.bottomright
			local otherv = Vector(bottomright[1],bottomright[2],bottomright[3]):ToScreen()
			cam.w = math.Clamp(otherv["x"] - screenv["x"], 50, 500)
			cam.h = math.Clamp(screenv["y"] - otherv["y"], 50, 500)
			render.RenderView( cam )
		end
	//end
end
hook.Add("HUDPaint", "E2Camera", E2Camera)

local function E2CameraRemove( ply, handle, id, encoded, decoded )
	if !LocalPlayer().E2Camera then LocalPlayer().E2Camera = {} end
	LocalPlayer().E2Camera[encoded.id] = {}
end
datastream12.Hook( "E2CameraRemove", E2CameraRemove )*/


local function SetCollisionScale(prop,scale)
	local propmx = prop:OBBMaxs()
	local propmn = prop:OBBMins()
	propmx.x = scale.x*propmx.x
	propmx.y = scale.y*propmx.y
	propmx.z = scale.z*propmx.z
	propmn.x = scale.x*propmn.x
	propmn.y = scale.y*propmn.y
	propmn.z = scale.z*propmn.z
	prop:SetCollisionBounds( propmx, propmn )
end

usermessage.Hook("expression2_collisionscalemessage", function(um)
	local index = um:ReadShort()
	local scale = um:ReadVector()
	local prop  = ents.GetByIndex(index)
	if !prop:IsValid() then
		timer.Create( "spawn_delay"..tostring(index), 0.35, 3, function()
			local prop  = ents.GetByIndex(index)
			if !prop:IsValid() then return end
			SetCollisionScale(prop,scale)
			timer.Remove( "spawn_delay"..tostring(index) )
		end)
		return
	end
	SetCollisionScale(prop,scale)
end)

//      ------------- JAKN RELATED ----------------
/*
local NoDrawListOld = {}
local function NoDrawSelectEnts( ply, handle, id, encoded, decoded )
	local NoDrawListNew = {}
	for k,v in ipairs(encoded) do
		if !NoDrawListOld[v] then
			local E = Entity(v)
			if E && E:IsValid() then E:SetNoDraw(true) end
		end
		NoDrawListNew[v] = true
	end
	for k,v in pairs(NoDrawListOld) do
		if !NoDrawListNew[k] then
			local E = Entity(k)
			if E && E:IsValid() then E:SetNoDraw(false) end
		end
	end
	NoDrawListOld = NoDrawListNew
end
datastream12.Hook( "NoDrawSelectEnts", NoDrawSelectEnts )

local DrawListOld = {}
local function DrawSelectEnts( ply, handle, id, encoded, decoded )
	local DrawListNew = {}
	for _,v in ipairs(encoded) do
		DrawListNew[v] = true
	end
	for k,_ in pairs(DrawListOld) do
		if !DrawListNew[k] then
			local E = Entity(k)
			if E && E:IsValid() then E:SetNoDraw(true) end
		end
	end
	for _,v in ipairs(encoded) do
		if !DrawListOld[v] then
			local E = Entity(v)
			if E && E:IsValid() then E:SetNoDraw(false) end
		end
	end
	DrawListOld = DrawListNew
end
datastream12.Hook( "DrawSelectEnts", DrawSelectEnts )
*/