print("[Server] boot script running")

local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)
local MoneyService = require(script.Parent.MoneyService)

Players.PlayerAdded:Connect(function(player)
	task.defer(function()
		local attempts = 0
		while not DataService.GetProfile(player) and attempts < 20 do
			task.wait(0.5)
			attempts += 1
		end
		if DataService.GetProfile(player) then
			MoneyService.OnPlayerReady(player)
		end
	end)
end)