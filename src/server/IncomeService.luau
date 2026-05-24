local Players = game:GetService("Players")
local DataService = require(script.Parent.DataService)
local MoneyService = require(script.Parent.MoneyService)
local PetService = require(script.Parent.PetService)

local TICK_RATE = 1

local IncomeService = {}

local function tickIncome(player: Player)
	local data = DataService.GetData(player)
	if not data then return end

	local definitions = PetService.GetEquippedPetDefinitions(player)
	if #definitions == 0 then return end

	-- Sum passive income across all equipped pets
	local totalIncome = 0
	for _, pet in definitions do
		totalIncome += pet.passiveIncomePerSec
	end

	if totalIncome > 0 then
		MoneyService.AddCoins(player, totalIncome)
	end
end

function IncomeService.Start()
	-- Run the income loop for all players every TICK_RATE seconds
	task.spawn(function()
		while true do
			task.wait(TICK_RATE)
			for _, player in Players:GetPlayers() do
				task.spawn(tickIncome, player)
			end
		end
	end)

	print("[IncomeService] Started — ticking every", TICK_RATE, "second(s)")
end

return IncomeService