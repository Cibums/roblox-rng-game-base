local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local UIComponents = require(script.Parent.UIComponents)
local CollectiblesData = require(game.ReplicatedStorage.Shared.CollectiblesData)
local MutationsData = require(game.ReplicatedStorage.Shared.MutationsData)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local InventoryController = {}
local inventoryScreen = nil

local RARITY_COLORS = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(80,  200, 80),
	Rare      = Color3.fromRGB(80,  140, 255),
	Epic      = Color3.fromRGB(180, 80,  255),
	Legendary = Color3.fromRGB(255, 180, 0),
	Mythic    = Color3.fromRGB(255, 60,  60),
	Divine    = Color3.fromRGB(255, 220, 255),
}

local RARITY_ORDER = { Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6, Divine=7 }

-- ─────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────

local function getEffectiveIncome(ownedPet)
	local def = CollectiblesData.ById[ownedPet.collectibleId]
	if not def then return 0 end
	local base = def.passiveIncomePerSec
	if ownedPet.mutationId then
		local mut = MutationsData.ById[ownedPet.mutationId]
		if mut then return base * mut.valueMultiplier end
	end
	return base
end

local function sortPets(pets)
	table.sort(pets, function(a, b)
		-- Equipped first
		if a.isEquipped ~= b.isEquipped then return a.isEquipped end
		-- Then by effective income desc
		return getEffectiveIncome(a) > getEffectiveIncome(b)
	end)
end

-- ─────────────────────────────────────────────
-- Build a single pet card
-- onToggle(instanceId, isCurrentlyEquipped) called on click
-- ─────────────────────────────────────────────

local function buildPetCard(parent, ownedPet, onToggle): Frame
	local def = CollectiblesData.ById[ownedPet.collectibleId]
	local mutation = ownedPet.mutationId and MutationsData.ById[ownedPet.mutationId] or nil
	local income = getEffectiveIncome(ownedPet)

	local rarityColor = def and RARITY_COLORS[def.rarity] or RARITY_COLORS.Common
	local borderColor = mutation
		and Color3.fromRGB(mutation.color.r, mutation.color.g, mutation.color.b)
		or rarityColor

	local card = Instance.new("Frame")
	card.Size = UDim2.new(0, 140, 0, 175)
	card.BackgroundColor3 = ownedPet.isEquipped
		and Color3.fromRGB(22, 22, 46)
		or  Color3.fromRGB(16, 16, 28)
	card.BorderSizePixel = 0
	card.Parent = parent
	UIComponents.makeCorner(card, 10)
	UIComponents.makeStroke(card, borderColor, ownedPet.isEquipped and 2.5 or 1.2)

	-- Equipped badge
	if ownedPet.isEquipped then
		local badge = Instance.new("Frame")
		badge.Size = UDim2.new(1, 0, 0, 20)
		badge.Position = UDim2.new(0, 0, 0, 0)
		badge.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
		badge.BorderSizePixel = 0
		badge.Parent = card
		UIComponents.makeCorner(badge, 8)

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.fromScale(1, 1)
		badgeLabel.BackgroundTransparency = 1
		badgeLabel.Text = "✓ EQUIPPED"
		badgeLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
		badgeLabel.TextScaled = true
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.Parent = badge
	end

	-- Rarity
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, -8, 0, 16)
	rarityLabel.Position = UDim2.new(0, 4, 0, ownedPet.isEquipped and 24 or 6)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = def and def.rarity or "?"
	rarityLabel.TextColor3 = rarityColor
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
	rarityLabel.Parent = card

	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, -8, 0, 38)
	nameLabel.Position = UDim2.new(0, 4, 0, ownedPet.isEquipped and 42 or 24)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def and def.displayName or "Unknown"
	nameLabel.TextColor3 = Color3.fromRGB(235, 235, 255)
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextWrapped = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = card

	local yBase = ownedPet.isEquipped and 82 or 64

	-- Mutation badge
	if mutation then
		local mutColor = Color3.fromRGB(mutation.color.r, mutation.color.g, mutation.color.b)
		local mutFrame = Instance.new("Frame")
		mutFrame.Size = UDim2.new(1, -8, 0, 20)
		mutFrame.Position = UDim2.new(0, 4, 0, yBase)
		mutFrame.BackgroundColor3 = mutColor
		mutFrame.BackgroundTransparency = 0.6
		mutFrame.BorderSizePixel = 0
		mutFrame.Parent = card
		UIComponents.makeCorner(mutFrame, 5)

		local mutLabel = Instance.new("TextLabel")
		mutLabel.Size = UDim2.fromScale(1, 1)
		mutLabel.BackgroundTransparency = 1
		mutLabel.Text = string.format("✨ %s %dx", mutation.displayName, mutation.valueMultiplier)
		mutLabel.TextColor3 = mutColor
		mutLabel.TextScaled = true
		mutLabel.Font = Enum.Font.GothamBold
		mutLabel.Parent = mutFrame

		yBase += 24
	end

	-- Income
	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Size = UDim2.new(1, -8, 0, 18)
	incomeLabel.Position = UDim2.new(0, 4, 0, yBase)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = "🪙 " .. UIComponents.formatNumber(income) .. "/s"
	incomeLabel.TextColor3 = Color3.fromRGB(180, 220, 140)
	incomeLabel.TextScaled = true
	incomeLabel.Font = Enum.Font.Gotham
	incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
	incomeLabel.Parent = card

	-- Equip / Unequip button
	local actionBtn = Instance.new("TextButton")
	actionBtn.Size = UDim2.new(1, -12, 0, 28)
	actionBtn.Position = UDim2.new(0, 6, 1, -34)
	actionBtn.BackgroundColor3 = ownedPet.isEquipped
		and Color3.fromRGB(120, 30, 30)
		or  Color3.fromRGB(30, 80, 160)
	actionBtn.Text = ownedPet.isEquipped and "Unequip" or "Equip"
	actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	actionBtn.TextScaled = true
	actionBtn.Font = Enum.Font.GothamBold
	actionBtn.BorderSizePixel = 0
	actionBtn.Parent = card
	UIComponents.makeCorner(actionBtn, 6)

	actionBtn.MouseButton1Click:Connect(function()
		onToggle(ownedPet.instanceId, ownedPet.isEquipped)
	end)

	return card
end

-- ─────────────────────────────────────────────
-- Refresh the grid inside an existing scroll frame
-- ─────────────────────────────────────────────

local function refreshGrid(scrollFrame: ScrollingFrame, onToggle)
	for _, child in scrollFrame:GetChildren() do
		if not child:IsA("UIGridLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end

	local pets = Remotes.GetInventory:InvokeServer()
	sortPets(pets)

	for _, ownedPet in pets do
		buildPetCard(scrollFrame, ownedPet, onToggle)
	end

	-- Update canvas size
	local layout = scrollFrame:FindFirstChildOfClass("UIGridLayout")
	if layout then
		local rows = math.ceil(#pets / 3)
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, rows * (175 + 10) + 10)
	end

	return pets
end

-- ─────────────────────────────────────────────
-- Open the inventory panel
-- ─────────────────────────────────────────────

local function openInventory()
	if inventoryScreen then return end

	inventoryScreen = Instance.new("ScreenGui")
	inventoryScreen.Name = "Inventory"
	inventoryScreen.ResetOnSpawn = false
	inventoryScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	inventoryScreen.Parent = playerGui

	-- Background panel
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 500, 0.85, 0)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(12, 12, 24)
	panel.BorderSizePixel = 0
	panel.Parent = inventoryScreen
	UIComponents.makeCorner(panel, 14)
	UIComponents.makeStroke(panel, Color3.fromRGB(60, 60, 100), 2)

	-- Header
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 52)
	header.BackgroundColor3 = Color3.fromRGB(18, 18, 40)
	header.BorderSizePixel = 0
	header.Parent = panel
	UIComponents.makeCorner(header, 14)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -220, 1, 0)
	title.Position = UDim2.new(0, 16, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🎒 My Pets"
	title.TextColor3 = Color3.fromRGB(200, 200, 255)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	-- Equip Best button
	local equipBestBtn = Instance.new("TextButton")
	equipBestBtn.Size = UDim2.new(0, 110, 0, 34)
	equipBestBtn.Position = UDim2.new(1, -168, 0.5, 0)
	equipBestBtn.AnchorPoint = Vector2.new(0, 0.5)
	equipBestBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 60)
	equipBestBtn.Text = "⚡ Equip Best"
	equipBestBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	equipBestBtn.TextScaled = true
	equipBestBtn.Font = Enum.Font.GothamBold
	equipBestBtn.BorderSizePixel = 0
	equipBestBtn.Parent = header
	UIComponents.makeCorner(equipBestBtn, 8)

	-- Close button
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 40, 0, 34)
	closeBtn.Position = UDim2.new(1, -50, 0.5, 0)
	closeBtn.AnchorPoint = Vector2.new(0, 0.5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(140, 30, 30)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.TextScaled = true
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.BorderSizePixel = 0
	closeBtn.Parent = header
	UIComponents.makeCorner(closeBtn, 8)

	-- Scrolling grid
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Size = UDim2.new(1, -16, 1, -62)
	scrollFrame.Position = UDim2.new(0, 8, 0, 58)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 140)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = panel

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 140, 0, 175)
	grid.CellPadding = UDim2.new(0, 10, 0, 10)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scrollFrame

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.Parent = scrollFrame

	-- Toggle handler — server call + refresh
	local isRefreshing = false
	local function onToggle(instanceId, isCurrentlyEquipped)
		if isRefreshing then return end
		isRefreshing = true

		if isCurrentlyEquipped then
			Remotes.UnequipPet:InvokeServer(instanceId)
		else
			Remotes.EquipPet:InvokeServer(instanceId)
		end

		refreshGrid(scrollFrame, onToggle)
		isRefreshing = false
	end

	-- Equip Best handler
	equipBestBtn.MouseButton1Click:Connect(function()
		if isRefreshing then return end
		isRefreshing = true
		Remotes.EquipBest:InvokeServer()
		refreshGrid(scrollFrame, onToggle)
		isRefreshing = false
	end)

	-- Close handler
	local function closeInventory()
		if inventoryScreen then
			inventoryScreen:Destroy()
			inventoryScreen = nil
		end
	end
	closeBtn.MouseButton1Click:Connect(closeInventory)

	-- Initial load
	refreshGrid(scrollFrame, onToggle)
end

-- ─────────────────────────────────────────────
-- Open button on HUD
-- ─────────────────────────────────────────────

function InventoryController.Init()
	local screen = Instance.new("ScreenGui")
	screen.Name = "InventoryButton"
	screen.ResetOnSpawn = false
	screen.Parent = playerGui

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 110, 0, 40)
	btn.Position = UDim2.new(0, 16, 0, 136)   -- below the currency HUD
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 90)
	btn.Text = "🎒 My Pets"
	btn.TextColor3 = Color3.fromRGB(200, 200, 255)
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.BorderSizePixel = 0
	btn.Parent = screen
	UIComponents.makeCorner(btn, 10)
	UIComponents.makeStroke(btn, Color3.fromRGB(70, 70, 130), 1.5)

	btn.MouseButton1Click:Connect(function()
		if inventoryScreen then
			inventoryScreen:Destroy()
			inventoryScreen = nil
		else
			openInventory()
		end
	end)

	print("[InventoryController] Initialised")
end

return InventoryController