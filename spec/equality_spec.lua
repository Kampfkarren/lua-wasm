--[[
	int main(int x) {
		return x == 42;
	}
--]]
local wasm = import("../lib")
local code = {0,97,115,109,1,0,0,0,1,134,128,128,128,0,1,96,1,127,1,127,3,130,128,128,128,0,1,0,4,132,128,128,128,0,1,112,0,0,5,131,128,128,128,0,1,0,1,6,129,128,128,128,0,0,7,145,128,128,128,0,2,6,109,101,109,111,114,121,2,0,4,109,97,105,110,0,0,10,141,128,128,128,0,1,135,128,128,128,0,0,32,0,65,42,70,11}

describe("equality", function()
	it("should return 1 when given 42", function()
		local module = wasm.module(code)
		local instance = wasm.instance(module, {})
		assert.are.same(instance.exports.main(42), 1)
	end)

	it("should return 0 when given not 42", function()
		local module = wasm.module(code)
		local instance = wasm.instance(module, {})
		assert.are.same(instance.exports.main(100), 0)
	end)
end)
