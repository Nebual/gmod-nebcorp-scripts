e2function void print2(num) if num != 0 then self.player:ChatPrint(tostring(num)) end end
e2function string linebreak()
	return string.char(10)
end

--- Returns the difference between <ang1> and <ang2>, when 350 degrees and 10 degrees are 20 apart.
e2function number angdiff(ang1, ang2)
	return math.AngleDifference(ang1, ang2)
end

e2function void gmanSay(string name, string msg)
	NIRC.Send("Gman", "PRIVMSG "..NIRC.channel.." :".."("..name..") "..msg)
end

e2function void entity:setBuoyancy(percent)
	if !IsValid(this) then return end
	SetBuoyancy( NULL, this, { Ratio = percent } )
end

e2function number benchTime() 
	return SysTime() - self.NCBench
end
