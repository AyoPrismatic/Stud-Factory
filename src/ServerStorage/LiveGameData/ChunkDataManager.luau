--[[
    This module proccesses a player's chunk data and formats only what is necessary
    for the client's visuals. Handles face culling and determines which
    blocks are sent to the client.
]]

--Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--Folders & Events
local ChunkEventsFolder = ReplicatedStorage.Events.ChunkDataEvents
local ChunkDataSender = ChunkEventsFolder.FromServer.ChunkDataSender

--Modules
local PlayerDataManager = require(ServerScriptService.Data.DataManager)
local SetPlayerData = PlayerDataManager.Set
local GetPlayerData = PlayerDataManager.Get

--Constants
local VectorOffsetToFace = table.freeze({
	[Vector3.new(1, 0, 0)] = "Front",
	[Vector3.new(-1, 0, 0)] = "Back",
	[Vector3.new(0, 0, -1)] = "Left",
	[Vector3.new(0, 0, 1)] = "Right",
	[Vector3.new(0, 1, 0)] = "Top",
	[Vector3.new(0, -1, 0)] = "Bottom",
})

local DefaultBlockVisibility = table.freeze({
	Front = true,
	Back = true,
	Left = true,
	Right = true,
	Top = true,
	Bottom = true,
	Visibility = 6
})

--Types
type ChunkData = {[number]: {{buffer}}}

--Module Table
local Public = {}
local Private = {}

--[[Public]]

function Public.PlotClaimed(PlotData)
	local SentClientData = Private.ProcessPlotForClient(PlotData)
     print(SentClientData)
end

--[[Private]]

--Main processing entry point
function Private.ProcessPlotForClient(PlotData: {}): {}
	local HighestY = PlotData.HighestYValue
	local SeenBlocks = {}

	for Y = HighestY, 0, -1 do
		for ChunkIndex = 1, 25 do
			local Chunk = PlotData[ChunkIndex]
			if Chunk[Y].BlockCount == 0 then
				continue
			end

			for X = 1, 14 do
				for Z = 1, 14 do
					Private.ProcessBlock(X, Y, Z, Chunk, ChunkIndex, HighestY, SeenBlocks)
				end
			end
		end
	end

	return SeenBlocks
end

--Process a single block for culling
function Private.ProcessBlock(X, Y, Z, Chunk, ChunkIndex, HighestY, SeenBlocks)
	local BlockData = Chunk[Y][Private.LayerIndex(X, Z)]
	local CalculateTop = Y ~= HighestY
	local CalculateBottom = Y ~= 0

	local RawX = X + (14 * (ChunkIndex - 1))
	local RawZ = Z + (14 * (ChunkIndex - 1))

	SeenBlocks[`{RawX}_{Y}_{RawZ}`] = {BlockData, table.clone(DefaultBlockVisibility)}
	SeenBlocks[`{RawX}_{Y}_{RawZ}`][2] = Private.CalculateCulling(SeenBlocks, RawX, Y, RawZ, CalculateTop, CalculateBottom)
end

function Private.CalculateCulling(SeenBlocks: {}, OriginX: number, OriginY: number, OriginZ: number, CalculateTop: boolean, CalculateBottom: boolean)
	local OriginVector = Vector3.new(OriginX, OriginY, OriginZ)

	local function CullFace(X, Y, Z, Face)
		local Data = SeenBlocks[`{X}_{Y}_{Z}`][2]
		Data.Visibility -= 1
		Data[Face] = false
	end

	local function TryCull(XOffset, YOffset, ZOffset)
		local AdjX, AdjY, AdjZ = OriginX + XOffset, OriginY + YOffset, OriginZ + ZOffset
		local Adjacent = SeenBlocks[`{AdjX}_{AdjY}_{AdjZ}`]
		if not Adjacent then return end

		local AdjVector = Vector3.new(AdjX, AdjY, AdjZ)
		local AdjData = Adjacent[1]
		local NBT = AdjData.NBT

		if NBT and NBT.Transparent then
			CullFace(AdjX, AdjY, AdjZ, VectorOffsetToFace[AdjVector - OriginVector])
			return
		end

		CullFace(AdjX, AdjY, AdjZ, VectorOffsetToFace[AdjVector - OriginVector])
		CullFace(OriginX, OriginY, OriginZ, VectorOffsetToFace[OriginVector - AdjVector])
	end

	for XOffset = -1, 1, 2 do
		TryCull(XOffset, 0, 0)
	end
	for ZOffset = -1, 1, 2 do
		TryCull(0, 0, ZOffset)
	end
	if CalculateTop then
		TryCull(0, 1, 0)
	end
	if CalculateBottom then
		TryCull(0, -1, 0)
	else
		CullFace(OriginX, OriginY, OriginZ, "Bottom")
	end
end

return Public
