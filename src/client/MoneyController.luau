local Players = game:GetService("Players")
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local MoneyController = {}

function MoneyController.Init()
	Remotes.UpdateBalance.OnClientEvent:Connect(function(balances)
		print("[MoneyController] Coins:", balances.Coins, "| Gems:", balances.Gems)
	end)
    
	Remotes.RequestBalance:FireServer()
end

return MoneyController