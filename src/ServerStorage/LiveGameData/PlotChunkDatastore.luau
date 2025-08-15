--Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--Modules
local BlockDataCompressor = require(ReplicatedStorage.Modules.DataUtils.BlockDataConverter)
local PackInt = BlockDataCompressor.Pack.Integer
local PackNBT = BlockDataCompressor.Pack.NBTData

local PlayerDataManager = require(ServerScriptService.Data.DataManager)
local SetPlayerData = PlayerDataManager.Set
local GetPlayerData = PlayerDataManager.Get

local ChunkDataManger = require(ServerStorage.LiveGameData.ChunkDataManager)

local Config = require(ReplicatedStorage.Modules.Data.Config)
local BlockIdDict = Config.BlockIDData.NameToID

local Plots = {
     [1] = {},
     [2] = {},
     [3] = {},
     [4] = {}
}

local PlotData = {}
local Private = {}

--[[Events]]

function PlotData.PlayerClaimedPlot(Player : Player, PlotIndex : number)
	local LifeIndex = GetPlayerData.CurrentSelectedLife(Player)
	local PlotData = GetPlayerData.RebirthPlotData(Player, LifeIndex - 1)

	if not PlotData or next(PlotData) == nil then
		PlotData = {HighestYValue = 5}
		SetPlayerData.RebirthPlotData(Player, LifeIndex - 1, PlotData)

		for ChunkIndex = 1, 25 do
			Private.FetchChunk(PlotData, ChunkIndex)
		end
	end

     ChunkDataManger.PlotClaimed(PlotData)
     Plots[PlotIndex] = {Player, LifeIndex, PlotData}
end

function PlotData.PlayerAbandonedPlot(Player : Player, PlotIndex : number)
     local PlotInfo = Plots[PlotIndex]

     local PlotLifeValue = PlotInfo[2]
     local PlotData = PlotInfo[3]

     SetPlayerData.RebirthPlotData(Player, PlotLifeValue, PlotData)

     Plots[PlotIndex] = {}
end

function PlotData.GetPlayerPlotData(Player : Player) : {}
     for _, PlotInfo in Plots do
          local PlotPlayerValue = PlotInfo[1]
          local PlotData = PlotInfo[3]

          if PlotPlayerValue == Player then
               return PlotData
          end
     end
end

function Private.FetchChunk(PlotData: {}, ChunkIndex: number): {}
	local Chunk = PlotData[ChunkIndex]

	if not Chunk then
		Chunk = Private.GenerateStarterChunk(PlotData)
		PlotData[ChunkIndex] = Chunk
	end

	return Chunk
end

--Starter chunk generation
function Private.GenerateStarterChunk(PlotData: {}): {}
	local Chunk = {}
	for Y = 0, 255 do
		local Layer = {}
		Layer["BlockCount"] = 0
		Chunk[Y] = Layer
	end

	Private.FillChunkLayer(PlotData, Chunk, 5, 5, BlockIdDict.Grass)
	Private.FillChunkLayer(PlotData, Chunk, 1, 4, BlockIdDict.Dirt)
	Private.FillChunkLayer(PlotData, Chunk, 0, 0, BlockIdDict.Bedrock)

	return Chunk
end

--Fills a range of Y layers with a given block
function Private.FillChunkLayer(PlotData, Chunk, YLow, YHigh, BlockId, Rotation, NBTData)
	for Y = YLow, YHigh do
		for X = 1, 14 do
			for Z = 1, 14 do
				task.spawn(Private.AppendBlock, PlotData, Chunk, X, Y, Z, BlockId, Rotation, NBTData)
			end
		end
	end
end

--Appends a single block to a chunk
function Private.AppendBlock(PlotData: {}, Chunk: {}, X: number, Y: number, Z: number, BlockId: number, Rotation: number?, NBTData: {}?)
	if not BlockId or type(BlockId) ~= "number" then
		warn(`BlockId is required! Got: {BlockId}`)
		return
	end

	local BlockData = {PackInt(BlockId)}
	if Rotation then
		BlockData.ROT = PackInt(Rotation)
	end
	if NBTData then
		BlockData.NBT = PackNBT(NBTData)
	end

	local Index = Private.LayerIndex(X, Z)
	local Layer = Chunk[Y]
     print(Chunk[Y])
	Layer[Index] = BlockData
	Layer["BlockCount"] += 1

	if Y > PlotData.HighestYValue then
		PlotData.HighestYValue = Y
	end
end

--Converts X,Z coords into layer index
function Private.LayerIndex(X: number, Z: number): number
	return 1 + X + (Z * 14)
end


return PlotData