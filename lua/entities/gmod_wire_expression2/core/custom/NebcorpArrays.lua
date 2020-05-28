local DEFAULT = {n={},ntypes={},s={},stypes={},size=0,istable=true,depth=0}

__e2setcost(2)
/*
e2function void print(...)
	local msg = ""
	for _,v in ipairs({...}) do
		if type(v) == "table" then v = "["..table.concat(v, ", ").."]" end
		msg = msg .. tostring(v) .. " "
	end
	self.player:ChatPrint(string.Left(msg, 255))
end*/
/*
registerOperator("add", "rr", "r", function(self, args)
	local op1, op2 = args[2], args[3]
	return table.Add(op1[1](self, op1), op2[1](self, op2))
end)
*/
registerCallback("postinit", function()
	-- generate this function for all types
	for typeid,_ in pairs(wire_expression_types2) do
		registerFunction("setValue", "t:s" .. typeid, "", function( self, args )	
			local op1, op2, op3 = args[2], args[3], args[4]
			local rv1, rv2, rv3 = op1[1](self, op1), op2[1](self, op2), op3[1](self, op3)
			if (!rv1 or !rv2 or !rv3) then return end
			if (typeid == "t") then
				rv3.depth = rv1.depth + 1
				rv3.parent = rv1
			end
			if (!rv1.s[rv2]) then rv1.size = rv1.size + 1 end
			rv1.s[rv2] = rv3
			rv1.stypes[rv2] = typeid
			self.vclk[rv1] = true
			return end)
	end
end)

e2function string table:getString(string index)
	if !this || this == {} then return "" end
	return this[index] or ""
end

e2function number table:getNumber(string index)
	if !this || this == {} then return 0 end
	return this[index] or 0
end

-- REMOVE THIS FUNCTION BY FEB 2010, ITS DEPRECEATED
e2function void table:setNumber(string index, num)
	if !this || this == {} then return end
	this.s[index] = num
	this.stypes[index] = "number"
end

/*
e2function vector table:getVector(string index)
	if !this || this == {} then return {0,0,0} end
	return this[index] or {0,0,0}
end

e2function entity table:getEntity(string index)
	if !this || this == {} then return nil end
	return this[index]
end

e2function angle table:getAngle(string index)
	if !this || this == {} then return {0,0,0} end
	return this[index] or {0,0,0}
end

e2function table table:getTable(string index)
	if !this || this == {} then return {} end
	return this[index] or {}
end

e2function array table:getArray(string index)
	if !this || this == {} then return {0,0,0} end
	return this[index] or {0,0,0}
end
*/
--- Sets a subarray <array2> at index <index> in array <this>
e2function array array:setArray(index, array array2)
	this[index] = array2
	return this
end

--- Sets a subtable <table2> at index <index> in array <this>
e2function array array:setTable(index, table table2)
	this[index] = table2
	return this
end

--- Differently returns a table stored at <index> in the array <this>
e2function table array:getTable(index)
	local ret = this[index]
	if ret then return ret else return {} end
end

--- Differently returns an array stored at <index> in the array <this>
e2function array array:getArray(index)
	local ret = this[index]
	if ret then return ret else return {} end
end


registerFunction("addNumber", "r:n", "r", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
    	if !rv1 then return {} end
	local array = rv1
	for k,v in ipairs(array) do
		if(isnumber(v)) then
			array[k] = v + rv2
		end
	end
	return array
end)


--- Returns an array of all connected player's entities.
e2function array activePlayers()
	return player.GetAll()
end

e2function array activeNPCs()
	return ents.FindByClass("npc_*")
end
/*
--- Find all entities with the given model sneakily
e2function array findByModel2(string model)
	return ents.FindByModel(model)
end
*/
--- Returns an array of all connected player's entities, sorted by distance to <position> (closest first).
e2function array activePlayers(vector position)
	position = Vector(position[1], position[2], position[3])
	local Distance = position.Distance
	local ret = {}
	for k,v in ipairs(player.GetAll()) do
		ret[k] = v
	end
	table.sort(ret, function(a, b)
		if not IsValid(a) then return false end -- !(invalid < b) <=> (b <= invalid)
		if not IsValid(b) then return true end -- (valid < invalid)
		
		return Distance(position, a:GetPos()) < Distance(position, b:GetPos())
	end)
	return ret
end

--- Removes all invalid entities from array <this> of entities, and returns the resulting array.
e2function array array:checkEntities()
	local ret = {}
	local count = 0
	for _,v in ipairs(this) do
		local entity = IsValid(v) and v
		if isnumber(v) then entity = IsValid(Entity(v)) and Entity(v) end
		if entity then 
			count = count + 1
			ret[count] = v
		end
	end
	return ret
end

local fishcolours = {
	{255,0,0},
	{255,255,0},
	{0,255,255},
	{122,122,122},
	{122,122,0},
	{122,0,122},
	{0,122,255},
	{0,255,122},
	{0,255,0},
	{122,255,0},
	{255,122,0},
	{255,0,122},
	{0,0,255},
	{122,0,255},
	{122,122,255},
	{255,122,122},
	{122,255,122},
	{122,255,255},
	{255,255,122},
	{255,122,255}
}
local function GetRandomColor()
	local tab = table.Random(fishcolours)
	return tab[1],tab[2],tab[3]
end

--- MAKE ARRAY <this> OF ENTS FLASH KOOLOURZ
e2function void array:fish()
	for _,v in ipairs(this) do
		if isnumber(v) then e = IsValid(Entity(v)) and Entity(v) else e = IsValid(v) and v end
		if e then 
			local r,g,b = GetRandomColor()
			local col = e:GetColor()
			e:SetColor(Color(r,g,b,col.a))
		end
	end
end

--- MAKE ARRAY <this> OF ENTS FLASH REALLY SHINY KOOLOURZ
e2function void array:fish2()
	for _,v in ipairs(this) do
		if isnumber(v) then e = IsValid(Entity(v)) and Entity(v) else e = IsValid(v) and v end
		if e then 
			local r,g,b = GetRandomColor()
			local col = e:GetColor()
			e:SetColor(Color(r,g,b,col.a))
			e:SetMaterial("models/shiny")
		end
	end
end

--- MAKE <this> FLASH KOOLOURZ
e2function void entity:fish()
	if IsValid(this) then
		local r,g,b = GetRandomColor()
		local col = this:GetColor()
		this:SetColor(Color(r,g,b,col.a))
	end
end

--- MAKE <this> FLASH KOOLOURZ
e2function void entity:fishOrdered()
	if IsValid(this) then
		local i = (this.fishi or 0) + 1
		if i > 20 then i = 1 end
		this.fishi = i
		local color = fishcolours[i]
		local col = this:GetColor()
		this:SetColor(Color(color[1],color[2],color[3],col.a))
	end
end

--- MAKE <this> FLASH KOOLOURZ
e2function void entity:fish2()
		if IsValid(this) then
		local r,g,b = GetRandomColor()
		local col = this:GetColor()
		this:SetColor(Color(r,g,b,col.a))
		this:SetMaterial("models/shiny")
	end
end

registerFunction("getAlphaArray", "r:", "r", function(self, args)
	local op1 = args[2]
	local rv1 = op1[1](self,op1)
    	if !rv1 then return {} end
	local array = {}
	for k,v in ipairs(rv1) do
		local ent = IsValid(v) and v
		if ent then
			local color = {ent:GetColor()}
			array[k] = color[4]
		end
	end
	return array
end)

registerFunction("setColor", "r:v", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	if !rv1 then return end
	local color2 = { math.Clamp(rv2[1],0,255), math.Clamp(rv2[2],0,255), math.Clamp(rv2[3],0,255) }
	for _,v in ipairs(rv1) do
		local ent = IsValid(v) and v
		if ent then 
			local color1 = {ent:GetColor()}
			ent:SetColor(color2[1], color2[2], color2[3], color1[4])
		end
	end
	return ""
end)

registerFunction("setAlpha", "r:r", "", function(self, args)
	local op1, op2 = args[2], args[3]
	local rv1, rv2 = op1[1](self,op1), op2[1](self,op2)
	if !rv1 || !rv2 then return end
	for k,v in ipairs(rv1) do
		local ent = IsValid(v) and v
		if ent then 
			local color = {ent:GetColor()}
			local alpha = rv2[k]
			if !alpha then alpha = 255 end 
			ent:SetColor(color[1], color[2], color[3], math.Clamp(alpha, 0, 255))
		end
	end
	return ""
end)

local function WriteArray(entity, array, extray)
	if not IsValid(entity) then return end
	if not entity.WriteCell then return end
	
	/*
	Tcolour = math.Clamp(math.floor(Tcolour), 0, 999)
	Bgcolour = math.Clamp(math.floor(Bgcolour), 0, 999)
	Flash = (Flash ~= 0) and 1 or 0
	local Params = Flash*1000000 + Bgcolour*1000 + Tcolour
	*/
	local Params = 999
	
	for Y,value in ipairs(array) do
		if extray then Y = Y + extray end
		if type(value) == "Player" then value = value:Nick()
		elseif type(value) == "entity" then
			value = string.Explode("/", value:GetModel())
			value = value[table.maxn(value)]
			value = string.Left(value, string.len(value) - 4)
		end
		value = value .. string.rep(" ", 30 - #value)
		for N = 1,#value do
			local Address = 2*(N-1+30*(Y-1))
			if (Address>1080 or Address<0) then return end
			local Byte = string.byte(value,N)
			if entity:ReadCell(Address) ~= Byte then
				entity:WriteCell(Address, Byte)
			end
			if entity:ReadCell(Address+1) ~= Params then
				entity:WriteCell(Address+1, Params)
			end
		end
	end
end

--- Can has write to digital screen
e2function void wirelink:writeArray(array array)
	WriteArray(this, array)
end

--- Can has write to digital screen
e2function void wirelink:writeArray(array array, y)
	WriteArray(this, array, y)
end

--- Can has write to digital screen
e2function void entity:writeArray(array array)
	WriteArray(this, array)
end

--- Can has write to digital screen
e2function void entity:writeArray(array array, y)
	WriteArray(this, array, y)
end

--- Implodes a string
e2function string array:implode(string pattern)
	return string.Implode(pattern, this)
end

__e2setcost(nil)