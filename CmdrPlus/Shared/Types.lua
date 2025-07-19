export type Settings = {
    ActivationKeys: {Enum.KeyCode? | Enum.UserInputType? },
    CmdActivationKeys: {Enum.KeyCode? | Enum.UserInputType? },
    Colors: {
        Success: Color3,
        Warning: Color3,
        Error: Color3,
        [string]: Color3
    },
    UserRanks: {
        [number]: string
    },
    GroupRanks: {
        {
            GroupId: number,
            Ranks: {
                [number]: string
            }
        }
    },
    InputFieldTypes: {
        string?
    }
}

return {}