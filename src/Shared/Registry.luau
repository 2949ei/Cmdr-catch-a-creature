local RunService = game:GetService("RunService")
local Util = require(script.Parent.Util)

local Registry: Registry = {
	TypeMethods = Util.MakeDictionary({
		"Transform",
		"Validate",
		"Autocomplete",
		"Parse",
		"DisplayName",
		"Listable",
		"ValidateOnce",
		"Prefixes",
		"Default",
		"ArgumentOperatorAliases",
	}),
	CommandMethods = Util.MakeDictionary({
		"Name",
		"Aliases",
		"AutoExec",
		"Description",
		"Args",
		"Run",
		"ClientRun",
		"Data",
		"Group",
		"Guards",
		"Permissions",
	}),
	CommandArgProps = Util.MakeDictionary({ "Name", "Type", "Description", "Optional", "Default" }),
	Types = {},
	TypeAliases = {},
	Commands = {},
	CommandsArray = {},
	Cmdr = nil,
	Hooks = {
		BeforeRun = {},
		AfterRun = {},
	},
	Stores = setmetatable({}, {
		__index = function(self, k)
			self[k] = {}
			return self[k]
		end,
	}),
	AutoExecBuffer = {},
	AutoExecFlushConnection = nil :: RBXScriptConnection?,
}

function Registry.RegisterType(self: Registry, name: string, typeObject)
	if not name or typeof(name) ~= "string" then
		error("[CmdrPlus]: Invalid type name provided: nil")
	end

	if not name:find("^[%d%l]%w*$") then
		error(
			`[CmdrPlus]: Invalid type name provided: "{name}", type names must be alphanumeric and start with a lower-case letter or a digit.`
		)
	end

	for key in pairs(typeObject) do
		if self.TypeMethods[key] == nil then
			error(`[CmdrPlus]: Unknown key/method in type "{name}": {key}`)
		end
	end

	if self.Types[name] ~= nil then
		return
		--error(`[CmdrPlus]: Type {name} has already been registered.`)
	end

	typeObject.Name = name
	typeObject.DisplayName = typeObject.DisplayName or name

	self.Types[name] = typeObject

	if typeObject.Prefixes then
		self:RegisterTypePrefix(name, typeObject.Prefixes)
	end
end

function Registry.RegisterTypePrefix(self: Registry, name: string, union: string)
	if not self.TypeAliases[name] then
		self.TypeAliases[name] = name
	end

	self.TypeAliases[name] = ("%s %s"):format(self.TypeAliases[name], union)
end

function Registry.RegisterTypeAlias(self: Registry, name: string, alias: string)
	assert(self.TypeAliases[name] == nil, `[CmdrPlus]: Type alias {alias} already exists!`)
	self.TypeAliases[name] = alias
end

function Registry.RegisterTypesIn(self: Registry, container: Instance)
	for _, object in pairs(container:GetChildren()) do
		if object:IsA("ModuleScript") then
			object.Parent = self.Cmdr.ReplicatedRoot.Types

			require(object)(self)
		else
			self:RegisterTypesIn(object)
		end
	end
end

function Registry.RegisterHooksIn(self: Registry, container: Instance)
	for _, object in pairs(container:GetChildren()) do
		if object:IsA("ModuleScript") then
			object.Parent = self.Cmdr.ReplicatedRoot.Hooks

			require(object)(self)
		else
			self:RegisterHooksIn(object)
		end
	end
end

function Registry.RegisterCommandObject(self: Registry, commandObject)
	for key in pairs(commandObject) do
		if self.CommandMethods[key] == nil then
			error(`[CmdrPlus]: Unknown key/method in command "{commandObject.Name or "unknown command"}": {key}`)
		end
	end

	if commandObject.Args then
		for i, arg in pairs(commandObject.Args) do
			if type(arg) == "table" then
				for key in pairs(arg) do
					if self.CommandArgProps[key] == nil then
						error(
							`[CmdrPlus]: Unknown property in command "{commandObject.Name or "unknown"}" argument #{i}: {key}`
						)
					end
				end
			end
		end
	end

	if commandObject.AutoExec and RunService:IsClient() then
		table.insert(self.AutoExecBuffer, commandObject.AutoExec)
		self:FlushAutoExecBufferDeferred()
	end

	local oldCommand = self.Commands[commandObject.Name:lower()]
	if oldCommand and oldCommand.Aliases then
		for _, alias in pairs(oldCommand.Aliases) do
			self.Commands[alias:lower()] = nil
		end
	elseif not oldCommand then
		table.insert(self.CommandsArray, commandObject)
	end

	self.Commands[commandObject.Name:lower()] = commandObject

	if commandObject.Aliases then
		for _, alias in pairs(commandObject.Aliases) do
			self.Commands[alias:lower()] = commandObject
		end
	end
end

function Registry.RegisterCommand(
	self: Registry,
	commandScript: ModuleScript,
	commandServerScript: ModuleScript?,
	filter: ((any) -> boolean)?
)
	local commandObject = require(commandScript)
	assert(
		typeof(commandObject) == "table",
		`[CmdrPlus]: Invalid return value from command script "{commandScript.Name}" (CommandDefinition expected, got {typeof(
			commandObject
		)})`
	)

	if commandServerScript then
		assert(RunService:IsServer(), "[CmdrPlus]: The commandServerScript parameter is not valid for client usage.")
		commandObject.Run = require(commandServerScript)
	end

	if filter and not filter(commandObject) then
		return
	end

	self:RegisterCommandObject(commandObject)

	commandScript.Parent = self.Cmdr.ReplicatedRoot.Commands
end

function Registry.RegisterCommandsIn(self: Registry, container: Instance, filter: ((any) -> boolean)?)
	local skippedServerScripts = {}
	local usedServerScripts = {}

	for _, commandScript in pairs(container:GetChildren()) do
		if commandScript:IsA("ModuleScript") then
			if not commandScript.Name:find("Server") then
				local serverCommandScript = container:FindFirstChild(commandScript.Name .. "Server")

				if serverCommandScript then
					usedServerScripts[serverCommandScript] = true
				end

				self:RegisterCommand(commandScript, serverCommandScript, filter)
			else
				skippedServerScripts[commandScript] = true
			end
		else
			self:RegisterCommandsIn(commandScript, filter)
		end
	end

	for skippedScript in pairs(skippedServerScripts) do
		if not usedServerScripts[skippedScript] then
			warn(
				`[CmdrPlus]: Command script {skippedScript.Name} was skipped because it has 'Server' in its name, and has no equivalent shared script.`
			)
		end
	end
end

function Registry.RegisterDefaultCommands(self: Registry, arrayOrFunc: { string }? | (any) -> boolean?)
	assert(RunService:IsServer(), "[CmdrPlus]: RegisterDefaultCommands cannot be called from the client.")

	local dictionary = if type(arrayOrFunc) == "table" then Util.MakeDictionary(arrayOrFunc) else nil

	self:RegisterCommandsIn(self.Cmdr.DefaultCommandsFolder, dictionary ~= nil and function(command)
		return dictionary[command.Group] ~= nil or false
	end or (arrayOrFunc :: (any) -> boolean))
end

function Registry.GetCommand(self: Registry, name: string)
	name = name or ""
	return self.Commands[name:lower()]
end

function Registry.GetCommands(self: Registry): { any }
	return self.CommandsArray
end

function Registry.GetCommandNames(self: Registry): { string }
	local commands = {}

	for _, command in pairs(self.CommandsArray) do
		table.insert(commands, command.Name)
	end

	return commands
end

function Registry.GetCommandsAsStrings(self: Registry): { string }
	return self:GetCommandNames()
end

function Registry.GetTypeNames(self: Registry): { string }
	local typeNames = {}

	for typeName in pairs(self.Types) do
		table.insert(typeNames, typeName)
	end

	return typeNames
end

function Registry.GetType(self: Registry, name: string)
	return self.Types[name]
end

function Registry.GetTypeName(self: Registry, name: string): string | any
	return self.TypeAliases[name] or name
end

function Registry.RegisterHook(self: Registry, hookName: string, callback: (any) -> string?, priority: number)
	if not self.Hooks[hookName] then
		error(("[CmdrPlus]: Invalid hook name: %q"):format(hookName), 2)
	end

	table.insert(self.Hooks[hookName], { callback = callback, priority = priority or 0 })
	table.sort(self.Hooks[hookName], function(a, b)
		return a.priority < b.priority
	end)
end

function Registry.AddHook(self: Registry, hookName: string, callback: (any) -> string?, priority: number)
	self:RegisterHook(hookName, callback, priority)
end

function Registry.GetStore(self: Registry, name: string)
	return self.Stores[name]
end

function Registry.FlushAutoExecBufferDeferred(self: Registry)
	if self.AutoExecFlushConnection then
		return
	end

	self.AutoExecFlushConnection = RunService.Heartbeat:Connect(function()
		self.AutoExecFlushConnection:Disconnect()
		self.AutoExecFlushConnection = nil
		self:FlushAutoExecBuffer()
	end)
end

function Registry.FlushAutoExecBuffer(self: Registry)
	for _, commandGroup in ipairs(self.AutoExecBuffer) do
		for _, command in ipairs(commandGroup) do
			self.Cmdr.Dispatcher:EvaluateAndRun(command)
		end
	end

	self.AutoExecBuffer = {}
end

export type Registry = typeof(Registry)

return function(cmdr)
	Registry.Cmdr = cmdr

	return Registry :: Registry
end
