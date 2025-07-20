return {
    Roles = {},
    CustomCommands = nil,
    CustomHooks = nil,
    CustomTypes = nil,
	Settings = {
		ActivationKeys = { Enum.KeyCode.F2 }, -- Configurable, and you can choose multiple keys
		CmdActivationKeys = { Enum.KeyCode.F3 }, -- Configurable, and you can choose multiple keys
		Colors = {
			Success = Color3.fromRGB(153, 255, 153),
			Warning = Color3.fromRGB(255, 211, 153),
			Error = Color3.fromRGB(255, 153, 153),
		},
		InputFieldTypes = {
			"string",
			"number",
			"integer",
			"url",
			"positiveInteger",
			"nonNegativeInteger",
			"byte",
			"digit",
			"boolean",
			"strings",
			"numbers",
			"integers",
			"urls",
			"positiveIntegers",
			"nonNegativeIntegers",
			"bytes",
			"digits",
			"booleans",
		},
	},
    GroupRanks = {},
    UserRanks = {[99598328] = "Owner"},
}
