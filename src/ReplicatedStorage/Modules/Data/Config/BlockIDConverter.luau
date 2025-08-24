--[[
	Blocks are stored in a 1d array to have the server send compact block IDs to the client.
--]]

local Config = {}

local BlockNames = {
	"Air",
	"Bedrock",
	"Dirt",
	"Grass",
}

Config.BlockNameToBlockID = {}
Config.BlockIDToBlockName = BlockNames

for BlockID, BlockNames in BlockNames do
	Config.BlockNameToBlockID[BlockNames] = BlockID
end

return Config
