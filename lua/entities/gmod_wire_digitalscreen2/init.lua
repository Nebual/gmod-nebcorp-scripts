AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "DigitalScreen2"

function ENT:Initialize()

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.Inputs = Wire_CreateInputs(self, { "PixelX", "PixelY", "PixelG", "Clk", "FillColor", "ClearRow", "ClearCol" })
	self.Outputs = Wire_CreateOutputs(self, { "Memory" })

	self.Memory = {}

	self.PixelX = 0
	self.PixelY = 0
	self.PixelG = 0
	self.Memory[1048575] = 1

	self.ScreenWidth = 32
	self.ScreenHeight = 32
	self.ChangedCellsSmall = {}
end

function ENT:SetDigitalSize(ScreenWidth, ScreenHeight)
	self:WriteCell(1048572, ScreenHeight)
	self:WriteCell(1048573, ScreenWidth)
end

function ENT:SendPixel()
	if self.Memory[1048575] == 0 then return end -- why?
	if self.PixelX < 0 then return end
	if self.PixelY < 0 then return end
	if self.PixelX >= self.ScreenWidth then return end
	if self.PixelY >= self.ScreenHeight then return end

	local address = self.PixelY*self.ScreenWidth + self.PixelX
	self:WriteCell(address, self.PixelG)
end

function ENT:ReadCell(Address)
	if Address < 0 then return nil end
	if Address >= 1048576 then return nil end

	return self.Memory[Address] or 0
end

function ENT:FlushCache()
	if next(self.ChangedCellsSmall) then
		net.Start("wire_digitalscreen2")
			net.WriteEntity(self.Entity)
			local count = math.Min(table.Count(self.ChangedCellsSmall),11000) -- Each pixel is 44 bits, or 5.5 bytes, and the max net size is 64kb.
			local netWriteUInt, next, tab = net.WriteUInt, next, self.ChangedCellsSmall -- Localize the function for speed
			netWriteUInt(count, 20)
			for i=1,count do
				local k,v = next(tab)
				tab[k]=nil
				netWriteUInt(k,20)
				netWriteUInt(v,24)
			end
		net.Broadcast()
	end
end

util.AddNetworkString("wire_digitalscreen2")
util.AddNetworkString("wire_digitalscreen2_ordered")
function ENT:RefreshClient(ply)
	net.Start("wire_digitalscreen2")
		net.WriteEntity(self)
		net.WriteUInt(5,20)
		net.WriteUInt(1048573,20) net.WriteUInt(self.Memory[1048573],24)
		net.WriteUInt(1048572,20) net.WriteUInt(self.Memory[1048572],24)
		net.WriteUInt(1048569,20) net.WriteUInt(self.Memory[1048569],24)
		net.WriteUInt(1048574,20) net.WriteUInt(self.Memory[1048574],24)
		net.WriteUInt(1048575,20) net.WriteUInt(self.Memory[1048575],24)
	net.Send(ply)
	local size = #self.Memory
	local numpackets = math.ceil(size/21000)
	for ball=1,size, 21000 do
		net.Start("wire_digitalscreen2_ordered")
			net.WriteEntity(self)
			local count = 21000
			if math.ceil(ball/21000) == numpackets then count = size - ball+1 end
			net.WriteUInt(ball, 20)
			net.WriteUInt(count, 20)
			local netWriteUInt, tab = net.WriteUInt, self.Memory
			for i=ball,ball+count do
				netWriteUInt(tab[i],24)
			end
		net.Send(ply)
	end
end
function SendInitialDigitalScreen2(ply)
	for _,ent in pairs(ents.FindByClass("gmod_wire_digitalscreen2")) do
		if ent:IsValid() then ent:RefreshClient(ply) end
	end
end
hook.Add("PlayerInitialSpawn","Wire_DigitalScreen2_initsend",SendInitialDigitalScreen2)
concommand.Add("refdigi2",SendInitialDigitalScreen2)

function ENT:ClearPixel(i)
	if self.Memory[1048569] == 1 then
		-- R G B mode
		self.Memory[i*3] = 0
		self.Memory[i*3+1] = 0
		self.Memory[i*3+2] = 0
		return
	end

	-- other modes
	self.Memory[i] = 0
end

function ENT:ClearCellRange(start, length)
	for i = start, start + length - 1 do
		self.Memory[i] = 0
	end
end

function ENT:WriteCell(Address, value)
	Address = math.floor (Address)
	if Address < 0 or Address >= 1048576 then return false end

	if Address < 1048500 then -- RGB data
		if self.Memory[Address] == value or
		   (value == 0 and self.Memory[Address] == nil) then
			return true
		end
	else
		if Address == 1048569 then -- Color mode (0: RGBXXX; 1: R G B; 2: 24 bit RGB; 3: RRRGGGBBB)
			-- not needed (yet)
		elseif Address == 1048570 then -- Clear row
			local row = math.Clamp(math.floor(value), 0, self.ScreenHeight-1)
			if self.Memory[1048569] == 1 then
				self:ClearCellRange(row*self.ScreenWidth*3, self.ScreenWidth*3)
			else
				self:ClearCellRange(row*self.ScreenWidth, self.ScreenWidth)
			end
		elseif Address == 1048571 then -- Clear column
			local col = math.Clamp(math.floor(value), 0, self.ScreenWidth-1)
			for i = col,col+self.ScreenWidth*(self.ScreenHeight-1),self.ScreenWidth do
				self:ClearPixel(i)
			end
		elseif Address == 1048572 then -- Height
			self.ScreenHeight = math.Clamp(math.floor(value), 1, 512)
		elseif Address == 1048573 then -- Width
			self.ScreenWidth  = math.Clamp(math.floor(value), 1, 512)
		elseif Address == 1048574 then -- Hardware Clear Screen
			local mem = {}
			for addr = 1048500,1048575 do
				mem[addr] = self.Memory[addr]
			end
			self.Memory = mem
			-- clear pixel data from usermessage queue
			self.ChangedCellsSmall = table.Copy(mem)
		elseif Address == 1048575 then -- CLK
			-- not needed atm
		end
	end

	self.Memory[Address] = value
	self.ChangedCellsSmall[Address] = value

	return true
end

function ENT:Think()
	self:FlushCache()
	self:NextThink(CurTime()+0.2)
	return true
end

function ENT:TriggerInput(iname, value)
	if (iname == "PixelX") then
		self.PixelX = math.floor(value)
		self:SendPixel()
	elseif (iname == "PixelY") then
		self.PixelY = math.floor(value)
		self:SendPixel()
	elseif (iname == "PixelG") then
		self.PixelG = math.floor(value)
		self:SendPixel()
	elseif (iname == "Clk") then
		self:WriteCell(1048575, value)
		self:SendPixel()
	elseif (iname == "FillColor") then
		self:WriteCell(1048574,value)
	elseif (iname == "ClearCol") then
		self:WriteCell(1048571,math.Clamp( value, 0, 31 ))
	elseif (iname == "ClearRow") then
		self:WriteCell(1048570,math.Clamp( value, 0, 31 ))
	end
end

function MakeWireDigitalScreen2( pl, Pos, Ang, model, ScreenWidth, ScreenHeight, Filepath, Dupepath )

	if ( !pl:CheckLimit( "wire_digitalscreens" ) ) then return false end

	local ent = ents.Create( "gmod_wire_digitalscreen2" )
	if (!ent:IsValid()) then return false end
	ent:SetModel(model)

	if (not ScreenWidth) then ScreenWidth = 32 end
	if (not ScreenHeight) then ScreenHeight = 32 end

	ent:SetAngles( Ang )
	ent:SetPos( Pos )
	ent:Spawn()
	ent:SetDigitalSize(ScreenWidth,ScreenHeight)

	ent:SetPlayer(pl)

	pl:AddCount( "wire_digitalscreens", ent )

	return ent
end
duplicator.RegisterEntityClass("gmod_wire_digitalscreen2", MakeWireDigitalScreen2, "Pos", "Ang", "Model", "ScreenWidth", "ScreenHeight")