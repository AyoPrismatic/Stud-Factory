--Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService('Players')

--Folders & Events
local ChunkEventsFolder = ReplicatedStorage.Events.ChunkDataEvents
local ChunkDataSender = ChunkEventsFolder.FromServer.ChunkDataSender

--Modules
local BlockDataCompress = require(ReplicatedStorage.Modules.DataUtils.BlockDataConverter)
local PackInt = BlockDataCompress.Pack.Integer

local PlayerDataManager = require(ServerScriptService.Data.DataManager)
local SetPlayerData = PlayerDataManager.Set
local GetPlayerData = PlayerDataManager.Get

local Config = require(ReplicatedStorage.Modules.Data.Config)
local BlockNameToID = Config.BlockIDData.NameToID

--Variables
local ChunkCellSize = 14
local SquaredChunkCellSize = math.pow(ChunkCellSize, 2)

--Types
type ChunkData = {[number] : buffer}
type ChunkAreaData = {ChunkData}

type Plot = "Plot1" | "Plot2" | "Plot3" | "Plot4"
type ChunkNumber = number

type DataRequests = {
	[Player] : {
		[Plot] : {
			[ChunkNumber] : boolean --KV pair is just to make it a dict
		}
	}
}

--Module Table
local Public = {}
local Private = {}

local OnGoingRequests : DataRequests = {}

--[[Public]]

function Public.ChunkDataRequested(Player : Player, PlotIndex : number, ChunkIndex : number)
	if OnGoingRequests[Player][`Plot{PlotIndex}`][ChunkIndex] then
		return
	else
		OnGoingRequests[Player][`Plot{PlotIndex}`][ChunkIndex] = true
	end

	local ChunkData = Private.FetchChunkData(Player, ChunkIndex)
	ChunkDataSender:FireClient(Player, ChunkIndex, ChunkData)
end

--[[Private]]

function Private.FetchChunkData(Player : Player, ChunkIndex : number) : ChunkAreaData
	local CurrentSelectedLife = GetPlayerData.CurrentSelectedLife(Player)
	local PlotData = GetPlayerData.RebirthPlotData(Player, CurrentSelectedLife)

	if not PlotData[ChunkIndex] then
		local PlotData = Private.CreateEmptyPlotData(Player, CurrentSelectedLife, ChunkIndex)
		return PlotData[ChunkIndex]
	end

	return PlotData[ChunkIndex]
end

function Private.CreateEmptyPlotData(Player : Player, RebirthIndex : number) : {}
	local PlotData = table.create(25, nil)

	for ChunkAreaIndex = 1, 25 do
		PlotData[ChunkAreaIndex] = Private.CreateStarterChunkData(ChunkAreaIndex)
	end

	SetPlayerData.RebirthPlotData(Player, RebirthIndex, PlotData)
	return PlotData
end

function Private.CreateStarterChunkData(ChunkAreaIndex : number) : {}
	local ChunkAreaData : ChunkAreaData = {}

	--[[
	for CubicChunk = 1, 3 do
		local CubicChunkData = table.create(252, nil)

		Private.FillLayers(CubicChunkData, 14, 1, BlockNameToID["Bedrock"])

		table.insert(ChunkAreaData, CubicChunk + 1, CubicChunkData)
	end
	--]]

	return ChunkAreaData
end

function Private.FillLayers(CubicChunkData : {}, TopY : number, BottomY : number, BlockID : number)
	for Y = BottomY, TopY do
		Private.FillLayer(CubicChunkData, Y, BlockID)
	end
end

function Private.FillLayer(CubicChunkData : {}, Y : number, BlockID : number)
	for X = 4, 10 do
		for Z = 4, 10  do
			if Z % math.random(1, 3) == 0 then
				if X % math.random(1, 3) == 0 then
					Private.AppendBlock(CubicChunkData, BlockID, X, Y, Z)
				end
			end
		end
	end
end

function Private.AppendBlock(ChunkData : {}, BlockID : number, X : number, Y : number, Z : number)
	ChunkData[Private.PosToIndex(X, Y, Z)] = {PackInt(BlockID)}
end

function Private.PosToIndex(X: number, Y : number, Z: number): number
	return (Y - 1) * SquaredChunkCellSize + (Z - 1) * ChunkCellSize + X
end

Players.PlayerAdded:Connect(function(Player)
	OnGoingRequests[Player] = {
		Plot1 = {},
		Plot2 = {},
		Plot3 = {},
		Plot4 = {},
	}
end)

Players.PlayerRemoving:Connect(function(Player)
	OnGoingRequests[Player] = nil
end)

return Public
