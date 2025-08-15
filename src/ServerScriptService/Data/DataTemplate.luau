local DataTemplate = {}

DataTemplate.DEFAULT_DATA_TYPE = {
	--[[Player Data]]
	--WorldData is a table of tables, each table is a life, holding block data
	WorldData = {
		--Life 1
		[1] = {},
	},
	--Indexes 1 - 10 of inventory is the players hotbar
	Inventory = {},

	--[[Player Stats]]
	CurrentSelectedLife = 1,
	Rebirths = 0,
	Cash = 100,
}

export type PlayerData = typeof(DataTemplate.DEFAULT_DATA_TYPE)

return DataTemplate