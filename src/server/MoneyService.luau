local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local MoneyService = {}

local function syncBalance(player: Player)
	local data = DataService.GetData(player)
	if data then
		Remotes.UpdateBalance:FireClient(player, {
			Coins = data.Coins,
			Gems  = data.Gems,
		})
	end
end

function MoneyService.OnPlayerReady(player: Player)
	syncBalance(player)
end

function MoneyService.AddCoins(player: Player, amount: number)
	assert(type(amount) == "number" and amount > 0, "Invalid amount")
	local data = DataService.GetData(player)
	if not data then return end
	data.Coins += amount
	syncBalance(player)
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
	syncBalance(player)
end

Remotes.RequestBalance.OnServerEvent:Connect(function(player)
	syncBalance(player)
end)

return MoneyService