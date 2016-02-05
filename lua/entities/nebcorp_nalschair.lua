AddCSLuaFile()
DEFINE_BASECLASS( "base_gmodentity" )

ENT.PrintName = "NALS Chair"
ENT.Author = "Nebual"
ENT.Purpose = "A chair you can stand in!"
ENT.Instructions	= ""

ENT.Category = "Nebcorp"
ENT.Spawnable = true
ENT.AdminSpawnable = false 
ENT.IsWire = true

if CLIENT then return end

function ENT:SpawnFunction( ply, tr )
	local ent = ents.Create("nebcorp_nalschair")
		ent:Spawn()
		ent:SetPos(tr.HitPos - Vector(0, 0, ent:OBBMins().z))
	return ent
end
	
function ENT:Initialize()

	self.Entity:SetModel( "models/hunter/plates/plate05x05.mdl" )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetUseType( SIMPLE_USE )

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
	
	self.Inputs = Wire_CreateInputs(self, { "HidePlayer" })
end
local warnedPlayers = {}
function ENT:Use( activator, caller )
	if not activator:IsPlayer() then return end
	print("Driver: "..tostring(self.Driver))
	if not IsValid(self.Driver) then
		self.Driver = activator
		activator.NalsEnt = self.Entity
		activator:SetMoveType(0)
		activator:SetAngles(self:GetAngles() + Angle(0,180,0))
		activator:SetPos(self:GetPos() + Vector(0,0,0))
		activator:SetParent(self.Entity)
		activator:SetGravity(0)
		activator:GodEnable()
		if self.HidePlayer then
			activator:SetNoDraw(true)
			activator:GetActiveWeapon():SetNoDraw(true)
		end
		activator:SetNotSolid(true)
		activator:GetPhysicsObject():SetMass(1)
		hook.Call("PlayerEnteredVehicle", GAMEMODE, activator, self.Entity, 1)
		if not warnedPlayers[activator] then
			warnedPlayers[activator] = true
			WireLib.AddNotify(activator, "Welcome to NALSChair, press Alt-E to get out!", NOTIFY_GENERIC, 7)
		end
	elseif self.Driver == activator then
		activator:SetParent()
		activator:SetMoveType(2)
		activator:SetPos(self:GetPos() + Vector(0,0,15))
		activator:SetAngles(self:GetAngles())
		activator:SetGravity(1)
		activator:GodDisable()
		activator:SetNoDraw(false)
		activator:GetActiveWeapon():SetNoDraw(false)
		activator:SetNotSolid(false)
		activator:GetPhysicsObject():SetMass(85)
		activator.NalsEnt = nil
		self.Driver = nil
		hook.Call("PlayerLeaveVehicle", GAMEMODE, activator, self.Entity)
	end
end

function ENT:Think()
	if IsValid(self.Driver) then
		self.Driver:SetPos(self:GetPos() + Vector(0,0,0))
		if self.HidePlayer and self.Driver:GetActiveWeapon():IsValid() then
			self.Driver:GetActiveWeapon():SetNoDraw(true)
		end
		if self.Driver:KeyDown(IN_USE) and self.Driver:KeyDown(IN_WALK) then self:Use(self.Driver,self.Driver,USE_ON,0) end
	end
end

function ENT:TriggerInput(iname, value)
	if (iname == "HidePlayer") then
		self.HidePlayer = value ~= 0
	end
end

if !oldIsVehicle then oldIsVehicle = FindMetaTable("Entity").IsVehicle end
if !oldInVehicle then oldInVehicle = FindMetaTable("Player").InVehicle end
if !oldGetVehicle then oldGetVehicle = FindMetaTable("Player").GetVehicle end
FindMetaTable("Entity").IsVehicle = function(self)
	if self:IsValid() and (oldIsVehicle(self) or self:GetClass() == "nebcorp_nalschair") then return true end
end
FindMetaTable("Player").InVehicle = function(self)
	if oldInVehicle(self) or (IsValid(self.NalsEnt) and self.NalsEnt:GetClass() == "nebcorp_nalschair") then return true end
end
FindMetaTable("Player").GetVehicle = function(self)
	if IsValid(self.NalsEnt) and self.NalsEnt:GetClass() == "nebcorp_nalschair" then return self.NalsEnt end
	return oldGetVehicle(self)
end
function ENT:GetDriver() return self.Driver or NULL end
ENT.GetPassenger = ENT.GetDriver


-- Wire Compatibility Shit
function ENT:OnRemove()
	Wire_Remove(self)
	if IsValid(self.Driver) then self:Use(self.Driver,self.Entity,USE_ON,0) end
end

function ENT:OnRestore() 
	Wire_Restored(self)
end

function ENT:BuildDupeInfo()
	return WireLib.BuildDupeInfo(self)
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	WireLib.ApplyDupeInfo( ply, ent, info, GetEntByID )
end

function ENT:PreEntityCopy()
	local DupeInfo = self:BuildDupeInfo()
	if(DupeInfo) then
		duplicator.StoreEntityModifier(self,"WireDupeInfo",DupeInfo)
	end
end

function ENT:PostEntityPaste(Player,Ent,CreatedEntities)
	if(Ent.EntityMods and Ent.EntityMods.WireDupeInfo) then
		Ent:ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, function(id) return CreatedEntities[id] end)
	end
end