--Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local Players = game:GetService('Players')

--Player
local Player = Players.LocalPlayer
local PlayerGUI = Player.PlayerGui

--Folders
local EventsFolder = ReplicatedStorage.Events
local PlotEvents = EventsFolder.PlotEvents

--GUI
local GameGUI = PlayerGUI:WaitForChild('GameGUI')

--Events
local PlotClaimedEvent = PlotEvents.FromServer.PlotClaimed

PlotClaimedEvent.OnClientEvent:Connect(function(PlotOwner, ClaimedPlotNumber)
     local PlotSelectionGUI = GameGUI.PlotSelection
     local PlotsListGUI = PlotSelectionGUI.PlotsList

     if PlotOwner ~= Player then
          local InvalidatedPlotButton = PlotsListGUI:FindFirstChild(`Plot{ClaimedPlotNumber}Button`)
          InvalidatedPlotButton.Visible = false
          return
     end

     local Character = Player.Character
     --Character:PivotTo(Character:GetPivot() * CFrame.new(0,20,0))

     PlotSelectionGUI:Destroy()
end)