local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)
local MoneyService = require(script.Parent.MoneyService)
local PetService = require(script.Parent.PetService)
local CollectiblesData = require(game.ReplicatedStorage.Shared.CollectiblesData)
local MutationsData = require(game.ReplicatedStorage.Shared.MutationsData)
local GachaConfig = require(game.ReplicatedStorage.Shared.GachaConfig)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local GachaService = {}

-- ─────────────────────────────────────────────
-- Weighted random collectible pick
-- ─────────────────────────────────────────────

local function pickCollectible()
	local roll = math.random() * CollectiblesData.TotalWeight
	local cumulative = 0
	for _, pet in CollectiblesData.List do
		cumulative += pet.rollWeight
		if roll <= cumulative then
			return pet
		end
	end
	return CollectiblesData.List[1]
end

-- ─────────────────────────────────────────────
-- Mutation roll
-- luckBonus is the flat bonus from the pet definition (e.g. +3 for Rare)
-- Each mutation is checked rarest-first; stops at the first hit.
-- luckBonus scales each mutation's chance: chance * (1 + luckBonus * 0.05)
-- So a pet with luckBonus 20 has 2× the base mutation chance.
-- ─────────────────────────────────────────────

local function rollMutation(luckBonus: number): string?
	local scale = 1 + (luckBonus * 0.05)
	for _, mutation in MutationsData.List do   -- rarest first
		local chance = mutation.baseRollChance * scale
		if math.random() < chance then
			return mutation.id
		end
	end
	return nil
end

-- ─────────────────────────────────────────────
-- Execute N rolls, award pets with mutations, return result list
-- ─────────────────────────────────────────────

local function executeRolls(player: Player, count: number, currency: "Coins" | "Gems"): { { collectibleId: string, mutationId: string? } }?
	local costs = currency == "Gems"
		and GachaConfig.GEM_ROLL_COSTS
		or  GachaConfig.COIN_ROLL_COSTS

	local cost = costs[count]
	if not cost then
		warn("[GachaService] Invalid roll count:", count)
		return nil
	end

	local success = currency == "Gems"
		and MoneyService.SpendGems(player, cost)
		or  MoneyService.SpendCoins(player, cost)

	if not success then return nil end

	local data = DataService.GetData(player)
	if not data then return nil end

	local results = {}
	for i = 1, count do
		local petDef = pickCollectible()
		local ownedPet = PetService.GivePet(player, petDef.id, i == 1)

		if ownedPet then
			-- Roll mutation using this pet's luck bonus
			local mutationId = rollMutation(petDef.luckBonus)
			ownedPet.mutationId = mutationId   -- write to the saved record

			table.insert(results, {
				collectibleId = petDef.id,
				mutationId    = mutationId,     -- nil if no mutation
			})
		end
	end

	MoneyService.SyncBalance(player)
	return results
end

-- ─────────────────────────────────────────────
-- Public roll — called by RemoteFunction
-- ─────────────────────────────────────────────

function GachaService.Roll(player: Player, count: number, currency: "Coins" | "Gems")
	if type(count) ~= "number" then
		return { success = false, reason = "Invalid count" }
	end
	if currency ~= "Coins" and currency ~= "Gems" then
		return { success = false, reason = "Invalid currency" }
	end
	if not GachaConfig.COIN_ROLL_COSTS[count] then
		return { success = false, reason = "Invalid roll count" }
	end

	local results = executeRolls(player, count, currency)
	if not results then
		return { success = false, reason = "Insufficient funds" }
	end

	return { success = true, results = results }
end

-- ─────────────────────────────────────────────
-- ProcessReceipt
-- ─────────────────────────────────────────────

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = DataService.GetData(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local receiptKey = tostring(receiptInfo.PurchaseId)
	if data.ProcessedReceipts[receiptKey] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local product = GachaConfig.PRODUCTS[receiptInfo.ProductId]
	if not product then
		warn("[GachaService] Unknown ProductId:", receiptInfo.ProductId)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local grantOk, grantErr = pcall(function()
		if product.type == "gems" then
			MoneyService.AddGems(player, product.amount)
			MoneyService.SyncBalance(player)

		elseif product.type == "coinRolls" then
			local results = {}
			for i = 1, product.amount do
				local petDef = pickCollectible()
				local ownedPet = PetService.GivePet(player, petDef.id, i == 1)
				if ownedPet then
					local mutationId = rollMutation(petDef.luckBonus)
					ownedPet.mutationId = mutationId
					table.insert(results, {
						collectibleId = petDef.id,
						mutationId    = mutationId,
					})
				end
			end
			MoneyService.SyncBalance(player)
			Remotes.ShowGachaResult:FireClient(player, results)
		end
	end)

	if not grantOk then
		warn("[GachaService] Grant failed:", grantErr)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	data.ProcessedReceipts[receiptKey] = true
	local keys = {}
	for k in data.ProcessedReceipts do table.insert(keys, k) end
	if #keys > GachaConfig.MAX_RECEIPT_LOG then
		table.sort(keys)
		data.ProcessedReceipts[keys[1]] = nil
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

MarketplaceService.ProcessReceipt = processReceipt

-- ─────────────────────────────────────────────
-- Init
-- ─────────────────────────────────────────────

function GachaService.Init()
	Remotes.RollGacha.OnServerInvoke = function(player, count, currency)
		return GachaService.Roll(player, count, currency)
	end
	print("[GachaService] Initialised")
end

return GachaService