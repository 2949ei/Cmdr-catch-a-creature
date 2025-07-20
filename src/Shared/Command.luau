local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Argument = require(script.Parent.Argument)

local IsServer = RunService:IsServer()

local Command = {}
Command.__index = Command

function Command.new(options)
	local self = {}

	self.Dispatcher = options.Dispatcher
	self.Object = options.CommandObject
	self.RawText = options.Text
	self.Alias = options.Alias
	self.Executor = options.Executor
	self.RawArguments = options.Arguments
	self.Data = options.Data
	self.Guards = options.Guards

	self.Cmdr = self.Dispatcher.Cmdr
	self.Name = self.Object.Name
	self.Group = self.Object.Group
	self.Aliases = self.Object.Aliases
	self.Description = self.Object.Description
	self.ArgumentDefinitions = self.Object.Args

	self.Colors = self.Cmdr.Settings.Colors

	self.State = {}
	self.Arguments = {}
	self.Response = nil

	setmetatable(self, Command)

	return self
end

function Command:ExecutorHasPermissions(Permission)
	return self.Cmdr.Auth:IsPlayerAuthorized(self.Executor.UserId, Permission)
end

function Command:GetRoleSetting(user, Permission)
	return self.Cmdr.Auth:IsPlayerAuthorized(user, Permission)
end

function Command:IsPlayerAuthorized(user)
	return self.Cmdr.Auth:IsPlayerAuthorized(user)
end

function Command:Parse(allowIncompleteArguments)
	local hadOptional = false
	for i, definition in ipairs(self.ArgumentDefinitions) do
		if type(definition) == "function" then
			definition = definition(self)

			if definition == nil then
				break
			end
		end

		local required = (definition.Default == nil and definition.Optional ~= true)

		if required and hadOptional then
			error(
				("[CmdrPlus]: Command %q: Required arguments cannot occur after optional arguments."):format(self.Name)
			)
		elseif not required then
			hadOptional = true
		end

		if self.RawArguments[i] == nil and required and allowIncompleteArguments ~= true then
			return false, ("Required argument #%d %s is missing."):format(i, definition.Name)
		elseif self.RawArguments[i] or allowIncompleteArguments then
			self.Arguments[i] = Argument.new(self, definition, self.RawArguments[i] or "")
		end
	end

	return true
end

function Command:Validate(isFinal)
	self._Validated = true
	local errorText = ""
	local success = true

	for i, arg in pairs(self.Arguments) do
		local argSuccess, argErrorText = arg:Validate(isFinal)

		if not argSuccess then
			success = false
			errorText = ("%s; #%d %s: %s"):format(errorText, i, arg.Name, argErrorText or "error")
		end
	end

	return success, errorText:sub(3)
end

function Command:GetLastArgument()
	for i = #self.Arguments, 1, -1 do
		if self.Arguments[i].RawValue then
			return self.Arguments[i]
		end
	end
end

function Command:GatherArgumentValues()
	local values = {}

	for i = 1, #self.ArgumentDefinitions do
		local arg = self.Arguments[i]
		if arg then
			values[i] = arg:GetValue()
		elseif type(self.ArgumentDefinitions[i]) == "table" then
			values[i] = self.ArgumentDefinitions[i].Default
		end
	end

	return values, #self.ArgumentDefinitions
end

function Command:Run()
	if self._Validated == nil then
		error("[CmdrPlus]: Must validate a command before running.")
	end

	local beforeRunHook = self.Dispatcher:RunHooks("BeforeRun", self)
	if beforeRunHook then
		return beforeRunHook
	end

	local guardMethods = self.Dispatcher:RunGuards(self)
	if guardMethods then
		return guardMethods
	end

	if not IsServer and self.Object.Data and self.Data == nil then
		local values, length = self:GatherArgumentValues()
		self.Data = self.Object.Data(self, unpack(values, 1, length))
	end

	if not IsServer and self.Object.ClientRun then
		local values, length = self:GatherArgumentValues()
		self.Response = self.Object.ClientRun(self, unpack(values, 1, length))
	end

	if self.Response == nil then
		if self.Object.Run then
			local values, length = self:GatherArgumentValues()
			self.Response = self.Object.Run(self, unpack(values, 1, length))
		elseif IsServer then
			if self.Object.ClientRun then
				warn(
					`[CmdrPlus]: {self.Name} command fell back to the server because ClientRun returned nil, but there is no server implementation! Either return a string from ClientRun, or create a server implementation for this command.`
				)
			else
				warn(`[CmdrPlus]: {self.Name} command has no implementation!`)
			end

			self.Response = "No implementation."
		else
			self.Response = self.Dispatcher:Send(self.RawText, self.Data)
		end
	end

	local afterRunHook = self.Dispatcher:RunHooks("AfterRun", self)
	if afterRunHook then
		return afterRunHook
	else
		if typeof(self.Response) == "table" and not self.Response.line then
			error("Command return data is not valid to be diplayed")
		elseif typeof(self.Response) == "string" then
			self.Response = { line = self.Response }
		end

		return self.Response
	end
end

function Command:GetArgument(index)
	return self.Arguments[index]
end

function Command:GetData()
	if self.Data then
		return self.Data
	end

	if self.Object.Data and not IsServer then
		self.Data = self.Object.Data(self)
	end

	return self.Data
end

function Command:SendEvent(player, event, ...)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "[CmdrPlus]: Argument #1 must be a Player")
	assert(type(event) == "string", "[CmdrPlus]: Argument #2 must be a string")

	if IsServer then
		self.Dispatcher.Cmdr.networker:fire(player, "Event", event, ...)
	elseif self.Dispatcher.Cmdr.Events[event] then
		assert(
			player == Players.LocalPlayer,
			"[CmdrPlus]: Event messages can only be sent to the local player on the client."
		)
		self.Dispatcher.Cmdr.Events[event](...)
	end
end

function Command:BroadcastEvent(...)
	if not IsServer then
		error("[CmdrPlus]: Can't broadcast event messages from the client.", 2)
	end

	self.Dispatcher.Cmdr.networker:fireAll("Event", ...)
end

function Command:Reply(...)
	return self:SendEvent(self.Executor, "AddLine", ...)
end

function Command:GetStore(...)
	return self.Dispatcher.Cmdr.Registry:GetStore(...)
end

function Command:HasImplementation()
	return ((RunService:IsClient() and self.Object.ClientRun) or self.Object.Run) and true or false
end

return Command
