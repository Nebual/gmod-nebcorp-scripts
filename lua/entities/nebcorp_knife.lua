AddCSLuaFile()
DEFINE_BASECLASS( "base_gmodentity" )

ENT.PrintName = "Melee Weapon"
ENT.Author = "Nebual"
ENT.Category = "Nebcorp"
ENT.Spawnable = true
ENT.AdminSpawnable = false

if CLIENT then return end

function ENT:SpawnFunction( ply, tr )
	local ent = ents.Create("nebcorp_knife")
		ent:Spawn()
		ent:SetPos(tr.HitPos - Vector(0, 0, ent:OBBMins().z))
	return ent
end
	
function ENT:Initialize()
	self.Entity:SetModel("models/weapons/w_models/w_knife.mdl") // TODO: Let them change model
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:DrawShadow( false )
	self.CDSIgnore = true
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end

	//timer.Create(self.Entity:EntIndex().."_Explode", self.Timer or 3, 1, function() if IsValid(self) then self:Explode() end end)
end

local nextcollide = 0
local knifesounds = {"weapons/knife/knife_hit1.wav","weapons/knife/knife_hit2.wav","weapons/knife/knife_hit3.wav","weapons/knife/knife_hit4.wav","weapons/knife/knife_hitwall1.wav","weapons/knife/knife_hitwall1.wav"}
function ENT:PhysicsCollide(data,phys)
	if nextcollide < CurTime() then
		nextcollide = CurTime() + 0.5
		self.Entity:EmitSound(Sound(table.Random(knifesounds)))
	end
	if !table.HasValue(constraint.GetAllConstrainedEntities(self.Entity), data.HitEntity) then
		data.HitEntity:TakeDamage(2 + (data.Speed / 8) )
		phys:ApplyForceCenter(phys:GetVelocity() * -0.8)
	end
end