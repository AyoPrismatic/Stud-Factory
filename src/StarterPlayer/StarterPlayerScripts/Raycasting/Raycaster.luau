--Services
local RunService = game:GetService("RunService")
local Players = game:GetService('Players')

--Player
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

--Default raycast parameters
local ModuleRayParams = RaycastParams.new()
ModuleRayParams.FilterType = Enum.RaycastFilterType.Exclude
ModuleRayParams.FilterDescendantsInstances = {}
local RaycastFilter = {}

--Module settings
local PlayerCamera = workspace.CurrentCamera
local RaycastDistance = 10000

--Private variables
local RenderSteppedConnection = nil
local RunningRaycasts = false
local LastRaycastResult = nil

local RaycastModule = {}

--[[Helper Functions]]

local function UpdateRaycast()
	if not PlayerCamera then
		PlayerCamera = workspace.CurrentCamera
	end

	--No workspace.CurrentCamera or Camera
	if not PlayerCamera then return nil end

	--Get screen center coordinates
	local ViewportSize = PlayerCamera.ViewportSize

	--Convert screen position to world ray
	local Ray = PlayerCamera:ScreenPointToRay(Mouse.X, Mouse.Y)
	
	--Perform and return the Raycast
	LastRaycastResult = workspace:Raycast(Ray.Origin, Ray.Direction * RaycastDistance, ModuleRayParams)
end

--[[Public Functions]]

--Disables or Enables raycasting
function RaycastModule.SetEnabled(Enabled)
	if not RunningRaycasts and Enabled == true then
		RenderSteppedConnection = RunService.RenderStepped:Connect(UpdateRaycast)
		UpdateRaycast()

		RunningRaycasts = true
		return
	end

	if RunningRaycasts and Enabled == false then
		if RenderSteppedConnection then
			RenderSteppedConnection:Disconnect()
			RenderSteppedConnection = nil
		end

		LastRaycastResult = nil
		RunningRaycasts = false
		return
	end
end

--Starts the raycasting
function RaycastModule.Start()
	if RunningRaycasts then return end
	RaycastModule.SetEnabled(true)
	print("Raycasting!")
end

--Stops the raycasting
function RaycastModule.Stop()
	if not RunningRaycasts then return end
	RaycastModule.SetEnabled(false)
	print("Raycasting stopped.")
end

--Returns if the raycaster is on or off
function RaycastModule.GetRaycasterState() : boolean
	return RunningRaycasts
end

--Returns the most recent raycast result
function RaycastModule.GetRaycastResult() : RaycastResult?
	if not RunningRaycasts then
		warn("RaycastModule: GetRaycastResult() called while module is stopped. Call SetEnabled(true) first.")
		return nil
	end

	return LastRaycastResult
end

--Updates the raycast parameters (filter, distance, etc.)
function RaycastModule.SetRaycastParams(NewParams : RaycastParams)
	if typeof(NewParams) ~= "RaycastParams" then
		warn("RaycastModule: SetRaycastParams() expects a RaycastParams object")
	end

	ModuleRayParams = NewParams
end

--Gets the current raycast parameters
function RaycastModule.GetRaycastParams()
	return ModuleRayParams
end

--Adds instance(s) to the raycast filter (Blacklist by default)
function RaycastModule.AddToFilter(Objects : {Instance} | Instance)
	if type(Objects) == "table" then
		for _, Object in Objects do
			if typeof(Object) ~= "Instance" then 
				warn(`{Object} in {Objects} must be an Instance!`)
				continue 
			end
			
			table.insert(RaycastFilter, Object)
		end
	else
		if typeof(Objects) ~= "Instance" then
			warn(`Passed in values must be a table or an instance! Got: {Objects}`)
			return
		end
		
		table.insert(RaycastFilter, Objects)
	end
	
	ModuleRayParams.FilterDescendantsInstances = RaycastFilter
end

--Removes instance(s) from the raycast filter
function RaycastModule.RemoveFromFilter(Instances : {Instance} | Instance)
	--Make a dict of instances to remove, and search for them in the filter
	if type(Instances) == "table" then
		local InstancesToRemove = table.create(#Instances, nil)

		--create the dictionary/hashmap
		for _, InstanceObject in Instances do
			InstancesToRemove[InstanceObject] = 0
		end

		--Search through and check if they are on the list to be removed
		for Index, InstanceObject in RaycastFilter do
			if not InstancesToRemove[InstanceObject] then continue end

			table.remove(RaycastFilter, Index)
		end
		
		ModuleRayParams.FilterDescendantsInstances = RaycastFilter
		return
	end

	--Find and remove the instance
	if typeof(Instances) == "Instance" then
		local Index = table.find(RaycastFilter, Instances)
		if not Index then return end

		table.remove(RaycastFilter, Index)
		ModuleRayParams.FilterDescendantsInstances = RaycastFilter
		return
	end

	warn(`Passed in values must be a table or an instance! Got: {Instances}`)
end

--Clears the raycast filter
function RaycastModule.ClearFilter()
	ModuleRayParams.FilterDescendantsInstances = {}
end

return RaycastModule