local Types = require(game.ReplicatedStorage.Shared.Types)

local BASE_PASSIVE  = 1    -- coins/sec for a Common pet
local BASE_ACTION   = 2    -- action multiplier for a Common pet
local BASE_LUCK     = 0    -- luck bonus for a Common pet (flat addition to roll weight)

local data: { Types.Pet } = {

	-- ┌──────────────────────────────────────────────┐
	-- │  COMMON  (rollWeight ~55–70)                 │
	-- └──────────────────────────────────────────────┘
	{
		id                  = "pet_common_01",
		displayName         = "Pebble Pup",
		rarity              = "Common",
		rollWeight          = 65,
		modelId             = 0,
		thumbnailId         = 0,

		passiveIncomePerSec = BASE_PASSIVE * 1,
		actionMultiplier    = BASE_ACTION  * 1,
		luckBonus           = BASE_LUCK,

		abilityId           = "",
		abilityCooldown     = 0,

		maxLevel            = 20,

		followsPlayer       = true,
		idleAnimationId     = 0,
		abilityEffectId     = 0,
	},
	{
		id                  = "pet_common_02",
		displayName         = "Dust Bunny",
		rarity              = "Common",
		rollWeight          = 60,
		modelId             = 0,
		thumbnailId         = 0,

		passiveIncomePerSec = BASE_PASSIVE * 1,
		actionMultiplier    = BASE_ACTION  * 1,
		luckBonus           = BASE_LUCK,

		abilityId           = "",
		abilityCooldown     = 0,

		maxLevel            = 20,

		followsPlayer       = true,
		idleAnimationId     = 0,
		abilityEffectId     = 0,
	},

	-- ┌──────────────────────────────────────────────┐
	-- │  UNCOMMON  (rollWeight ~25–35)               │
	-- └──────────────────────────────────────────────┘
	{
		id                  = "pet_uncommon_01",
		displayName         = "Crystal Cub",
		rarity              = "Uncommon",
		rollWeight          = 28,
		modelId             = 0,
		thumbnailId         = 0,

		passiveIncomePerSec = BASE_PASSIVE * 3,
		actionMultiplier    = BASE_ACTION  * 2,
		luckBonus           = BASE_LUCK    + 1,

		abilityId           = "",
		abilityCooldown     = 0,

		maxLevel            = 30,

		followsPlayer       = true,
		idleAnimationId     = 0,
		abilityEffectId     = 0,
	},

	-- ┌──────────────────────────────────────────────┐
	-- │  RARE  (rollWeight ~8–12)                    │
	-- └──────────────────────────────────────────────┘
	{
		id                  = "pet_rare_01",
		displayName         = "Sapphire Fox",
		rarity              = "Rare",
		rollWeight          = 10,
		modelId             = 0,
		thumbnailId         = 0,

		passiveIncomePerSec = BASE_PASSIVE * 10,
		actionMultiplier    = BASE_ACTION  * 5,
		luckBonus           = BASE_LUCK    + 3,

		abilityId           = "",
		abilityCooldown     = 0,

		maxLevel            = 40,

		followsPlayer       = true,
		idleAnimationId     = 0,
		abilityEffectId     = 0,
	},

	-- ┌──────────────────────────────────────────────┐
	-- │  EPIC  (rollWeight ~2–5)                     │
	-- └──────────────────────────────────────────────┘
	{
		id                  = "pet_epic_01",
		displayName         = "Ember Drake",
		rarity              = "Epic",
		rollWeight          = 3,
		modelId             = 0,
		thumbnailId         = 0,

		passiveIncomePerSec = BASE_PASSIVE * 30,
		actionMultiplier    = BASE_ACTION  * 15,
		luckBonus           = BASE_LUCK    + 8,

		abilityId           = "",
		abilityCooldown     = 0,

		maxLevel            = 50,

		followsPlayer       = true,
		idleAnimationId     = 0,
		abilityEffectId     = 0,
	},

	-- ┌──────────────────────────────────────────────┐
	-- │  LEGENDARY  (rollWeight ~0.5–1)              │
	-- └──────────────────────────────────────────────┘
	{
		id                  = "pet_legendary_01",
		displayName         = "Prism Serpent",
		rarity              = "Legendary",
		rollWeight          = 0.8,
		modelId             = 0,
		thumbnailId         = 0,

		passiveIncomePerSec = BASE_PASSIVE * 100,
		actionMultiplier    = BASE_ACTION  * 50,
		luckBonus           = BASE_LUCK    + 20,

		abilityId           = "",
		abilityCooldown     = 0,

		maxLevel            = 60,

		followsPlayer       = true,
		idleAnimationId     = 0,
		abilityEffectId     = 0,
	},

	-- ┌──────────────────────────────────────────────┐
	-- │  MYTHIC  (rollWeight ~0.05–0.1)              │
	-- └──────────────────────────────────────────────┘
	{
		id                  = "pet_mythic_01",
		displayName         = "Void Leviathan",
		rarity              = "Mythic",
		rollWeight          = 0.08,
		modelId             = 0,
		thumbnailId         = 0,

		passiveIncomePerSec = BASE_PASSIVE * 400,
		actionMultiplier    = BASE_ACTION  * 200,
		luckBonus           = BASE_LUCK    + 60,

		abilityId           = "",
		abilityCooldown     = 0,

		maxLevel            = 75,

		followsPlayer       = true,
		idleAnimationId     = 0,
		abilityEffectId     = 0,
	},

	-- ┌──────────────────────────────────────────────┐
	-- │  DIVINE  (rollWeight ~0.005–0.01)            │
	-- └──────────────────────────────────────────────┘
	{
		id                  = "pet_divine_01",
		displayName         = "Celestial Titan",
		rarity              = "Divine",
		rollWeight          = 0.007,
		modelId             = 0,
		thumbnailId         = 0,

		passiveIncomePerSec = BASE_PASSIVE * 2000,
		actionMultiplier    = BASE_ACTION  * 1000,
		luckBonus           = BASE_LUCK    + 200,

		abilityId           = "",
		abilityCooldown     = 0,

		maxLevel            = 100,

		followsPlayer       = true,
		idleAnimationId     = 0,
		abilityEffectId     = 0,
	},
}

local byId: { [string]: Types.Pet } = {}
for _, pet in data do
	byId[pet.id] = pet
end

local totalWeight = 0
for _, pet in data do
	totalWeight += pet.rollWeight
end

return {
	List        = data,
	ById        = byId,
	TotalWeight = totalWeight,
}