local UnsignedIntegerByteSizes = table.freeze({
	[tonumber(2^8) - 1] = 1,
	[tonumber(2^16) - 1] = 2,
	[tonumber(2^24) - 1] = 3,
	[tonumber(2^32) - 1] = 4,
	[tonumber(2^64) - 1] = 5,
})

local Compresser = {}
Compresser.Pack = {}
Compresser.Unpack = {}

--[[Block Data Sent to the Client]]

function Compresser.Pack.ClientBlockData(X : number, Y : number, Z : number, BlockID : number, Rotation : number) : buffer
	local Packed = bit32.bor(
		bit32.lshift(bit32.band(X, 0xF), 23),
		bit32.lshift(bit32.band(Z, 0xF), 19),
		bit32.lshift(bit32.band(Y, 0xFF), 11),
		bit32.lshift(bit32.band(BlockID, 0xFF), 3)
	)

	-- Only include rotation if provided
	if Rotation then
		Packed = bit32.bor(Packed, bit32.band(Rotation, 0x7))
	end

	return Compresser.Pack.Integer(Packed)
end

function Compresser.Unpack.ClientBlockData(BlockDataBuffer : buffer) : (number, number, number, number, number | nil)
	local Packed = Compresser.Unpack.Buffer(BlockDataBuffer)
	
	local X = bit32.band(bit32.rshift(Packed, 23), 0xF)
	local Z = bit32.band(bit32.rshift(Packed, 19), 0xF)
	local Y = bit32.band(bit32.rshift(Packed, 11), 0xFF)
	local BlockID = bit32.band(bit32.rshift(Packed, 3), 0xFF)

	local RemainingBits = bit32.band(Packed, 0x7)
	local Rotation = RemainingBits ~= 0 and RemainingBits or 0

	return X, Y, Z, BlockID, Rotation
end

--[[Block Data Stored on Server Chunk data]]

function Compresser.Pack.NBTData(NBTData : {})
	for Key, Value in NBTData do
		if type(Value) == "number" then
			NBTData[Key] = Compresser.Pack.Integer(Value)
		end
	end
end

function Compresser.Unpack.NBTData(NBTData : {})
	for Key, Value in NBTData do
		if typeof(Value) == "buffer" then
			NBTData[Key] = Compresser.Unpack.Buffer(Value)
		end
	end
end

--[[Block Face Visibility]]

function Compresser.Pack.BlockVisibilityData(FrontFace : boolean, BackFace : boolean, LeftFace : boolean, RightFace : boolean, TopFace : boolean, BottomFace : boolean) : buffer
	local Packed = 0
	Packed = bit32.bor(Packed, bit32.lshift(FrontFace and 1 or 0, 0))   -- bit 0
	Packed = bit32.bor(Packed, bit32.lshift(BackFace 	and 1 or 0, 1))   -- bit 1
	Packed = bit32.bor(Packed, bit32.lshift(LeftFace 	and 1 or 0, 2))   -- bit 2
	Packed = bit32.bor(Packed, bit32.lshift(RightFace and 1 or 0, 3))   -- bit 3
	Packed = bit32.bor(Packed, bit32.lshift(TopFace 	and 1 or 0, 4))   -- bit 4
	Packed = bit32.bor(Packed, bit32.lshift(BottomFace and 1 or 0, 5))  -- bit 5
	
	local Buffer = buffer.create(1)
	buffer.writeu8(Buffer, 0, Packed)
	
	return Buffer
end

function Compresser.Unpack.BlockVisibilityData(BlockDataBuffer : buffer) : (boolean, boolean, boolean, boolean, boolean, boolean)
	local Packed = buffer.readbits(BlockDataBuffer, 0, 6)

	local Front = bit32.band(Packed, bit32.lshift(1, 0)) ~= 0
	local Back = bit32.band(Packed, bit32.lshift(1, 1)) ~= 0
	local Left = bit32.band(Packed, bit32.lshift(1, 2)) ~= 0
	local Right = bit32.band(Packed, bit32.lshift(1, 3)) ~= 0
	local Top = bit32.band(Packed, bit32.lshift(1, 4)) ~= 0
	local Bottom = bit32.band(Packed, bit32.lshift(1, 5)) ~= 0
	return Front, Back, Left, Right, Top, Bottom
end

--[[General Use]]

local function PackPositiveInteger(Integer : number) : buffer
	local ByteSize = 1

	for MaxNumber, ByteCount in UnsignedIntegerByteSizes do
		if Integer <= MaxNumber then
			ByteSize = ByteCount
			break
		end
	end

	local Buffer = buffer.create(ByteSize)
	buffer.writebits(Buffer, 0, ByteSize * 8, Integer)

	return Buffer
end

--Compresses an integer to the most compact byte form. (Turns any float to int)
function Compresser.Pack.Integer(Integer : number) : buffer
	Integer = math.round(Integer)

	if type(Integer) ~= "number" then
		warn("Given Value wasn't a number!")
		return
	end

	if Integer > 0 then
		return PackPositiveInteger(Integer)
	end
end

function Compresser.Unpack.Buffer(Buffer : buffer) : number
	local BufferBitSize = buffer.len(Buffer) * 8

	return buffer.readbits(Buffer, 0, BufferBitSize)
end

return Compresser