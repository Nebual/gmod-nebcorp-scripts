-- By nebual@nebtown.info 2012
AddCSLuaFile("autorun/client/cl_ncvote.lua")
util.AddNetworkString("NC_StartVote")
util.AddNetworkString("NC_HearVote")
util.AddNetworkString("NC_EndVote")

local voteoptions, plyvotes
function StartVote(title,time,headings,options,callback)
	voteoptions = {}
	plyvotes = {}
	for k,v in pairs(options) do
		if istable(v) then
			table.insert(v,0)
			table.insert(voteoptions,v)
		else
			table.insert(voteoptions,{v,0})
		end
	end
	net.Start("NC_StartVote")
		net.WriteString(title)
		if istable(headings) then
			table.insert(headings,"Votes")
			net.WriteTable(headings)
		else
			net.WriteTable({headings,"Votes"})
		end
		net.WriteTable(voteoptions)
	net.Broadcast()
	timer.Create("NC_EndVote",time,1, function()
		net.Start("NC_EndVote")
		net.Broadcast()
		local lastid = #voteoptions[1]
		local highest, highestval = "none",0
		for k,v in pairs(voteoptions) do
			if v[lastid] > highestval then
				highestval = v[lastid]
				highest = v
			end
		end
		callback(highest[1])
		voteoptions = nil
	end)
end
-- Where name is the first parameter of the line, and val is either +1 or -1
local function ModifyVote(name, val)
	for k,v in pairs(voteoptions or {}) do
		if v[1] == name then
			v[#v] = v[#v] + val
			net.Start("NC_HearVote")
				net.WriteString(v[1])
				net.WriteUInt(v[#v],8)
			net.Broadcast()
			return
		end
	end
end

concommand.Add("nc_vote",function(ply,cmd,args)
	print(tostring(ply).." voted for: "..args[1])
	if plyvotes[ply] then ModifyVote(plyvotes[ply], -1) end
	ModifyVote(args[1],1)
	plyvotes[ply] = args[1]
end)

concommand.Add("nc_vote_example", function(ply,cmd,args)
	if ply:IsValid() and not ply:IsAdmin() then return end
	-- This will produce a vote with two columns shown, "Map Name" and "Number of times played".
	StartVote("Next Map?",3,{"Map Name","Number of times played"},{{"gm_construct",6},{"gm_flatgrass",3}}, function(winner)
		print("The winner of the vote is: "..winner)
	end)
	/*
	-- This also works for a "one column" vote
	StartVote("Next Map?",3,"Map Name",{"gm_construct","gm_flatgrass"}, function(winner)
		print("The winner of the vote is: "..winner)
	end)
	*/
end)