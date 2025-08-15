local ParentActor : Actor = script.Parent
if not ParentActor:IsA("Actor") then
     error("ChunkLoader incorrectly parented!")
end

--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Folders
local ChunkEventsFolder = ReplicatedStorage.Events.ChunkDataEvents
local ServerChunkEvents = ChunkEventsFolder.FromServer

--Events
local ServerChunkDataSender = ServerChunkEvents.ChunkDataSender

--Variables
local LoaderChunkNumber = tonumber(ParentActor.Name)

ServerChunkDataSender.OnServerEvent:ConnectParallel(function(RecievedChunkIndex : number, PlotNumber : number, ChunkData : {})
     if LoaderChunkNumber ~= RecievedChunkIndex then return end
     if next(ChunkData) == nil then
          warn("Recieved an empty chunk data table!")
          return
     end

     
end)