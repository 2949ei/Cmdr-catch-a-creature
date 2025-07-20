return {
	Name = "blink",
	Aliases = { "b" },
	Description = "Teleports you to where your mouse is hovering.",
	Group = "Debug",
	Permissions = {},
	Args = {},

	ClientRun = function(context)
		-- We implement this here because player position is owned by the client.
		-- No reason to bother the server for this!

		local mouse = context.Executor:GetMouse()
		local character = context.Executor.Character

		if not character then
			return { line = "You don't have a character.", color = nil }
		end

		character:MoveTo(mouse.Hit.p)

		return { line = "Blinked!", color = nil }
	end,
}
