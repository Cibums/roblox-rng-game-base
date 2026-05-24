local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local HUDController = require(script.Parent.HUDController)
local UIComponents = require(script.Parent.UIComponents)
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local MoneyController = {}

local STREAK_COLORS = {
	Color3.fromRGB(180, 180, 180),  -- day 1
	Color3.fromRGB(100, 200, 100),  -- day 2
	Color3.fromRGB(80,  160, 255),  -- day 3
	Color3.fromRGB(180, 80,  255),  -- day 4
	Color3.fromRGB(255, 160, 0),    -- day 5
	Color3.fromRGB(255, 80,  80),   -- day 6
	Color3.fromRGB(255, 215, 0),    -- day 7 — gold
}

local function showOfflineModal(earned: number, elapsed: number)
	local player = Players.LocalPlayer
	local gui = player:WaitForChild("PlayerGui")

	local screen = Instance.new("ScreenGui")
	screen.Name = "OfflineModal"
	screen.ResetOnSpawn = false
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = gui

	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.45
	backdrop.BorderSizePixel = 0
	backdrop.Parent = screen

	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 320, 0, 180)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
	card.BorderSizePixel = 0
	card.Parent = screen
	UIComponents.makeCorner(card, 14)
	UIComponents.makeStroke(card, Color3.fromRGB(80, 80, 120), 2)

	local hours = math.floor(elapsed / 3600)
	local mins  = math.floor((elapsed % 3600) / 60)
	local timeStr = hours > 0
		and string.format("%dh %dm", hours, mins)
		or string.format("%dm", mins)

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 44)
	header.Position = UDim2.new(0, 0, 0, 16)
	header.BackgroundTransparency = 1
	header.Text = "Welcome back!"
	header.TextColor3 = Color3.fromRGB(200, 200, 255)
	header.TextScaled = true
	header.Font = Enum.Font.GothamBold
	header.Parent = card

	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, -24, 0, 52)
	body.Position = UDim2.new(0, 12, 0, 66)
	body.BackgroundTransparency = 1
	body.Text = string.format(
		"Your pets earned\n🪙 %s while you were away (%s)",
		UIComponents.formatNumber(earned), timeStr
	)
	body.TextColor3 = Color3.fromRGB(255, 220, 100)
	body.TextScaled = true
	body.Font = Enum.Font.Gotham
	body.TextWrapped = true
	body.Parent = card

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -32, 0, 36)
	btn.Position = UDim2.new(0, 16, 1, -48)
	btn.BackgroundColor3 = Color3.fromRGB(80, 80, 200)
	btn.Text = "Collect"
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.BorderSizePixel = 0
	btn.Parent = card
	UIComponents.makeCorner(btn, 8)

	btn.MouseButton1Click:Connect(function()
		local info = TweenInfo.new(0.2)
		TweenService:Create(backdrop, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(card, info, { BackgroundTransparency = 1 }):Play()
		for _, child in card:GetDescendants() do
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				TweenService:Create(child, info, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
			end
		end
		task.delay(0.25, function() screen:Destroy() end)
	end)
end

local function showStreakModal(streakCount: number, day: number, reward: { coins: number? })
	local player = Players.LocalPlayer
	local gui = player:WaitForChild("PlayerGui")

	local screen = Instance.new("ScreenGui")
	screen.Name = "StreakModal"
	screen.ResetOnSpawn = false
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = gui

	local accentColor = STREAK_COLORS[day] or STREAK_COLORS[1]

	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel = 0
	backdrop.Parent = screen

	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 300, 0, 210)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
	card.BorderSizePixel = 0
	card.Parent = screen
	UIComponents.makeCorner(card, 14)
	UIComponents.makeStroke(card, accentColor, 2.5)

	local dayLabel = Instance.new("TextLabel")
	dayLabel.Size = UDim2.new(1, 0, 0, 36)
	dayLabel.Position = UDim2.new(0, 0, 0, 14)
	dayLabel.BackgroundTransparency = 1
	dayLabel.Text = string.format("Day %d Streak!", streakCount)
	dayLabel.TextColor3 = accentColor
	dayLabel.TextScaled = true
	dayLabel.Font = Enum.Font.GothamBold
	dayLabel.Parent = card

	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Size = UDim2.new(1, -24, 0, 60)
	rewardLabel.Position = UDim2.new(0, 12, 0, 58)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	rewardLabel.TextScaled = true
	rewardLabel.Font = Enum.Font.GothamBold
	rewardLabel.TextWrapped = true
	rewardLabel.Parent = card

	local parts = {}
	if reward.coins and reward.coins > 0 then
		table.insert(parts, "🪙 " .. UIComponents.formatNumber(reward.coins) .. " Coins")
	end
	rewardLabel.Text = table.concat(parts, "\n")

	local pipRow = Instance.new("Frame")
	pipRow.Size = UDim2.new(1, -24, 0, 24)
	pipRow.Position = UDim2.new(0, 12, 0, 130)
	pipRow.BackgroundTransparency = 1
	pipRow.Parent = card

	local pipLayout = Instance.new("UIListLayout")
	pipLayout.FillDirection = Enum.FillDirection.Horizontal
	pipLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pipLayout.Padding = UDim.new(0, 6)
	pipLayout.Parent = pipRow

	for i = 1, 7 do
		local pip = Instance.new("Frame")
		pip.Size = UDim2.new(0, 22, 0, 22)
		pip.BackgroundColor3 = i <= day
			and (STREAK_COLORS[i] or accentColor)
			or Color3.fromRGB(50, 50, 70)
		pip.BorderSizePixel = 0
		pip.Parent = pipRow
		UIComponents.makeCorner(pip, 11)
	end

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -32, 0, 36)
	btn.Position = UDim2.new(0, 16, 1, -46)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 100)
	btn.Text = day == 7 and "🎉 Claim!" or "Claim"
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.BorderSizePixel = 0
	btn.Parent = card
	UIComponents.makeCorner(btn, 8)

	btn.MouseButton1Click:Connect(function()
		local info = TweenInfo.new(0.2)
		TweenService:Create(backdrop, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(card, info, { BackgroundTransparency = 1 }):Play()
		for _, child in card:GetDescendants() do
			if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("Frame") then
				pcall(function()
					TweenService:Create(child, info, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
				end)
			end
		end
		task.delay(0.25, function() screen:Destroy() end)
	end)
end

function MoneyController.Init()
	HUDController.Init()

	Remotes.UpdateBalance.OnClientEvent:Connect(function(balances)
		HUDController.SetCoins(balances.Coins)
		HUDController.SetGems(balances.Gems)
		if balances.IncomePerSec then
			HUDController.SetIncomeRate(balances.IncomePerSec)
		end
	end)

	Remotes.ShowOfflineEarnings.OnClientEvent:Connect(function(earned, elapsed)
		showOfflineModal(earned, elapsed)
	end)

	Remotes.ShowDailyStreak.OnClientEvent:Connect(function(streakCount, day, reward)
		showStreakModal(streakCount, day, reward)
	end)

	Remotes.RequestBalance:FireServer()
end

return MoneyController