local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local DataService = require(script.Parent.DataService)
local MoneyService = require(script.Parent.MoneyService)
local PetService = require(script.Parent.PetService)
local CollectiblesData = require(game.ReplicatedStorage.Shared.CollectiblesData)
local GachaConfig = require(game.ReplicatedStorage.Shared.GachaConfig)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local GachaService = {}

-- ─────────────────────────────────────────────
-- Internal: weighted random pick
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
	return CollectiblesData.List[1]   -- fallback; should never reach here
end

-- ─────────────────────────────────────────────
-- Internal: execute N rolls, award pets, return result list
-- Returns nil if the spend failed (insufficient funds)
-- ─────────────────────────────────────────────

local function executeRolls(player: Player, count: number, currency: "Coins" | "Gems"): { { collectibleId: string } }?
	local costs = currency == "Gems"
		and GachaConfig.GEM_ROLL_COSTS
		or GachaConfig.COIN_ROLL_COSTS

	local cost = costs[count]
	if not cost then
		warn("[GachaService] Invalid roll count:", count)
		return nil
	end

	-- Spend first — if the player can't afford it, bail before touching inventory
	local success = currency == "Gems"
		and MoneyService.SpendGems(player, cost)
		or  MoneyService.SpendCoins(player, cost)

	if not success then return nil end

	local results = {}
	for i = 1, count do
		local pet = pickCollectible()
		PetService.GivePet(player, pet.id, i == 1)   -- auto-equip only the first if slots open
		table.insert(results, { collectibleId = pet.id })
	end

	MoneyService.SyncBalance(player)
	return results
end

-- ─────────────────────────────────────────────
-- Public: called by the RemoteFunction binding below
-- Returns { success: bool, results: table?, reason: string? }
-- ─────────────────────────────────────────────

function GachaService.Roll(player: Player, count: number, currency: "Coins" | "Gems")
	-- Validate inputs — never trust the client
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
-- ProcessReceipt — the Robux monetization handler
-- CRITICAL: only return PurchaseGranted after a confirmed data write.
-- Roblox will retry the receipt if we return NotProcessedYet or crash.
-- ─────────────────────────────────────────────

local function processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left mid-purchase. Return NotProcessedYet so Roblox retries
		-- when they next join.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local data = DataService.GetData(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Idempotency check — don't double-grant if the receipt replays
	local receiptKey = tostring(receiptInfo.PurchaseId)
	if data.ProcessedReceipts[receiptKey] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local product = GachaConfig.PRODUCTS[receiptInfo.ProductId]
	if not product then
		warn("[GachaService] Unknown ProductId:", receiptInfo.ProductId)
		-- Unknown product — grant anyway to avoid Roblox locking the purchase
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Grant the product
	local grantOk, grantErr = pcall(function()
		if product.type == "gems" then
			MoneyService.AddGems(player, product.amount)
			MoneyService.SyncBalance(player)

		elseif product.type == "coinRolls" then
			-- Free rolls purchased with Robux — execute without spending coins
			local results = {}
			for i = 1, product.amount do
				local pet = pickCollectible()
				PetService.GivePet(player, pet.id, i == 1)
				table.insert(results, { collectibleId = pet.id })
			end
			MoneyService.SyncBalance(player)
			Remotes.ShowGachaResult:FireClient(player, results)
		end
	end)

	if not grantOk then
		warn("[GachaService] Grant failed:", grantErr)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Log the receipt — prune oldest if over the cap
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
-- RemoteFunction binding — client calls this to request a roll
-- ─────────────────────────────────────────────

function GachaService.Init()
	Remotes.RollGacha.OnServerInvoke = function(player, count, currency)
		-- Extra server-side guard: rate-limit rapid repeat calls
		-- (a proper debounce table would go here in production)
		return GachaService.Roll(player, count, currency)
	end

	print("[GachaService] Initialised")
end

return GachaService