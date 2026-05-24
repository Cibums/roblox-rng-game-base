local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local UIComponents = require(script.Parent.UIComponents)
local CollectiblesData = require(game.ReplicatedStorage.Shared.CollectiblesData)
local MutationsData = require(game.ReplicatedStorage.Shared.MutationsData)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GachaController = {}
local isRolling = false

local RARITY_COLORS = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(80,  200, 80),
	Rare      = Color3.fromRGB(80,  140, 255),
	Epic      = Color3.fromRGB(180, 80,  255),
	Legendary = Color3.fromRGB(255, 180, 0),
	Mythic    = Color3.fromRGB(255, 60,  60),
	Divine    = Color3.fromRGB(255, 220, 255),
}

local function showResultCard(result: { collectibleId: string, mutationId: string? })
	local pet = CollectiblesData.ById[result.collectibleId]
	if not pet then return end

	local mutation = result.mutationId and MutationsData.ById[result.mutationId] or nil

	-- Border color: mutation color takes priority over rarity color
	local borderColor = RARITY_COLORS[pet.rarity] or RARITY_COLORS.Common
	if mutation then
		borderColor = Color3.fromRGB(mutation.color.r, mutation.color.g, mutation.color.b)
	end

	local screen = Instance.new("ScreenGui")
	screen.Name = "GachaResult"
	screen.ResetOnSpawn = false
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = playerGui

	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel = 0
	backdrop.Parent = screen

	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 260, 0, mutation and 230 or 200)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	card.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
	card.BorderSizePixel = 0
	card.Parent = screen
	UIComponents.makeCorner(card, 14)
	UIComponents.makeStroke(card, borderColor, mutation and 3.5 or 2)

	-- Rarity label
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, 0, 0, 28)
	rarityLabel.Position = UDim2.new(0, 0, 0, 12)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = pet.rarity:upper()
	rarityLabel.TextColor3 = RARITY_COLORS[pet.rarity] or RARITY_COLORS.Common
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = card

	-- Pet name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -16, 0, 40)
	nameLabel.Position = UDim2.new(0, 8, 0, 44)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = pet.displayName
	nameLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextWrapped = true
	nameLabel.Parent = card

	-- Mutation badge — only shown if a mutation was rolled
	local incomeYOffset = 90
	if mutation then
		local mutColor = Color3.fromRGB(mutation.color.r, mutation.color.g, mutation.color.b)

		local badge = Instance.new("Frame")
		badge.Size = UDim2.new(1, -32, 0, 28)
		badge.Position = UDim2.new(0, 16, 0, 90)
		badge.BackgroundColor3 = mutColor
		badge.BackgroundTransparency = 0.7
		badge.BorderSizePixel = 0
		badge.Parent = card
		UIComponents.makeCorner(badge, 6)
		UIComponents.makeStroke(badge, mutColor, 1.5)

		local mutLabel = Instance.new("TextLabel")
		mutLabel.Size = UDim2.fromScale(1, 1)
		mutLabel.BackgroundTransparency = 1
		mutLabel.Text = string.format("✨ %s  (%d×)", mutation.displayName, mutation.valueMultiplier)
		mutLabel.TextColor3 = mutColor
		mutLabel.TextScaled = true
		mutLabel.Font = Enum.Font.GothamBold
		mutLabel.Parent = badge

		incomeYOffset = 126
	end

	-- Income rate (after mutation multiplier)
	local effectiveIncome = pet.passiveIncomePerSec * (mutation and mutation.valueMultiplier or 1)
	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Size = UDim2.new(1, -16, 0, 28)
	incomeLabel.Position = UDim2.new(0, 8, 0, incomeYOffset)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = string.format("🪙 %s / sec", UIComponents.formatNumber(effectiveIncome))
	incomeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	incomeLabel.TextScaled = true
	incomeLabel.Font = Enum.Font.Gotham
	incomeLabel.Parent = card

	-- Dismiss button
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -32, 0, 36)
	btn.Position = UDim2.new(0, 16, 1, -46)
	btn.BackgroundColor3 = mutation
		and Color3.fromRGB(mutation.color.r // 2, mutation.color.g // 2, mutation.color.b // 2)
		or  Color3.fromRGB(60, 60, 180)
	btn.Text = mutation and "🎉 Amazing!" or "Nice!"
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.BorderSizePixel = 0
	btn.Parent = card
	UIComponents.makeCorner(btn, 8)

	local function dismiss()
		local info = TweenInfo.new(0.15)
		TweenService:Create(backdrop, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(card, info, { BackgroundTransparency = 1 }):Play()
		for _, child in card:GetDescendants() do
			if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("Frame") then
				pcall(function()
					TweenService:Create(child, info, {
						BackgroundTransparency = 1,
						TextTransparency = 1,
					}):Play()
				end)
			end
		end
		task.delay(0.2, function() screen:Destroy() end)
	end

	btn.MouseButton1Click:Connect(dismiss)
	task.delay(3, function()
		if screen and screen.Parent then dismiss() end
	end)
end

local function onGachaResult(results)
	for i, result in results do
		task.delay((i - 1) * 0.6, function()
			showResultCard(result)
		end)
	end
end

function GachaController.Roll(count: number, currency: "Coins" | "Gems")
	if isRolling then return end
	isRolling = true

	local response = Remotes.RollGacha:InvokeServer(count, currency)

	if response and response.success then
		for i, result in response.results do
			task.delay((i - 1) * 0.6, function()
				showResultCard(result)
			end)
		end
	else
		warn("[GachaController]", response and response.reason or "Roll failed")
	end

	isRolling = false
end

local function buildTestButton()
	local screen = Instance.new("ScreenGui")
	screen.Name = "GachaTest"
	screen.ResetOnSpawn = false
	screen.Parent = playerGui

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 140, 0, 44)
	btn.Position = UDim2.new(1, -156, 0, 16)
	btn.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
	btn.Text = "🎲 Roll (1)"
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.BorderSizePixel = 0
	btn.Parent = screen
	UIComponents.makeCorner(btn, 10)

	btn.MouseButton1Click:Connect(function()
		GachaController.Roll(1, "Coins")
	end)
end

function GachaController.Init()
	Remotes.ShowGachaResult.OnClientEvent:Connect(onGachaResult)
	buildTestButton()
	print("[GachaController] Initialised")
end

return GachaController