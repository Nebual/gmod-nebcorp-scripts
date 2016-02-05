
ENT.RenderGroup    = RENDERGROUP_BOTH


function ENT:Initialize()
	self.Memory1 = {}
	self.Memory2 = {}

	self.LastClk = true
	self.NewClk = true
	self.Memory1[1048575] = 1
	self.Memory2[1048575] = 1
	self.NeedRefresh = true
	self.IsClear = true
	self.ClearQueued = false
	self.RefreshPixels = {}
	self.RefreshRows = {}

	self.ScreenWidth = 32
	self.ScreenHeight = 32

	for i=1,self.ScreenHeight do
		self.RefreshRows[i] = i-1
	end
	for i=1,self.ScreenHeight do
		self.RefreshRows[i] = i-1
	end

	//0..786431 - RGB data

	//1048569 - Color mode (0: RGBXXX; 1: R G B)
	//1048570 - Clear row
	//1048571 - Clear column
	//1048572 - Screen Height
	//1048573 - Screen Width
	//1048574 - Hardware Clear Screen
	//1048575 - CLK

	self.GPU = WireGPU(self.Entity)
end

function ENT:OnRemove()
	self.GPU:Finalize()
	self.NeedRefresh = true
end

net.Receive("ncpainting_dupe",function(len)
	RunConsoleCommand("gmod_tool","adv_duplicator")
	RunConsoleCommand("adv_duplicator_open_dir","adv_duplicator/-Public Folder-/Showcase")
	RunConsoleCommand("adv_duplicator_load_filename",net.ReadString())
	RunConsoleCommand("adv_duplicator_open")
end)

local filecache = {}
net.Receive("FileTransfer",function(len)
	local filepath = net.ReadString()
	filecache[filepath] = filecache[filepath] or {count = 0, buffer = ""}
	local cache = filecache[filepath]
	
	local numpackets = net.ReadUInt(16)
	local size = net.ReadUInt(16)
	cache.buffer = cache.buffer .. net.ReadData(size)
	cache.count = cache.count + 1
	if cache.count == numpackets then
		file.CreateDir(string.GetPathFromFilename(filepath),"DATA")
		local f = file.Open(filepath,"wb","DATA")
		f:Write(cache.buffer)
		f:Close()
		filecache[filepath] = nil
	end
end)

net.Receive("NCPainting",function(len)
	local id, filepath = net.ReadUInt(16), net.ReadString()
	if !file.Exists("showcase/"..filepath,"DATA") then 
		RunConsoleCommand("file_request","showcase/"..filepath)
		timer.Create("NCPaintingDelayRerequest_"..id,0.5,1,function()
			RunConsoleCommand("ncpainting_refresh",id,filepath)
		end)
	else
		local ent = Entity(id)
		if ent:IsValid() then 
			if ent.Filepath != filepath then 
				ent:LoadFile(filepath) 
			else
				timer.Create("ncpainting_refresh_"..ent:EntIndex(),0.15,file.Size("showcase/"..filepath,"rb","DATA")/4/8000, function() 
					if ent:IsValid() then ent:WriteCell(1048575,1) end 
				end)
			end
		else 
			timer.Create("NCPainting_Loadfiledelay_"..id,0.33,3,function() 
				if Entity(id):IsValid() then
					Entity(id):LoadFile(filepath) 
					timer.Remove("NCPainting_Loadfiledelay_"..id)
				end
			end)
		end
	end
end)
function ENT:LoadFile(filepath)
	self.Filepath = filepath
	local x = tonumber(filepath:sub(string.find(filepath,"_",1,true)+1,string.find(filepath,"x",string.find(filepath,"_",1,true),true)-1))
	local y = tonumber(filepath:sub(string.find(filepath,"x",string.find(filepath,"_",1,true),true)+1,-4))
	self:WriteCell(1048573,x)
	self:WriteCell(1048572,y)
	self:WriteCell(1048569,2)
	self:WriteCell(1048574,0)
	self:WriteCell(1048575,1)
	local f = file.Open("showcase/"..filepath,"rb","DATA")
	local size = f:Size()/4
	
	local entMemory2 = self.Memory2
	self:WriteCell(1048575,0)
	self.IsClear = false
	for i=1,size do
		entMemory2[i] = f:ReadLong()
	end
	timer.Create("ncpainting_refresh_"..self:EntIndex(),0.15,size/8000,function() if self:IsValid() then self:WriteCell(1048575,1) end end)
end

function ENT:WriteCell(Address,value)
	if Address < 0 then return false end
	if Address >= 1048576 then return false end

	if Address == 1048575 then
		self.NewClk = value ~= 0
	elseif Address < 1048500 then
		self.IsClear = false
	end

	if (self.NewClk) then
		self.Memory1[Address] = value -- visible buffer
		self.NeedRefresh = true
		if self.Memory1[1048569] == 1 then -- R G B mode
			local pixelno = math.floor(Address/3)
			if self.RefreshPixels[#self.RefreshPixels] ~= pixelno then
				self.RefreshPixels[#self.RefreshPixels+1] = pixelno
			end
		else -- other modes
			self.RefreshPixels[#self.RefreshPixels+1] = Address
		end
	end
	self.Memory2[Address] = value -- invisible buffer

	if Address == 1048574 then
		local mem1,mem2 = {},{}
		for addr = 1048500,1048575 do
			mem1[addr] = self.Memory1[addr]
			mem2[addr] = self.Memory2[addr]
		end
		self.Memory1,self.Memory2 = mem1,mem2
		self.IsClear = true
		self.ClearQueued = true
		self.NeedRefresh = true
	elseif Address == 1048572 then
		self.ScreenHeight = value
		if not self.IsClear then
			self.NeedRefresh = true
			for i = 1,self.ScreenHeight do
				self.RefreshRows[i] = i-1
			end
		end
	elseif Address == 1048573 then
		self.ScreenWidth = value
		if not self.IsClear then
			self.NeedRefresh = true
			for i = 1,self.ScreenHeight do
				self.RefreshRows[i] = i-1
			end
		end
	end

	if self.LastClk ~= self.NewClk then
		-- swap the memory if clock changes
		self.LastClk = self.NewClk
		self.Memory1 = table.Copy(self.Memory2)

		self.NeedRefresh = true
		for i=1,self.ScreenHeight do
			self.RefreshRows[i] = i-1
		end
	end
	return true
end

local transformcolor = {}
transformcolor[0] = function(c) -- RGBXXX
	local crgb = math.floor(c / 1000)
	local cgray = c - math.floor(c / 1000)*1000

	cb = cgray+28*math.fmod(crgb, 10)
	cg = cgray+28*math.fmod(math.floor(crgb / 10), 10)
	cr = cgray+28*math.fmod(math.floor(crgb / 100), 10)

	return cr, cg, cb
end
transformcolor[2] = function(c) -- 24 bit mode
	cb = math.fmod(c, 256)
	cg = math.fmod(math.floor(c / 256), 256)
	cr = math.fmod(math.floor(c / 65536), 256)

	return cr, cg, cb
end
transformcolor[3] = function(c) -- RRRGGGBBB
	cb = math.fmod(c, 1000)
	cg = math.fmod(math.floor(c / 1e3), 1000)
	cr = math.fmod(math.floor(c / 1e6), 1000)

	return cr, cg, cb
end

local floor = math.floor

function ENT:RedrawPixel(a)
	if a >= self.ScreenWidth*self.ScreenHeight then return end

	local cr,cg,cb

	local x = a % self.ScreenWidth
	local y = math.floor(a / self.ScreenWidth)

	local colormode = self.Memory1[1048569] or 0

	if colormode == 1 then
		cr = self.Memory1[a*3  ] or 0
		cg = self.Memory1[a*3+1] or 0
		cb = self.Memory1[a*3+2] or 0
	else
		local c = self.Memory1[a] or 0
		cr, cg, cb = (transformcolor[colormode] or transformcolor[0])(c)
	end

	local xstep = (512/self.ScreenWidth)
	local ystep = (512/self.ScreenHeight)

	surface.SetDrawColor(cr,cg,cb,255)
	local tx, ty = floor(x*xstep), floor(y*ystep)
	surface.DrawRect( tx, ty, floor((x+1)*xstep-tx), floor((y+1)*ystep-ty) )
end

function ENT:RedrawRow(y)
	local xstep = (512/self.ScreenWidth)
	local ystep = (512/self.ScreenHeight)
	if y >= self.ScreenHeight then return end
	local a = y*self.ScreenWidth

	local colormode = self.Memory1[1048569] or 0

	for x = 0,self.ScreenWidth-1 do
		local cr,cg,cb

		if (colormode == 1) then
			cr = self.Memory1[(a+x)*3  ] or 0
			cg = self.Memory1[(a+x)*3+1] or 0
			cb = self.Memory1[(a+x)*3+2] or 0
		else
			local c = self.Memory1[a+x] or 0
			cr, cg, cb = (transformcolor[colormode] or transformcolor[0])(c)
		end

		surface.SetDrawColor(cr,cg,cb,255)
		local tx, ty = floor(x*xstep), floor(y*ystep)
		surface.DrawRect( tx, ty, floor((x+1)*xstep-tx), floor((y+1)*ystep-ty) )
	end
end

function ENT:Draw()
	self.Entity:DrawModel()

	if self.NeedRefresh then
		self.NeedRefresh = false

		self.GPU:RenderToGPU(function()
			local pixels = 0
			local idx = 1

			if self.ClearQueued then
				surface.SetDrawColor(0,0,0,255)
				surface.DrawRect(0,0, 512,512)
				self.ClearQueued = false
			end

			if (#self.RefreshRows > 0) then
				idx = #self.RefreshRows
				while ((idx > 0) and (pixels < 8192)) do
					self:RedrawRow(self.RefreshRows[idx])
					self.RefreshRows[idx] = nil
					idx = idx - 1
					pixels = pixels + self.ScreenWidth
				end
				if (idx == 0) then
					self.RefreshRows = {}
				end
			else
				idx = #self.RefreshPixels
				while ((idx > 0) and (pixels < 8192)) do
					self:RedrawPixel(self.RefreshPixels[idx])
					self.RefreshPixels[idx] = nil
					idx = idx - 1
					pixels = pixels + 1
				end
				if (idx == 0) then
					self.RefreshRows = {}
				end
			end
		end)

	end

	if EmuFox then return end

	self.GPU:Render()
	Wire_Render(self.Entity)
end

function ENT:IsTranslucent()
	return true
end
