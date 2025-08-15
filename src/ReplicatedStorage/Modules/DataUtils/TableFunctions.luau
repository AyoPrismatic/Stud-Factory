local TableFunctions = {}

--[[Table function logic]]

local function IsTable(T : {}?, C : boolean?) : boolean
	if C == nil then C = true end

	if type(T) ~= "table" and C then
		warn(T, "Isn't a table!")
	end

	return type(T) == "table"
end

local function RecursiveFreeze(T : {}) : nil
	if not table.isfrozen(T) then
		table.freeze(T)
	end
	
	for K, V in T do
		if type(K) == "table" then RecursiveFreeze(K) end
		if type(V) == "table" then RecursiveFreeze(V) end
	end
end

local function RecursiveKVFlip(T : {}) : {}
	local RT = {} -- Returned Table

	for K, V in T do
		if type(K) == "table" then K = RecursiveKVFlip(K) end
		if type(V) == "table" then V = RecursiveKVFlip(V) end

		RT[V] = K
	end

	return RT
end

local function RecursiveClone<T>(T : {T}, F : boolean) : {T}
	local C = {}
	
	for K, V in T do
		if type(K) == "table" then K = RecursiveClone(K, F) end
		if type(V) == "table" then V = RecursiveClone(V, F) end
		
		C[K] = V
	end
	
	if not table.isfrozen(C) and F == true then
		return table.freeze(C)
	end

	return C
end

local function TableCompare(T1 : {}, T2 : {}, S : {}) : boolean
	if not IsTable(T1, false) then return type(T1) == type(T2) end
	if not IsTable(T2, false) then return type(T1) == type(T2) end
	if T1 == T2 then return true end

	S = S or {}
	if S[T1] and S[T1][T2] then return true end
	S[T1] = S[T1] or {}
	S[T1][T2] = true

	-- Check that all keys in T1 exist in T2
	for K in T1 do
		if T2[K] == nil then
			return false
		end
	end

	-- Check that all keys in T2 exist in T1
	for K in T2 do
		if T1[K] == nil then
			return false
		end
	end

	-- Deep compare values
	for K, V1 in T1 do
		local V2 = T2[K]
		if not TableCompare(V1, V2, S) then
			return false
		end
	end

	return true
end

--[[Globally Accessed Functions]]

--[[
Swaps two given indexes in a table if they exist.
E.g: T[I1], T[I2] = T[I2], T[I1]
]]
function TableFunctions.SwitchKVs(T : {}, K1:(string?)|(number?)|({}?), K2:(string?)|(number?)|({}?)) : nil
	if not IsTable(T) then return end
	
	if not T[K1] then
		warn(K1, "Is not a valid key of", T)
		return
	end
	
	if not T[K2] then
		warn(K2, "Is not a valid key of", T)
		return
	end
	
	T[K1], T[K2] = T[K2], T[K1]
end

--[[
Inverts an array in O(n) time and space complexity.
E.G: {"HI", "I", "AM", 15} -> {15, "AM", "I", "HI"}
]]
function TableFunctions.InvertArray<T>(T : {T}) : {T}|nil
	if not IsTable(T) then return end
	
	local TS = #T -- Table Size
	local IT = table.create(TS, false) -- Inverted table
	
	for i = TS, 1, -1 do
		if type(T) ~= "number" then
			warn("Passed In Table isn't an array:", T)
			return T
		end
		
		IT[i] = T[TS - i + 1]
	end
	
	return IT
end

--[[
Swaps a KV pair in a table if it exists.
E.G: {X = 15} -> {15 = X}
]]
function TableFunctions.SwapKV(T : {}, K:(string?)|(number?)|({}?)) : nil
	if not IsTable(T) then return end
	
	if not T[K] then
		warn(K, "Is not a valid key of", T)
		return
	end
	
	local V = T[K]
	
	T[K], T[V] = nil, K
end

--[[
Swaps all KV pairs in a table if it exists.
E.G: {X = 15} -> {15 = X}
]]
function TableFunctions.SwapAllPairs(T: {}) : {}|nil
	if not IsTable(T) then return end
	
	return RecursiveKVFlip(T)
end

--[[
Returns true if the Tables are of the same memory
address, if their both empty, or if all the Shallow
Keys are the same, and if all the deep KV's are the
same. This is performed in O(n) best case, O(n + r(nested tables)) worst.
]]
function TableFunctions.CheckPairsEquality(T1 : {}, T2 : {}) : boolean
	if not IsTable(T1) then return false end
	if not IsTable(T2) then return false end
	
	return TableCompare(T1, T2, {})
end

--[[
Recursively Freezes any table within a table
(DeepFreeze Function is inclusive of the passed in table)
]]
function TableFunctions.DeepFreeze(T : {}) : nil
	if not IsTable(T) then return end
	
	RecursiveFreeze(T)
end

--[[
Recursively clones any table passed in.
The "ReadOnly" variable freezes any table.
It is optional and also recursive.
(Clone Function is inclusive of the passed in table)
]]
function TableFunctions.Clone<T>(T : {T}, ReadOnly : boolean?) : {T}|nil
	if not IsTable(T) then return end
	
	return RecursiveClone(T, ReadOnly or false)
end

return TableFunctions
