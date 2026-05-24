local Players = game:GetService("Players")
local UIComponents = require(script.Parent.UIComponents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HUDController = {}

local coinsLabel: TextLabel
local gemsLabel: TextLabel

function HUDController.Init()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Name = "CurrencyContainer"
	container.Size = UDim2.new(0, 180, 0, 104)
	container.Position = UDim2.new(0, 16, 0, 16)
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	coinsLabel = UIComponents.makeCurrencyChip(
		container, 0, "🪙",
		Color3.fromRGB(255, 210, 60),
		Color3.fromRGB(255, 220, 100)
	)

	gemsLabel = UIComponents.makeCurrencyChip(
		container, 54, "💎",
		Color3.fromRGB(100, 210, 255),
		Color3.fromRGB(130, 220, 255)
	)

	print("[HUDController] HUD initialised")
end

function HUDController.SetCoins(amount: number)
	if not coinsLabel then return end
	coinsLabel.Text = UIComponents.formatNumber(amount)
	UIComponents.flashLabel(coinsLabel)
end

function HUDController.SetGems(amount: number)
	if not gemsLabel then return end
	gemsLabel.Text = UIComponents.formatNumber(amount)
	UIComponents.flashLabel(gemsLabel)
end

return HUDController