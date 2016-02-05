local default_tab = {n={},ntypes={},s={},stypes={},size=0,istable=true,depth=3}

__e2setcost(100)

// ========================
// FILE READING/WRITING MODULE
// ==========================

require"glon"
// By Nebual

--- Returns the string stored serverside at <filepath>
e2function string fileReadString(string filepath)
	if string.sub(filepath, -4,-4) != "." then filepath = filepath .. ".txt" end
	if string.Left(filepath, 1) == "/" then filepath = string.Right(filepath, string.len(filepath)-1)
	else filepath = "e2storeddata/" .. filepath end
	local data = ""
	if file.Exists(filepath,"DATA") then data = file.Read(filepath,"DATA") end
	data = string.Replace( data, "[br]", "\n" )
	if data then return data else return "" end
end

--- Returns the array stored serverside at <filepath>
e2function array fileReadArray(string filepath)
	if string.Right(filepath, 4) != ".txt" then filepath = "e2storeddata/" .. filepath .. ".txt"
	else filepath = "e2storeddata/" .. filepath end
	
	if file.Exists(filepath,"DATA") then 
		// To get around the Infinite Loop Detected! error
		debug.sethook()
		return glon.decode(file.Read(filepath,"DATA"))
	else return {} 
	end
end

--- Returns the table stored serverside at <filepath>
e2function table fileReadTable(string filepath)
	if string.Right(filepath, 4) != ".txt" then filepath = "e2storeddata/" .. filepath .. ".txt"
	else filepath = "e2storeddata/" .. filepath end
	
	if file.Exists(filepath,"DATA") then 
		// To get around the Infinite Loop Detected! error
		debug.sethook()
		local tab = glon.decode(file.Read(filepath,"DATA"))
		if !tab then return table.Copy(default_tab) end
		if tab.size then return tab else 
			local ret = table.Copy(default_tab)
			for k,v in pairs(tab) do
				local vtype =  string.Left(type(v),1)
				if type(k) == "number" then
					ret.n[k] = v
					ret.ntypes[k] = vtype
				else
					ret.s[k] = v
					if vtype == "P" then vtype = "e" end
					ret.stypes[k] = vtype
				end
			end
			return ret
		end
	else return table.Copy(default_tab) 
	end
end

--- Writes the string <data> to a serverside file at <filepath>
e2function void fileWriteString(string filepath, string data)
	if string.Right(filepath, 4) != ".txt" then filepath = filepath .. ".txt" end
	if string.Left(filepath, 1) == "/" then filepath = string.Right(filepath, string.len(filepath)-1)
	else filepath = "e2storeddata/" .. filepath end
	data = string.Replace( data, "\n", "[br]" )
	file.Write(filepath, data)
end

--- Writes the array <data> to a serverside file at <filepath>
e2function void fileWriteArray(string filepath, array data)
	if string.Right(filepath, 4) != ".txt" then filepath = "e2storeddata/" .. filepath .. ".txt"
	else filepath = "e2storeddata/" .. filepath end
	
	// To get around the Infinite Loop Detected! error
	debug.sethook()
	file.Write(filepath, glon.encode(data))
end

--- Writes the table <data> to a serverside file at <filepath>
e2function void fileWriteTable(string filepath, table data)
	if string.Right(filepath, 4) != ".txt" then filepath = "e2storeddata/" .. filepath .. ".txt"
	else filepath = "e2storeddata/" .. filepath end
	
	// To get around the Infinite Loop Detected! error
	debug.sethook()
	file.Write(filepath, glon.encode(data))
end

e2function void fileCreateDir(string filepath)
	file.CreateDir(string.GetPathFromFilename("e2storeddata/" ..filepath),"DATA")
end

--- Returns an array of all filenames in directory <filepath>
e2function array fileList(string filepath)
	if string.Right(filepath, 1) != "/" then filepath = "e2storeddata/" .. filepath .. "/"
	else filepath = "e2storeddata/" .. filepath end
	local ret = file.Find(filepath .. "*.txt","DATA")
	table.sort(ret)
	return ret
end

local left = string.Left
local right = string.Right
--- Sorts a file list lul
e2function string fileListSort(array incoming, num)
	if !next(incoming) then return "" end
	local arr = {}
	local count = 0
	for k,v in ipairs(incoming) do
		local word = left(right(v, 21), 17)
		local value = ((tonumber(left(word, 2)) or 9) - 9)*365*31*24*60*60
		word = right(word, 14)
		value = value + tonumber(left(word, 2))*31*24*60*60
		word = right(word, 11)
		value = value + tonumber(left(word, 2))*24*60*60
		word = right(word, 8)
		value = value + tonumber(left(word, 2))*60*60
		word = right(word, 5)
		value = value + tonumber(left(word, 2))*60
		value = value + tonumber(right(word, 2))
		arr[k] = {value, v}
		count = k
	end

	local k = 0
	local arr2 = {}
	while k < num do
		k = k + 1
		local Greatest = 1
		local l = 0
		
		while l < count do
			l = l + 1 
			if arr[l] then
				if arr[l][1] > arr[Greatest][1] then Greatest = l end
			end
		end
		arr2[k] = arr[Greatest]
		table.remove(arr, Greatest)
	end
	
	return arr2[math.Min(num, #arr2)][2]
end

--- Returns an array of all directory names in directory <filepath>
e2function array fileListDir(string filepath)
	if string.Right(filepath, 1) != "/" then filepath = filepath .. "/" end
	local _,ret = file.Find("e2storeddata/" .. filepath .. "*","DATA")
	//local ret = {}
	//for _, v in pairs(list) do table.insert(ret, v) end
	table.sort(ret)
	return ret
end

--- Deletes the file stored serverside at <filepath>
e2function void fileDelete(string filepath)
	file.Delete("e2storeddata/" .. filepath)
end

--- Updates the MOTD
e2function void motdSet(string motd)
	MOTDUpdate(motd)
end

// ========================
// DUPE MODULE
// ==========================

__e2setcost(2)

--- Returns <this>'s entity table.
e2function table entity:entTable()
	if IsValid(this) then 
		local tab = table.Copy(default_tab)
		for k,v in pairs(this:GetTable()) do
			local vtype =  string.Left(type(v),1)
			if type(k) == "number" then
				tab.n[k] = v
				tab.ntypes[k] = vtype
			else
				if vtype == "P" then vtype = "e" end
				tab.stypes[k] = vtype
			end
		end
		tab.s = this:GetTable()
		if !tab.n then tab.n = {} end
		tab.size = 70
		return tab
	else return table.Copy(default_tab) end
end

--- Returns a nicely formatted string about the current date/time.
e2function string dupeTime()
	return os.date(" %y-%m-%d %H-%M-%S")
end

// ########
// Multiple Entity Saving
// ########

__e2setcost(50)
// Dear reader: Please take it to heart that all numbers, including 0, are "True" in an if statement. Cost me a month of troubleshooting D:

--- Performs a complete Advanced Duplication Copy of <Ent>, returning a table for saving. <extra> saves the chip too.
e2function table dupeCopy(entity Ent, extra)
	if !IsValid(Ent) then return {} end
	-- Lets Adv Dupe give us relevent Entity/Constraint data
	local ETable,CTable = AdvDupe.Copy( Ent, {}, {}, Ent:GetPos() )
	local CRet = {}
	
	local keepself, wipee2s
	local options = tostring(extra)
	local optlength = string.len(options)
	if optlength > 0 then keepself = tobool(string.Right(options, 1)) end
	if optlength > 1 then wipee2s = tobool(string.Left(string.Right(options, 2), 1)) end
	
	-- If we're not preserving the E2 chip, make sure its not saved
	local E2ID = self.entity:EntIndex()
	local ecount = 0
	for k,v in pairs(ETable) do
		ecount = ecount + 1
		
		if !keepself && k == E2ID then 
			ETable[k] = nil
		else
			if v.Class == "prop_vehicle_prisoner_pod" then
				if v.EntityMods then v.EntityMods["VehicleMemDupe"] = nil end
				if v.VehicleTable && v.VehicleTable.Members then v.VehicleTable.Members["HandleAnimation"] = nil end
			end
			/*
			if wipee2s && ent:GetClass() == "gmod_wire_expression2" then
				v["_vars"] = {}
			end
			*/
		end
	end
	local ccount = 0
	for _,v in pairs(CTable) do
		ccount = ccount + 1
		if !keepself && v.Type == "Weld" && (v.Entity[1].Index == E2ID || v.Entity[2].Index == E2ID) then v = nil
		elseif v.Type == "" then v = nil
		else
			-- The CTable needs to be reorganized, specifically the indexes must be removed and reset to be sequentially numerical.
			table.insert( CRet, v )
		end
	end
	
	local tracedata = {}
	local pos = Ent:GetPos()
	tracedata.start = pos
	tracedata.endpos = Vector(pos.x, pos.y, -30000)
	local alltab = constraint.GetAllConstrainedEntities(Ent)
	table.insert(alltab, Ent)
	tracedata.filter = alltab
	local trace = util.TraceLine(tracedata)
	
	-- Setup our single savable table
	local Ret = {
		n={},ntypes={},
		s = {
			ETable  = ETable,
			CTable  = CRet,
			HeadID  = Ent:EntIndex(),
			HeadPos = pos,
			ECount  = ecount,
			CCount  = ccount,
			Height  = pos.z - trace.HitPos.z
		},
		stypes={ETable="t",CTable="t",HeadID="n",HeadPos="v",ECount="n",CCount="c",Height="n"},
		size=7,istable=true,depth=2
	}
	return Ret
end

--- Pastes a dupeCopy <Master> at original location.
e2function void dupePaste(table tab)
	if !tab || !next(tab) || !next(tab.s) then return end
	local Master = tab.s
	if !Master["ECount"] then WireLib.ClientError("This dupe has no ents in it??", self.player) return end
	AdvDupe.SetPercentText( self.player, "Pasting" )
	AdvDupe.StartPaste( self.player, Master["ETable"], Master["CTable"], Master["HeadID"], Master["HeadPos"], Angle(0,0,0), Master["ECount"], Master["CCount"], false, false)
end
--- Pastes a dupeCopy <Master> at original location.
e2function void dupePaste(table tab, Frozen, WOConst)
	if !tab || !next(tab) || !next(tab.s) then return end
	local Master = tab.s
	if !Master["ECount"] then WireLib.ClientError("This dupe has no ents in it??", self.player) return end
	AdvDupe.SetPercentText( self.player, "Pasting" )
	AdvDupe.StartPaste( self.player, Master["ETable"], Master["CTable"], Master["HeadID"], Master["HeadPos"], Angle(0,0,0), Master["ECount"], Master["CCount"], Frozen != 0, WOConst != 0)
end

--- Pastes a dupeCopy <Master> at <vec> <ang>.
e2function void dupePaste(table tab, vector vec, angle ang)
	if !tab || !next(tab) || !next(tab.s) then return end
	local Master = tab.s
	if !Master["ECount"] then WireLib.ClientError("This dupe has no ents in it??", self.player) return end
	AdvDupe.SetPercentText( self.player, "Pasting" )
	AdvDupe.StartPaste( self.player, Master["ETable"], Master["CTable"], Master["HeadID"], Vector(vec[1], vec[2], vec[3]), Angle(ang[1], ang[2], ang[3]), Master["ECount"], Master["CCount"], false, false)
end

--- Pastes a dupeCopy <Master> at <vec> <ang>, freezes it if <Frozen> != 0, and doesn't paste constraints if <IsWOConst> != 0.
e2function void dupePaste(table tab, vector vec, angle ang, Frozen, WOConst)
	if !tab || !next(tab) || !next(tab.s) then return end
	local Master = tab.s
	if !Master["ECount"] then WireLib.ClientError("This dupe has no ents in it??", self.player) return end
	AdvDupe.SetPercentText( self.player, "Pasting" )
	AdvDupe.StartPaste( self.player, Master["ETable"], Master["CTable"], Master["HeadID"], Vector(vec[1], vec[2], vec[3]), Angle(ang[1], ang[2], ang[3]), Master["ECount"], Master["CCount"], Frozen != 0, WOConst != 0)
end

--- Pastes a dupeCopy <Master> at <vec> <ang>, freezes it if <Frozen> != 0, and doesn't paste constraints if <IsWOConst> != 0.
e2function void dupePaste(table tab, vector vec, angle ang, Frozen, WOConst, UseHeight)
	if !tab || !next(tab) || !next(tab.s) then return end
	local Master = tab.s
	if !Master["ECount"] then WireLib.ClientError("This dupe has no ents in it??", self.player) return end
	AdvDupe.SetPercentText( self.player, "Pasting" )
	AdvDupe.StartPaste( self.player, Master["ETable"], Master["CTable"], Master["HeadID"], Vector(vec[1], vec[2], vec[3] + (UseHeight and Master["Height"] or 0)), Angle(ang[1], ang[2], ang[3]), Master["ECount"], Master["CCount"], Frozen != 0, WOConst != 0)
end


// ########
// Single Entity Saving
// ########
__e2setcost(10)
/*
--- Returns a table containing save information about <Ent>, for use with pasteEntity.
e2function table saveEntity(entity Ent)
	if !Ent then return {} end
	return AdvDupe.GetSaveableEntity( Ent, Ent:GetPos() )
end

local function pasteEntity(ply, ETable, PosOffset, AngOffset)
	local prop = AdvDupe.CreateEntityFromTable( ply, ETable, 0, Vector(PosOffset[1], PosOffset[2], PosOffset[3]), Angle(AngOffset[1], AngOffset[2], AngOffset[3]) )
	ply:AddCleanup( "props", prop )
	undo.Create("e2_spawned_prop")
		undo.AddEntity( prop )
		undo.SetPlayer( ply )
	undo.Finish()
	if prop:GetClass() == "gmod_wire_expression2" then prop:Reset() end
	return prop
end

--- Pastes an entity at <Offset> <AngOffset> from data stored in <ETable> (from a saveEntity)
e2function entity pasteEntity(table ETable, vector Offset, angle AngOffset)
	return pasteEntity(self.player, ETable, Offset, AngOffset)
end
*/
// ########
// E2 code saving
// ########

--- Saves the code of <this>, for pasteE2.
e2function string entity:saveE2()
	if !this || !this:IsValid() || !this.original then return "" end
	return this.original
end

--- Pastes the code <code> into <this>, reseting and updating it.
e2function void entity:updateE2(string code)
	if !this || !this:IsValid() then return end
	this:Setup(code)
end


local function createE2Delayed(self,code, pos, ang)
	self.data.SpawnedE2s = self.data.SpawnedE2s or {}
	table.insert(self.data.SpawnedE2s, NULL)
	local num = #self.data.SpawnedE2s
	timer.Simple(0.1, function() createE2(self.player, code, pos, ang, self.data.SpawnedE2s, num) end)
	return num
end
function createE2(ply, code, pos, ang, SpawnedE2s, num)
	local entity = ents.Create("gmod_wire_expression2")
	if !entity:IsValid() || !ply:IsValid() then return end

	ply:AddCount("wire_expressions", entity)
	
	entity:SetModel("models/beer/wiremod/gate_e2.mdl")
	entity:SetAngles(ang or Angle())
	entity:SetPos(pos or Vector())
	entity:Spawn()
	entity.player = ply
	entity:SetPlayer(ply)
	entity:SetNWEntity( "player", ply )

	undo.Create("wire_expression2")
		undo.AddEntity(entity)
		undo.SetPlayer(ply)
	undo.Finish()
	
	ply:AddCleanup("wire_expressions", entity)
	
	entity.name = "Wat no code??"
	entity.inc_files = {}
	entity:Setup(code,entity.inc_files)
	if SpawnedE2s then SpawnedE2s[num] = entity end
	return entity
end
//createE2(fileReadString("N7E2/slowfall.txt"),entity():pos() + vec(0,0,3))

--- Creates a new E2, using the code <code> and infusing the extra code <code2>.
e2function number createE2(string code, string code2)
	local arr = string.Explode("\n",code)
	for k,v in ipairs(arr) do if string.Left(v,1) != "@" then table.insert(arr,k,code2) break end end
	return createE2Delayed(self,table.concat(arr, "\n"), self.entity:GetPos(), Angle(0,0,0))
end

--- Creates a new E2, using the code <code> at pos <pos>.
e2function number createE2(string code, vector pos)
	return createE2Delayed(self,code, Vector(pos[1], pos[2], pos[3]), Angle(0,0,0))
end

--- Creates a new E2, using the code <code> at pos <pos> and ang <ang>.
e2function number createE2(string code, vector pos, angle ang)
	return createE2Delayed(self,code, Vector(pos[1], pos[2], pos[3]), Angle(ang[1], ang[2], ang[3]))
end

e2function entity spawnedE2(num)
	if !self.data || !self.data.SpawnedE2s then return 0 end
	return self.data.SpawnedE2s[num]
end


-- Helper for E2 autosaver	
e2function array array:sortReverse()
	table.SortDesc(this)
	return this
end

__e2setcost(nil)