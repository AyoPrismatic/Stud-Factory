--Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--Player
local Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts

--Objects
local ExamplePart : BasePart = workspace:WaitForChild("ExamplePart")

--Modules
local Raycaster = require(PlayerScripts.Raycasting.Raycaster)

--Events
local SlotDeselected : BindableEvent = PlayerScripts.BindableEvents.Hotbar.SlotDeselected
local SlotSelected : BindableEvent = PlayerScripts.BindableEvents.Hotbar.SlotSelected

local HeartbeatConnection : RBXScriptConnection

SlotSelected.Event:Connect(function()
     HeartbeatConnection = RunService.Heartbeat:Connect(function()
          local RaycastResult = Raycaster.GetRaycastResult()
          if not RaycastResult then return end

          local Coords = Vector3.new(
               math.round((RaycastResult.Position.X / 3)) * 3,
               math.round((RaycastResult.Position.Y / 3) + 0.5) * 3,
               math.round((RaycastResult.Position.Z / 3)) * 3
          )

          ExamplePart:PivotTo(CFrame.new(Coords))
     end)
end)

SlotDeselected.Event:Connect(function()
     HeartbeatConnection:Disconnect()

     ExamplePart:PivotTo(CFrame.new(0, -10, 0))
end)