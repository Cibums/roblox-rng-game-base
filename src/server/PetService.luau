local HttpService = game:GetService("HttpService")
local DataService = require(script.Parent.DataService)
local CollectiblesData = require(game.ReplicatedStorage.Shared.CollectiblesData)
local Types = require(game.ReplicatedStorage.Shared.Types)

local PetService = {}

-- Creates a new OwnedPet instance from a collectible id
local function createOwnedPet(collectibleId: string): Types.OwnedPet
	return {
		instanceId    = HttpService:GenerateGUID(false),
		collectibleId = collectibleId,
		level         = 1,
		isEquipped    = false,
		acquiredAt    = os.time(),
	}
end

-- Gives a player a pet and optionally auto-equips it
function PetService.GivePet(player: Player, collectibleId: string, autoEquip: boolean?): Types.OwnedPet?
	local data = DataService.GetData(player)
	if not data then return nil end

	-- Validate the collectible exists
	if not CollectiblesData.ById[collectibleId] then
		warn("[PetService] Unknown collectibleId:", collectibleId)
		return nil
	end

	local pet = createOwnedPet(collectibleId)
	data.OwnedPets[pet.instanceId] = pet

	if autoEquip and #data.EquippedPetIds < data.MaxEquipSlots then
		pet.isEquipped = true
		table.insert(data.EquippedPetIds, pet.instanceId)
	end

	return pet
end

-- Returns the Pet definitions for all currently equipped pets
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

-- Gives a starter pet to new players on first join
function PetService.GiveStarterPetIfNeeded(player: Player)
	local data = DataService.GetData(player)
	if not data then return end

	-- Only runs once — if they already have pets, skip
	if next(data.OwnedPets) ~= nil then return end

	-- Give the first Common pet, auto-equip it
	PetService.GivePet(player, "pet_common_01", true)
	print("[PetService] Gave starter pet to", player.Name)
end

return PetService