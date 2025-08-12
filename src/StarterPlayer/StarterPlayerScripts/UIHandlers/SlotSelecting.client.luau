--Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

--Player
local Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts

--Events
local SlotDeselected : BindableEvent = PlayerScripts.BindableEvents.Hotbar.SlotDeselected
local SlotSelected : BindableEvent = PlayerScripts.BindableEvents.Hotbar.SlotSelected

--Variables
local ValidSlots = table.freeze({
     [Enum.KeyCode.One] = "Slot1",
     [Enum.KeyCode.Two] = "Slot2",
     [Enum.KeyCode.Three] = "Slot3",
     [Enum.KeyCode.Four] = "Slot4",
     [Enum.KeyCode.Five] = "Slot5",
     [Enum.KeyCode.Six] = "Slot6",
     [Enum.KeyCode.Seven] = "Slot7",
     [Enum.KeyCode.Eight] = "Slot8",
     [Enum.KeyCode.Nine] = "Slot9",
     [Enum.KeyCode.Zero] = "Slot10",
})

InputService.InputBegan:Connect(function(Input, Typing)
     if not ValidSlots[Input.KeyCode] then return end
     if Typing then return end

     local SelectedSlot = ValidSlots[Input.KeyCode]

     if SelectedSlot == Player:GetAttribute("ActiveSlot") then
          Player:SetAttribute("ActiveSlot", "")
          SlotDeselected:Fire()
     else
          Player:SetAttribute("ActiveSlot", SelectedSlot)
          SlotSelected:Fire()
     end
end)