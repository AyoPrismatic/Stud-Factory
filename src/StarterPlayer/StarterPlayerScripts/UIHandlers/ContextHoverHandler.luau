--Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local Players = game:GetService('Players')

--Player
local Player = Players.LocalPlayer
local PlayerGUI = Player.PlayerGui

--GUI
local GameGUI = PlayerGUI:WaitForChild('GameGUI')

local Hover = {}

--[[Hover Functions]]

function Hover.ScaleUp(Button : TextButton)
	local OutTweeninfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local InTweeninfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local BaseSize = Button:GetAttribute("ScaleUpBaseSize")
	
	if not BaseSize then
		Button:SetAttribute("ScaleUpBaseSize", Button.Size)
		BaseSize = Button:GetAttribute("ScaleUpBaseSize")
	end
	
	local ScaleDownDelay = Button:GetAttribute("ScaleDownDelay") or 0
	local ScaleSize = Button:GetAttribute("ScaleSize") or 0.0085
	
	local TweenedSize = BaseSize + UDim2.new(ScaleSize, 0, ScaleSize, 0)
	
	--Play the animation
	local Tween = TweenService:Create(Button, InTweeninfo, {Size = TweenedSize})
	Tween:Play()
	
	--If the player stopped hovering then ease out
	Button.MouseLeave:Once(function()
		task.wait(ScaleDownDelay)
		
		Tween:Pause()
		Tween:Destroy()

		local Tween = TweenService:Create(Button, OutTweeninfo, {Size = BaseSize})
		Tween:Play()

		--if they entered back in, stop to prevent glitchy animations
		Button.MouseEnter:Once(function()
			Tween:Pause()
			Tween:Destroy()
		end)
	end)
end

return Hover