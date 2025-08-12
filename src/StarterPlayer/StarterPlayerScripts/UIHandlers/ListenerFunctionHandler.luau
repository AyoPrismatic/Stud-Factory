--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService('TweenService')
local Players = game:GetService("Players")

--Player
local Player = Players.LocalPlayer
local PlayerGUI = Player.PlayerGui

--GUI
local GameGUI = PlayerGUI:WaitForChild('GameGUI')

--Modules
local CachedHelperFunctions = require(ReplicatedStorage.Modules.CachedHelperFunctions)

local Listener = {}

--[[UI Specific]]

function Listener.ActiveSlotVisualizer(Button : TextButton)
     local ActiveSlotColor = ColorSequence.new(Color3.new(0.4, 0.4, 0.4), Color3.new(0.3, 0.3, 0.3))
     local BaseSlotColor = ColorSequence.new(Color3.new(0.12, 0.12, 0.12), Color3.new())

     local ButtonGUI = Button.UIGradient

     Player.AttributeChanged:Connect(function(ChangedAttribute)
          if ChangedAttribute ~= "ActiveSlot" then return end

          local ActiveSlot = Player:GetAttribute("ActiveSlot")

          local NewColor = ActiveSlotColor
          if ActiveSlot ~= Button.Name then
               if ButtonGUI.Color == BaseSlotColor then return end
               NewColor = BaseSlotColor
          end

          ButtonGUI.Color = NewColor
     end)
end

return Listener