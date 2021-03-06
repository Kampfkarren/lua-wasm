--[[
	int main() { 
		return 42;
	}
--]]
local wasm = import("../lib")
local code = {0,97,115,109,1,0,0,0,1,133,128,128,128,0,1,96,0,1,127,3,130,128,128,128,0,1,0,4,132,128,128,128,0,1,112,0,0,5,131,128,128,128,0,1,0,1,6,129,128,128,128,0,0,7,145,128,128,128,0,2,6,109,101,109,111,114,121,2,0,4,109,97,105,110,0,0,10,138,128,128,128,0,1,132,128,128,128,0,0,65,42,11}

describe("basic main", function()
	it("should return 42", function()
		local module = wasm.module(code)
		local instance = wasm.instance(module, {})
		assert.are.same(instance.exports.main(), 42)
	end)
end)
