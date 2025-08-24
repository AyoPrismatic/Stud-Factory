local ParentActor : Actor = script.Parent
if not ParentActor:IsA("Actor") then
	error("ChunkLoader incorrectly parented!")
end

--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--Player
local Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts

--Modules
local BlockDataCompresser = require(ReplicatedStorage.Modules.DataUtils.BlockDataConverter)
local UnpackInt = BlockDataCompresser.Unpack.Buffer

local Global = require(PlayerScripts.ChunkLoaders.LoaderGlobals)
local BlockSize = Global.BlockSize
local ChunkBlockSize = Global.ChunkCellSize * BlockSize

local Config = require(ReplicatedStorage.Modules.Data.Config)
local BlockIDToBlockName = Config.BlockIDData.IDToName
local CullingIgnoreList = Config.CullingIgnoreList

--Constants
local GroundLayerBlockIDs = Global.GroundLayerBlockIDs
local ChunkLoaderIndex = tonumber(script.Parent.Name)
local Base0ChunkIndex = ChunkLoaderIndex - 1
local ChunkAreaGridSize = 5

local RShift = bit32.rshift --Bit32 functions were shortened to look cleaner
local LShift = bit32.lshift
local Reverse = bit32.bnot
local BAnd = bit32.band

--Types
type ChunkData = {[number] : {[number] : any}}

type PositionData = {
	--Two methods of getting position
	X : number?, Y : number?, Z : number?,
	Index : number?
}

local NeighboringBlockOffsets = table.freeze({
	Top = Vector3.new(0, 1, 0),
	Bottom = Vector3.new(0, -1, 0),
	Right = Vector3.new(1, 0, 0),
	Left = Vector3.new(-1, 0, 0),
	Front = Vector3.new(0, 0, 1),
	Back = Vector3.new(0, 0, -1),
})

local ChunkLoader = {}

--[[Local]]

local function PosToIndex(X : number, Y : number, Z : number) : number
	return (Y - 1) * Global.SqrdChunkCellSize + (Z - 1) * Global.ChunkCellSize + X
end

local function IndexToPos(Index : number) : (number, number, number)
	local i = Index - 1
	local Y = math.floor(i / Global.SqrdChunkCellSize) + 1
	local r = i % Global.SqrdChunkCellSize
	local Z = math.floor(r / Global.ChunkCellSize) + 1
	local X = (r % Global.ChunkCellSize) + 1
	
	return X, Y, Z
end

--Mean't for pcall, don't use otherwise
local function GetBlockData(PlotIndex : number, CubicChunkIndex : number, X : number, Y : number, Z : number)
	local Data = Global.ChunkData[PlotIndex][ChunkLoaderIndex][CubicChunkIndex][tostring(PosToIndex(X, Y, Z))]
	if Data then return Data else error() end
end

local function SpawnCubicChunk(PlotIndex : number, ChunkData : ChunkData, CubicChunkData : {}, CubicChunkIndex : number)
	for PosIndex, BlockData in CubicChunkData do
		local BlockID = UnpackInt(BlockData[1])
		local X, Y, Z = IndexToPos(PosIndex)

		ChunkLoader.GenerateBlock(PlotIndex, ChunkData, CubicChunkIndex, BlockID, {X = X, Y = Y, Z = Z})

		task.wait()
		task.wait()
	end
end

local function SpawnGroundLayer(YLayer : number, PlotIndex : number, ChunkData : ChunkData, CubicChunkIndex : number)
	for X = 1, 14 do
		task.spawn(function()
			for Z = 1, 14 do
				if ChunkLoader.BlockAt(PlotIndex, CubicChunkIndex, Vector3.new(X, YLayer, Z), true) then
					continue
				end

				local BlockID = GroundLayerBlockIDs[YLayer]
				ChunkLoader.GenerateBlock(PlotIndex, ChunkData, CubicChunkIndex, BlockID, {X = X, Y = YLayer, Z = Z})
			end
		end)
		task.wait()
	end
end

--[[Global]]

function ChunkLoader.LoadData(PlotIndex : number, ChunkData : ChunkData)
	Global.ChunkData[PlotIndex][ChunkLoaderIndex] = ChunkData
	
	for YLayer = 1, 6 do
		-- 1 is the lowest cubic chunk, it's being used here because were generating the starter ground layer
		task.spawn(SpawnGroundLayer, YLayer, PlotIndex, ChunkData, 1)
	end

	if ChunkLoaderIndex == 25 then
		local ChunkSlices = ChunkLoader.GenerateChunkSlices(PlotIndex, 1)
		local ValidFaces  = ChunkLoader.CalculateCulledFaces(ChunkSlices)

		print(ValidFaces)
	end
	
	for CubicChunkIndex, CubicChunkData in ChunkData do
		task.spawn(SpawnCubicChunk, PlotIndex, ChunkData, CubicChunkData, CubicChunkIndex)
	end
end

function ChunkLoader.GenerateBlock(PlotIndex : number, ChunkData : ChunkData, CubicChunkIndex : number, BlockID : number?, PosData : PositionData)
	local X,Y,Z = if PosData.Index then IndexToPos(PosData.Index) else PosData.X, PosData.Y, PosData.Z
	
	if not BlockID then
		local DataWasFound, BlockData = pcall(GetBlockData, PlotIndex, CubicChunkIndex, X,Y,Z)
		if not DataWasFound then return end

		BlockID = UnpackInt(BlockData[1])
	end

	local BlockName = BlockIDToBlockName[BlockID]
	if BlockName == "Air" then return end

	xpcall(function()
		local BlockModel : Model = ReplicatedStorage.Blocks:FindFirstChild(BlockName, true):Clone()

		ChunkLoader.LoadFaces(PlotIndex, ChunkData, CubicChunkIndex, BlockModel, X, Y, Z)
		BlockModel:PivotTo(CFrame.new(ChunkLoader.LocalToGlobalVector(CubicChunkIndex, PlotIndex, X, Y, Z)))
	end, function(ErrorMSG)
		warn(`No model found for {BlockName}!`)
		warn(ErrorMSG)
	end)
end

function ChunkLoader.GenerateChunkSlices(PlotIndex : number, CubicChunkIndex : number) : {number}
	local Slices = {}

	--Padded chunk size is decremented by 1 to have each axis be 0 - 15 (16 blocks total)
	local PaddedChunkCellSize = Global.PaddedChunkCellSize - 1

	for X = 0, PaddedChunkCellSize do
		for Y = 0, PaddedChunkCellSize do
			--Generated outside the loop for less calculations
			local FrontBackIndex = X + (Y * Global.PaddedChunkCellSize) + Global.DoubleSqrdPaddedChunkCellSize
			
			for Z = 0, PaddedChunkCellSize do
				local RecievedData, CubicChunkIndex, BX, BY, BZ = ChunkLoader.GetChunkAtPositionOverlap(CubicChunkIndex, X,Y,Z)
				if not RecievedData then continue end -- No block there, guaranteed

				local TopDownIndex	 = 	X + (Z * Global.PaddedChunkCellSize)
				local LeftRightIndex = 	Z + (Y * Global.PaddedChunkCellSize) + Global.SqrdPaddedChunkCellSize
				
				local BlockAtPos = ChunkLoader.BlockAt(PlotIndex, CubicChunkIndex, Vector3.new(BX, BY, BZ))
				if BlockAtPos then
					--Fill in chunk slices for their axis
					Slices[LeftRightIndex] 	= bit32.bor(Slices[LeftRightIndex] or 0, bit32.lshift(1, X))
					Slices[TopDownIndex] 	= bit32.bor(Slices[TopDownIndex] or 0, bit32.lshift(1, Y))
					Slices[FrontBackIndex] 	= bit32.bor(Slices[FrontBackIndex] or 0, bit32.lshift(1, Z))
				end
			end
		end
	end

	return Slices
end

function ChunkLoader.CalculateCulledFaces(Slices : {number}) : {number}
	local ValidFaces = {}

	for Axis = 0, 3 do
		for i = 0, Global.SqrdPaddedChunkCellSize do
			local Column = Slices[(Global.SqrdPaddedChunkCellSize * Axis) + i]
			if not Column then continue end

			ValidFaces[(Global.SqrdPaddedChunkCellSize * (Axis * 2 + 1)) + i] 	= BAnd(Column, Reverse(RShift(Column, 1)))
			ValidFaces[(Global.SqrdPaddedChunkCellSize * (Axis * 2)) + i]		= BAnd(Column, Reverse(LShift(Column, 1)))
		end
	end

	return ValidFaces
end

function ChunkLoader.LoadFaces(PlotIndex : number, ChunkData : ChunkData, CubicChunkIndex : number, BlockModel : Model, X : number, Y : number, Z : number)
	local LocalBlockOrigin = Vector3.new(X, Y, Z)
	local Visibility = 6

	for FaceName, OffsetVector in NeighboringBlockOffsets do
		local FoundBlock = ChunkLoader.BlockAt(PlotIndex, CubicChunkIndex, LocalBlockOrigin + OffsetVector)
		if not FoundBlock then continue end
		
		local Face = BlockModel:FindFirstChild(FaceName, true)
		if Face then
			Face:Destroy()
			Visibility -= 1

			if Visibility <= 0 then
				BlockModel:Destroy()
				return
			end
		end
	end

	BlockModel.Parent = workspace.Plots["Plot" .. PlotIndex]
end

function ChunkLoader.BlockAt(PlotIndex : number, CubicChunkIndex : number, ChunkVector : Vector3, IgnoreDefaultBlocks : boolean?) : boolean
	local X, Y, Z = ChunkVector.X, ChunkVector.Y, ChunkVector.Z
	local ChunkIndex = ChunkLoaderIndex

	for _, Axis in {X, Y, Z} do
		if Axis <= 0 or Axis >= 15 then
			ChunkIndex, CubicChunkIndex, X, Y, Z = ChunkLoader.GetChunkAtPositionOverlap(CubicChunkIndex, X,Y,Z)
			if not ChunkIndex then return false end
			break -- no point in checking other axes as the function considers all of them
		end
	end

	local CacheIndex = `{ChunkIndex}_{CubicChunkIndex}_{PosToIndex(X,Y,Z)}_{IgnoreDefaultBlocks and "Ignore" or "Normal"}`

	--Check cache first
	if Global.IsBlockAtCache[PlotIndex][CacheIndex] then
		return Global.IsBlockAtCache[PlotIndex][CacheIndex]
	end

	local DataWasFound, BlockData = pcall(GetBlockData, PlotIndex, CubicChunkIndex, X,Y,Z)
	if DataWasFound then
		local BlockID = UnpackInt(BlockData[1])
		local CullValue = Config:CullBlock(BlockID)

		Global.IsBlockAtCache[PlotIndex][CacheIndex] = CullValue
		return CullValue
	end

	if IgnoreDefaultBlocks then
		Global.IsBlockAtCache[PlotIndex][CacheIndex] = false
		return false
	end

	--Check if position is within default ground layer bounds
	if CubicChunkIndex == 1 and Y <= 6 then -- and X >= 1 and X <= 14 and Z >= 1 and Z <= 14 
		Global.IsBlockAtCache[PlotIndex][CacheIndex] = true
		return true
	end

	Global.IsBlockAtCache[PlotIndex][CacheIndex] = false
	return false
end

function ChunkLoader.LocalToGlobalVector(CubicChunkIndex : number, PlotIndex : number, X : number, Y : number, Z : number) : Vector3
	--XYZ are converted to zero base for the block offset
	local BlockXOffset = (X - 1) * BlockSize
	local BlockYOffset = (Y - 7) * BlockSize --chunks are offset on the Y axis
	local BlockZOffset = (Z - 1) * BlockSize

	local ChunkX = Base0ChunkIndex % ChunkAreaGridSize
	local ChunkZ = math.floor(Base0ChunkIndex / ChunkAreaGridSize)

	local ChunkXOffset = ChunkX * ChunkBlockSize
	local ChunkYOffset = (CubicChunkIndex - 1) * ChunkBlockSize
	local ChunkZOffset = ChunkZ * ChunkBlockSize

	local HorizontalOffsetToCorner = (Global.PlotSize / 2) - (BlockSize / 2)

	local OffsetFromCorner = Vector3.new(BlockXOffset + ChunkXOffset, BlockYOffset + ChunkYOffset, BlockZOffset + ChunkZOffset)
	local OffsetToCorner = Vector3.new(HorizontalOffsetToCorner, 0, HorizontalOffsetToCorner)
	local PlotOriginPosition = Global.PlotOrigins[PlotIndex]

	return PlotOriginPosition - OffsetToCorner + OffsetFromCorner
end

function ChunkLoader.GetChunkAtPositionOverlap(CubicChunkIndex : number, LX : number, LY : number, LZ : number) -- Local Positions to the parent chunk
	local CubicChunkOffset = 0
	local ColumnOffset = 0
	local RowOffset = 0

	local Transformations = {
		LX, ColumnOffset,
		LY, CubicChunkOffset,
		LZ, RowOffset,
	}

	for LocalAxis = 1, 6, 2 do
		local Offset = LocalAxis + 1

		if Transformations[LocalAxis] <= 0 then
			Transformations[LocalAxis] += 14
			Transformations[Offset] -= 1
		elseif Transformations[LocalAxis] >= 15 then
			Transformations[LocalAxis] -= 14
			Transformations[Offset] += 1
		end
	end

	LX, ColumnOffset = Transformations[1], Transformations[2]
	LY, CubicChunkOffset = Transformations[3], Transformations[4]
	LZ, RowOffset = Transformations[5], Transformations[6]

	local RowIndex = math.floor((ChunkLoaderIndex - 1) / 5) + 1
	local ColumnIndex : number

	for i, ChunkIndex in Global.ChunkIndexes[RowIndex] do
		if ChunkLoaderIndex == ChunkIndex then
			ColumnIndex = i
		end
	end

	local OffsetCubicChunkIndex = CubicChunkIndex + CubicChunkOffset
	local OffsetColumnIndex = ColumnIndex + ColumnOffset
	local OffsetRowIndex = RowIndex + RowOffset

	for _, OffsetIndex in {OffsetColumnIndex, OffsetRowIndex} do
		if OffsetIndex <= 0 or OffsetIndex >= 6 then
			return nil -- No Chunk is in the given coords / No block will be there (Position outside of plot)
		end
	end

	if OffsetCubicChunkIndex <= 0 then
		return nil -- Out of bounds, no block will be there
	end

	return Global.ChunkIndexes[OffsetRowIndex][OffsetColumnIndex], OffsetCubicChunkIndex, LX, LY, LZ
end

return ChunkLoader