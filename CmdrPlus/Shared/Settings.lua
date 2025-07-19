local Types = require(script.Parent.Types)

local Settings: Types.Settings = {
	ActivationKeys = { Enum.KeyCode.F2 }, -- Configurable, and you can choose multiple keys
	CmdActivationKeys = { Enum.KeyCode.F3 }, -- Configurable, and you can choose multiple keys
	Colors = {
		Success = Color3.fromRGB(153, 255, 153),
		Warning = Color3.fromRGB(255, 211, 153),
		Error = Color3.fromRGB(255, 153, 153),
	},
	UserRanks = {
		--[userid] = Role
		[game.CreatorId] = "Owner",
	},
	GroupRanks = {
		{
			GroupId = 0,
			Ranks = {
				[255] = "Owner",
				[253] = "Admin",
			},
		},
	},
	InputFieldTypes = {
		"string","number","integer",
		"url","positiveInteger","nonNegativeInteger",
		"byte","digit","boolean",
		"strings","numbers","integers",
		"urls","positiveIntegers","nonNegativeIntegers",
		"bytes","digits","booleans",
	}
}

return Settings
