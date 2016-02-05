timer.Create("HackE2Lib.isOwner", 1, 1, function()
	function E2Lib.isOwner(self, entity)
		if game.SinglePlayer() then return true end
		if entity:IsWorld() then return true end
		if NADMOD.Props[entity:EntIndex()] && NADMOD.Props[entity:EntIndex()].Name == "O" then return true end
		local player = self.player
		local owner = getOwner(self, entity)
		if not IsValid(owner) then return false end

		return E2Lib.isFriend(owner, player)
	end
	isOwner = E2Lib.isOwner
end)