if SERVER then AddCSLuaFile() end
function net.WriteColor(col)
	net.WriteUInt(col.r,8)
	net.WriteUInt(col.g,8)
	net.WriteUInt(col.b,8)
end
function net.ReadColor()
	return Color(net.ReadUInt(8),net.ReadUInt(8),net.ReadUInt(8))
end