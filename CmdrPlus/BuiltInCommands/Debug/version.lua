local version = "Cmdrplus v1.0.0 Cmdr v1.12.0"

return {
	Name = "version",
	Args = {},
	Description = "Shows the current version of Cmdrplus",
	Group = "Default",

	ClientRun = function()
		return {line = ("Cmdr Version %s"):format(version), color = nil}
	end,
}
