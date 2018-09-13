local Reader = import("./reader")

describe("Reader", function()
	it("should create a new Reader when using Reader.new", function()
		assert.are_not.same(nil, Reader.new({}))
	end)

	describe("Primitives", function()
		it("should read one byte", function()
			local reader = Reader.new({ 0xFF })
			assert.are.same(0xFF, reader:ReadByte())
		end)

		it("should read one byte multiple times", function()
			local reader = Reader.new({ 0xAB, 0xCD })
			assert.are.same(0xAB, reader:ReadByte())
			assert.are.same(0xCD, reader:ReadByte())
		end)

		it("should read n bytes as little endian", function()
			local reader = Reader.new({ 0xAB, 0xCD })
			assert.are.same(0xCDAB, reader:ReadBytes(2))
		end)

		it("should read uint32", function()
			local reader = Reader.new({ 0xAB, 0xCD, 0xDE, 0xFF })
			assert.are.same(0xFFDECDAB, reader:ReadUInt32())
		end)

		describe("LEB128", function()
			-- Numbers are from https://en.wikipedia.org/wiki/LEB128
			it("should read varuint32", function()
				local reader = Reader.new({ 0xE5, 0x8E, 0x26, 0x80 })
				assert.are.same(624485, reader:ReadVarUInt(32))
			end)

			it("should read varint32", function()
				local reader = Reader.new({ 0x9B, 0xF1, 0x59, 0x80 })
				assert.are.same(-624485, reader:ReadVarInt(32))
			end)
		end)
	end)
end)
