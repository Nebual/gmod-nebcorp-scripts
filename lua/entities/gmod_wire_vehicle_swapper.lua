AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName		= "Wire Vehicle Swapper"
ENT.RenderGroup		= RENDERGROUP_BOTH
ENT.Purpose         = "Switches the passengers of two vehicles"
ENT.WireDebugName = "Vehicle Swapper"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self.Inputs = Wire_CreateInputs( self, { "Clk", "Clk2" } )
	self.NextTime = 0
end

-- This function is called by the STOOL
function ENT:SendVars( Ent1, Ent2 )
	self.Ent1 = Ent1
	self.Ent2 = Ent2
	self:UpdateOverlay()
end

function ENT:TriggerInput( iname, value )
	if iname == "Clk" or iname == "Clk2" then
		if value ~= 0 and self.NextTime < CurTime() then
			if IsValid(self.Ent1) and IsValid(self.Ent2) and self.Ent1:IsVehicle() and self.Ent2:IsVehicle() then
				local ply1, ply2 = self.Ent1:GetDriver(), self.Ent2:GetDriver()
				if IsValid(ply1) then ply1:ExitVehicle() end
				if IsValid(ply2) then ply2:ExitVehicle() end
				if IsValid(ply1) then ply1:EnterVehicle(self.Ent2) end
				if IsValid(ply2) then ply2:EnterVehicle(self.Ent1) end
				self.NextTime = CurTime() + 0.75
			end
		end
	end

end

function ENT:UpdateOverlay()
	self:SetOverlayText(tostring(self.Ent1).."\n"..tostring(self.Ent2))
end

function MakeWireVehicleSwapperController( pl, Pos, Ang, model )
	local controller = ents.Create("gmod_wire_vehicle_swapper")

	controller:SetPos( Pos )
	controller:SetAngles( Ang )
	controller:SetModel( Model(model or "models/jaanus/wiretool/wiretool_siren.mdl") )
	controller:SetPlayer(pl)

	controller:Spawn()

	return controller
end
duplicator.RegisterEntityClass("gmod_wire_vehicle_swapper", MakeWireVehicleSwapperController, "Pos", "Ang", "Model")

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	if IsValid( self.Ent1 ) then
		info.Ent1 = self.Ent1:EntIndex()
	end
	if IsValid( self.Ent2 ) then
		info.Ent2 = self.Ent2:EntIndex()
	end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	if info.Ent1 then
		self.Ent1 = GetEntByID(info.Ent1)
		if !self.Ent1 then
			self.Ent1 = ents.GetByIndex(info.Ent1)
		end
	end

	if info.Ent2 then
		self.Ent2 = GetEntByID(info.Ent2)
		if !self.Ent2 then
			self.Ent2 = ents.GetByIndex(info.Ent2)
		end
	end
	self:UpdateOverlay()
end
