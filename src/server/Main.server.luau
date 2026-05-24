local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)
local MoneyService = require(script.Parent.MoneyService)
local PetService = require(script.Parent.PetService)
local IncomeService = require(script.Parent.IncomeService)

IncomeService.Start()

Players.PlayerAdded:Connect(function(player)
	task.defer(function()
		local attempts = 0
		while not DataService.GetProfile(player) and attempts < 20 do
			task.wait(0.5)
			attempts += 1
		end
		if DataService.GetProfile(player) then
			MoneyService.OnPlayerReady(player)
			PetService.GiveStarterPetIfNeeded(player)
		end
	end)
end)