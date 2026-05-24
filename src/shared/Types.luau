export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Divine"

export type Collectible = {
	id          : string,
	displayName : string,
	rarity      : Rarity,
	rollWeight  : number,
	modelId     : number,
	thumbnailId : number,
}

export type Pet = Collectible & {
	passiveIncomePerSec : number,
	actionMultiplier    : number,
	luckBonus           : number,

	abilityId           : string,
	abilityCooldown     : number,

	maxLevel            : number,

	followsPlayer       : boolean,
	idleAnimationId     : number,
	abilityEffectId     : number,
}

export type OwnedPet = {
	instanceId    : string,
	collectibleId : string,
	mutationId    : string?,
	level         : number,
	isEquipped    : boolean,
	acquiredAt    : number,
}

return {}