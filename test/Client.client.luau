local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AutoRegisterFile = require(ReplicatedStorage.AutoRegisterFile)
local CmdrPlus = require(ReplicatedStorage.CmdrPlus)
local CmdrPlusClient: CmdrPlus.Client = CmdrPlus.client

CmdrPlusClient:Init()
CmdrPlusClient:AutoRegister(AutoRegisterFile)
