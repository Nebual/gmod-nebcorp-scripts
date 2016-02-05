if SERVER then AddCSLuaFile() end

properties.List.gravity.Filter	= function( self, ent, ply ) 
	if ( !IsValid( ent ) ) then return false end
	if ( !gamemode.Call( "CanProperty", ply, "gravity", ent ) ) then return false end
	return true
end

-- a handwritten replacement intended with "for k,v in ipairs2(table) do" where you plan on altering, specifically removing, parts of the table itself
-- This works well when t = {"A","B","C","D"} and you want to remove any "B"'s or "C"'s via table.remove, but NOT when you want to remove B's from {"A","B","B","B","C"}
function ipairs2(t)
	local last
	return function(t,k)
		local v = t[k]
		if last == v then
			k = k + 1
			v = t[k]
		end

		if v then
			last = v
			return k,v
		end
	end,t,0
end