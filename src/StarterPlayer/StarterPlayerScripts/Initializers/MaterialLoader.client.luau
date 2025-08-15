--Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local MaterialService = game:GetService('MaterialService')

MaterialService:ClearAllChildren()

local ResourcePack = ReplicatedStorage.ResourcePacks['512x512'].Studded:Clone()
ResourcePack.Parent = MaterialService