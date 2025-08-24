--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--Folder
local PlotEvents = ReplicatedStorage.Events.PlotEvents
local ServerPlotEvents = PlotEvents.FromServer

--Game Events
local PlotAbandoned : RemoteEvent = ServerPlotEvents.PlotAbandoned
local PlotClaimed : RemoteEvent = ServerPlotEvents.PlotClaimed

--Variables
local Plots : {[number] : Player | ""} = {
     [1] = "",
     [2] = "",
     [3] = "",
     [4] = ""
}

local PlotManager = {}

--[[Actions]]

function PlotManager.ClaimPlot(Player : Player, PlotNumber : number)
     if not Plots[PlotNumber] then
          warn(`{Player} tried to claim an invalid Plot!`)
          return
     end

     if Plots[PlotNumber] ~= "" then
          warn(`{Player} tried to claim an owned Plot!`)
          return
     end

     PlotClaimed:FireAllClients(Player, PlotNumber)
     Plots[PlotNumber] = Player
end

local function AbandonPlot(Player : Player, PlotIndex : number)
     --Find the player's plot
     local PlotNumber
     for Number, Owner in Plots do
          if Owner == Player then
               PlotNumber = Number
          end
     end

     PlotAbandoned:FireAllClients(Player, PlotNumber)
     Plots[PlotNumber] = ""
end

--[[Getters]]

function PlotManager.GetAvailablePlots() : {number}
     local AvailablePlotNumbers = {}

     for PlotNumber, Key in Plots do
          if Key == "" then
               table.insert(AvailablePlotNumbers, PlotNumber)
          end
     end

     return AvailablePlotNumbers
end

--[[Clean up on player leave]]

Players.PlayerRemoving:Connect(function(PlayerLeaving)
     for OwnedPlotIndex, Player in Plots do
          if PlayerLeaving ~= Player then continue end
          AbandonPlot(Player, OwnedPlotIndex)
     end
end)

return PlotManager