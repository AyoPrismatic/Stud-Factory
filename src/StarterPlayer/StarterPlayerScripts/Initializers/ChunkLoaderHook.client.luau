--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService('Players')

--Player
local Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts

--Folders
local ChunkEventsFolder = ReplicatedStorage.Events.ChunkDataEvents
local PlotEventsFolder = ReplicatedStorage.Events.PlotEvents

local ServerChunkEvents = ChunkEventsFolder.FromServer
local ClientChunkEvents = ChunkEventsFolder.FromClient
local ServerPlotEvents = PlotEventsFolder.FromServer

local ChunkLoaderFolder = PlayerScripts.ChunkLoaders

local ChunkAreasFolder : Folder = workspace.ChunkAreas

--Objects
local ReferenceLoaderModule = ChunkLoaderFolder.ReferenceLoaderModule

--Events
local RequestChunkData : UnreliableRemoteEvent = ClientChunkEvents.RequestChunkData
local RecievedChunkData : RemoteEvent = ServerChunkEvents.ChunkDataSender
local PlotClaimed : RemoteEvent = ServerPlotEvents.PlotClaimed

for ChunkIndex = 1, 25 do
     local Actor = Instance.new('Actor')
     Actor.Parent = ChunkLoaderFolder
     Actor.Name = ChunkIndex

     local ChunkLoader = ReferenceLoaderModule:Clone()
     ChunkLoader.Name = `ChunkLoader{ChunkIndex}`
     ChunkLoader.Parent = Actor

     require(ChunkLoader)
end

ReferenceLoaderModule:Destroy()

local function SortChunksTable(A, B) return A.Distance < B.Distance end
local function SortChunks(PlotNumber : number) : {}
     local ChunkAreas = ChunkAreasFolder:FindFirstChild("Plot" .. PlotNumber)
     local SortedChunks = table.create(25, nil)

     for _, ChunkArea : BasePart in ChunkAreas:GetChildren() do
          local ChunkAreaPosition = ChunkArea:GetPivot().Position
          local CharacterPosition = Vector3.zero
          local Character = Player.Character

          if Character then
               CharacterPosition = Character:GetPivot().Position
          end

          local Distance = (CharacterPosition - ChunkAreaPosition).Magnitude

          table.insert(SortedChunks, {ChunkIndex = ChunkArea.Name, Distance = Distance, DataGrabbed = false})
     end

     table.sort(SortedChunks, SortChunksTable)
     return SortedChunks
end

local function OnPlotClaimed(_, PlotIndex)
     local SortedChunks = SortChunks(PlotIndex)
     local ChunksAwaitingData = {}

     RecievedChunkData.OnClientEvent:Connect(function(ChunkIndex, ChunkData)
          local ChunkIndex = tostring(ChunkIndex)
          
          ChunksAwaitingData[ChunkIndex].DataGrabbed = true

          local ChunkLoaderActor = ChunkLoaderFolder:FindFirstChild(ChunkIndex)
          local ChunkLoader = require(ChunkLoaderActor[`ChunkLoader{ChunkIndex}`])

          task.spawn(ChunkLoader.LoadData, PlotIndex, ChunkData)
     end)

     for _, ChunkData in SortedChunks do
          local ChunkIndex = ChunkData.ChunkIndex

          local RequestedChunkBuffer = buffer.create(1)
          local PlotIndexBuffer = buffer.create(1)

          buffer.writeu8(RequestedChunkBuffer, 0, ChunkIndex)
          buffer.writeu8(PlotIndexBuffer, 0, PlotIndex)
          
          ChunksAwaitingData[ChunkIndex] = ChunkData

          while ChunkData.DataGrabbed == false do
               RequestChunkData:FireServer(PlotIndexBuffer, RequestedChunkBuffer)
               task.wait(0.14)
          end
     end     
end

PlotClaimed.OnClientEvent:Connect(OnPlotClaimed)

