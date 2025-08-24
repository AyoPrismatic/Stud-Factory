local UnsignedIntegerByteSizes = table.freeze({
	[1] = tonumber(2^8) - 1,
	[2] = tonumber(2^16) - 1,
	[3] = tonumber(2^24) - 1,
	[4] = tonumber(2^32) - 1,
	[8] = tonumber(2^64) - 1,
})

local Compresser = {}
Compresser.Pack = {}
Compresser.Unpack = {}

--[[Block Data Sent to the Client]]

function Compresser.Pack.ClientBlockData(X : number, Y : number, Z : number, BlockID : number) : buffer
	assert(X >= 0 and X < 16, "X must fit in 4 bits (0-15)")
	assert(Y >= 0 and Y < 16, "Y must fit in 4 bits (0-15)")
	assert(Z >= 0 and Z < 16, "Z must fit in 4 bits (0-15)")
	assert(BlockID >= 0 and BlockID < 4096, "BlockID must fit in 12 bits (0-4095)")

	local Packed = bit32.bor(
		bit32.lshift(bit32.band(X, 0xF), 20),
		bit32.lshift(bit32.band(Z, 0xF), 16),
		bit32.lshift(bit32.band(Y, 0xF), 12),
		bit32.lshift(bit32.band(BlockID, 0xFFF), 0)
	)

	return Compresser.Pack.Integer(Packed)
end

function Compresser.Unpack.ClientBlockData(BlockDataBuffer : buffer) : (number, number, number, number)
	assert(buffer.len(BlockDataBuffer) > 3, "Buffer has too many bytes!")

	local Packed = Compresser.Unpack.Buffer(BlockDataBuffer)
	
	local X = bit32.band(bit32.rshift(Packed, 20), 0xF)
	local Z = bit32.band(bit32.rshift(Packed, 16), 0xF)
	local Y = bit32.band(bit32.rshift(Packed, 12), 0xF)
	local BlockID = bit32.band(bit32.rshift(Packed, 0), 0xFFF)

	return X, Y, Z, BlockID
end

--[[General Use]]

local function PackPositiveInteger(Integer : number) : buffer
	local ByteSize = 1

	for ByteCount = 1, 5 do 
		--Done in a for loop to iterate from the smallest int limit to the biggest (8 -> 64)
		if ByteCount == 5 then ByteCount = 8 end
		local MaxNumber = UnsignedIntegerByteSizes[ByteCount]

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

	if Integer >= 0 then
		return PackPositiveInteger(Integer)
	end
end

function Compresser.Unpack.Buffer(Buffer : buffer) : number
	local BufferBitSize = buffer.len(Buffer) * 8

	return buffer.readbits(Buffer, 0, BufferBitSize)
end

return Compresser