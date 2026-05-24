local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local MoneyService = {}

local function syncBalance(player: Player)
	local data = DataService.GetData(player)
	if not data then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		local gems  = leaderstats:FindFirstChild("Gems")
		if coins then coins.Value = data.Coins end
		if gems  then gems.Value  = data.Gems  end
	end

	Remotes.UpdateBalance:FireClient(player, {
		Coins        = data.Coins,
		Gems         = data.Gems,
		IncomePerSec = data.IncomePerSec or 0,
	})
end

local function setupLeaderstats(player: Player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("NumberValue")
	coins.Name  = "Coins"
	coins.Value = data.Coins
	coins.Parent = leaderstats

	local gems = Instance.new("NumberValue")
	gems.Name  = "Gems"
	gems.Value = data.Gems
	gems.Parent = leaderstats
end

function MoneyService.OnPlayerReady(player: Player)
	setupLeaderstats(player, DataService.GetData(player))
	syncBalance(player)
end

function MoneyService.AddCoins(player: Player, amount: number)
	assert(type(amount) == "number" and amount > 0, "Invalid amount")
	local data = DataService.GetData(player)
	if not data then return end
	data.Coins += amount
end

function MoneyService.SpendCoins(player: Player, amount: number): boolean
	assert(type(amount) == "number" and amount > 0, "Invalid amount")
	local data = DataService.GetData(player)
	if not data then return false end
	if data.Coins < amount then return false end
	data.Coins -= amount
	syncBalance(player)
	return true
end

function MoneyService.AddGems(player: Player, amount: number)
	assert(type(amount) == "number" and amount > 0, "Invalid amount")
	local data = DataService.GetData(player)
	if not data then return end
	data.Gems += amount
end

function MoneyService.SpendGems(player: Player, amount: number): boolean
	assert(type(amount) == "number" and amount > 0, "Invalid amount")
	local data = DataService.GetData(player)
	if not data then return false end
	if data.Gems < amount then return false end
	data.Gems -= amount
	syncBalance(player)
	return true
end

function MoneyService.SyncBalance(player: Player)
	syncBalance(player)
end

Remotes.RequestBalance.OnServerEvent:Connect(function(player)
	syncBalance(player)
end)

return MoneyService