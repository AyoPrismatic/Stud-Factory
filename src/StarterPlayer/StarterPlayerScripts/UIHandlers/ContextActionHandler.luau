--Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
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

function Actions.EditAttributes(Button : TextButton)
     local AttributesToChange = Button:GetAttribute("AttributesToChange")
     local ValuesSplitter = Button:GetAttribute("ValuesSplitter") or ", "
     local AttributeValues = Button:GetAttribute("AttributeValues")

     AttributesToChange = string.split(AttributesToChange, ValuesSplitter)
     AttributeValues = string.split(AttributeValues, ValuesSplitter)

     for i = 1, #AttributeValues do
          Button:SetAttribute(AttributesToChange[i], AttributeValues[i])
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

return Actions