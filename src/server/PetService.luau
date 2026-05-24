local HttpService = game:GetService("HttpService")
local DataService = require(script.Parent.DataService)
local CollectiblesData = require(game.ReplicatedStorage.Shared.CollectiblesData)
local Types = require(game.ReplicatedStorage.Shared.Types)

local PetService = {}

local function createOwnedPet(collectibleId: string): Types.OwnedPet
	return {
		instanceId    = HttpService:GenerateGUID(false),
		collectibleId = collectibleId,
		level         = 1,
		isEquipped    = false,
		acquiredAt    = os.time(),
	}
end

local function getIncome(ownedPet: Types.OwnedPet): number
	local def = CollectiblesData.ById[ownedPet.collectibleId]
	return def and def.passiveIncomePerSec or 0
end

local function getWeakestEquipped(data): (string?, number)
	local weakestId = nil
	local weakestIncome = math.huge

	for _, instanceId in data.EquippedPetIds do
		local owned = data.OwnedPets[instanceId]
		if owned then
			local income = getIncome(owned)
			if income < weakestIncome then
				weakestIncome = income
				weakestId = instanceId
			end
		end
	end

	return weakestId, weakestIncome == math.huge and 0 or weakestIncome
end

-- Unequips a pet by instance ID
local function unequip(data, instanceId: string)
	local owned = data.OwnedPets[instanceId]
	if owned then
		owned.isEquipped = false
	end
	for i, id in data.EquippedPetIds do
		if id == instanceId then
			table.remove(data.EquippedPetIds, i)
			break
		end
	end
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
			-- Free slot available — equip directly
			pet.isEquipped = true
			table.insert(data.EquippedPetIds, pet.instanceId)
		else
			-- All slots full — replace the weakest if the new pet is better
			local weakestId, weakestIncome = getWeakestEquipped(data)
			if weakestId and newIncome > weakestIncome then
				unequip(data, weakestId)
				pet.isEquipped = true
				table.insert(data.EquippedPetIds, pet.instanceId)
			end
		end
	end

	return pet
end

function PetService.GetEquippedPetDefinitions(player: Player): { Types.Pet }
	local data = DataService.GetData(player)
	if not data then return {} end

	local definitions = {}
	for _, instanceId in data.EquippedPetIds do
		local ownedPet = data.OwnedPets[instanceId]
		if ownedPet then
			local definition = CollectiblesData.ById[ownedPet.collectibleId]
			if definition then
				table.insert(definitions, definition)
			end
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

return PetService