--Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

--Modules
local PlotOwnerShipManager = require(ServerStorage.LiveGameData.PlotOwnerShip)
local ChunkDataManager = require(ServerStorage.LiveGameData.ChunkDataManager)

--Folders
local ChunkEventsFolder = ReplicatedStorage.Events.ChunkDataEvents
local ClientChunkEvents = ChunkEventsFolder.FromClient

--Events
local RequestChunkData = ClientChunkEvents.RequestChunkData

RequestChunkData.OnServerEvent:Connect(function(Player : Player, PlotIndex : buffer, ChunkIndex : buffer)
     if typeof(ChunkIndex) ~= "buffer" then
          warn(`Invalid Chunk request recieved from {Player}! ChunkIndex isn't a buffer!`)
          return
     end
     if typeof(PlotIndex) ~= "buffer" then
          warn(`Invalid Chunk request recieved from {Player}! PlotIndex isn't a buffer!`)
          return
     end

     local ChunkIndex : number = buffer.readu8(ChunkIndex, 0)
     local PlotIndex : number = buffer.readu8(PlotIndex, 0)

     if ChunkIndex < 1 or ChunkIndex > 25 then
          warn(`Invalid Chunk request recieved from {Player}! ChunkIndex isn't between 1-25!`)
          return
     end
     if PlotIndex < 1 or PlotIndex > 4 then
          warn(`Invalid Chunk request recieved from {Player}! PlotIndex isn't between 1-4!`)
          return
     end

     ChunkDataManager.ChunkDataRequested(Player, PlotIndex, ChunkIndex)
end)