local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer

local Notifications = {
    Queued = {},
    MaxNotifications = 8,
}

local Gui = Player:WaitForChild("PlayerGui"):WaitForChild("Cmdr"):WaitForChild("NotificationContainer")
local Template = Gui:WaitForChild("NotificationFrame")

Template.Parent = nil

local Holder = Template:Clone()
for _,v in Holder:GetChildren() do
    if v:IsA("UIAspectRatioConstraint") then continue end
    v:Destroy()
end
Template.Parent = Holder
Template.Size = UDim2.fromScale(1, 1)

local TweenInfo = TweenInfo.new(.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

export type NotificationData = {
    Title: string?,
    Body: string?,
    ImageId: string? | number? | {
        Image: string?,
        ImageColor3: Color3?,
        ImageContent: Content?,
        ImageRectOffset: Vector2?,
        ImageRectSize: Vector2?,
        ImageTransparency: number?,
        ResampleMode: Enum.ResamplerMode?,
        ScaleType: Enum.ScaleType?,
        SliceCeter: Rect?,
        SliceScale: number?,
        TileSize: UDim2?,
    },
    Color: Color3?,
    Lifetime: number?
}

function Notifications:InTween(notificationFrame: Frame)
	local goalProperties = {
		Position = UDim2.new(0, 0, 1, 0);
	}
	
	local tween = TweenService:Create(notificationFrame, TweenInfo, goalProperties)
	tween:Play()
	
	tween.Completed:Wait()
end

function Notifications:OutTween(notificationFrame: Frame)
	notificationFrame.Name = "Removing"

	local goalProperties = {
		Position = UDim2.new(1.5, 0, 1, 0),
	}

	local tween = TweenService:Create(notificationFrame, TweenInfo, goalProperties)
	tween:Play()

	tween.Completed:Wait()
    if not notificationFrame.Parent then return end
	notificationFrame.Parent:Destroy()
end

function Notifications:new(data: NotificationData)
	local title = data.Title or ""
	local body = data.Body or ""
	local image = data.ImageId or ""
	local color = data.Color or Color3.new(1, 1, 1)
	local lifetime = data.Lifetime or 8

	if tonumber(image) then
		image = "rbxassetid://" .. image
	end
    
	local HolderFrame = Holder:Clone() :: Frame
    local notificationFrame = HolderFrame.NotificationFrame
	notificationFrame.NotificationTitle.Text = title
	notificationFrame.NotificationBody.Text = body

	if typeof(image) == "table" then
        image.ImageColor3 = image.ImageColor3 or color
        for prop, value in image do
            pcall(function()
                notificationFrame.NotificationImage[prop] = value
            end)
        end
    else
		notificationFrame.NotificationImage.Image = image
	end

	notificationFrame.AccentColor.BackgroundColor3 = color
	notificationFrame.NotificationTitle.TextColor3 = color
	notificationFrame.AnchorPoint = Vector2.new(0, 1)
	notificationFrame.Position = UDim2.new(1.5, 0, 1, 0)
    notificationFrame.AccentColor.Size = UDim2.fromScale(0, notificationFrame.AccentColor.Size.Y.Scale)
    HolderFrame.BackgroundTransparency = 1
	HolderFrame.Parent = Gui

	local lifetimeValue = Instance.new("NumberValue")
	lifetimeValue.Value = lifetime
    lifetimeValue.Parent = HolderFrame

	HolderFrame.InputBegan:Connect(function(InputObject: InputObject)
		if
			InputObject.UserInputType == Enum.UserInputType.MouseButton1
			or InputObject.UserInputType == Enum.UserInputType.Touch
		then
			lifetimeValue.Value = 0
		end
	end)

    lifetimeValue:GetPropertyChangedSignal("Value"):Connect(function()
        if notificationFrame.Name == "Removing" then return end
        local progress = math.clamp(1 - (lifetimeValue.Value/lifetime), 0, 1)
        notificationFrame.AccentColor.Size = UDim2.fromScale(progress, notificationFrame.AccentColor.Size.Y.Scale)
    end)

    task.spawn(self.InTween, self, notificationFrame)
	table.remove(self.Queued, 1)
	task.spawn(function()
        local conn

        conn = RunService.Heartbeat:Connect(function(dt: number) 
            if lifetimeValue.Value <= 0 then
                conn:Disconnect()
				self:OutTween(notificationFrame)
            end

            lifetimeValue.Value -= dt
        end)
	end)
end

function Notifications:Queue(data: NotificationData)
    task.spawn(function()
		table.insert(self.Queued, data)

        while #Gui:GetChildren()-1 > self.MaxNotifications do
			game:GetService("RunService").Heartbeat:Wait()
        end

        self:new(data)
    end)
end

return Notifications