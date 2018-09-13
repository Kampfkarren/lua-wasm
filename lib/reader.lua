local bit32 = require("bit32")
local Constants = import("./constants")

local Reader = {}
Reader.__index = Reader

function Reader.new(binary)
	return setmetatable({
		binary = binary,
		cursor = 1
	}, Reader)
end

-- Primitive

function Reader:ReadByte()
	local byte = self.binary[self.cursor]
	assert(byte, "Attempted to read a byte at the end of the binary.")
	self.cursor = self.cursor + 1
	return byte
end

-- Converts { 0xAB, 0xCD, 0xDE } to 0xDECDAB
-- TODO: Make this use math instead of string stuff if that's faster
local READER_READ_BYTES_STRING_FORMAT = "%02x"
function Reader:ReadBytes(n)
	local result = ""

	for _=1,n do
		local byte = self:ReadByte()
		result = string.format(READER_READ_BYTES_STRING_FORMAT, byte) .. result
	end

	return tonumber(result, 16)
end

function Reader:ReadBytesArray(n)
	local result = {}

	for index=n,1,-1 do
		result[index] = self:ReadByte()
	end

	return result
end

function Reader:ReadUInt32()
	return self:ReadBytes(4)
end

-- TODO: the code for varuint and varint should be similar, but getting varints to work was a huge headache
-- and thus their code is separate. would be ideal to combine them.

function Reader:ReadVarUInt(n)
	local result, count, max = 0, 0, math.ceil(n / 7)
	local byte = Constants.VARUINT_PADDING

	while bit32.band(byte, Constants.VARUINT_PADDING) ~= 0 and count < max do
		byte = self:ReadByte()
		result = bit32.bor(result, (bit32.lshift(bit32.band(byte, 0x7F), count * 7)))
		count = count + 1
	end

	return result, byte, count
end

function Reader:ReadVarInt(n)
	local num, shift, byte = 0, 0, 0

	while shift < n do
		byte = self:ReadByte()
		num = bit32.bor(num, bit32.lshift(bit32.band(byte, 0x7F), shift))
		shift = shift + 7
		if bit32.rshift(byte, 7) == 0 then
			break
		end
	end

	if bit32.band(byte, 0x40) then
		num = bit32.bor(num, bit32.lshift(bit32.bnot(0), shift))

		if num > 2^31 then
			num = num - 2^32
		end
	end

	return num
end

-- Abstract
function Reader:ReadFuncType()
	local funcType = {}

	funcType.form = self:ReadVarInt(7)
	funcType.paramCount = self:ReadVarUInt(32)
	-- TODO: read value type
	funcType.returnCount = self:ReadVarUInt(1)
	funcType.returnType = self:ReadVarUInt(7)

	return funcType
end

function Reader:ReadTableType()
	local elementType = self:ReadElemType()
end

function Reader:ReadResizableLimits()
	local resizableLimits = {}

	resizableLimits.flags = self:ReadVarUInt(1)
	resizableLimits.initial = self:ReadVarUInt(32)

	if resizableLimits.flags == 1 then
		resizableLimits.maximum = self:ReadVarUInt(32)
	end

	return resizableLimits
end

function Reader:ReadGlobalType()
	local globalType = {}
	globalType.contentType = self:ReadVarUInt(7)
	globalType.mutability = self:ReadVarUInt(1)
	return globalType
end

function Reader:ReadUTF8(bytes)
	local text = ""
	local bytes = self:ReadBytesArray(bytes)

	for n=#bytes,1,-1 do
		text = text .. string.char(bytes[n])
	end

	return text
end

function Reader:ReadExternalKind()
	return self:ReadByte()
end

-- TODO: some stuff doesnt use this
function Reader:ReadValueType()
	return self:ReadVarUInt(7)
end

-- Util
function Reader:IsFinished()
	return self.cursor == #self.binary + 1
end

return Reader
