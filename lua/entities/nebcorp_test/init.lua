ENT.Type 		= "anim"
ENT.Base 		= "base_gmodentity"
ENT.PrintName 	= "Nebcorp Test Ent (varies)"
ENT.Category	= "Nebcorp"
ENT.Author		= "Nebual"
ENT.Purpose		= ";D"
ENT.Instructions	= ""

ENT.Spawnable		= true
ENT.AdminSpawnable	= false

AddCSLuaFile( "cl_init.lua" )

function ENT:SpawnFunction(ply,tr)
	local Ent=ents.Create("nebcorp_test")
	Ent:SetPos(tr.HitPos + tr.HitNormal*8)
	Ent:SetAngles(ply:GetAngles())
	Ent:Spawn()
	Ent:Activate()
	return Ent
end

function ENT:Initialize()
	if !self.Entity:GetModel() || self.Entity:GetModel() == "" then self.Entity:SetModel("models/props_c17/oildrum001.mdl") end
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	//self.Entity:GetPhysicsObject():Wake()
	//self.Entity:GetPhysicsObject():SetMass(250)\
end