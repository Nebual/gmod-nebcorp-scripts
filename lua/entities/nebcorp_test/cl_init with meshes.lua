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
//BONK = gl-------------on.decode("23.725002288818-23.724998474121-23.72500038147-23.724998474121-23.72500228881823.7250003814723.725002288818-23.72499847412123.72500038147-23.724998474121-23.725002288818-23.72500038147-23.724998474121-23.72500228881823.7250003814723.725002288818-23.724998474121-23.7250003814723.72499847412123.72500228881823.7250003814723.72499847412123.725002288818-23.7250003814723.725002288818-23.72499847412123.7250003814723.72499847412123.725002288818-23.7250003814723.725002288818-23.724998474121-23.7250003814723.725002288818-23.72499847412123.7250003814723.72499847412123.725002288818-23.72500038147-23.724998474121-23.725002288818-23.7250003814723.725002288818-23.724998474121-23.72500038147-23.72500228881823.724998474121-23.72500038147-23.724998474121-23.725002288818-23.7250003814723.72499847412123.725002288818-23.72500038147-23.72500228881823.724998474121-23.72500038147-23.724998474121-23.72500228881823.72500038147-23.724998474121-23.725002288818-23.72500038147-23.72500228881823.72499847412123.72500038147-23.724998474121-23.72500228881823.72500038147-23.72500228881823.724998474121-23.72500038147-23.72500228881823.72499847412123.72500038147-23.72500228881823.724998474121-23.7250003814723.72499847412123.72500228881823.72500038147-23.72500228881823.724998474121-23.7250003814723.72499847412123.725002288818-23.7250003814723.72499847412123.72500228881823.72500038147-23.72500228881823.72499847412123.7250003814723.72499847412123.72500228881823.72500038147-23.724998474121-23.72500228881823.7250003814723.72499847412123.72500228881823.7250003814723.725002288818-23.72499847412123.72500038147-23.724998474121-23.72500228881823.72500038147")
local newtab = {}
for k,v in pairs(BONK) do
	for i=1,3 do table.insert(newtab,{pos = v[i], normal = vector_up}) end
end
local oldmesh = NewMesh()
 //local meshtable = {}
	//for k,v in pairs(directions) do
		/*mesh.Begin( MATERIAL_QUADS, k )
			mesh.QuadEasy( v, v, 2, 2 )
		mesh.End( ) */
		/*for _,pos in ipairs(positions) do
			table.insert(meshtable, {pos = pos:Rotate(v), normal = v})
		end
	end*/
oldmesh:BuildFromTriangles(newtab)
PrintTable(newtab)


function ENT:Draw( )
	//self:DrawModel( )
 
	local matrix = Matrix( )
	matrix:Translate( self:GetPos( ) )
	matrix:Rotate( self:GetAngles( ) )
	//matrix:Scale(Vector(32,32,32))
 
	cam.PushModelMatrix( matrix )
 
		render.SetMaterial( Material( "phoenix_storms/plastic" ) )
		//local oldmesh = NewMesh()
		//oldmesh:BuildFromTriangles(newtab)
		oldmesh:Draw()
 
	cam.PopModelMatrix( )
end