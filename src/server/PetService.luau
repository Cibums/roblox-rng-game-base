local HttpService = game:GetService("HttpService")
local DataService = require(script.Parent.DataService)
local CollectiblesData = require(game.ReplicatedStorage.Shared.CollectiblesData)
local MutationsData = require(game.ReplicatedStorage.Shared.MutationsData)
local Types = require(game.ReplicatedStorage.Shared.Types)
local Remotes = require(game.ReplicatedStorage.Shared.Remotes)

local PetService = {}

-- ─────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────

local function createOwnedPet(collectibleId: string): Types.OwnedPet
	return {
		instanceId    = HttpService:GenerateGUID(false),
		collectibleId = collectibleId,
		mutationId    = nil,
		level         = 1,
		isEquipped    = false,
		acquiredAt    = os.time(),
	}
end

local function getEffectiveIncome(ownedPet: Types.OwnedPet): number
	local def = CollectiblesData.ById[ownedPet.collectibleId]
	if not def then return 0 end
	local base = def.passiveIncomePerSec
	if ownedPet.mutationId then
		local mutation = MutationsData.ById[ownedPet.mutationId]
		if mutation then return base * mutation.valueMultiplier end
	end
	return base
end

-- Recomputes data.IncomePerSec from currently equipped pets.
-- Called after any equip/unequip so MoneyService can read it without
-- needing to know anything about pets.
local function recomputeIncome(data)
	local total = 0
	for _, instanceId in data.EquippedPetIds do
		local owned = data.OwnedPets[instanceId]
		if owned then
			total += getEffectiveIncome(owned)
		end
	end
	data.IncomePerSec = total * (data.RebirthMultiplier or 1)
end

local function getWeakestEquipped(data): (string?, number)
	local weakestId = nil
	local weakestIncome = math.huge
	for _, instanceId in data.EquippedPetIds do
		local owned = data.OwnedPets[instanceId]
		if owned then
			local income = getEffectiveIncome(owned)
			if income < weakestIncome then
				weakestIncome = income
				weakestId = instanceId
			end
		end
	end
	return weakestId, weakestIncome == math.huge and 0 or weakestIncome
end

local function rawUnequip(data, instanceId: string)
	local owned = data.OwnedPets[instanceId]
	if owned then owned.isEquipped = false end
	for i, id in data.EquippedPetIds do
		if id == instanceId then
			table.remove(data.EquippedPetIds, i)
			break
		end
	end
end

-- ─────────────────────────────────────────────
-- Public
-- ─────────────────────────────────────────────

function PetService.GetDefinition(collectibleId: string)
	return CollectiblesData.ById[collectibleId]
end

function PetService.GivePet(player: Player, collectibleId: string, autoEquip: boolean?): Types.OwnedPet?
	local data = DataService.GetData(player)
	if not data then return nil end
	if not CollectiblesData.ById[collectibleId] then
		warn("[PetService] Unknown collectibleId:", collectibleId)
		return nil
	end

	local pet = createOwnedPet(collectibleId)
	data.OwnedPets[pet.instanceId] = pet

	if autoEquip then
		local newIncome = CollectiblesData.ById[collectibleId].passiveIncomePerSec
		if #data.EquippedPetIds < data.MaxEquipSlots then
			pet.isEquipped = true
			table.insert(data.EquippedPetIds, pet.instanceId)
		else
			local weakestId, weakestIncome = getWeakestEquipped(data)
			if weakestId and newIncome > weakestIncome then
				rawUnequip(data, weakestId)
				pet.isEquipped = true
				table.insert(data.EquippedPetIds, pet.instanceId)
			end
		end
	end

	recomputeIncome(data)
	return pet
end

function PetService.EquipPet(player: Player, instanceId: string): boolean
	local data = DataService.GetData(player)
	if not data then return false end

	local owned = data.OwnedPets[instanceId]
	if not owned then return false end
	if owned.isEquipped then return true end

	if #data.EquippedPetIds < data.MaxEquipSlots then
		owned.isEquipped = true
		table.insert(data.EquippedPetIds, instanceId)
		recomputeIncome(data)
		return true
	end

	-- All slots full — bump weakest regardless of income
	-- (player made an intentional choice)
	local weakestId, _ = getWeakestEquipped(data)
	if weakestId then
		rawUnequip(data, weakestId)
		owned.isEquipped = true
		table.insert(data.EquippedPetIds, instanceId)
		recomputeIncome(data)
		return true
	end

	return false
end

function PetService.UnequipPet(player: Player, instanceId: string): boolean
	local data = DataService.GetData(player)
	if not data then return false end
	local owned = data.OwnedPets[instanceId]
	if not owned or not owned.isEquipped then return false end
	rawUnequip(data, instanceId)
	recomputeIncome(data)
	return true
end

function PetService.EquipBest(player: Player): boolean
	local data = DataService.GetData(player)
	if not data then return false end

	local allPets = {}
	for _, ownedPet in data.OwnedPets do
		table.insert(allPets, ownedPet)
	end
	table.sort(allPets, function(a, b)
		return getEffectiveIncome(a) > getEffectiveIncome(b)
	end)

	for _, ownedPet in allPets do
		ownedPet.isEquipped = false
	end
	table.clear(data.EquippedPetIds)

	for i = 1, math.min(data.MaxEquipSlots, #allPets) do
		local pet = allPets[i]
		pet.isEquipped = true
		table.insert(data.EquippedPetIds, pet.instanceId)
	end

	recomputeIncome(data)
	return true
end

function PetService.GetInventoryData(player: Player): { Types.OwnedPet }
	local data = DataService.GetData(player)
	if not data then return {} end
	local list = {}
	for _, ownedPet in data.OwnedPets do
		table.insert(list, {
			instanceId    = ownedPet.instanceId,
			collectibleId = ownedPet.collectibleId,
			mutationId    = ownedPet.mutationId,
			isEquipped    = ownedPet.isEquipped,
			level         = ownedPet.level,
			acquiredAt    = ownedPet.acquiredAt,
		})
	end
	return list
end

function PetService.GetEquippedPetDefinitions(player: Player)
	local data = DataService.GetData(player)
	if not data then return {} end
	local definitions = {}
	for _, instanceId in data.EquippedPetIds do
		local ownedPet = data.OwnedPets[instanceId]
		if ownedPet then
			local definition = CollectiblesData.ById[ownedPet.collectibleId]
			if definition then table.insert(definitions, definition) end
		end
	end
	return definitions
end

function PetService.GiveStarterPetIfNeeded(player: Player)
	local data = DataService.GetData(player)
	if not data then return end
	if next(data.OwnedPets) ~= nil then return end
	PetService.GivePet(player, "pet_common_01", true)
	print("[PetService] Gave starter pet to", player.Name)
end

-- ─────────────────────────────────────────────
-- Remote bindings — MoneyService required lazily here only,
-- after both modules are fully loaded, so no cycle
-- ─────────────────────────────────────────────

function PetService.InitRemotes()
	local MoneyService = require(script.Parent.MoneyService)

	Remotes.GetInventory.OnServerInvoke = function(player)
		return PetService.GetInventoryData(player)
	end

	Remotes.EquipPet.OnServerInvoke = function(player, instanceId)
		if type(instanceId) ~= "string" then return false end
		local ok = PetService.EquipPet(player, instanceId)
		if ok then MoneyService.SyncBalance(player) end
		return ok
	end

	Remotes.UnequipPet.OnServerInvoke = function(player, instanceId)
		if type(instanceId) ~= "string" then return false end
		local ok = PetService.UnequipPet(player, instanceId)
		if ok then MoneyService.SyncBalance(player) end
		return ok
	end

	Remotes.EquipBest.OnServerInvoke = function(player)
		local ok = PetService.EquipBest(player)
		if ok then MoneyService.SyncBalance(player) end
		return ok
	end

	print("[PetService] Remotes bound")
end

return PetService