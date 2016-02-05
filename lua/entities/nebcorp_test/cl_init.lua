ENT.Type 		= "anim"
ENT.Base 		= "base_gmodentity"
ENT.PrintName 	= "Nebcorp Test Ent (varies)"
ENT.Category	= "Nebcorp"
ENT.Author		= "Nebual"
ENT.Purpose		= ";D"
ENT.Instructions	= ""

ENT.Spawnable		= true
ENT.AdminSpawnable	= false

ENT.RenderGroup = RENDERGROUP_OPAQUE
/*
local function PushQuad()
	mesh.Position( Vector( 0, 0, 0 ) );
	mesh.Normal( Vector( 0, 0, 1 ) );
	//mesh.TexCoord( 0, 0, 0 );
	mesh.Color( 255, 0, 0, 255 );
	mesh.AdvanceVertex();
end*/
local num = 2 ^ 0.5 / 2 // 0.707106781
local directions = {Vector(0,0,1),Vector(0,0,-1),Vector(1,0,0),Vector(-1,0,0),Vector(0,1,0),Vector(0,-1,0)}
local positions = {Vector(num,num,0),Vector(-num,num,0),Vector(-num,-num,0),Vector(num,-num,0)}
function ENT:Initialize()
	self:SetModel("models/props_phx/construct/metal_tube.mdl")
end
function ENT:Draw( )
	self:DrawModel( )
 /*
	cam.Start3D(LocalPlayer():EyePos(),LocalPlayer():EyeAngles())
        render.SetMaterial( Material( "phoenix_storms/plastic" ) )
		for k,v in pairs(directions) do
			render.DrawQuadEasy( Vector(0,0,0),    --position of the rect
			v,        --direction to face in
			64, 64,              --size of the rect
			Color( 255, 255, 255, 255 ),  --color
			90                     --rotate 90 degrees
			) 
		end
    cam.End3D()*/
	
		

		//render.SuppressEngineLighting( false )
	/*
	cam.Start3D(LocalPlayer():EyePos(),LocalPlayer():EyeAngles())
        render.SetMaterial( Material( "sprites/blueglow2" ) )
        render.DrawQuadEasy( Vector(0,0,0),    --position of the rect
        Vector(0,0,-1),        --direction to face in
        128, 128,              --size of the rect
        Color( 255, 255, 255, 255 ),  --color
        90                     --rotate 90 degrees
        ) 
    cam.End3D()*/
end