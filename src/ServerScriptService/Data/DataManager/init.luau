--Services
local ServerScriptService = game:GetService('ServerScriptService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

--Modules
local PlayerDataTemplate = require(ServerScriptService.Data.DataTemplate)
local ProfileStore = require(ServerScriptService.Data.ProfileStore)
local DataMethods = require(script.DataMethods)

--Datastores
local DATA_STORE_KEY = RunService:IsStudio() and 'StudioData' or 'GameData'

--Server's list of player data
local PlayerStore = ProfileStore.New(DATA_STORE_KEY, PlayerDataTemplate.DEFAULT_DATA_TYPE)
local Profiles: {[Player]: typeof(PlayerStore:StartSessionAsync())} = {}
local InitialPlayerData = setmetatable({}, {__mode = 'k'})

--Table of Functions

local DataManager = {}
DataManager.Private = {}
DataManager.Public = {}

DataManager.Public.Get = {}
DataManager.Public.Set = {}

--[[Server Startup]]
function DataManager.Private.OnStart()
	for _, Player in Players:GetPlayers() do
		task.spawn(DataManager.Private.LoadProfile, Player)
	end
	
	game:BindToClose(function()
		for _, Player in Players:GetChildren() do
			DataManager.Private.RemoveProfile(Player)
		end
	end)
	
	Players.PlayerRemoving:Connect(DataManager.Private.RemoveProfile)
	Players.PlayerAdded:Connect(DataManager.Private.LoadProfile)
end

--[[Loading Profile Data]]
function DataManager.Private.LoadProfile(Player: Player)
	local profile = PlayerStore:StartSessionAsync(tostring(Player.UserId), {
		Cancel = function()
			return Player.Parent ~= Players
		end,
	})
	
	if profile == nil then
		return Player:Kick('Something Failed, Please Join Again!')
	end
	
	profile:AddUserId(Player.UserId)
	profile:Reconcile()
	
	profile.OnSessionEnd:Connect(function()
		Profiles[Player] = nil
		return Player:Kick('DataProfile Ended Abruptly, Please Join Again!')
	end)
	
	if Player.Parent == Players then -- checks for if their in game
		Profiles[Player] = profile
	else
		profile:EndSession()
	end
	
	InitialPlayerData[tostring(Player.UserId)] = profile['Data']
	DataManager.Private.CreateReplicatedData(Player)
end

function DataManager.Private.CreateReplicatedData(Player: Player)
	local Data = Profiles[Player]
	if not Data then return end
	
	local StatsFolder = Instance.new('Folder')
	StatsFolder.Parent = Player
	StatsFolder.Name = 'Stats'
	
	local LeaderstatsFolder = Instance.new('Folder')
	LeaderstatsFolder.Parent = Player
	LeaderstatsFolder.Name = 'leaderstats'

	--[[TODO: Finish later!]]
end

local function ReturnData(Player : Player) : {} | nil
	return Profiles[Player]["Data"]
end

function DataManager.Private.GetPlayerData(Player : Player) : {}
	local GotData, Data = pcall(ReturnData, Player)
	while not GotData do
		warn(`Failed to load player data for {Player}`)
		GotData, Data = pcall(ReturnData, Player)

		task.wait(0.1)
	end

	return Data
end

--[[Player Removal]]
function DataManager.Private.RemoveProfile(Player : Player)
	local OnJoinProfileSave = InitialPlayerData[tostring(Player.UserId)]
	local CurrentProfileSave = Profiles[Player]
	
	if CurrentProfileSave ~= nil then
		if OnJoinProfileSave ~= CurrentProfileSave then -- prevents unnescessary saves
			CurrentProfileSave:Save()
		end
		
		CurrentProfileSave:EndSession()
	end
	
	InitialPlayerData[tostring(Player.UserId)] = nil
end

--[[Public Getter Functions]]

--Returns Plot data from a specific life/rebirth
function DataManager.Public.Get.RebirthPlotData(Player : Player, LifeIndex : number) : {}
	local Data = DataManager.Private.GetPlayerData(Player)
	if Data then 
		local TotalRebirths = DataManager.Public.Get.Rebirths(Player)
		LifeIndex -= 1

		if LifeIndex < 0 or LifeIndex > TotalRebirths then
			warn(`Incorrect Rebirth Index! {LifeIndex}`)
			return
		end
		
		return Data["WorldData"][LifeIndex + 1]
	end
end

--Returns ALL Plot data of a player
function DataManager.Public.Get.PlotDataArray(Player : Player) : {}
	local Data = DataManager.Private.GetPlayerData(Player)
	return Data["WorldData"]
end

function DataManager.Public.Get.HotbarSlot(Player : Player, Slot : number) : {}
	local Data = DataManager.Private.GetPlayerData(Player)
	if Slot < 1 or Slot > 10 then
		warn(`Incorrect Slot Index! {Slot}`)
		return
	end
	
	return Data["Inventory"][Slot]
end

function DataManager.Public.Get.Inventory(Player : Player) : {}
	local Data = DataManager.Private.GetPlayerData(Player)
	return Data["Inventory"]
end

function DataManager.Public.Get.CurrentSelectedLife(Player : Player) : number
	local Data = DataManager.Private.GetPlayerData(Player)
	return Data["CurrentSelectedLife"]
end

function DataManager.Public.Get.Rebirths(Player : Player) : number
	local Data = DataManager.Private.GetPlayerData(Player)
	return Data["Rebirths"]
end

function DataManager.Public.Get.Cash(Player : Player) : number
	local Data = DataManager.Private.GetPlayerData(Player)
	return Data["Cash"]
end

--[[Public Setter Functions]]

function DataManager.Public.Set.RebirthPlotData(Player : Player, LifeIndex : number, WorldData : {}) : number
	if type(LifeIndex) ~= "number" then
		warn(`Incorrect type for Life Index! Got {LifeIndex} : {type(LifeIndex)}`)
		return
	end

	local Data = DataManager.Private.GetPlayerData(Player)
	local TotalRebirths = DataManager.Public.Get.Rebirths(Player)

	LifeIndex -= 1
	if LifeIndex < 0 or LifeIndex > TotalRebirths then
		warn(`Incorrect Rebirth Index! {LifeIndex}`)
		return
	end
	
	Data["WorldData"][LifeIndex + 1] = WorldData
end

function DataManager.Public.Set.HotbarSlot(Player : Player, Slot : number, SlotData) : number
	if type(Slot) ~= "number" then
		warn(`Incorrect type for Hotbar Slot! Got {Slot} : {type(Slot)}`)
		return
	end

	if Slot < 1 or Slot > 10 then
		warn(`Incorrect Slot Index! {Slot}`)
		return
	end

	local Data = DataManager.Private.GetPlayerData(Player)
	Data["Inventory"][Slot] = SlotData
end

function DataManager.Public.Set.Inventory(Player : Player, Index : number, IndexData) : number
	local Data = DataManager.Private.GetPlayerData(Player)
	
	Data["Inventory"][Index] = IndexData
end

function DataManager.Public.Set.Rebirths(Player : Player, Count) : number
	if type(Count) ~= "number" then
		warn(`Incorrect type for Rebirth Count! Got {Count} : {type(Count)}`)
		return
	end

	local Data = DataManager.Private.GetPlayerData(Player)
	Data["Rebirths"] = Count
end

function DataManager.Public.Set.Cash(Player : Player, Amount : number) : number
	if type(Amount) ~= "number" then
		warn(`Incorrect type for Cash Amount! Got {Amount} : {type(Amount)}`)
		return
	end

	local Data = DataManager.Private.GetPlayerData(Player)
	Data["Cash"] = Amount
end



DataManager.Private.OnStart()
return DataManager.Public