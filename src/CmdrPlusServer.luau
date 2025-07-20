local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Networker = require(script.Parent.Packages.Networker)
local Auth = require(script.Parent.Shared.Auth)
local DefaultSettings = require(script.Parent.Shared.DefaultSettings)
local Dispatcher = require(script.Parent.Shared.Dispatcher)
local Registry = require(script.Parent.Shared.Registry)
local Util = require(script.Parent.Shared.Util)
local CreateGui = require(script.Parent.UI.CreateGui)

local CmdrPlusServer: CmdrPlusServer = {
	inited = false,
	Auth = Auth,
	Util = Util,
	Settings = {} :: Settings,
}

--// CmdrPlusServer \\--
function CmdrPlusServer.Init(self: CmdrPlusServer)
	assert(not self.inited, "CmdrPlus is already Inited")
	assert(RunService:IsServer(), "CmdrPlusClient can only be Init on the Server")
	print("[CmdrPlusServer]: Initiating...")

	if not RunService:IsRunning() then
		return
	end

	self.networker = Networker.server.new("CmdrPlus", self, {
		self.Send
	})
	self.Registry = Registry(self)
	self.Dispatcher = Dispatcher(self)
	self.inited = true
	self.ReplicatedRoot = script.Parent
	self.DefaultCommandsFolder = self.ReplicatedRoot:WaitForChild("BuiltInCommands") :: Folder

	Util.Create("Folder", "Commands", self.ReplicatedRoot)
	Util.Create("Folder", "Types", self.ReplicatedRoot)
	Util.Create("Folder", "Hooks", self.ReplicatedRoot)

	self.Registry:RegisterTypesIn(script.Parent.BuiltInTypes)
	self.Registry:RegisterHooksIn(script.Parent.BuiltInHooks)

	script.Parent.BuiltInTypes:Destroy()
	script.Parent.BuiltInHooks:Destroy()
	script.Parent.BuiltInCommands.Name = "Server commands"

	if StarterGui:WaitForChild("Cmdr", 2) == nil then
		CreateGui()
	end

	print("[CmdrPlusServer]: Initiating Done")
end

function CmdrPlusServer.AutoRegister(self: CmdrPlusServer, autotegisterfile: AutoRegisterFile)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	assert(
		autotegisterfile.Roles and typeof(autotegisterfile.Roles) == "table",
		"Roles field is missing make it is there filled out or {}"
	)
	assert(
		autotegisterfile.CustomCommands == nil or autotegisterfile.CustomCommands:IsA("Folder"),
		"CustomCommands field is not a folder make it is there folder or nil"
	)
	assert(
		autotegisterfile.CustomHooks == nil or autotegisterfile.CustomHooks:IsA("Folder"),
		"CustomHooks field is not a folder make it is there folder or nil"
	)
	assert(
		autotegisterfile.CustomTypes == nil or autotegisterfile.CustomTypes:IsA("Folder"),
		"CustomTypes field is not a folder make it is there folder or nil"
	)
	assert(
		autotegisterfile.Settings and typeof(autotegisterfile.Settings) == "table",
		"Settings field is missing make it is there filled out or {}"
	)
	assert(
		autotegisterfile.GroupRanks and typeof(autotegisterfile.GroupRanks) == "table",
		"GroupRanks field is missing make it is there filled out or {}"
	)
	assert(
		autotegisterfile.UserRanks and typeof(autotegisterfile.UserRanks) == "table",
		"GroupRanks field is missing make it is there filled out or {}"
	)

	self:RegisterRoles(autotegisterfile.Roles)

	if autotegisterfile.CustomCommands then
		self.Registry:RegisterCommandsIn(autotegisterfile.CustomCommands)
	end

	if autotegisterfile.CustomHooks then
		self.Registry:RegisterHooksIn(autotegisterfile.CustomHooks)
	end

	if autotegisterfile.CustomTypes then
		self.Registry:RegisterTypesIn(autotegisterfile.CustomTypes)
	end

	for setting, data: any | { any } | { [string]: any } in autotegisterfile.Settings do
		local Isarray = typeof(data) == "table" and #data > 0 or false
		if Isarray then
			if not self.Settings[setting] then
				self.Settings[setting] = data
			else
				for _, val in data :: { any } do
					if not table.find(self.Settings[setting], val) then
						table.insert(self.Settings[setting], val)
					end
				end
			end
		elseif typeof(data) == "table" then
			for index, val in data :: { [string]: any } do
				self.Settings[setting][index] = val
			end
		end
	end

	self:RegisterGroups(autotegisterfile.GroupRanks)
	self:RegisterUsers(autotegisterfile.UserRanks)
end

function CmdrPlusServer.RegisterDefaultCommands(self: CmdrPlusServer, arrayOrFunc: { string }? | (any) -> boolean?)
	self.Registry:RegisterDefaultCommands(arrayOrFunc)
end

function CmdrPlusServer.Send(self: CmdrPlusServer, player, text, options)
	if #text > 10000 then
		return "Input too long"
	end

	return self.Dispatcher:EvaluateAndRun(text, player, options)
end

--// Auth \\--
function CmdrPlusServer.RegisterGroups(self: CmdrPlusServer, groups: { Auth.GroupData? })
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.Auth:RegisterGroups(groups)
end

function CmdrPlusServer.RegisterGroup(self: CmdrPlusServer, group: Auth.GroupData)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.Auth:RegisterGroup(group)
end

function CmdrPlusServer.RegisterRoles(self: CmdrPlusServer, roles: Auth.Roles)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.Auth:RegisterRoles(roles)
end

function CmdrPlusServer.RegisterRole(self: CmdrPlusServer, role: string, data: Auth.RoleData)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.Auth:RegisterRole(role, data)
end

function CmdrPlusServer.RegisterUsers(self: CmdrPlusServer, users: { [number | string]: string? })
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.Auth:RegisterUsers(users)
end

function CmdrPlusServer.RegisterUser(self: CmdrPlusServer, user: number | string, role: string)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.Auth:RegisterUser(user, role)
end

function CmdrPlusServer.IsPlayerAuthorized(
	self: CmdrPlusServer,
	id: number | string,
	permission: string? | { string? }
): boolean
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	return self.Auth:IsPlayerAuthorized(id, permission)
end

CmdrPlusServer.Settings = DefaultSettings

--// Types \\--
export type CmdrPlusServer = typeof(CmdrPlusServer) & {
	networker: Networker.Server,
	Registry: Registry.Registry,
	Dispatcher: Dispatcher.Dispatcher,
	Settings: Settings,
	ReplicatedRoot: Folder,
	DefaultCommandsFolder: Folder,
}

export type Settings = {
	ActivationKeys: { Enum.KeyCode? | Enum.UserInputType? },
	CmdActivationKeys: { Enum.KeyCode? | Enum.UserInputType? },
	Colors: {
		Success: Color3,
		Warning: Color3,
		Error: Color3,
		[string]: Color3,
	},
	InputFieldTypes: { string? },
}

export type AutoRegisterFile = {
	Roles: { [string]: Auth.RoleData? },
	CustomCommands: Folder?,
	CustomHooks: Folder?,
	CustomTypes: Folder?,
	Settings: Settings,
	GroupRanks: { Auth.GroupData? },
	UserRanks: { [number | string]: string }?,
}

return CmdrPlusServer :: CmdrPlusServer
