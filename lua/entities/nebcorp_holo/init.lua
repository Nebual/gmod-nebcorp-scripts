ENT.Type 		= "anim"
ENT.Base 		= "base_anim"
ENT.PrintName 	= "Nebcorp Hologram"
ENT.Category	= "Nebcorp"
ENT.Author		= "Nebual"
ENT.Purpose		= ";D"
ENT.Instructions	= ""

ENT.Spawnable		= true
ENT.AdminSpawnable	= false

AddCSLuaFile( "cl_init.lua" )

function ENT:SpawnFunction(ply,tr)
	local Ent=ents.Create("nebcorp_holo")
	Ent:SetModel( "models/Combine_Helicopter/helicopter_bomb01.mdl" )
	Ent:SetPos(tr.HitPos + tr.HitNormal*8)
	Ent:SetAngles(ply:GetAngles())
	Ent:Spawn()
	Ent:Activate()
	return Ent
end

function ENT:Initialize()
	//if self:GetMaterial()=="" then self:SetMaterial("spacebuild/Floor5") end
    self.Entity:PhysicsInit(SOLID_VPHYSICS)
	self.Entity:GetPhysicsObject():EnableMotion(false)
	self.Entity:SetSolid( SOLID_VPHYSICS )
end

util.AddNetworkString("NCPhys_Dyn")
function ENT:HoloCreate(maintab)
	self.holodata =  maintab
	net.Start("NCPhys_Dyn") net.WriteEntity(self.Entity) net.WriteTable(maintab) net.Broadcast()
end

function holoCompile(baseprop, entities)
	local maintab = {}
	for k,v in pairs(entities) do
		local tab = {}
		tab.pos = baseprop:WorldToLocal(v:GetPos())
		tab.ang = baseprop:WorldToLocalAngles(v:GetAngles())
		if v.data && v.data.Scale then tab.scale = v.data.Scale else tab.scale = Vector(1,1,1) end
		tab.model = v:GetModel()
		if v:GetMaterial() != "" then tab.material = v:GetMaterial() end
		tab.color = v:GetColor()
		table.insert(maintab,tab)
	end
	local tab = {}
	if baseprop.data && baseprop.data.Scale then tab.scale = baseprop.data.Scale else tab.scale = Vector(1,1,1) end
	tab.model = baseprop:GetModel()
	if baseprop:GetMaterial() != "" then tab.material = baseprop:GetMaterial() end
	tab.color = baseprop:GetColor()
	maintab[0] = tab
	
	return maintab
end

function holoSpawn(maintab,pos,ply)
	local baseproptab = maintab[0]
	local ent = ents.Create("nebcorp_holo")
	//tab = table.Copy(maintab)
	ent:SetModel(baseproptab.model)
	if baseproptab.material then ent:SetMaterial(baseproptab.material) end
	ent:SetColor(baseproptab.color)
	SetScale(ent,baseproptab.scale)
	ent:SetPos(pos)
	ent:Spawn()
	if ply then
		//gamemode.Call( "PlayerSpawnedProp", ply, maintab[0], ent )
		NADMOD.PlayerMakePropOwner(ply,ent)
		ply:AddCleanup( "props", ent )
		undo.Create("E2 Spawned Holographic") //e2_spawned_collision
			undo.AddEntity( ent )
			undo.SetPlayer( ply )
		undo.Finish()
	end
	ent:HoloCreate(maintab)
	return ent
end

function holoSpawnProps(maintab,pos,ply)
	local baseproptab = maintab[0]
	local baseprop = ents.Create("prop_physics")
	baseprop:SetModel(baseproptab.model)
	if baseproptab.material then baseprop:SetMaterial(baseproptab.material) end
	baseprop:SetColor(baseproptab.color)
	SetScale(baseprop,baseproptab.scale)
	baseprop:SetPos(pos)
	baseprop:Spawn()
	baseprop:GetPhysicsObject():EnableMotion(false)
	if ply then
		NADMOD.PlayerMakePropOwner(ply,baseprop)
		ply:AddCleanup( "props", baseprop )
		undo.Create("E2 Spawned Holographic") //e2_spawned_collision
		undo.AddEntity( baseprop )
		undo.SetPlayer( ply )
	end
	local temptab = table.Copy(maintab)
	temptab[0] = nil
	for k,v in pairs(temptab) do
		local ent = ents.Create("prop_physics")
		ent:SetModel(v.model)
		if v.material then ent:SetMaterial(v.material) end
		ent:SetColor(v.color)
		SetScale(ent,v.scale)
		ent:SetPos(baseprop:LocalToWorld(v.pos))
		ent:SetAngles(baseprop:LocalToWorldAngles(v.ang))
		ent:Spawn()
		ent:GetPhysicsObject():EnableMotion(false)
		if ply then
			NADMOD.PlayerMakePropOwner(ply,ent)
			undo.AddEntity( ent )
		end
	end
	
	if ply then undo.Finish() end
	return ent
end

function ENT:PreEntityCopy()
	duplicator.StoreEntityModifier(self,"holodata",self.holodata)
end
function ENT:PostEntityPaste( Player, Ent, CreatedEntities )
	local maintab = Ent.EntityMods.holodata
	if maintab then
		self.holodata = maintab
		net.Start("NCPhys_Dyn") net.WriteEntity(self.Entity) net.WriteTable(maintab) net.Broadcast()
	end
end

hook.Add("PlayerInitialSpawn","Holos_Refresh",function(ply)
	for k,v in pairs(ents.FindByClass("nebcorp_holo")) do if v.holodata then net.Start("NCPhys_Dyn") net.WriteEntity(v) net.WriteTable(v.holodata) net.Send(ply) end end
end)