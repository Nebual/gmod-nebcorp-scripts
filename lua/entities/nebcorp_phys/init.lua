ENT.Type 		= "anim"
ENT.Base 		= "base_anim"
ENT.PrintName 	= "Nebcorp Physics"
ENT.Category	= "Nebcorp"
ENT.Author		= "Nebual"
ENT.Purpose		= ";D"
ENT.Instructions	= ""

ENT.Spawnable		= true
ENT.AdminSpawnable	= false

AddCSLuaFile( "cl_init.lua" )

function ENT:SpawnFunction(ply,tr)
	local Ent=ents.Create("nebcorp_phys")
	Ent:SetPos(tr.HitPos + tr.HitNormal*8)
	Ent:SetAngles(ply:GetAngles())
	Ent:Spawn()
	Ent:Activate()
	return Ent
end

function ENT:Initialize()
	self.Entity:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )
	if self:GetMaterial()=="" then self:SetMaterial("spacebuild/Floor5") end
    //self.Entity:PhysicsInit(SOLID_VPHYSICS)
	if self.radius then 
		self.size = Vector(self.radius,self.radius,1)
		//self.Entity:PhysicsInitSphere(self.radius)
	else
		if self.size then self.size = self.size / 2 else self.size = Vector(50,100,50) end
	end
	self.Entity:PhysicsInitBox(-self.size,self.size)
	
	self.Entity:SetCollisionBounds(-self.size,self.size)
	self.Entity:GetPhysicsObject():EnableMotion(false)
	self.Entity:SetSolid( SOLID_BBOX )
end