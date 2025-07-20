return function(_, players)
	for _, player in pairs(players) do
		if player.Character then
			player:LoadCharacter()
		end
	end
	return { line = ("Respawned %d players."):format(#players), color = nil }
end
