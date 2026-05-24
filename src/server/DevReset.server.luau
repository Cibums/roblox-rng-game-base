-- DEVELOPMENT ONLY — delete before publishing

local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)
local PlayerDataTemplate = require(game.ReplicatedStorage.Shared.PlayerDataTemplate)

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		if msg:lower() ~= "/resetdata" then return end
		if player.UserId ~= 420821417 then return end

		local profile = DataService.GetProfile(player)
		if not profile then
			warn("[DevReset] Profile not loaded yet")
			return
		end

		for key, value in PlayerDataTemplate do
			profile.Data[key] = value
		end

		player:Kick("Data reset. Rejoin to start fresh.")
	end)
end)