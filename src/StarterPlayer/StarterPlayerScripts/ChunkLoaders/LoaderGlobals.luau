--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Modules
local Config = require(ReplicatedStorage.Modules.Data.Config)
local BlockNameToID = Config.BlockIDData.NameToID

local Global = {}

Global.LoadTimes = {0,0,0,0}

Global.BlockSize = 4
Global.ChunkCellSize = 14
Global.PaddedChunkCellSize = 16
Global.SqrdChunkCellSize = math.pow(Global.ChunkCellSize, 2)
Global.SqrdPaddedChunkCellSize = math.pow(Global.PaddedChunkCellSize, 2)
Global.DoubleSqrdPaddedChunkCellSize = Global.SqrdPaddedChunkCellSize * 2
Global.PlotSize = Global.ChunkCellSize * Global.BlockSize * 5

--[[
     the initial starter layers for every plot, and the block id for
     the different y levels of it.
--]]
Global.GroundLayerBlockIDs = table.freeze({
     [6] = BlockNameToID["Grass"],
     [5] = BlockNameToID["Dirt"],
     [4] = BlockNameToID["Dirt"],
     [3] = BlockNameToID["Dirt"],
     [2] = BlockNameToID["Dirt"],
     [1] = BlockNameToID["Bedrock"],
})

Global.ChunkIndexes = table.freeze({
	[5] = {21,  22,  23,  24,  25},
	[4] = {16,  17,  18,  19,  20},
	[3] = {11,  12,  13,  14,  15},
	[2] = { 6,   7,   8,   9,  10},
	[1] = { 1,   2,   3,   4,   5},
})

Global.IsBlockAtCache = table.create(4, setmetatable({}, {__mode = "k"}))
Global.ChunkData = table.create(4, table.create(25, {}))

Global.PlotOrigins = {}
for PlotIndex = 1, 4 do
     local Plot = workspace.ChunkAreas:FindFirstChild("Plot"..PlotIndex)
     local PlotPos = Plot:GetPivot().Position

     table.insert(Global.PlotOrigins, Vector3.new(PlotPos.X, 0, PlotPos.Z))
end

table.freeze(Global.PlotOrigins)

return Global