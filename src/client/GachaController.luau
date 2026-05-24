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

-- ─────────────────────────────────────────────
-- Shake a frame back and forth for a given duration
-- ─────────────────────────────────────────────

local function shake(frame: Frame, duration: number, amplitude: number)
	local origin = frame.Position
	local deadline = tick() + duration
	task.spawn(function()
		while tick() < deadline do
			TweenService:Create(frame, TweenInfo.new(0.07, Enum.EasingStyle.Sine), {
				Position = origin + UDim2.new(0, amplitude, 0, 0),
			}):Play()
			task.wait(0.07)
			TweenService:Create(frame, TweenInfo.new(0.07, Enum.EasingStyle.Sine), {
				Position = origin - UDim2.new(0, amplitude, 0, 0),
			}):Play()
			task.wait(0.07)
		end
		frame.Position = origin
	end)
end

-- ─────────────────────────────────────────────
-- Pulse the border color of a UIStroke
-- ─────────────────────────────────────────────

local function pulseStroke(stroke: UIStroke, duration: number)
	local colors = {
		Color3.fromRGB(255, 200, 50),
		Color3.fromRGB(200, 50, 255),
		Color3.fromRGB(50, 200, 255),
	}
	local deadline = tick() + duration
	local i = 1
	task.spawn(function()
		while tick() < deadline do
			TweenService:Create(stroke, TweenInfo.new(0.3, Enum.EasingStyle.Sine), {
				Color = colors[i],
			}):Play()
			i = (i % #colors) + 1
			task.wait(0.3)
		end
	end)
end

-- ─────────────────────────────────────────────
-- Build one card-back frame inside a parent
-- ─────────────────────────────────────────────

local function makeCardBack(parent: Frame): Frame
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(14, 14, 30)
	card.BorderSizePixel = 0
	card.Parent = parent
	UIComponents.makeCorner(card, 12)

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = Color3.fromRGB(255, 200, 50)
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = card

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "?"
	label.TextColor3 = Color3.fromRGB(200, 200, 255)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = card

	return card
end

-- ─────────────────────────────────────────────
-- Fade-flip a card back to a result card in place
-- ─────────────────────────────────────────────

local function flipToResult(cardFrame: Frame, result: { collectibleId: string, mutationId: string? })
	local pet = CollectiblesData.ById[result.collectibleId]
	local mutation = result.mutationId and MutationsData.ById[result.mutationId] or nil

	-- Fade out card back
	local fadeOut = TweenInfo.new(0.12, Enum.EasingStyle.Linear)
	for _, child in cardFrame:GetDescendants() do
		if child:IsA("UIStroke") then
			TweenService:Create(child, fadeOut, { Transparency = 1 }):Play()
		elseif child:IsA("TextLabel") or child:IsA("TextButton") then
			TweenService:Create(child, fadeOut, { TextTransparency = 1 }):Play()
		elseif child:IsA("Frame") then
			TweenService:Create(child, fadeOut, { BackgroundTransparency = 1 }):Play()
		end
	end
	TweenService:Create(cardFrame, fadeOut, { BackgroundTransparency = 1 }):Play()
	task.wait(0.15)

	-- Clear old children
	for _, child in cardFrame:GetChildren() do
		if not child:IsA("UICorner") then child:Destroy() end
	end

	-- Determine colors
	local borderColor = RARITY_COLORS[pet and pet.rarity] or RARITY_COLORS.Common
	if mutation then
		borderColor = Color3.fromRGB(mutation.color.r, mutation.color.g, mutation.color.b)
	end

	-- Rebuild as result card
	cardFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 32)
	cardFrame.BackgroundTransparency = 1

    local stroke = Instance.new("UIStroke")
	stroke.Thickness = mutation and 3.5 or 2
	stroke.Color = borderColor
	stroke.Transparency = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = cardFrame

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, 0, 0, 20)
	rarityLabel.Position = UDim2.new(0, 0, 0, 8)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.TextTransparency = 1
	rarityLabel.Text = pet and pet.rarity:upper() or "?"
	rarityLabel.TextColor3 = RARITY_COLORS[pet and pet.rarity] or RARITY_COLORS.Common
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = cardFrame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -8, 0, 34)
	nameLabel.Position = UDim2.new(0, 4, 0, 32)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextTransparency = 1
	nameLabel.Text = pet and pet.displayName or "Unknown"
	nameLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextWrapped = true
	nameLabel.Parent = cardFrame

	local yOffset = 70
	if mutation then
		local mutColor = Color3.fromRGB(mutation.color.r, mutation.color.g, mutation.color.b)
		local badge = Instance.new("Frame")
		badge.Size = UDim2.new(1, -12, 0, 22)
		badge.Position = UDim2.new(0, 6, 0, 70)
		badge.BackgroundColor3 = mutColor
		badge.BackgroundTransparency = 1
		badge.BorderSizePixel = 0
		badge.Parent = cardFrame
		UIComponents.makeCorner(badge, 5)

		local mutLabel = Instance.new("TextLabel")
		mutLabel.Size = UDim2.fromScale(1, 1)
		mutLabel.BackgroundTransparency = 1
		mutLabel.TextTransparency = 1
		mutLabel.Text = string.format("✨ %s %dx", mutation.displayName, mutation.valueMultiplier)
		mutLabel.TextColor3 = mutColor
		mutLabel.TextScaled = true
		mutLabel.Font = Enum.Font.GothamBold
		mutLabel.Parent = badge

		yOffset = 96
	end

	local effectiveIncome = (pet and pet.passiveIncomePerSec or 0) * (mutation and mutation.valueMultiplier or 1)
	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Size = UDim2.new(1, -8, 0, 20)
	incomeLabel.Position = UDim2.new(0, 4, 0, yOffset)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.TextTransparency = 1
	incomeLabel.Text = string.format("🪙 %s/s", UIComponents.formatNumber(effectiveIncome))
	incomeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	incomeLabel.TextScaled = true
	incomeLabel.Font = Enum.Font.Gotham
	incomeLabel.Parent = cardFrame

	-- Fade in result
	local fadeIn = TweenInfo.new(0.18, Enum.EasingStyle.Sine)
	TweenService:Create(cardFrame, fadeIn, { BackgroundTransparency = 0 }):Play()
    for _, child in cardFrame:GetDescendants() do
		if child:IsA("UIStroke") then
			TweenService:Create(child, fadeIn, { Transparency = 0 }):Play()
		elseif child:IsA("TextLabel") or child:IsA("TextButton") then
			TweenService:Create(child, fadeIn, { TextTransparency = 0 }):Play()
		elseif child:IsA("Frame") then
			-- Badge frames are semi-transparent, plain card frame is opaque
			local targetTransparency = child.Name == "card" and 0 or 0.6
			TweenService:Create(child, fadeIn, { BackgroundTransparency = targetTransparency }):Play()
		end
	end

	-- Highlight mutation with a flash
	if mutation then
		task.delay(0.2, function()
			TweenService:Create(stroke, TweenInfo.new(0.2), {
				Thickness = 5,
			}):Play()
			task.delay(0.25, function()
				TweenService:Create(stroke, TweenInfo.new(0.3), {
					Thickness = 3.5,
				}):Play()
			end)
		end)
	end
end

-- ─────────────────────────────────────────────
-- Main roll flow
-- ─────────────────────────────────────────────

function GachaController.Roll(count: number, currency: "Coins" | "Gems")
	if isRolling then return end
	isRolling = true

	-- Layout constants
	local isSingle = count == 1
	local CARD_W = isSingle and 200 or 120
	local CARD_H = isSingle and 260 or 155
	local COLS = math.min(count, 5)
	local ROWS = math.ceil(count / 5)
	local GAP = 10
	local TOTAL_W = COLS * CARD_W + (COLS - 1) * GAP
	local TOTAL_H = ROWS * CARD_H + (ROWS - 1) * GAP
	local MIN_SUSPENSE = 1.8  -- seconds of animation before reveal

	-- Build screen
	local screen = Instance.new("ScreenGui")
	screen.Name = "GachaRoll"
	screen.ResetOnSpawn = false
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = playerGui

	local backdrop = Instance.new("Frame")
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.35
	backdrop.BorderSizePixel = 0
	backdrop.Parent = screen

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(0, TOTAL_W, 0, TOTAL_H)
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.5)
	holder.BackgroundTransparency = 1
	holder.Parent = screen

	-- Spawn card backs staggered
	local cardFrames = {}
	for i = 1, count do
		local col = (i - 1) % 5
		local row = math.floor((i - 1) / 5)
		local container = Instance.new("Frame")
		container.Size = UDim2.new(0, CARD_W, 0, CARD_H)
		container.Position = UDim2.new(0, col * (CARD_W + GAP), 0, row * (CARD_H + GAP))
		container.BackgroundTransparency = 1
		container.Parent = holder
		UIComponents.makeCorner(container, 12)

		local cardBack = makeCardBack(container)
		cardBack.BackgroundTransparency = 1
		for _, child in cardBack:GetDescendants() do
			pcall(function() child.TextTransparency = 1 end)
		end

		-- Stagger card appearance
		task.delay((i - 1) * 0.06, function()
			TweenService:Create(cardBack, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0,
			}):Play()
			for _, child in cardBack:GetDescendants() do
				pcall(function()
					TweenService:Create(child, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()
				end)
			end
		end)

		table.insert(cardFrames, container)
	end

	-- Wait for all cards to appear, then shake + pulse
	task.wait(count * 0.06 + 0.25)
	local suspenseRemaining = MIN_SUSPENSE - (count * 0.06 + 0.25)

	for _, container in cardFrames do
		local cardBack = container:FindFirstChildOfClass("Frame")
		if cardBack then
			local stroke = cardBack:FindFirstChildOfClass("UIStroke")
			shake(container, suspenseRemaining, isSingle and 14 or 8)
			if stroke then pulseStroke(stroke, suspenseRemaining) end
		end
	end

	-- Fire server in parallel while animation plays
	local serverResult = nil
	task.spawn(function()
		serverResult = Remotes.RollGacha:InvokeServer(count, currency)
	end)

	-- Wait for suspense to finish, then for server
	task.wait(suspenseRemaining)
	while serverResult == nil do task.wait(0.05) end

	-- Stop shaking cleanly
	task.wait(0.1)

	-- Reveal cards one by one
	if serverResult and serverResult.success then
		for i, result in serverResult.results do
			task.wait(i == 1 and 0 or (isSingle and 0 or 0.35))
			flipToResult(cardFrames[i]:FindFirstChildOfClass("Frame") or cardFrames[i], result)
		end
	end

	-- Dismiss button appears after all reveals
	task.wait(count * 0.35 + 0.5)
	if not screen.Parent then
		isRolling = false
		return
	end

	local doneBtn = Instance.new("TextButton")
	doneBtn.Size = UDim2.new(0, 180, 0, 44)
	doneBtn.AnchorPoint = Vector2.new(0.5, 0)
	doneBtn.Position = UDim2.new(0.5, 0, 0, TOTAL_H / 2 + 20)
	doneBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 140)
	doneBtn.Text = count > 1 and "Done" or "Nice!"
	doneBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	doneBtn.TextScaled = true
	doneBtn.Font = Enum.Font.GothamBold
	doneBtn.BorderSizePixel = 0
	doneBtn.Parent = holder
	UIComponents.makeCorner(doneBtn, 10)

	-- Fade button in
	doneBtn.BackgroundTransparency = 1
	doneBtn.TextTransparency = 1
	TweenService:Create(doneBtn, TweenInfo.new(0.2), {
		BackgroundTransparency = 0, TextTransparency = 0,
	}):Play()

    local function dismiss()
		if not screen.Parent then return end
		local info = TweenInfo.new(0.2)
		TweenService:Create(backdrop, info, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(holder, info, { BackgroundTransparency = 1 }):Play()
		for _, child in holder:GetDescendants() do
			if child:IsA("Frame") then
				TweenService:Create(child, info, { BackgroundTransparency = 1 }):Play()
			elseif child:IsA("TextLabel") or child:IsA("TextButton") then
				TweenService:Create(child, info, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
			elseif child:IsA("UIStroke") then
				TweenService:Create(child, info, { Transparency = 1 }):Play()
			end
		end
		task.delay(0.25, function() screen:Destroy() end)
		isRolling = false
	end

	doneBtn.MouseButton1Click:Connect(dismiss)
	task.delay(6, dismiss)
end

-- ─────────────────────────────────────────────
-- Test button (remove when real shop UI exists)
-- ─────────────────────────────────────────────

local function buildTestButtons()
	local screen = Instance.new("ScreenGui")
	screen.Name = "GachaTest"
	screen.ResetOnSpawn = false
	screen.Parent = playerGui

	local function makeBtn(label, yOffset, onClick)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 140, 0, 40)
		btn.Position = UDim2.new(1, -156, 0, yOffset)
		btn.BackgroundColor3 = Color3.fromRGB(70, 50, 160)
		btn.Text = label
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextScaled = true
		btn.Font = Enum.Font.GothamBold
		btn.BorderSizePixel = 0
		btn.Parent = screen
		UIComponents.makeCorner(btn, 10)
		btn.MouseButton1Click:Connect(onClick)
	end

	makeBtn("🎲 Roll ×1",  16,  function() GachaController.Roll(1,  "Coins") end)
	makeBtn("🎲 Roll ×10", 62,  function() GachaController.Roll(10, "Coins") end)
end

function GachaController.Init()
	Remotes.ShowGachaResult.OnClientEvent:Connect(function(results)
		-- Robux purchase results — show inline without suspense animation
		for i, result in results do
			task.delay((i - 1) * 0.4, function()
				flipToResult(Instance.new("Frame"), result)
			end)
		end
	end)
	buildTestButtons()
	print("[GachaController] Initialised")
end

return GachaController