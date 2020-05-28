AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Hull Designator"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.Purpose         = "Toggles Hull Designator"
ENT.WireDebugName = "Hull Designator"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = WireLib.CreateInputs( self, {"Entity [ENTITY]", "On", "Height", "Gravity"} )
	self.NextTime = 0
	self.On = false
	self.Height = 100
	self.Gravity = 1
end

-- This function is called by the STOOL
function ENT:SendVars( Entity )
	self.Ent = Entity
	self:UpdateOverlay()
end

function ENT:TriggerInput( iname, value )
	if iname == "On" then
		self.On = value
	elseif iname == "Entity" then
		if IsValid(self.Ent) and self.Ent ~= value then
			GravHull.UnHull(self.Ent)
		end
		self.Ent = value
	elseif iname == "Height" then
		self.Height = value
	elseif iname == "Gravity" then
		self.Gravity = value
	end

	if IsValid(self.Ent) then
		if self.On then
			GravHull.RegisterHull(self.Ent, self.Height, self.Gravity)
			GravHull.UpdateHull(self.Ent, true)
		else
			GravHull.UnHull(self.Ent)
		end
	end
end

function ENT:UpdateOverlay()
	self:SetOverlayText(tostring(self.Ent)
		.. "\nOn: " .. tostring(self.On)
		.. "\nHeight: " ..tostring(self.Height)
		.. "\nGravity: " .. tostring(self.Gravity)
	)
end

function MakeWireHullDesignatorController( pl, Pos, Ang, model )
	local controller = ents.Create("gmod_wire_hulldesignator")

	controller:SetPos( Pos )
	controller:SetAngles( Ang )
	controller:SetModel( Model(model or "models/jaanus/wiretool/wiretool_siren.mdl") )
	controller:SetPlayer(pl)

	controller:Spawn()

	return controller
end
duplicator.RegisterEntityClass("gmod_wire_hulldesignator", MakeWireHullDesignatorController, "Pos", "Ang", "Model")

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if IsValid( self.Ent ) then
		info.Ent = self.Ent:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if info.Ent then
		self.Ent = GetEntByID(info.Ent)
		if not self.Ent then
			self.Ent = ents.GetByIndex(info.Ent)
		end
	end

	self:UpdateOverlay()
end
