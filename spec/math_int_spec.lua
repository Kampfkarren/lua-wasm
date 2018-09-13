--[[
	int add(int x) {
		return x + 1;
	}
--]]
local wasm = import("../lib")
local code = {0,97,115,109,1,0,0,0,1,134,128,128,128,0,1,96,1,127,1,127,3,130,128,128,128,0,1,0,4,132,128,128,128,0,1,112,0,0,5,131,128,128,128,0,1,0,1,6,129,128,128,128,0,0,7,144,128,128,128,0,2,6,109,101,109,111,114,121,2,0,3,97,100,100,0,0,10,141,128,128,128,0,1,135,128,128,128,0,0,32,0,65,1,106,11}

describe("math", function()
	it("should return 42 when calling add(41)", function()
		local module = wasm.module(code)
		local instance = wasm.instance(module, {})
		assert.are.same(instance.exports.add(41), 42)
	end)

	-- TODO: subtracting relies on i32.const actually returning signed ints properly
end)
