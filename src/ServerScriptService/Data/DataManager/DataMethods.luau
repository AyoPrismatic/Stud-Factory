--These are functions to sanitize data

local UnsaveableTypes = table.freeze({
	"nil",
	"Axes",
	"BrickColor",
	"CFrame",
	"CatalogSearchParams",
	"Color3",
	"ColorSequence",
	"ColorSequenceKeypoint",
	"DateTime",
	"DockWidgetPluginGuiInfo",
	"EnumItem",
	"Faces",
	"FloatCurveKey",
	"Font",
	"Instance",
	"NumberRange",
	"NumberSequence",
	"NumberSequenceKeypoint",
	"PathWaypoint",
	"PhysicalProperties",
	"Random",
	"Ray",
	"RaycastParams",
	"Rect",
	"Region3",
	"Region3int16",
	"TweenInfo",
	"UDim",
	"UDim2",
	"Vector2",
	"Vector2int16",
	"Vector3",
	"Vector3int16",
	"function"
})

local Data = {}

function Data.TypeCheck(Var)
	for _, Type in UnsaveableTypes do
		if typeof(Var) == Type then
			return false
		else
			continue
		end
	end
	
	return true
end

function Data.UTF8_CleanString(str)
	local result = {}
	local i = 1

	while i <= #str do
		local c = string.byte(str, i)

		if c >= 0x00 and c <= 0x7F then
			table.insert(result, string.char(c))
			i = i + 1
		elseif c >= 0xC2 and c <= 0xDF then
			local b2 = string.byte(str, i + 1)
			if b2 and b2 >= 0x80 and b2 <= 0xBF then
				table.insert(result, str:sub(i, i + 1))
				i = i + 2
			else
				i = i + 1
			end
		elseif c == 0xE0 then
			local b2 = string.byte(str, i + 1)
			local b3 = string.byte(str, i + 2)
			if b2 and b3 and b2 >= 0xA0 and b2 <= 0xBF and b3 >= 0x80 and b3 <= 0xBF then
				table.insert(result, str:sub(i, i + 2))
				i = i + 3
			else
				i = i + 1
			end
		elseif c >= 0xE1 and c <= 0xEC or c >= 0xEE and c <= 0xEF then
			local b2 = string.byte(str, i + 1)
			local b3 = string.byte(str, i + 2)
			if b2 and b3 and b2 >= 0x80 and b2 <= 0xBF and b3 >= 0x80 and b3 <= 0xBF then
				table.insert(result, str:sub(i, i + 2))
				i = i + 3
			else
				i = i + 1
			end
		elseif c == 0xED then
			local b2 = string.byte(str, i + 1)
			local b3 = string.byte(str, i + 2)
			if b2 and b3 and b2 >= 0x80 and b2 <= 0x9F and b3 >= 0x80 and b3 <= 0xBF then
				table.insert(result, str:sub(i, i + 2))
				i = i + 3
			else
				i = i + 1
			end
		elseif c == 0xF0 then
			local b2 = string.byte(str, i + 1)
			local b3 = string.byte(str, i + 2)
			local b4 = string.byte(str, i + 3)
			if b2 and b3 and b4 and b2 >= 0x90 and b2 <= 0xBF and b3 >= 0x80 and b3 <= 0xBF and b4 >= 0x80 and b4 <= 0xBF then
				table.insert(result, str:sub(i, i + 3))
				i = i + 4
			else
				i = i + 1
			end
		elseif c >= 0xF1 and c <= 0xF3 then
			local b2 = string.byte(str, i + 1)
			local b3 = string.byte(str, i + 2)
			local b4 = string.byte(str, i + 3)
			if b2 and b3 and b4 and b2 >= 0x80 and b2 <= 0xBF and b3 >= 0x80 and b3 <= 0xBF and b4 >= 0x80 and b4 <= 0xBF then
				table.insert(result, str:sub(i, i + 3))
				i = i + 4
			else
				i = i + 1
			end
		elseif c == 0xF4 then
			local b2 = string.byte(str, i + 1)
			local b3 = string.byte(str, i + 2)
			local b4 = string.byte(str, i + 3)
			if b2 and b3 and b4 and b2 >= 0x80 and b2 <= 0x8F and b3 >= 0x80 and b3 <= 0xBF and b4 >= 0x80 and b4 <= 0xBF then
				table.insert(result, str:sub(i, i + 3))
				i = i + 4
			else
				i = i + 1
			end
		else
			i = i + 1
		end
	end

	return table.concat(result)
end

return Data
