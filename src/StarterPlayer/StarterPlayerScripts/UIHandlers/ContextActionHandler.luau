--Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

--Player
local Player = Players.LocalPlayer
local PlayerGUI = Player.PlayerGui
local PlayerScripts = Player.PlayerScripts

--GUI
local GameGUI = PlayerGUI:WaitForChild('GameGUI')

local Actions = {}

function Actions.FireEvent(Button : TextButton)
     local EventStorageType = Button:GetAttribute("EventStorageType")
     local EventName = Button:GetAttribute("EventName")

     if EventStorageType == "Client" then
          local Event : BindableEvent = PlayerScripts.BindableEvents:FindFirstChild(EventName, true)
          Event:Fire()
     else
          local Event : RemoteEvent = ReplicatedStorage.Remotes:FindFirstChild(EventName, true)
          Event:FireServer()
     end
end

function Actions.SwapAttributes(Button : TextButton)
     local AttributesToSwap = Button:GetAttribute("AttributesToSwap")
     AttributesToSwap = string.split(AttributesToSwap, ", ")

     local Attr1 = Button:GetAttribute(AttributesToSwap[1])
     local Attr2 = Button:GetAttribute(AttributesToSwap[2])

     Button:SetAttribute(AttributesToSwap[1], Attr2)
     Button:SetAttribute(AttributesToSwap[2], Attr1)
end

local PlotRequester = ReplicatedStorage.Events.PlotEvents.FromClient.RequestPlot
function Actions.RequestPlot(Button : TextButton)
     local PlotIndex = Button:GetAttribute("PlotIndex")
     if not PlotIndex then
          warn(`Plot Index not found for {Button}!`)
          return
     end

     PlotRequester:FireServer(PlotIndex)
end

--[[UI Specific]]
local GlobalChunkLoaderData = require(PlayerScripts.ChunkLoaders.LoaderGlobals)
function Actions.PrintPlotLoadTime(Button : TextButton)
     for PlotIndex, LoadTime in GlobalChunkLoaderData.LoadTimes do
          if LoadTime == 0 then continue end
          
          print(`Took {math.round(LoadTime * 1000000) / 1000} Ms to load plot {PlotIndex}`)
     end
end

return Actions