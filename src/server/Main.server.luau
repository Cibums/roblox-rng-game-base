local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)
local MoneyService = require(script.Parent.MoneyService)
local PetService = require(script.Parent.PetService)
local IncomeService = require(script.Parent.IncomeService)
local GachaService = require(script.Parent.GachaService)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)
local DailyStreakConfig = require(game.ReplicatedStorage.Shared.DailyStreakConfig)

local OFFLINE_CAP_SECONDS = 4 * 3600

local function awardOfflineEarnings(player: Player)
	local data = DataService.GetData(player)
	if not data then return end

	local lastSeen = data.OfflineEarningsTimestamp or 0
	if lastSeen == 0 then
		data.OfflineEarningsTimestamp = os.time()
		return
	end

	local elapsed = math.min(os.time() - lastSeen, OFFLINE_CAP_SECONDS)
	if elapsed < 60 then
		data.OfflineEarningsTimestamp = os.time()
		return
	end

	local definitions = PetService.GetEquippedPetDefinitions(player)
	local ratePerSec = 0
	for _, pet in definitions do
		ratePerSec += pet.passiveIncomePerSec
	end

	local multiplier = data.RebirthMultiplier or 1
	local earned = math.floor(ratePerSec * elapsed * multiplier)

	if earned > 0 then
		MoneyService.AddCoins(player, earned)
		MoneyService.SyncBalance(player)
		Remotes.ShowOfflineEarnings:FireClient(player, earned, elapsed)
	end

	data.OfflineEarningsTimestamp = os.time()
end

local function handleDailyStreak(player: Player)
	local data = DataService.GetData(player)
	if not data then return end

	local now = os.time()
	local last = data.LastClaimTimestamp or 0
	local secondsSinceLast = now - last

	if secondsSinceLast < 86400 then return end

	if secondsSinceLast >= 86400 * 2 then
		data.DailyStreak = 0
	end

	data.DailyStreak += 1
	data.LastClaimTimestamp = now

	local day = ((data.DailyStreak - 1) % 7) + 1
	local reward = DailyStreakConfig[day]

	if reward.coins and reward.coins > 0 then
		MoneyService.AddCoins(player, reward.coins)
	end

	MoneyService.SyncBalance(player)
	Remotes.ShowDailyStreak:FireClient(player, data.DailyStreak, day, reward)
end

GachaService.Init()
IncomeService.Start()

Players.PlayerAdded:Connect(function(player)
	task.defer(function()
		local attempts = 0
		while not DataService.GetProfile(player) and attempts < 20 do
			task.wait(0.5)
			attempts += 1
		end
		if DataService.GetProfile(player) then
			awardOfflineEarnings(player)
			handleDailyStreak(player)
			MoneyService.OnPlayerReady(player)
			PetService.GiveStarterPetIfNeeded(player)
		else
			player:Kick("Failed to load data — please rejoin.")
		end
	end)
end)