local YourExtraCommandsTableHere = {
//	ThisPartIsThePermissionName = {
//		lowercase_chatcmd = function(ply,args) ply:SendMessage("Bonk!") return 2, "Boink!" end,
//	},
	Annoys = { 
		boast = function(ply, args)
			local tar = NADMOD.GuessTarget(ply,args) 
			if !tar then return 1, "I don't know who you're better than!" end
			return 3, "Hey everyone! "..ply:Nick().." is better at Gmod than "..tar:Nick()
		end,
	},
}

-- Uncomment this line to merge the above commands into NADMOD.
//timer.Simple(1,function() table.Merge(NADMOD.Permissions, YourExtraCommandsTableHere) end)
-- This creates a command called '!boast jake', requiring the permission Annoys, 
-- that either errors (return 1) or broadcasts a message (return 3, "Nebual is better at Gmod than Jake Thunder!")


/* Notes on writing ChatCommands:
	NADMOD.FindPlayer(string) is a convinence function that returns the ent of the player whose name contains 'string'.
	NADMOD.GuessTarget(ply,args) is a convinence function that attempts to find a target based on args[1], defaults to the ply if none is found, and also returns the next arg
	local tar,hp = NADMOD.GuessTarget(ply,args) // For '!cmd Neb 20' this'll return 'Entity[neb] & 20', while '!cmd 20' returns 'Entity[you] & 20'
	
	RETURN A # AND A "MESSAGE", because everyone likes chat responce to their commands. The # corresponds with what kind of message you want.
	return 1, "This is an --error-- message just to the player."
	return 2, "This is a normal message just to the player."
	return 3, "This is a normal message to all gmodders."
	return 4, "This is a message to IRC & all gmodders."
*/