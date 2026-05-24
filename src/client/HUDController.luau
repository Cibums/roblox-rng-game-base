local Players = game:GetService("Players")
local UIComponents = require(script.Parent.UIComponents)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HUDController = {}

local coinsLabel: TextLabel
local gemsLabel: TextLabel
local incomeLabel: TextLabel   -- new

function HUDController.Init()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local container = Instance.new("Frame")
	container.Name = "CurrencyContainer"
	container.Size = UDim2.new(0, 180, 0, 158)   -- taller to fit income row
	container.Position = UDim2.new(0, 16, 0, 16)
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	coinsLabel = UIComponents.makeCurrencyChip(
		container, 0, "🪙",
		Color3.fromRGB(255, 210, 60),
		Color3.fromRGB(255, 220, 100)
	)

	-- Income-per-second label, sits directly below the coins chip
	incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeRate"
	incomeLabel.Size = UDim2.new(1, 0, 0, 20)
	incomeLabel.Position = UDim2.new(0, 0, 0, 48)   -- just below coins chip
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "+0/sec"
	incomeLabel.TextColor3 = Color3.fromRGB(160, 210, 130)
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
	incomeLabel.TextSize = 13
	incomeLabel.Font = Enum.Font.Gotham
	incomeLabel.Parent = container

	gemsLabel = UIComponents.makeCurrencyChip(
		container, 72, "💎",   -- shifted down to make room for income row
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

function HUDController.SetIncomeRate(ratePerSec: number)
	if not incomeLabel then return end
	incomeLabel.Text = "+" .. UIComponents.formatNumber(ratePerSec) .. "/sec"
end

return HUDController