local YourExtraCommandsTableHere = {
	All = {
		setpin = function(ply, args)
			local accounts = util.JSONToTable(file.Read("nebcorp/atm_pins.txt","DATA") or "{}")
			local account, pin = ply:SteamID(), args[1]
			if #args > 1 then account, pin = args[1], args[2] end
			--if accounts[account] then
				--return 1, "That account already exists."
			--end
			--The chat command should always succeed, so people can change their pin if they forgot or it was compromised.
			accounts[account] = pin
			file.Write("nebcorp/atm_pins.txt", util.TableToJSON(accounts))
			return 2, "Pin set!"
		end,
	},
}

timer.Simple(1,function() 
	table.Merge(NADMOD.Permissions, YourExtraCommandsTableHere)

	local colortable = {} colortable[50] = 2 colortable[25] = 4 colortable[10] = 12 colortable[6] = 11 colortable[5] = 4 colortable[4]=3 colortable[2]=10 colortable[1]=14
	function NADMOD.IRCName(ply)
		if !ply:IsValid() or !ply:IsPlayer() then return end
		return string.char(2)..string.char(3)..colortable[(NADMOD.Users[ply:SteamID()] or {Rank = 1}).Rank]..ply:Nick()..string.char(2)..string.char(3)
	end
end)
