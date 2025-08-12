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
local ListenerFunctions = require(PlayerScripts.UIHandlers.ListenerFunctionHandler)

--Read only list of Functions(Attribute Names) connecting to Actions(Functions)
local Functions = table.freeze({
	--[[Specific uses]]
	['ActiveSlotVisualizer'] = ListenerFunctions.ActiveSlotVisualizer
})

local ActiveGUI = {}

--Grabs the context and matches it to the correct function
local function ConnectFunctions()
	for Index, Button : TextButton in CollectionService:GetTagged('ListenerGUI') do 
		--ActiveGUI is a dict to have fast look ups
		if ActiveGUI[Button] == nil then
			--[[GetTagged() doesn't return in any specific order, 
			so we make a dict/hashmap to check later]]
			ActiveGUI[Button] = true -- This Bool Value doesn't mean anything btw
		else continue end
		
		local ListenFunctions = Button:GetAttribute("ListenFunctions")
		if not ListenFunctions then continue end

		--Splits the contexts into an array
		local RequestedFunctions = string.split(ListenFunctions, ", ")

		--Makes sure the context is valid
		for Index, Function in RequestedFunctions do
			if Functions[Function] == nil then
				warn("Listener function doesn't exist", Function)
				table.remove(RequestedFunctions, Index)
				continue
			end
		end

		--Connects on to the function
		for _, Function in RequestedFunctions do
			--Calls a function inside of the module with the argument of the button
			Functions[Function](Button)
		end
	end
end

CollectionService:GetInstanceAddedSignal("ListenerGUI"):Connect(ConnectFunctions)
ConnectFunctions()