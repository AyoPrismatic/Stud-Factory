local Module = {}
--[[
This is a module script was originally made for gui, but I shifted it over to
other places too
]]

--Services
local TweenService = game:GetService('TweenService')
local Players = game:GetService('Players')

--GUI
local GameGUI = script.Parent

--[[
Init Tables for caching
table.create() is used with nil as it's just to make a table start 
with a certain bit size to prevent unneeded table resizes in the future
]]
local PlayerImages = table.create(#Players:GetPlayers(), nil)
local TweenInfos = table.create(10, nil)

--[[
Time, Style, & Direction are optional and will default to Quad and InOut if not given.
T, S, D = Time, Style, Direction.

Style & Direction are supposed to be strings:
E.g. NewTInfo(0.5, "Back", "In") -> TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
]]
function Module.NewTweenInfo(Info:{T : number?, S : string?, D : string?}) : TweenInfo
	Info = Info or {}
	
	local Direction = Info["D"] or "InOut"
	local Style = Info["S"] or "Quad"
	local Time = Info["T"] or 0.5

	local LookUpIndex = Time..Style..Direction

	if not TweenInfos[LookUpIndex] then
		TweenInfos[LookUpIndex] = TweenInfo.new(
			Time,
			Enum.EasingStyle[Style],
			Enum.EasingDirection[Direction]
		)
	end

	return TweenInfos[LookUpIndex]
end

--[[
Returns a tween for you to play()/use.
Move to Start is a bool value which either:
  - Moves the Frame from it's [start position + offset] -> [start position] (true)
  - Moves the Frame from it's [start position] -> [start position + offset] (false)
]]
function Module.TweenGUIPos(GUIElement, Offset : UDim2, AnimInfo : TweenInfo, MoveToStart : BoolValue) : Tween
	--Setup
	local StartPosition = GUIElement.Position
	GUIElement.Visible = true

	if MoveToStart then
		--Offset the Frame
		GUIElement.Position += Offset
		--Animate to Start Position
		return TweenService:Create(GUIElement, AnimInfo, {Position = StartPosition})
	else
		--Animate to Position
		return TweenService:Create(GUIElement, AnimInfo, {Position = StartPosition + Offset})
	end
end

local function EditPlayerImages(UserID:number, Remove:boolean, IDValidityCheck:boolean) end

--[[
Grabs a player's character thumbnail which gets generated upon joining.
All images are 420x420 and Enum.ThumbnailType.AvatarBust.
]]
function Module.GetPlayerThumbnail(UserID : number)
	--Image found so return the image
	if PlayerImages[UserID] then
		return PlayerImages[UserID]
	end

	--Image not found so make a new player image
	local Success = EditPlayerImages(UserID, false, true)

	--return nil if the userid is invalid (Player isn't in the game)
	if not Success then
		warn(UserID, "is an invalid UserID!!")
		return nil
	end

	--Return the image
	return Success
end

--[[Init functions]]
--functions for setting up caching things

EditPlayerImages = function(UserID : number, Remove : boolean, IDValidityCheck : boolean)
	--Remove the image if requested
	if Remove	then
		PlayerImages[UserID] = nil
		return -- no more image so return nothing
	end

	if IDValidityCheck then
		local Found = false

		for _, Player in Players:GetPlayers() do
			if Player.UserId == UserID then 
				Found = true
				break 
			end
		end

		if Found == false then return end
	end

	PlayerImages[UserID] = Players:GetUserThumbnailAsync(
		UserID, 
		Enum.ThumbnailType.AvatarBust, 
		Enum.ThumbnailSize.Size420x420
	)

	return PlayerImages[UserID]
end

--Intended for on player's being added or for all players when the client first joins
local function PlayerInit(Player : Player)
	EditPlayerImages(Player.UserId)
end

--Cleans up unnecessary data within the cache
local function RemovePlayerData(Player : Player)
	EditPlayerImages(Player.UserId, true)
end

for _, Player in Players:GetPlayers() do
	PlayerInit(Player)
end

Players.PlayerRemoving:Connect(RemovePlayerData)
Players.PlayerAdded:Connect(PlayerInit)

return Module
