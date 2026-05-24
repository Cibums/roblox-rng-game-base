local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local HUDController = require(script.Parent.HUDController)

local MoneyController = {}

function MoneyController.Init()
	HUDController.Init()

	Remotes.UpdateBalance.OnClientEvent:Connect(function(balances)
		HUDController.SetCoins(balances.Coins)
		HUDController.SetGems(balances.Gems)
	end)

	Remotes.RequestBalance:FireServer()
end

return MoneyController