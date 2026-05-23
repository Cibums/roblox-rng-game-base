local Players = game:GetService("Players")
local ProfileStore = require(game.ServerScriptService.ServerPackages.ProfileStore)
local PlayerDataTemplate = require(game.ReplicatedStorage.Shared.PlayerDataTemplate)

local PlayerStore = ProfileStore.New("PlayerStore_v1", PlayerDataTemplate)

local Profiles = {}

local function onPlayerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync(tostring(player.UserId), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile.OnSessionEnd:Connect(function()
			Profiles[player] = nil
			player:Kick("Session ended — please rejoin.")
		end)
		if player.Parent == Players then
			Profiles[player] = profile
		else
			profile:EndSession()
		end
	else
		player:Kick("Failed to load data — please rejoin.")
	end
end

local function onPlayerRemoving(player: Player)
	local profile = Profiles[player]
	if profile then
		profile:EndSession()
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

local DataService = {}

function DataService.GetProfile(player: Player)
	return Profiles[player]   -- returns nil if not loaded yet
end

function DataService.GetData(player: Player)
	local profile = Profiles[player]
	return profile and profile.Data or nil
end

return DataService