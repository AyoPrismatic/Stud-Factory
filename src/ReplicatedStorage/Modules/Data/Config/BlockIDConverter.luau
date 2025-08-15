--[[
	I know this is awful, but it's a 1 dimensional array of BlockIDs - Block Names
	This is done for performance so the client can know what block to place through
	only a small set of a bits.
--]]

local Config = {}

Config.BlockNameToBlockID = {
	Bedrock 	= 0,
	Dirt 	= 1,
	Grass 	= 2,
}

Config.BlockIDToBlockName = {}

for BlockName, BlockID in Config.BlockNameToBlockID do
	local StoredBlockName = Config.BlockIDToBlockName[BlockID]

	if not StoredBlockName then
		Config.BlockIDToBlockName[BlockID] = BlockName
	else
		error(`Conflicting/Duplicate Block IDs! {BlockName} tried overwriting {StoredBlockName}`)
	end
end

return Config
