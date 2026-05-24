local MutationsData = {}

-- Listed rarest → most common — roll order matters
MutationsData.List = {
	{
		id             = "cosmic",
		displayName    = "Cosmic",
		valueMultiplier = 200,
		baseRollChance = 0.001,   -- 0.1%
		color          = { r = 180, g = 100, b = 255 },
	},
	{
		id             = "rainbow",
		displayName    = "Rainbow",
		valueMultiplier = 50,
		baseRollChance = 0.005,   -- 0.5%
		color          = { r = 255, g = 80, b = 180 },
	},
	{
		id             = "gold",
		displayName    = "Gold",
		valueMultiplier = 20,
		baseRollChance = 0.02,    -- 2%
		color          = { r = 255, g = 200, b = 0 },
	},
	{
		id             = "shiny",
		displayName    = "Shiny",
		valueMultiplier = 5,
		baseRollChance = 0.10,    -- 10%
		color          = { r = 180, g = 255, b = 180 },
	},
}

MutationsData.ById = {}
for _, mutation in MutationsData.List do
	MutationsData.ById[mutation.id] = mutation
end

return MutationsData