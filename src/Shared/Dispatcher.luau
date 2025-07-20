local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local Util = require(script.Parent.Util)
local Command = require(script.Parent.Command)

local HISTORY_SETTING_NAME = "CmdrCommandHistory"
local displayedBeforeRunHookWarning = false

local Dispatcher = {
	Cmdr = nil,
	Registry = nil,
}

function Dispatcher.Evaluate(
	self: Dispatcher,
	text: string,
	executor: Player,
	allowIncompleteArguments: boolean?,
	data: any?
)
	if RunService:IsClient() == true and executor ~= Players.LocalPlayer then
		error("[CmdrPlus]: Can't evaluate a command that isn't sent by the local player.")
	end

	local arguments = Util.SplitString(text)
	local commandName = table.remove(arguments, 1)
	local commandObject = self.Registry:GetCommand(commandName)

	if commandObject then
		arguments = Util.MashExcessArguments(arguments, #commandObject.Args)

		local command = Command.new({
			Dispatcher = self,
			Text = text,
			CommandObject = commandObject,
			Alias = commandName,
			Executor = executor,
			Arguments = arguments,
			Data = data,
		})
		local success, errorText = command:Parse(allowIncompleteArguments)

		if success then
			return command
		else
			return false, errorText
		end
	else
		return false,
			("%q is not a valid command name. Use the help command to see all available commands."):format(
				tostring(commandName)
			)
	end
end

function Dispatcher.EvaluateAndRun(
	self: Dispatcher,
	text: string,
	executor: Player?,
	options: {
		Data: any?,
		IsHuman: boolean?,
	}?
)
	executor = executor or Players.LocalPlayer
	options = options or {}

	if RunService:IsClient() and (options :: any).IsHuman then
		self:PushHistory(text)
	end

	local command, errorText = self:Evaluate(text, executor :: Player, nil, (options :: any).Data)

	if not command then
		return errorText
	end

	local ok, out = xpcall(function()
		local valid, errorText = command:Validate(true)

		if not valid then
			return errorText
		end

		return command:Run() or "Command executed."
	end, function(value)
		return debug.traceback(tostring(value))
	end)

	if not ok then
		warn((`[CmdrPlus]: Error occurred while evaluating command string %q\n{tostring(out)}`):format(text))
	end

	return ok and out or "An error occurred while running this command. Check the console for more information."
end

function Dispatcher.Send(self: Dispatcher, text: string, data: any?)
	if RunService:IsClient() == false then
		error("[CmdrPlus]: Dispatcher:Send can only be called from the client.")
	end

	return self.Cmdr.networker:fetch("Send", text, {
		Data = data,
	})
end

function Dispatcher.Run(self: Dispatcher, ...): string
	if not Players.LocalPlayer then
		error("[CmdrPlus]: Dispatcher:Run can only be called from the client.")
	end

	local args = { ... }
	local text = args[1]

	for i = 2, #args do
		text = text .. " " .. tostring(args[i])
	end

	local command, errorText = self:Evaluate(text, Players.LocalPlayer)

	if not command then
		error(errorText)
	end

	local success, errorText = command:Validate(true)

	if not success then
		error(errorText)
	end

	return command:Run()
end

function Dispatcher.RunGuards(self: Dispatcher, commandContext, ...)
	local guardMethods = commandContext.Object.Guards
	if guardMethods == nil then
		return
	end

	local typeofGuardMethods = typeof(guardMethods)
	assert(typeofGuardMethods == "table", `expected a table for Command.Guards, got {typeofGuardMethods}`)

	for _, guardMethod in pairs(guardMethods) do
		local typeofGuardMethod = typeof(guardMethod)
		assert(
			typeofGuardMethod == "function",
			`expected a function for a value in Command.Guards, got {typeofGuardMethod}`
		)

		local guardResult = guardMethod(commandContext, ...)
		if guardResult == nil then
			continue
		end

		return tostring(guardResult)
	end
	return
end

function Dispatcher.RunHooks(self: Dispatcher, hookName: string, commandContext, ...)
	if not self.Registry.Hooks[hookName] then
		error(("[CmdrPlus]: Invalid hook name: %q"):format(hookName), 2)
	end

	if
		hookName == "BeforeRun"
		and #self.Registry.Hooks[hookName] == 0
		and commandContext.Group ~= "DefaultUtil"
		and commandContext.Group ~= "UserAlias"
		and commandContext:HasImplementation()
	then
		if RunService:IsStudio() then
			if displayedBeforeRunHookWarning == false then
				commandContext:Reply(
					(RunService:IsServer() and "<Server>" or "<Client>")
						.. " Commands will not run in-game if no BeforeRun hook is configured. Learn more: https://eryn.io/Cmdr/guide/Hooks.html",
					Color3.fromRGB(255, 228, 26)
				)
				displayedBeforeRunHookWarning = true
			end
		else
			return "Command blocked for security as no BeforeRun hook is configured."
		end
	end

	for _, hook in ipairs(self.Registry.Hooks[hookName]) do
		local value = hook.callback(commandContext, ...)

		if value ~= nil then
			if typeof(value) == "table" and value.line then
				return value
			end

			return tostring(value)
		end
	end
end

function Dispatcher.PushHistory(self: Dispatcher, text: string)
	assert(RunService:IsClient(), "[CmdrPlus]: PushHistory may only be used from the client.")

	local history = self:GetHistory()

	if Util.TrimString(text) == "" or text == history[#history] then
		return
	end

	history[#history + 1] = text

	TeleportService:SetTeleportSetting(HISTORY_SETTING_NAME, history)
end

function Dispatcher.GetHistory(self: Dispatcher): { string }
	assert(RunService:IsClient(), "[CmdrPlus]: GetHistory may only be used from the client.")

	return TeleportService:GetTeleportSetting(HISTORY_SETTING_NAME) or {}
end

export type Dispatcher = typeof(Dispatcher)

return function(cmdr)
	Dispatcher.Cmdr = cmdr
	Dispatcher.Registry = cmdr.Registry

	return Dispatcher :: Dispatcher
end
