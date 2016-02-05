AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "NCPainting"

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
end

util.AddNetworkString("FileTransfer")
util.AddNetworkString("NCPainting")
function SendFile(filename, ply)
	//local f = file.Open("showcase/"..filepath,"rb","DATA")
	local f = file.Open(filename,"rb","DATA")
	local numpackets = math.ceil(f:Size() / 60000)
	for i=1,numpackets do
		net.Start("FileTransfer")
			net.WriteString(filename)
			net.WriteUInt(numpackets,16)
			local datastr = f:Read(60000)
			net.WriteUInt(#datastr,16)
			net.WriteData(datastr,#datastr)
		if ply then net.Send(ply) else net.Broadcast() end
	end
end
concommand.Add("ncpainting_refresh",function(ply,cmd,args)
	net.Start("NCPainting")
		net.WriteUInt(args[1],16)
		net.WriteString(args[2])
	net.Send(ply)
end)
concommand.Add("file_request",function(ply,cmd,args)
	SendFile(args[1],ply)
end)

function ENT:Use(ply)
	timer.Create("NCPaintinguse_"..ply:EntIndex(),1,1,function()
		if ply:IsValid() && self:IsValid() then
			if ply:KeyDown(IN_USE) then
				if self.Dupepath then
					net.Start("ncpainting_dupe")
						net.WriteString(self.Dupepath)
					net.Send(ply)
				end
			else
				if self.Filepath then
					net.Start("NCPainting")
						net.WriteUInt(self:EntIndex(),16)
						net.WriteString(self.Filepath)
					net.Send(ply)
				end
			end
		end
	end)
end

//filepath = krystal24_90x75
function ENT:Setup(filepath, dupepath)
	if filepath then
		if string.Right(filepath,4) != ".txt" then filepath = filepath .. ".txt" end
		if file.Exists("showcase/"..filepath,"DATA") then
			self.Filepath = filepath
			net.Start("NCPainting")
				net.WriteUInt(self:EntIndex(),16)
				net.WriteString(filepath)
			net.Broadcast()
		end
	end
	if dupepath then
		if string.Right(dupepath,4) != ".txt" then dupepath = dupepath .. ".txt" end
		if file.Exists("adv_duplicator/-Public Folder-/Showcase/"..dupepath,"DATA") then
			self.Dupepath = dupepath
		end
	end
end
hook.Add("PlayerInitialSpawn","NCPainting_initsend",function(ply)
	for _,ent in pairs(ents.FindByClass("gmod_wire_digitalscreen2")) do
		if ent:IsValid() && ent.Filepath then 
			net.Start("NCPainting")
				net.WriteUInt(ent:EntIndex(),16)
				net.WriteString(ent.Filepath)
			net.Send(ply)
		end
	end
end)
//lr local ply = FindPlayer("Neb") MakeWireDigitalScreen2(ply,ply:GetShootPos()+ply:GetAimVector()*30,Angle(),"models/kobilica/wiremonitorbig.mdl",32,32)
util.AddNetworkString("ncpainting_dupe")
function MakeNCPainting( pl, Pos, Ang, model, Filepath, Dupepath )

	if ( !pl:CheckLimit( "wire_ncpainting" ) ) then return false end

	local ent = ents.Create( "ncpainting" )
	if (!ent:IsValid()) then return false end
	ent:SetModel(model)

	ent:SetAngles( Ang )
	ent:SetPos( Pos )
	ent:Spawn()

	ent:SetPlayer(pl)

	pl:AddCount( "wire_ncpainting", ent )
	
	ent:Setup(Filepath, Dupepath)

	return ent
end
duplicator.RegisterEntityClass("ncpainting", MakeNCPainting, "Pos", "Ang", "Model", "Filepath","Dupepath")