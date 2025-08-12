--Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

--Player
local Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts

--Modules
local Raycaster = require(script.Parent.Raycaster)

--Events
local SlotDeselected : BindableEvent = PlayerScripts.BindableEvents.Hotbar.SlotDeselected
local SlotSelected : BindableEvent = PlayerScripts.BindableEvents.Hotbar.SlotSelected

local StartRaycasting : RBXScriptConnection
local StopRaycasting : RBXScriptConnection

Player.CharacterAdded:Connect(function()
     StartRaycasting = SlotSelected.Event:Connect(Raycaster.Start)
     StopRaycasting = SlotDeselected.Event:Connect(Raycaster.Stop)
end)

Player.CharacterRemoving:Connect(function()
     StartRaycasting:Disconnect()
     StopRaycasting:Disconnect()
end)