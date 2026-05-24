local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local MoneyService = {}

local function syncBalance(player: Player)
	local data = DataService.GetData(player)
	if data then

		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local coins = leaderstats:FindFirstChild("Coins")
			local gems = leaderstats:FindFirstChild("Gems")
			
			if coins then 
				coins.Value = data.Coins 
			end

			if gems then 
				gems.Value = data.Gems 
			end
		end

		Remotes.UpdateBalance:FireClient(player, {
			Coins = data.Coins,
			Gems  = data.Gems,
		})
	end
end

local function setupLeaderstats(player: Player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.Coins
	coins.Parent = leaderstats

	local gems = Instance.new("IntValue")
	gems.Name = "Gems"
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