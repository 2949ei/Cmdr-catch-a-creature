return function(context, players)
	for _, player in pairs(players) do
		if player.Character then
			player.Character:BreakJoints()
		end
	end

	return { line = ("Killed %d players."):format(#players), color = context.Colors.Success }
end
