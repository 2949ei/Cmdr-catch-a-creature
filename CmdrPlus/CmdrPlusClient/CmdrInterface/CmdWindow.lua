local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Player = Players.LocalPlayer

function getViewport(obj)
	return (
		obj.Parent:IsA("GuiBase2d")
			and (obj.Parent:IsA("ScrollingFrame") and obj.Parent.AbsoluteCanvasSize or obj.Parent.AbsoluteSize)
		or workspace.CurrentCamera.ViewportSize
	)
end

return function(Cmdr)
	local Registry = Cmdr.Registry
	local Dispatcher = Cmdr.Dispatcher
	local Settings = Cmdr.Settings

	local CmdWindow = {
		CommandData = nil,
		ProcessEntry = nil,
		Notifications = nil,
		Cmdr = Cmdr,
	}

	local Detect = Player:WaitForChild("PlayerGui"):WaitForChild("Cmdr"):WaitForChild("Detect") :: Frame
	local Gui = Player:WaitForChild("PlayerGui"):WaitForChild("Cmdr"):WaitForChild("Cmd") :: Frame
	local DropMenu = Player:WaitForChild("PlayerGui"):WaitForChild("Cmdr"):WaitForChild("DropMenu") :: Frame
	local CmdList = Gui:WaitForChild("CmdList") :: ScrollingFrame
	local Header = Gui:WaitForChild("Header") :: Frame
	local Close = Header:WaitForChild("Close")
	local HeaderSample = CmdList:WaitForChild("HeaderSample") :: Frame
	local CmdSample = CmdList:WaitForChild("CmdSample") :: ImageButton
	local Content = Gui:WaitForChild("Content") :: Frame
	local Arguments = Content:WaitForChild("Arguments") :: ScrollingFrame
	local DescriptionLabel = Arguments:WaitForChild("DescriptionLabel")
	local ArgumentSample = Arguments:WaitForChild("ArgumentSample") :: Frame
	local DropList = DropMenu:WaitForChild("ScrollingFrame") :: ScrollingFrame
	local DropButton = DropList:WaitForChild("DropButton") :: TextButton
	local DropSearch = DropMenu:WaitForChild("TextBox") :: TextBox
	local Run = Content:WaitForChild("Buttons"):WaitForChild("Close") :: TextButton
	local InfoLabel = Content:WaitForChild("InfoLabel") :: TextLabel

	function CmdWindow:Show()
		Gui.Visible = true
	end

	function CmdWindow:Hide()
		Gui.Visible = false
	end

	function CmdWindow:LoadCommandArguments(cmd)
		local command = Dispatcher:Evaluate(cmd, Player, true)
		local commandObject = Registry:GetCommand(cmd)

		self.CommandData = {
			Command = command,
			Args = {},
		}

		for _, btn in Arguments:GetChildren() do
			if not btn:IsA("ImageButton") and not btn:IsA("Frame") or btn == ArgumentSample then
				continue
			end
			btn:Destroy()
		end

		DescriptionLabel.Text = commandObject.Description
		for _index, Argument in command.Arguments do
			local argument = ArgumentSample:Clone()
			argument.Parent = Arguments
			argument.Name = Argument.Object.Name
			argument.LayoutOrder = _index
			argument.NameLabel.Text = Argument.Object.Name
			argument.DescLabel.Text = Argument.Object.Description
			argument.Visible = true
			self.CommandData.Args[_index] = {}

			if not table.find(Settings.InputFieldTypes, Argument.Object.Type) then
				local button = argument.Menu
				button.BackgroundColor3 = if Argument.Object.Optional then Color3.new() else Color3.new(0.7, 0, 0)
				self:ConnectDropMenu(button, Argument, _index)
				argument.Menu.Visible = true
			else
				local button = argument.Input :: TextBox
				argument.Menu.Visible = false
				button.Visible = true
				button.BackgroundColor3 = if Argument.Object.Optional then Color3.new() else Color3.new(0.7, 0, 0)
				button.PlaceholderText = `{Argument.Object.Name} here`
				button:GetPropertyChangedSignal("Text"):Connect(function()
					Argument.RawValue = button.Text
					Argument.TextSegmentInProgress = button.Text
					Argument.TransformedValues = {}
					Argument:Transform()
					local state = Argument:Validate()
					button.BackgroundColor3 = if state then Color3.new() else Color3.new(0.7, 0, 0)
					self.CommandData.Args[_index] = state and button.Text or nil
				end)
			end
		end
	end

	function CmdWindow:LoadDropdown(items, multi, callback)
		for _, btn in DropList:GetChildren() do
			if not btn:IsA("TextButton") or btn == DropButton then
				continue
			end
			btn:Destroy()
		end

		for index, item in items do
			local newitem = DropButton:Clone()
			newitem.Parent = DropList
			newitem.Text = item
			newitem.Name = item
			newitem.LayoutOrder = index
			newitem.Visible = true
			newitem.Active = true
			newitem.Activated:Connect(function()
				local Added = callback(item, not multi)
				if Added then
					newitem.BackgroundTransparency = 0.9
				else
					newitem.BackgroundTransparency = 1
				end

				if not multi then
					Detect.Visible = false
					DropMenu.Visible = false
					Arguments.ScrollingEnabled = true
				end
			end)
		end
	end

	function CmdWindow:ConnectDropMenu(button: TextButton, Argument, _index)
		local function update(List)
			Argument.RawValue = table.concat(List, ",")
			Argument.TextSegmentInProgress = table.concat(List, ",")
			Argument.TransformedValues = {}
			Argument:Transform()
			local state = Argument:Validate()

			button.BackgroundColor3 = if state then Color3.new() else Color3.new(0.7, 0, 0)
			button.Text = if Argument.Type.Listable
				then `{#List} {Argument.Type.Name} Selected`
				else `{List[1] or "None"}`
		end

		update({})

		button.Active = true
		button.Activated:Connect(function()
			if Detect.Visible then
				return
			end
			Detect.Visible = true
			DropMenu.Visible = true
			Arguments.ScrollingEnabled = false

			local pos = (button.AbsolutePosition + button.AbsoluteSize)
			DropMenu.Position = UDim2.fromOffset(pos.X, pos.Y)
			local strings = Argument:GetDefaultAutocomplete()
			self:LoadDropdown(strings, Argument.Type.Listable, function(item, overide)
				local List = self.CommandData.Args[_index]
				if overide then
					if List[1] == item then
						List[1] = nil
						update(List)
						return false
					else
						List[1] = item
						update(List)
						return true
					end
				else
					local found = table.find(List, item)
					if found then
						table.remove(List, found)
						update(List)
						return false
					end

					table.insert(List, item)
					update(List)
					return true
				end
			end)
		end)
	end

	function CmdWindow:Refesh()
		local Commands = Registry:GetCommands()
		local SortedByGroup = {}

		for _index, cmddata in Commands do
			if cmddata.Group == "Help" then
				continue
			end
			if not SortedByGroup[cmddata.Group] then
				SortedByGroup[cmddata.Group] = {}
			end
			table.insert(SortedByGroup[cmddata.Group], cmddata)
		end

		for _group, cmds in SortedByGroup do
			table.sort(cmds, function(a, b)
				return a.Name < b.Name
			end)
		end

		for _, btn in CmdList:GetChildren() do
			if not btn:IsA("ImageButton") and not btn:IsA("Frame") or btn == CmdSample or btn == HeaderSample then
				continue
			end
			btn:Destroy()
		end

		local i = 0
		for group, cmds in SortedByGroup do
			i += 1
			local newHeader = HeaderSample:Clone()
			newHeader.Parent = CmdList
			newHeader.LayoutOrder = i * 10000
			newHeader.Label.Text = group
			newHeader.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			newHeader.Visible = true

			for pos, cmd in cmds do
				local newCmd = CmdSample:Clone()
				newCmd.Active = true
				newCmd.Name = cmd.Name
				newCmd.Parent = CmdList
				newCmd.LayoutOrder = (i * 10000) + pos
				newCmd.Label.Text = cmd.Name
				newCmd.BackgroundColor3 = if pos % 2 == 0 then Color3.fromRGB(0, 0, 0) else Color3.fromRGB(17, 17, 17)
				newCmd.Visible = true
				newCmd.Activated:Connect(function()
					self:LoadCommandArguments(cmd.Name)
				end)
			end
		end
	end

	function CmdWindow:BeginInput(input, gameProcessed)
		if GuiService.MenuIsOpen then
			self:Hide()
		end
	
		if gameProcessed and self:IsVisible() == false then
			return
		end
	
		if self.Cmdr.CmdActivationKeys[input.KeyCode] then -- Activate the command bar
			if self.Cmdr.Enabled then
				self:SetVisible(not self:IsVisible())
	
				if GuiService.MenuIsOpen then -- Special case for menu getting stuck open (roblox bug)
					self:Hide()
				end
			end
	
			return
		end
	
		if self.Cmdr.Enabled == false or not self:IsVisible() then
			if self:IsVisible() then
				self:Hide()
			end
	
			return
		end
	end

	function CmdWindow:DisplayLine(data)
		local text, options, waittime = "", {}, nil
		if typeof(data) == "table" and data.line then
			options = data.color or {}
			text = tostring(data.line)
			waittime = data.waittime
		else
			options = options or {}
			text = tostring(data)
			waittime = waittime
		end
	
		if typeof(options) == "Color3" then
			options = { Color = options }
		end

		if #text == 0 then
			return
		end

		local Colors = CmdWindow.Cmdr.Settings.Colors
		local errored = text:match("An error") ~= nil

		self.Notifications:Queue({
			Title = errored and "" or "Succes",
			Body = text,
			ImageId = {
				Image = "rbxassetid://16898617325",
				ImageRectOffset = Vector2.new(514, 257),
				ImageRectSize = Vector2.new(256, 256),
			},
			Color = options.Color or errored and Colors.Error or Colors.Success,
			Lifetime = waittime or not errored and 2 or errored and 5,
		})
	end

	function CmdWindow:IsVisible()
		return Gui.Visible
	end

	function CmdWindow:SetVisible(visible)
		Gui.Visible = visible
	end

	local Down = false
	local StartPos = Vector2.new()
	Header.InputBegan:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			Down = true
			local inputpos = input.Position
			local pos = Vector2.new(inputpos.X, inputpos.Y)
			local guipos = Gui.AbsolutePosition
			StartPos = guipos - pos
		end
	end)

	Header.InputEnded:Connect(function(input: InputObject)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			Down = false
		end
	end)

	Detect.InputEnded:Connect(function(input: InputObject)
		if
			(input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
			and DropMenu.Visible
		then
			local ps = input.Position
			local ap = DropMenu.AbsolutePosition
			local as = DropMenu.AbsoluteSize
			if ps.X < ap.X or ps.X > ap.X + as.X or ps.Y < ap.Y or ps.Y > ap.Y + as.Y then
				DropMenu.Visible = false
				Arguments.ScrollingEnabled = true
				--task.wait(0.1)
				Detect.Visible = false
			end
		end
	end)

	DropSearch:GetPropertyChangedSignal("Text"):Connect(function()
		local NewText = DropSearch.Text
		for _, v in DropList:GetChildren() do
			if v:IsA("TextButton") and v ~= DropButton then
				if NewText ~= "" then
					v.Visible = string.find(v.Text, NewText)
				else
					v.Visible = true
				end
			end
		end
	end)

	Run.Active = true
	Run.Activated:Connect(function()
		if not CmdWindow.CommandData then return end
		local Command = CmdWindow.CommandData.Command
		local commandValid, errorText = Command:Validate()

		if commandValid then
			local Text = Command.Name

			for _, arg in Command.Arguments do
				Text ..= ` {arg.RawValue}`
			end

			CmdWindow.ProcessEntry(Text)
		else
			CmdWindow.Notifications:Queue({
				Title = "Errored",
				Body = errorText,
				ImageId = {
					Image = "rbxassetid://16898791187",
					ImageRectOffset = Vector2.new(257, 514),
					ImageRectSize =  Vector2.new(256, 256),
				},
				Color = CmdWindow.Cmdr.Settings.Colors.Error,
				Lifetime = 5
			})
		end
	end)

	Close.Active = true
	Close.Activated:Connect(function()
		CmdWindow:Hide()
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		return CmdWindow:BeginInput(input, gameProcessed)
	end)

	RunService.Heartbeat:Connect(function()
		if not Down then
			return
		end
		local mouse = Player:GetMouse()
		local opos = Vector2.new(mouse.X, mouse.Y) + StartPos
		local viewport = getViewport(Gui)

		Gui.Position = UDim2.fromScale((opos.X / viewport.X), (opos.Y / viewport.Y))
	end)

	return CmdWindow
end
