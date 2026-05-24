local TweenService = game:GetService("TweenService")

local UIComponents = {}

function UIComponents.makeCorner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

function UIComponents.makePadding(parent: Instance, px: number)
	local p = Instance.new("UIPadding")
	p.PaddingLeft   = UDim.new(0, px)
	p.PaddingRight  = UDim.new(0, px)
	p.PaddingTop    = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.Parent = parent
end

function UIComponents.makeStroke(parent: Instance, color: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

function UIComponents.flashLabel(label: TextLabel)
	local tween = TweenService:Create(label, TweenInfo.new(0.1), {
		TextColor3 = Color3.fromRGB(255, 255, 255),
	})
	tween:Play()
	tween.Completed:Connect(function()
		TweenService:Create(label, TweenInfo.new(0.3), {
			TextColor3 = label:GetAttribute("BaseColor"),
		}):Play()
	end)
end

function UIComponents.formatNumber(n: number): string
	if n >= 1_000_000_000 then
		return string.format("%.1fB", n / 1_000_000_000)
	elseif n >= 1_000_000 then
		return string.format("%.1fM", n / 1_000_000)
	elseif n >= 1_000 then
		return string.format("%.1fK", n / 1_000)
	end
	return tostring(math.floor(n))
end

function UIComponents.makeCurrencyChip(
	parent: Frame,
	yOffset: number,
	iconText: string,
	iconColor: Color3,
	baseTextColor: Color3
): TextLabel

	local chip = Instance.new("Frame")
	chip.Name = "Chip"
	chip.Size = UDim2.new(0, 180, 0, 44)
	chip.Position = UDim2.new(0, 0, 0, yOffset)
	chip.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
	chip.BackgroundTransparency = 0.15
	chip.BorderSizePixel = 0
	chip.Parent = parent
	UIComponents.makeCorner(chip, 10)
	UIComponents.makeStroke(chip, Color3.fromRGB(60, 60, 90), 1.5)

	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 36, 1, 0)
	icon.Position = UDim2.new(0, 0, 0, 0)
	icon.BackgroundTransparency = 1
	icon.Text = iconText
	icon.TextColor3 = iconColor
	icon.TextScaled = true
	icon.Font = Enum.Font.GothamBold
	icon.Parent = chip

	local label = Instance.new("TextLabel")
	label.Name = "Value"
	label.Size = UDim2.new(1, -44, 1, 0)
	label.Position = UDim2.new(0, 40, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = "0"
	label.TextColor3 = baseTextColor
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = chip

	label:SetAttribute("BaseColor", baseTextColor)

	return label
end

return UIComponents