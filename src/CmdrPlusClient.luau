local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local Networker = require(script.Parent.Packages.Networker)
local Auth = require(script.Parent.Shared.Auth)
local DefaultSettings = require(script.Parent.Shared.DefaultSettings)
local Dispatcher = require(script.Parent.Shared.Dispatcher)
local Registry = require(script.Parent.Shared.Registry)
local Util = require(script.Parent.Shared.Util)

local Interface: any
local CmdrPlusClient: CmdrPlusClient = {
	inited = false,
	Auth = Auth,
	Util = Util,
	Settings = {} :: Settings,
	ActivationKeys = {} :: {[Enum.KeyCode | Enum.UserInputType]: true},
	CmdActivationKeys = {} :: {[Enum.KeyCode | Enum.UserInputType]: true},
	Enabled = true,
	MashToEnable = false,
	ActivationUnlocksMouse = false,
	HideOnLostFocus = true,
	PlaceName = "Cmdr",
	Events = {} :: {[string]: (...any) -> ()?},
}

--// CmdrPlusClient \\--
function CmdrPlusClient.Init(self: CmdrPlusClient): ()
	assert(not self.inited, "CmdrPlus is already Inited")
	assert(RunService:IsClient(), "CmdrPlusClient can only be Init on the client")
	print("[CmdrPlusClient]: Initiating...")

	if not RunService:IsRunning() then
		return
	end

	self.networker = Networker.client.new("CmdrPlus", self)
	self.Registry = Registry(self)
	self.Dispatcher = Dispatcher(self)
	self.inited = true
	self.ReplicatedRoot = script.Parent

	if
		StarterGui:WaitForChild("Cmdr")
		and wait()
		and Player:WaitForChild("PlayerGui"):FindFirstChild("Cmdr") == nil
	then
		StarterGui.Cmdr:Clone().Parent = Player.PlayerGui
	end

	Interface = require(script.Parent.UI.CmdrInterface)(self)
	
	self.Registry:RegisterCommandsIn(self.ReplicatedRoot:WaitForChild("Commands"))
	self.Registry:RegisterTypesIn(self.ReplicatedRoot:WaitForChild("Types"))
	self.Registry:RegisterHooksIn(self.ReplicatedRoot:WaitForChild("Hooks"))
	
	Interface.CmdWindow:Refesh()

	require(script.Parent.UI.DefaultEventHandlers)(self)

	print("[CmdrPlusClient]: Initiating Done")

	self:HasGuiAccess()
end

function CmdrPlusClient.AutoRegister(self: CmdrPlusClient, autotegisterfile: AutoRegisterFile)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	assert(
		autotegisterfile.Roles and typeof(autotegisterfile.Roles) == "table",
		"Roles field is missing make it is there filled out or {}"
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

	self:HasGuiAccess()
end

--// Auth \\--
function CmdrPlusClient.RegisterGroups(self: CmdrPlusClient, groups: { Auth.GroupData? })
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.Auth:RegisterGroups(groups)
end

function CmdrPlusClient.RegisterGroup(self: CmdrPlusClient, group: Auth.GroupData)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.Auth:RegisterGroup(group)
end

function CmdrPlusClient.RegisterRoles(self: CmdrPlusClient, roles: Auth.Roles)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.Auth:RegisterRoles(roles)
end

function CmdrPlusClient.RegisterRole(self: CmdrPlusClient, role: string, data: Auth.RoleData)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.Auth:RegisterRole(role, data)
end

function CmdrPlusClient.RegisterUsers(self: CmdrPlusClient, users: { [number | string]: string? })
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.Auth:RegisterUsers(users)
end

function CmdrPlusClient.RegisterUser(self: CmdrPlusClient, user: number | string, role: string)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.Auth:RegisterUser(user, role)
end

function CmdrPlusClient.IsPlayerAuthorized(
	self: CmdrPlusClient,
	id: number | string,
	permission: string? | { string? }
): boolean
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	return self.Auth:IsPlayerAuthorized(id, permission)
end

function CmdrPlusClient.Event(self: CmdrPlusClient, name: string, ...)
	local Event = self.Events[name]
	if Event then
		Event(...)
	end
end

CmdrPlusClient.Settings = DefaultSettings

--// CmdrPlusClient UI \\--

function CmdrPlusClient.HasGuiAccess(self: CmdrPlusClient)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")

	if self:IsPlayerAuthorized(Player) then
		self:SetActivationKeys(self.Settings.ActivationKeys :: {})
		self:SetCmdActivationKeys(self.Settings.CmdActivationKeys :: {})
	else
		self:SetActivationKeys({})
		self:SetCmdActivationKeys({})
	end
end

function CmdrPlusClient.SetActivationKeys(self: CmdrPlusClient, keys: { Enum.KeyCode })
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.ActivationKeys = Util.MakeDictionary(keys)
end

function CmdrPlusClient.SetCmdActivationKeys(self: CmdrPlusClient, keys: { Enum.KeyCode })
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.CmdActivationKeys = Util.MakeDictionary(keys)
end

function CmdrPlusClient.SetPlaceName(self: CmdrPlusClient, name: string)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.PlaceName = name
	Interface.Window:UpdateLabel()
end

function CmdrPlusClient.SetEnabled(self: CmdrPlusClient, enabled: boolean)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.Enabled = enabled
end

function CmdrPlusClient.SetActivationUnlocksMouse(self: CmdrPlusClient, enabled: boolean)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.ActivationUnlocksMouse = enabled
end

function CmdrPlusClient.Show(self: CmdrPlusClient)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	if not self.Enabled then
		return
	end

	Interface.Window:Show()
end

function CmdrPlusClient.Hide(self: CmdrPlusClient)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	Interface.Window:Hide()
end

function CmdrPlusClient.Toggle(self: CmdrPlusClient)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	if not self.Enabled then
		self:Hide()
		return
	end

	Interface.Window:SetVisible(not Interface.Window:IsVisible())
end

function CmdrPlusClient.SetMashToEnable(self: CmdrPlusClient, enabled: boolean)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.MashToEnable = enabled

	if enabled then
		self:SetEnabled(false)
	end
end

function CmdrPlusClient.SetHideOnLostFocus(self: CmdrPlusClient, enabled: boolean)
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.HideOnLostFocus = enabled
end

function CmdrPlusClient.HandleEvent(self: CmdrPlusClient, name: string, callback: (...any) -> ())
	assert(self.inited, "Init CmdrPlus befor running AutoRegister")
	self.Events[name] = callback
end

--// Types \\--
export type CmdrPlusClient = typeof(CmdrPlusClient) & {
	networker: Networker.Client,
	Registry: Registry.Registry,
	Dispatcher: Dispatcher.Dispatcher,
	Settings: Settings,
	ReplicatedRoot: Folder,
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

return CmdrPlusClient :: CmdrPlusClient
