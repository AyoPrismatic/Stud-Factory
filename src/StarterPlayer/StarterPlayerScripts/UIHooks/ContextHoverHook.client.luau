--[[
	UI Hooks use CollectionService to connect/"hook" various UI elements to their
	wanted functionality which is built/coded in the UIHandlers.
--]]

--Services
local CollectionService = game:GetService('CollectionService')
local Players = game:GetService('Players')

--Player
local Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts

--Modules
local ContextHovers = require(PlayerScripts.UIHandlers.ContextHoverHandler)

--Read only list of Contexts(Attribute Values) connecting to Actions(Functions)
local Contexts = table.freeze({
	['ScaleUp'] = ContextHovers.ScaleUp,
})

local ActiveGUI = {}

--Grabs the context and matches it to the correct function
local function ConnectContexts()
	for Index, Button : TextButton in CollectionService:GetTagged('ContextHoverGUI') do 
		--ActiveGUI is a dict to have fast look ups
		if ActiveGUI[Button] == nil then
			--[[GetTagged() doesn't return in any specific order, 
			so we make a dict/hashmap to check later]]
			ActiveGUI[Button] = true -- This Bool Value doesn't mean anything btw
		else continue end
		
		local HoverContext = Button:GetAttribute("HoverContext")
		if not HoverContext then continue end
		
		--Splits the contexts into an array
		local RequestedContexts = string.split(HoverContext, ", ")
		
		--Makes sure the context is valid
		for Index, Context in RequestedContexts do
			if Contexts[Context] == nil then
				warn("Context function doesn't exist", Context)
				table.remove(RequestedContexts, Index)
				continue
			end
		end
		
		--Connects on press to the context
		Button.MouseEnter:Connect(function()
			for _, Context in RequestedContexts do
				--Calls a function inside of the module with the argument of the button
				Contexts[Context](Button)
			end
		end)
	end
end

CollectionService:GetInstanceAddedSignal("ContextHoverGUI"):Connect(function()
	ConnectContexts()
end)

ConnectContexts()