--Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

--Modules
local PlotManager = require(ServerStorage.LiveGameData.PlotOwnerShip)

--Folders
local PlotEventsFolder = ReplicatedStorage.Events.PlotEvents
local ClientPlotEvents = PlotEventsFolder.FromClient

--Events
local PlotRequestEvent = ClientPlotEvents.RequestPlot

PlotRequestEvent.OnServerEvent:Connect(function(Player : Player, PlotIndex : number)
     if type(PlotIndex) ~= "number" then
          warn(`Invalid Plot request recieved from {Player}! PlotIndex isn't a number!`)
          return
     end

     if PlotIndex < 1 or PlotIndex > 4 then
          warn(`Invalid Plot request recieved from {Player}! PlotIndex isn't within plot count!`)
          return
     end

     local AvailablePlots = PlotManager.GetAvailablePlots()
     local RequestedPlotAvailable = false
     for _, Index in AvailablePlots do
          if PlotIndex ~= Index then continue end

          RequestedPlotAvailable = true
          break
     end

     if not RequestedPlotAvailable then
          warn(`{Player} Requested a taken or invalid Plot! [{PlotIndex}]`)
          return
     end

     PlotManager.ClaimPlot(Player, PlotIndex)
end)