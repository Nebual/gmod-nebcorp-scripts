registerCallback("construct", function(self)
	self.data.nextweldlist = 0
	self.data.weldlist = {}
	self.data.constraintUndos = true
end)

e2function void setConstraintUndo(num)
	self.data.constraintUndos = num != 0
end
e2function void constraintUndo(num)
	self.data.constraintUndos = num != 0
end

local function checkEnts(ent1, ent2)
	if !ent1 || (!ent1:IsValid() && !ent1:IsWorld()) || !ent2 || (!ent2:IsValid() && !ent2:IsWorld()) || ent1 == ent2 then return false end
	return true
end
local function addundo(self, prop, message)
	self.player:AddCleanup( "constraints", prop )
	if self.data.constraintUndos then
		undo.Create("e2_"..message)
			undo.AddEntity( prop )
			undo.SetPlayer( self.player )
		undo.Finish()
	end
end

__e2setcost(1)

--- Like getConstraints(), returns an array of all entities in <this>'s constraint system, including <this>
e2function array entity:getConstraints2()
	if !IsValid(this) then return {} end
	if !constraint.HasConstraints(this) then return {this} end
	local ret, count = {this}, 1
	for _,v in pairs(constraint.GetAllConstrainedEntities(this)) do
		if IsValid(v) && v != this then
			count = count + 1
			ret[count] = v
		end
	end
	self.prf = self.prf + count / 3 // Most of the cost is here ;D
	//ret[count + 1] = this
	return ret
end

// Notes about Constraintmakers:
// All vectors are LOCAL positions relative to their corresponding entities
/*

__e2setcost(5)

// axis(entity():isWeldedTo(), vec(), E2, vec())
--- Creates an axis between <e1> and <e2> at vector positions local to each ent.
e2function void axis(entity e1, vector v1, entity e2, vector v2)
	if !checkEnts(e1, e2) then return end
	local vec1, vec2 = Vector(v1[1], v1[2], v1[3]), Vector(v2[1], v2[2], v2[3])
	addundo(self, constraint.Axis(e1, e2, 0, 0, vec1, vec2, 0, 0, 0, 0), "Axis")
end

--- Creates an axis between <e1> and <e2> at vector positions local to each ent, with <friction> friction.
e2function void axis(entity e1, vector v1, entity e2, vector v2, friction)
	if !checkEnts(e1, e2) then return end
	local vec1, vec2 = Vector(v1[1], v1[2], v1[3]), Vector(v2[1], v2[2], v2[3])
	addundo(self, constraint.Axis(e1, e2, 0, 0, vec1, vec2, 0, 0, friction, 0), "Axis")
end

//This example E2 line creates two ballsockets between two entities (E, and Top) to create a hinge.
//ballsocket(Top, vec(-E:boxSize():x()/2 + 0.5, E:boxSize():x()/2 -0.5, 0), AxisProp, 0), ballsocket(Top, vec(-E:boxSize():x()/2 +0.5, -E:boxSize():x()/2+0.5, 0), AxisProp, 0)
--- Creates a ballsocket between <e1> and <e2> at <v>, which is local to <e1>
e2function void ballsocket(entity e1, vector v, entity e2)
	if !checkEnts(e1, e2) then return end
	local vec = Vector(v[1], v[2], v[3])
	addundo(self, constraint.Ballsocket(e1, e2, 0, 0, vec, 0, 0, 0), "BallSocket")
end

--- Creates a ballsocket between <e1> and <e2> at <v>, which is local to <e1>, with friction <friction>
e2function void ballsocket(entity e1, vector v, entity e2, friction)
	if !checkEnts(e1, e2) then return end
	local vec = Vector(v[1], v[2], v[3])
	addundo(self, constraint.AdvBallsocket(e1, e2, 0, 0, Vector(), vec, 0, 0, -180, -180, -180, 180, 180, 180, friction, friction, friction, 0, 1), "BallSocket")
end

--- Creates an angular weld (angles are fixed, position isn't) between <e1> and <e2> at <v>, which is local to <e1>
e2function void weldAng(entity e1, vector v, entity e2)
	if !checkEnts(e1, e2) then return end
	local vec = Vector(v[1], v[2], v[3])
	addundo(self, constraint.AdvBallsocket(e1, e2, 0, 0, Vector(), vec, 0, 0, 0, -0, 0, 0, 0, 0, 0, 0, 0, 1, 1), "BallSocket")
end


local function CalcElasticConsts(Phys1, Phys2, Ent1, Ent2)
	local minMass
	if Ent1:IsWorld() then 
		minMass = Phys2:GetMass()
	elseif Ent2:IsWorld() then 
		minMass = Phys1:GetMass()
	else 
		minMass = math.min( Phys1:GetMass(), Phys2:GetMass() )
	end
	
	local const = minMass * 100
	local damp = const * 0.2
	
	return const, damp
end

// Note: Winch is just a rename of Hydraulic with the last parameter True.
--- Makes a winch constraint (stored at index <index>) between <e1> and <e2>, at vectors local to their respective ents, with <width> width. 
e2function void winch(index, entity e1, vector v1, entity e2, vector v2, width)
	if !checkEnts(e1, e2) then return end
	local vec1, vec2 = Vector(v1[1],v1[2],v1[3]), Vector(v2[1],v2[2],v2[3])
	if width < 0 || width > 50 then width = 1 end
	if !e1.data then e1.data = {} end
	if !e1.data.Hydraulics then e1.data.Hydraulics = {} end
	local con = e1.data.Hydraulics[index]
	if con && con:IsValid() then
		con:Remove()
		table.remove(e1.data.Hydraulics, index)
	end
	local constant, dampen = CalcElasticConsts( e1:GetPhysicsObject(), e2:GetPhysicsObject(), e1, e2 )
	e1.data.Hydraulics[index] = constraint.Elastic( e1, e2, 0, 0, vec1, vec2, constant, dampen, 0, "cable/cable2", width, true )
	addundo(self, e1.data.Hydraulics[index], "Winch")
end

--- Makes a hydraulic constraint (stored at index <index>) between <e1> and <e2>, at vectors local to their respective ents, with <width> width. 
e2function void hydraulic(index, entity e1, vector v1, entity e2, vector v2, width)
	if !checkEnts(e1, e2) then return end
	local vec1, vec2 = Vector(v1[1],v1[2],v1[3]), Vector(v2[1],v2[2],v2[3])
	if width < 0 || width > 50 then width = 1 end
	if !e1.data then e1.data = {} end
	if !e1.data.Hydraulics then e1.data.Hydraulics = {} end
	local con = e1.data.Hydraulics[index]
	if con && con:IsValid() then
		con:Remove()
		table.remove(e1.data.Hydraulics, index)
	end
	local constant, dampen = CalcElasticConsts( e1:GetPhysicsObject(), e2:GetPhysicsObject(), e1, e2 )
	e1.data.Hydraulics[index] = constraint.Elastic( e1, e2, 0, 0, vec1, vec2, constant, dampen, 0, "cable/cable2", width, false )
	addundo(self, e1.data.Hydraulics[index], "Hydraulic")
end

--- Sets a hydraulic/winch stored at index <index> inside <this> (the first entity) to be <length> long.
e2function void entity:setHydraulic(index, length)
	if !IsValid(this) then return end
	if length < 0 then length = 0 end
	if this.data.Hydraulics then
		local con = this.data.Hydraulics[index]
		if con then con:Fire("SetSpringLength", length, 0) end
	end
end

*/

--- Updates all hydraulics/winchs involving <this> (useful if the weight of the entities have been changed)
e2function void entity:updateHydraulic()
	if !IsValid(this) then return end
	for _,v in pairs( this:GetTable().Constraints ) do
		if IsValid(v) then
			local CTab = v:GetTable()
			if CTab.Type == "Elastic" then
				local constant, dampen = CalcElasticConsts( CTab.Ent1:GetPhysicsObject(), CTab.Ent2:GetPhysicsObject(), CTab.Ent1, CTab.Ent2 )
				v:Fire("SetSpringConstant", constant, 0) 
				v:Fire("SetSpringDamping", dampen, 0)
			end
	 	end
	end
end

--- Nocollides <this> to <entity2>
e2function void entity:noCollide(entity entity2)
	if !checkEnts(this, entity2) then return end
	local const = constraint.NoCollide(this, entity2, 0, 0)
	//print("Type: "..tostring(const.Ent1) .. tostring(const.Ent2))
	addundo(self, const, "NoCollide") 
end

--- Nocollides <this> to every entity in <array>
e2function void entity:noCollide(array array)
	if !IsValid(this) || array == {} then return end
	for _,v in ipairs(array) do
		if checkEnts(this, v) then
			constraint.NoCollide(this, v, 0, 0)
		end
	end
end

--- Nocollides every entity in <this> to eachother (EXPENSIVE)
e2function void array:noCollideTogether()
	if !this || this == {} then return end
	for _,v in ipairs(this) do
		for _,v2 in ipairs(this) do
			if checkEnts(v, v2) then
				constraint.NoCollide(v, v2, 0, 0)
			end
		end
	end
end

--- Nocollides <this> to entities/players, just like Right Click of No-Collide Stool
e2function void entity:noCollideAll(state)
	if !IsValid(this) then return end
	if state != 0 then 
		this:SetCollisionGroup( COLLISION_GROUP_WORLD )
	else
		this:SetCollisionGroup( COLLISION_GROUP_NONE )
	end
end

--- Breaks the weld between <this> and <entity2>
e2function void entity:noCollideBreak(entity ent2)
	if !checkEnts(this, ent2) then return end
	local consts = this.Constraints
	local consts2 = ent2.Constraints
	if !consts && !consts2 then return end
	if !consts then // If our Ent1 is the world, we can't get a constraint table, so switch the entities and look through them that way
		local thirdEnt = this
		this = ent2
		ent2 = thirdEnt
		consts = consts2
	end 
	for _,v in pairs( consts ) do
		if IsValid(v) then
			local CTab = v:GetTable()
			if CTab.Type == "NoCollide" && ( CTab.Ent1 == this && CTab.Ent2 == ent2 ) ||  ( CTab.Ent1 == ent2 && CTab.Ent2 == this ) then
				v:Remove()
				return
			end
	 	end
	end
end

--- Breaks all nocollides on <this>
e2function void entity:noCollideBreakAll()
	if !IsValid(this) then return end
	constraint.RemoveConstraints(this, "Nocollide")
end

/*

--- Creates a rope between <e1> and <e2> at vector positions local to each ent.
e2function void rope(index, entity e1, vector v1, entity e2, vector v2)
	if !checkEnts(e1, e2) then return end
	self.E2Ropes = self.E2Ropes or {}
	local vec1, vec2 = Vector(v1[1], v1[2], v1[3]), Vector(v2[1], v2[2], v2[3])
	local length = (e1:LocalToWorld(vec1) - e2:LocalToWorld(vec2)):Length()
	local const = constraint.Rope( e1, e2, 0, 0, vec1, vec2, length, 0, 0, 1, "cable/rope", false )
	if IsValid(self.E2Ropes[index]) then self.E2Ropes[index]:Remove() end
	self.E2Ropes[index] = const
	addundo(self, const, "Rope")
end

--- Creates a rope between <e1> and <e2> at vector positions local to each ent, with <addlength> additional length, <width> width, and <mat> material.
e2function void rope(index, entity e1, vector v1, entity e2, vector v2, addlength, width, string mat)
	if !checkEnts(e1, e2) then return end
	self.E2Ropes = self.E2Ropes or {}
	local vec1, vec2 = Vector(v1[1], v1[2], v1[3]), Vector(v2[1], v2[2], v2[3])
	local length = (e1:LocalToWorld(vec1) - e2:LocalToWorld(vec2)):Length()
	local const = constraint.Rope( e1, e2, 0, 0, vec1, vec2, length, addlength, 0, width, mat, false )
	if IsValid(self.E2Ropes[index]) then self.E2Ropes[index]:Remove() end
	self.E2Ropes[index] = const
	addundo(self, const, "Rope")
end

--- Sets the length of an existing rope <index> to be <len>
e2function void ropeLength(index, len)
	if !self.E2Ropes || !IsValid(self.E2Ropes[index]) then return end
	self.E2Ropes[index]:SetKeyValue( "addlength", math.Max(len,0))
end

--- Breaks all ropes on <this>
e2function void entity:ropeBreakAll()
	local ent = IsValid(this) and this
	if ent then constraint.RemoveConstraints(ent, "Rope") end
end

*/

--- Breaks EVERY CONSTRAINT on <this>
e2function void entity:constraintBreakAll()
	local ent = IsValid(this) and this
	if ent then constraint.RemoveAll(ent) end
end

--- Creates a slider between <e1> and <e2> at vector positions local to each ent.
e2function void slider(entity e1, vector v1, entity e2, vector v2)
	if !checkEnts(e1, e2) then return end
	local vec1, vec2 = Vector(v1[1], v1[2], v1[3]), Vector(v2[1], v2[2], v2[3])
	addundo(self, constraint.Slider(e1, e2, 0, 0, vec1, vec2, 1), "Slider")
end

--- Creates a slider between <e1> and <e2> at vector positions local to each ent, with <width> width.
e2function void slider(entity e1, vector v1, entity e2, vector v2, width)
	if !checkEnts(e1, e2) then return end
	local vec1, vec2 = Vector(v1[1], v1[2], v1[3]), Vector(v2[1], v2[2], v2[3])
	addundo(self, constraint.Slider(e1, e2, 0, 0, vec1, vec2, width), "Slider")
end

--- Breaks all sliders on <this>
e2function void entity:sliderBreakAll()
	local ent = IsValid(this) and this
	if ent then constraint.RemoveConstraints(ent, "Slider") end
end

--- Breaks all constraints of type <type> on <this>
e2function void entity:constraintBreak(string type)
	local ent = IsValid(this) and this
	if ent then constraint.RemoveConstraints(ent, type) end
end

--- Welds <this> to <e2>
e2function void entity:weld(entity e2)
	if !checkEnts(this, e2) then return end
	addundo(self, constraint.Weld(this, e2, 0, 0, 0, true), "Weld")
end

--- Welds <this> to <e2> without the undo entry
e2function void entity:weld2(entity e2)
	if !checkEnts(this, e2) then return end
	constraint.Weld(this, e2, 0, 0, 0, true)
end

--- Welds every entity in <array> to <this>
e2function void entity:weld(array array)
	local ent1 = IsValid(this) and this
	if !ent1 || !array || array == {} then return end
	for _,v in ipairs(array) do
		local ent2 = IsValid(v) and v
		if ent2 && ent1 != ent2 then
			constraint.Weld(ent1, ent2, 0, 0, 0, true)
		end
	end
end

--- Breaks the weld between <this> and <entity2>
e2function void entity:weldBreak(entity ent2)
	if !checkEnts(this, ent2) then return end
	local consts = this.Constraints
	local consts2 = ent2.Constraints
	if !consts && !consts2 then return end
	if !consts then // If our Ent1 is the world, we can't get a constraint table, so switch the entities and look through them that way
		local thirdEnt = this
		this = ent2
		ent2 = thirdEnt
		consts = consts2
	end 
	for _,v in pairs( consts ) do
		if IsValid(v) then
			local CTab = v:GetTable()
			if CTab.Type == "Weld" && ( CTab.Ent1 == this && CTab.Ent2 == ent2 ) ||  ( CTab.Ent1 == ent2 && CTab.Ent2 == this ) then
				v:Remove()
				return
			end
	 	end
	end
end

--- Breaks all welds between <this> and every entity in <array>
e2function void entity:weldBreak(array array)
	local ent = IsValid(this) and this
	if !ent || !array || array == {} then return end
	if !ent:GetTable().Constraints then return end
	for _,v in pairs( ent:GetTable().Constraints ) do
		if v && v:IsValid() then
			local CTab = v:GetTable()
			if CTab.Type == "Weld" then
				for _,v2 in ipairs(array) do
					if IsValid(v2) && (  ( CTab.Ent1 == ent && CTab.Ent2 == v2 ) ||  ( CTab.Ent1 == v2 && CTab.v2 == ent )  ) then
						v:Remove()
					end
				end
			end
	 	end
	end
end

--- Breaks all welds on <this>
e2function void entity:weldBreakAll()
	local ent = IsValid(this) and this
	if ent then constraint.RemoveConstraints(ent, "Weld") end
end

--- Breaks all welds on every entity in <this>
e2function void array:weldBreakAll()
	if !this || this == {} then return end
	for _,v in ipairs(this) do
		local ent = IsValid(v) and v
		if ent then constraint.RemoveConstraints(ent, "Weld") end
	end
end

registerFunction("getWelds", "e:", "r", function(self, args)
    	local op1 = args[2]
    	local rv1 = op1[1](self, op1)
	local ent = IsValid(rv1) and rv1
   	if(IsValid(ent) && constraint.HasConstraints(rv1))then
		local con = constraint.FindConstraints( rv1, "Weld" )
		local array = {}
		local count = 0
		local e = nil
		for _,v in pairs(con) do
			if(v.Ent1==ent) then e = v.Ent2 else e = v.Ent1 end
			if IsValid(e) then
				count = count + 1
				array[count] = e
			end
		end
	return array
	end
	return {}
end)

local function FindWeldsOnce( Ent, RetTable )
	local WeldTable = constraint.FindConstraints( Ent, "Weld" )
	if not WeldTable then return RetTable end
	for _,Weld in ipairs(WeldTable) do
		local CurEnt = nil
		if Weld.Ent1 == Ent then CurEnt = Weld.Ent2 else CurEnt = Weld.Ent1 end
		if IsValid(CurEnt) then
			if not table.HasValue( RetTable, CurEnt ) then
				RetTable[table.Count(RetTable) + 1] = CurEnt
			end
		end
	end
	return RetTable
end

local function weldlistquery_blocked(self, update)
	local time = CurTime()
	if time < self.data.nextweldlist then return true end
	if update then self.data.nextweldlist = time+1 end
	return false
end

--- A more expensive version of getConstraints(), attempts to find all entities that are connected via welds to <this>
e2function array entity:getAllWelds()
	if not IsValid(this) then return {} end
	if weldlistquery_blocked(self, true) then return self.data.weldlist end
	local RetTable = {}
	local ScannedEnts = {}
	local T1 = {}
	T1[1] = this
	table.Add(RetTable, T1)
	local T2 = FindWeldsOnce( this, T1 )
	table.Add(RetTable, T2)
	for _,v1 in ipairs(T2) do
		if ScannedEnts[v1] then continue else ScannedEnts[v1] = true end
		local T3 = FindWeldsOnce( v1, T2 )
		table.Add(RetTable, T3)
		for _,v2 in ipairs(T3) do
			if ScannedEnts[v2] then continue else ScannedEnts[v2] = true end
			local T4 = FindWeldsOnce( v2, T3 )
			table.Add(RetTable, T4)
			for _,v3 in ipairs(T4) do
				if ScannedEnts[v3] then continue else ScannedEnts[v3] = true end
				local T5 = FindWeldsOnce( v3, T4 )
				table.Add(RetTable, T5)
				for _,v4 in ipairs(T4) do
					if ScannedEnts[v4] then continue else ScannedEnts[v4] = true end
					local T6 = FindWeldsOnce( v4, T5 )
					table.Add(RetTable, T6)
					for _,v5 in ipairs(T6) do
						if ScannedEnts[v5] then continue else ScannedEnts[v5] = true end
						local T7 = FindWeldsOnce( v5, T6 )
						table.Add(RetTable, T7)
						for _,v6 in ipairs(T4) do
							if ScannedEnts[v6] then continue else ScannedEnts[v6] = true end
							local T8 = FindWeldsOnce( v6, T7 )
							table.Add(RetTable, T8)
						end
					end
				end
			end
		end
	end
	self.data.weldlist = RetTable
	return RetTable
end

__e2setcost(nil)