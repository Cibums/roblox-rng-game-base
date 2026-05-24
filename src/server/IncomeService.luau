local Players   = game:GetService("Players")
local DataService  = require(script.Parent.DataService)
local MoneyService = require(script.Parent.MoneyService)
local PetService   = require(script.Parent.PetService)

local INCOME_TICK = 1
local SYNC_TICK   = 5

local IncomeService = {}

local function tickIncome(player: Player)
	local data = DataService.GetData(player)
	if not data then return end

	local definitions = PetService.GetEquippedPetDefinitions(player)
	if #definitions == 0 then return end

	local totalIncome = 0
	for _, pet in definitions do
		totalIncome += pet.passiveIncomePerSec
	end

	local multiplier = data.RebirthMultiplier or 1
	if totalIncome > 0 then
		data.Coins += totalIncome * multiplier
	end
end

function IncomeService.Start()
	task.spawn(function()
		while true do
			task.wait(INCOME_TICK)
			for _, player in Players:GetPlayers() do
				task.spawn(tickIncome, player)
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(SYNC_TICK)
			for _, player in Players:GetPlayers() do
				task.spawn(MoneyService.SyncBalance, player)
			end
		end
	end)

	print("[IncomeService] Started — income every", INCOME_TICK, "s, sync every", SYNC_TICK, "s")
end

return IncomeService