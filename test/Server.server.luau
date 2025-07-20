local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AutoRegisterFile = require(ReplicatedStorage.AutoRegisterFile)
local CmdrPlus = require(ReplicatedStorage.CmdrPlus)
local CmdrPlusServer: CmdrPlus.Server = CmdrPlus.server

CmdrPlusServer:Init()
CmdrPlusServer:RegisterDefaultCommands()
CmdrPlusServer:AutoRegister(AutoRegisterFile)