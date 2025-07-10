return function(Parent)
	local NotificationContainer = Instance.new("Frame")
	NotificationContainer.Name = "NotificationContainer"
	NotificationContainer.Parent = Parent
	NotificationContainer.AnchorPoint = Vector2.new(1, 1)
	NotificationContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	NotificationContainer.BackgroundTransparency = 1.000
	NotificationContainer.BorderColor3 = Color3.fromRGB(27, 42, 53)
	NotificationContainer.BorderSizePixel = 0
	NotificationContainer.ClipsDescendants = false
	NotificationContainer.Position = UDim2.new(0.994535208, 0, 0.989058852, 0)
    NotificationContainer.Size = UDim2.new(0.199203193, 0, 0.9799999, 0)

	local UIListLayout = Instance.new("UIListLayout")
	UIListLayout.Padding = UDim.new(0, 4)
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	UIListLayout.Parent = NotificationContainer

	local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint.Parent = NotificationContainer
    UIAspectRatioConstraint.AspectRatio = 0.360

	local NotificationFrame = Instance.new("Frame")
	NotificationFrame.Active = true
	NotificationFrame.Name = "NotificationFrame"
	NotificationFrame.Parent = NotificationContainer
	NotificationFrame.AnchorPoint = Vector2.new(0.5, 1)
	NotificationFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
	NotificationFrame.BackgroundTransparency = 0.400
	NotificationFrame.BorderColor3 = Color3.fromRGB(27, 42, 53)
	NotificationFrame.BorderSizePixel = 0
	NotificationFrame.Position = UDim2.new(0.5, 0, 1, 0)
    NotificationFrame.Size = UDim2.new(1, 0, 0.0912450179, 0)

	local NotificationImage = Instance.new("ImageLabel")
	NotificationImage.Name = "NotificationImage"
	NotificationImage.Parent = NotificationFrame
	NotificationImage.AnchorPoint = Vector2.new(0.5, 0.5)
	NotificationImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	NotificationImage.BackgroundTransparency = 1.000
	NotificationImage.BorderColor3 = Color3.fromRGB(27, 42, 53)
	NotificationImage.BorderSizePixel = 0
	NotificationImage.Position = UDim2.new(0.121333569, 0, 0.474073976, 0)
	NotificationImage.Size = UDim2.new(0.196333304, 0, 0.763088942, 0)
	NotificationImage.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    NotificationImage.ScaleType = Enum.ScaleType.Fit

	local NotificationTitle = Instance.new("TextLabel")
	NotificationTitle.Name = "NotificationTitle"
	NotificationTitle.Parent = NotificationFrame
	NotificationTitle.AnchorPoint = Vector2.new(0.5, 0.5)
	NotificationTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	NotificationTitle.BackgroundTransparency = 1.000
	NotificationTitle.BorderColor3 = Color3.fromRGB(27, 42, 53)
	NotificationTitle.BorderSizePixel = 0
	NotificationTitle.Position = UDim2.new(0.603333414, 0, 0.228366062, 0)
	NotificationTitle.Size = UDim2.new(0.736666739, 0, 0.325823933, 0)
	NotificationTitle.Font = Enum.Font.Unknown
	NotificationTitle.Text = "Notification"
	NotificationTitle.TextColor3 = Color3.fromRGB(255, 35, 57)
	NotificationTitle.TextScaled = true
	NotificationTitle.TextSize = 14.000
	NotificationTitle.TextWrapped = true
	NotificationTitle.TextXAlignment = Enum.TextXAlignment.Left
    NotificationTitle.TextYAlignment = Enum.TextYAlignment.Top

	local NotificationBody = Instance.new("TextLabel")
	NotificationBody.Name = "NotificationBody"
	NotificationBody.Parent = NotificationFrame
	NotificationBody.AnchorPoint = Vector2.new(0.5, 0.5)
	NotificationBody.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	NotificationBody.BackgroundTransparency = 1.000
	NotificationBody.BorderColor3 = Color3.fromRGB(27, 42, 53)
	NotificationBody.BorderSizePixel = 0
	NotificationBody.Position = UDim2.new(0.596039176, 0, 0.624825299, 0)
	NotificationBody.Size = UDim2.new(0.707491755, 0, 0.470134199, 0)
	NotificationBody.Font = Enum.Font.Roboto
	NotificationBody.Text = "This is a notification. This is a notification."
	NotificationBody.TextColor3 = Color3.fromRGB(255, 255, 255)
	NotificationBody.TextScaled = true
	NotificationBody.TextSize = 14.000
	NotificationBody.TextWrapped = true
	NotificationBody.TextXAlignment = Enum.TextXAlignment.Left
    NotificationBody.TextYAlignment = Enum.TextYAlignment.Top

	local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	UITextSizeConstraint.Parent = NotificationBody
    UITextSizeConstraint.MaxTextSize = 18

	local AccentColor = Instance.new("Frame")
	AccentColor.Name = "AccentColor"
	AccentColor.Parent = NotificationFrame
	AccentColor.AnchorPoint = Vector2.new(1, 0.5)
	AccentColor.BackgroundColor3 = Color3.fromRGB(255, 35, 57)
	AccentColor.BorderColor3 = Color3.fromRGB(27, 42, 53)
	AccentColor.BorderSizePixel = 0
	AccentColor.Position = UDim2.new(1, 0, 0.975000024, 0)
    AccentColor.Size = UDim2.new(1, 0, 0.0500000007, 0)

	local UIAspectRatioConstraint2 = Instance.new("UIAspectRatioConstraint")
	UIAspectRatioConstraint2.Parent = NotificationFrame
	UIAspectRatioConstraint2.AspectRatio = 3.947
end
