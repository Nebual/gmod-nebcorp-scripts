ENT.Type 		= "anim"
ENT.Base 		= "base_anim"
ENT.PrintName 	= "Nebcorp Hologram"
ENT.Category	= "Nebcorp"
ENT.Author		= "Nebual"
ENT.Purpose		= ";D"
ENT.Instructions	= ""
ENT.Spawnable		= true
ENT.AdminSpawnable	= false
ENT.RenderGroup = RENDERGROUP_OPAQUE

/*
Interestingly, two consecutive DrawModels of the same ent require a SetModelScale in between (does that gen a new model?)
*/
function ENT:Initialize()
	self.Entity:DrawShadow( false )
	//self.Entity:SetModelScale( vector_origin )
	self.size = (self.Entity:OBBMaxs() - self.Entity:OBBMins())/2
	//self.Entity.RenderOverride = Draw
	//self.Entity.Draw = Draw
end

local mList = mList or {}
local mListSizes = util.JSONToTable(file.Read("nebcorp/mlist_sizes.txt") or "{}")
local Vector111 = Vector(1,1,1)

local function DrawDynamic(self)
	self:DrawModel()
	render.SetBlend(1)
	local mEnt, pos2, ang2
	local pos,ang=self:GetPos(),self:GetAngles()
	for k,v in pairs(self.holodata) do
		mEnt = mList[v.model]
		mEnt:SetMaterial(v.material or "")
		pos2,ang2 = LocalToWorld((v.pos or vector_origin),(v.ang or Angle()),pos,ang)
		mEnt:SetRenderOrigin(pos2)
		mEnt:SetRenderAngles(ang2)
		if v.scale then 
			if mEnt.EnableMatrix then
				local mat = Matrix()
				mat:Scale(v.scale)
				mEnt:EnableMatrix("RenderMultiply", mat)
			else
				mEnt:SetModelScale(v.scale.x)
			end
		end
		mEnt:DrawModel()
	end
end

local function processDynData(mainent, holodata)
	holodata[0] = nil
	mainent.holodata = holodata
	local updatedscalesdatabase,min2,max2
	local min,max = Vector(),Vector()
	for k,stuff in pairs(holodata) do
		if !mList[stuff.model] then
			local ent
			if !mListSizes[stuff.model] then
				ent = ents.Create("prop_physics")
				ent:SetModel(stuff.model)
				mListSizes[stuff.model]=ent:OBBMaxs() - ent:OBBMins()
				ent:Remove()
				updatedscalesdatabase=true
			end
			ent = ClientsideModel(stuff.model,RENDERGROUP_BOTH)
			ent:SetNoDraw(true)
			ent:DrawShadow(false)
			mList[stuff.model]=ent
		end
		// Caculate how big the renderbox should be!
		min2,max2 = stuff.pos - 0.5*mListSizes[stuff.model]*(stuff.scale or Vector111), stuff.pos + 0.5*mListSizes[stuff.model]*(stuff.scale or Vector111)
		if min2.x < min.x then min.x = min2.x end
		if min2.y < min.y then min.y = min2.y end
		if min2.z < min.z then min.z = min2.z end
		if max2.x > max.x then max.x = max2.x end
		if max2.y > max.y then max.y = max2.y end
		if max2.z > max.z then max.z = max2.z end
	end
	min2,max2 = mainent:OBBMins()*(mainent.OldScale or Vector111), mainent:OBBMaxs()*(mainent.OldScale or Vector111)
	if min2.x < min.x then min.x = min2.x end
	if min2.y < min.y then min.y = min2.y end
	if min2.z < min.z then min.z = min2.z end
	if max2.x > max.x then max.x = max2.x end
	if max2.y > max.y then max.y = max2.y end
	if max2.z > max.z then max.z = max2.z end
	mainent.RBmax, mainent.RBmin = max,min
	timer.Create("holo_updaterenderbounds"..decoded[1],0.5,1,function() if mainent:IsValid() then mainent:SetRenderBounds( mainent.RBmax, mainent.RBmin ) end end)
	mainent.RenderOverride = DrawDynamic
	mainent.Draw = DrawDynamic
	if updatedscalesdatabase then file.Write("nebcorp/mlist_sizes.txt",util.TableToJSON(mListSizes)) end
end
local function receiveDynData(handle, id, encoded, decoded)

end
net.Receive( "NCPhys_Dyn", function(len)
	local ent, tab = net.ReadEntity(), net.ReadTable()
	//If the datastream somehow got to the client faster than the entityspawned internals did, wait a second
	if !IsValid(ent) then timer.Create("NCPhys_ReceiveDyn_"..tostring(ent),1,1,function() processDynData(ent, tab) end) else processDynData(ent, tab) end
end)

concommand.Add("reload_holos",function(ply,cmd,args) 
	for k,v in pairs(ents.FindByClass("nebcorp_holo")) do
		v.Draw = DrawDynamic
		v.RenderOverride = DrawDynamic
	end
end)