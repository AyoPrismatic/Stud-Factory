--Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')

--Modules
local CachedFunctions = require(ReplicatedStorage.Modules.CachedHelperFunctions)

export type FOPair = {FillOpacity:number, FillColor:Color3,  OutlineOpacity:number, OutlineColor:Color3}

local Highlighter = {}

--[[
	An in out animation for the opacity. 
	Starts at 1 and goes down to specified opacity.
	Then it reverses and goes back to 1.
	Time is evenly divided between tweens.
]]
function Highlighter.PulseHighlightTween(Object:Instance, Time:number, Args : FOPair)
	local Highlight = Instance.new('Highlight')
	Highlight.OutlineTransparency = 1
	Highlight.FillTransparency = 1
	Highlight.Parent = Object
	
	local AnimInfo = CachedFunctions.NewTweenInfo({T = Time / 2})
	Highlight.OutlineColor = Args.OutlineColor
	Highlight.FillColor = Args.FillColor
	
	local OutlineTween = TweenService:Create(Highlight, AnimInfo, {OutlineTransparency = Args.OutlineOpacity})
	local FillTween = TweenService:Create(Highlight, AnimInfo, {FillTransparency = Args.FillOpacity})
	OutlineTween:Play()
	FillTween:Play()
	
	FillTween.Completed:Once(function()
		task.wait(0.075)
		
		local OutlineTween = TweenService:Create(Highlight, AnimInfo, {OutlineTransparency = 1})
		local FillTween = TweenService:Create(Highlight, AnimInfo, {FillTransparency = 1})
		
		OutlineTween:Play()
		FillTween:Play()
		
		FillTween.Completed:Once(function()
			Highlight:Destroy()
		end)
	end)
end

export type FadeInFOPair = {InitialFillOpacity:number, FillOpacity:number, FillColor:Color3,  InitialOutlineOpacity:number, OutlineOpacity:number, OutlineColor:Color3}

--Creates a Highlight that starts invisible and fades in to a specified opacity
function Highlighter.FadeInHighlight(Object:Instance, Time:number, Args : FadeInFOPair) : Highlight
	local Highlight = Instance.new('Highlight')
	Highlight.OutlineTransparency = Args.InitialFillOpacity
	Highlight.FillTransparency = Args.InitialFillOpacity
	Highlight.Parent = Object

	Highlight.OutlineColor = Args.OutlineColor
	Highlight.FillColor = Args.FillColor
	
	local AnimInfo = CachedFunctions.NewTweenInfo({T = Time})
	local OutlineTween = TweenService:Create(Highlight, AnimInfo, {OutlineTransparency = Args.OutlineOpacity})
	local FillTween = TweenService:Create(Highlight, AnimInfo, {FillTransparency = Args.FillOpacity})
	OutlineTween:Play()
	FillTween:Play()

	return Highlight
end

--Updates the color of a highlight to a specified color
function Highlighter.UpdateColor(Object:Instance, FillColor:Color3, OutlineColor:Color3)
	if not Object then return end
	
	local Highlight = Object:FindFirstChildOfClass("Highlight")
	Highlight.OutlineColor = OutlineColor or Highlight.OutlineColor
	Highlight.FillColor = FillColor or Highlight.FillColor
end

--Adds and returns a highlight within a specified object
function Highlighter.AddHighlight(Object:Instance, Args : FOPair) : Highlight
	local Highlight = Instance.new('Highlight')
	Highlight.OutlineTransparency = Args.OutlineOpacity
	Highlight.FillTransparency = Args.FillOpacity
	Highlight.Parent = Object

	Highlight.OutlineColor = Args.OutlineColor
	Highlight.FillColor = Args.FillColor
	
	return Highlight
end

return Highlighter
