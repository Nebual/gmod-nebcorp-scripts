local voteoccured
function StartMapVote()
	voteoccured = true  -- Otherwise subsequent !rtvs would instantly trigger another vote
	local maps = string.Explode("\n",string.Trim(file.Read("mapcycle.txt","GAME")))
	local oldvotes = util.JSONToTable(file.Read("mapvotes.txt","DATA") or "{}")
	local options = {}
	for k,map in pairs(maps) do
		options[k] = {map, oldvotes[map] or 0}
	end
	StartVote("Vote for the Next Map",28,{"Map Name", "Times Voted"},options, function(winner)
		GameMsg("The next map chosen is: "..winner)
		for _, ply in pairs( player.GetAll() ) do
			ply:PrintMessage( HUD_PRINTTALK, "[RTV] The next map will be: "..winner)
		end
		
		-- Record that this map was chosen
		oldvotes[winner] = (oldvotes[winner] or 0) + 1
		file.Write("mapvotes.txt",util.TableToJSON(oldvotes))
		
		timer.Create("TTT_NextMap",10,1,function()
			game.ConsoleCommand("changelevel "..winner.."\n")
		end)
	end)
end
local rtvplys = {}
function rtv(ply)
	if rtvplys[ply] then return ULib.tsayError( ply, "[RTV] You have already voted to change the map!", true ) end
	if voteoccured then
		ply:ChatPrint( "[RTV] A map vote has already occured!" )
		return
	end
	rtvplys[ply] = true
	if table.Count(rtvplys) == 1 then
		for _, p in pairs( player.GetAll() ) do
			p:ChatPrint( "[RTV] "..ply:Nick().." wants to start a new map vote!" )
		end
	end
	if table.Count(rtvplys) > (#player.GetAll()*0.51) then
		StartMapVote()
	end
end
local cmd = ulx.command( "Utility", "ulx rtv", rtv, "!rtv" )
cmd:defaultAccess( ULib.ACCESS_ALL )
cmd:help( "Attempts to start a Map Vote" )