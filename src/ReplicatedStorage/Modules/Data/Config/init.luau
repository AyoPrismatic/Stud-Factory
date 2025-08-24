--Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')

--Modules
local TableFunctions = require(ReplicatedStorage.Modules.DataUtils.TableFunctions)

--[[Initalizing Data]]
local BlockIDData = require(script.BlockIDConverter)
local CullingIgnoreList = require(script.BlockCullingData)

local Config = {
	BlockIDData = {
		IDToName = BlockIDData.BlockIDToBlockName,
		NameToID = BlockIDData.BlockNameToBlockID
	},
	
	CullingIgnoreList = CullingIgnoreList
}

--[[Accessor Methods]]

function Config:GetNestedData(Names : {string}, WarnOnFail : boolean)
	if WarnOnFail == nil then WarnOnFail = true end
	if type(Names) ~= "table" then
		warn("Error when fetching nested config data:")
		warn(Names, "should be a table!")
	end
	
	local ReturnData = self
	
	for _, Name in Names do
		Name = tonumber(Name) or Name
		if not ReturnData[Name] then
			if not WarnOnFail then return end
			warn("Error when fetching nested config data:")
			warn(Name, "Not found in", ReturnData)
			return
		else
			ReturnData = ReturnData[Name]
		end
	end
	
	return ReturnData
end

function Config:GetGamemodeData(Name : string)
	local GMData = self.GamemodeData
	if not GMData[Name] then
		warn(Name, "not found in config (Gamemode Data)")
		return
	end

	return GMData[Name]
end

function Config:GetData(Name : string)
	if not self[Name] then
		warn(Name, "not found in config")
		return
	end
	
	return self[Name]
end

function Config:CullBlock(ID) : boolean
	if CullingIgnoreList[ID] then
		return false
	else
		return true
	end
end

--[[Exporting Nested Types]]



TableFunctions.DeepFreeze(Config)
return Config