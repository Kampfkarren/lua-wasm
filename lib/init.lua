local Constants = import("./constants")
local Reader = import("./reader")

local wasm = {}

local WASM_ERROR_FORMAT = "[%s] - %s"
function wasm.error(errorCode, message, ...)
	error(WASM_ERROR_FORMAT:format(errorCode, message:format(...)))
end
Reader.error = wasm.error

function wasm.module(binary)
	local module = {}
	module.codeSections = {}
	module.data = {}
	module.exports = {}
	module.exportsByName = {}
	module.functions = {}
	module.types = {}

	local reader = Reader.new(binary)

	local magic = reader:ReadUInt32()
	if magic ~= Constants.MODULE_MAGIC_NUMBER then
		wasm.error("BAD_MAGIC", "Bad magic number provided in module. Expected %x, got %x.", Constants.MODULE_MAGIC_NUMBER, magic)
	end

	local version = reader:ReadUInt32()
	if version ~= Constants.SUPPORTED_VERSION then
		wasm.error("SUPPORTED_VERSION", "wasm-lua only supports version 1 of the WASM binary format. Your module is version %d.", version)
	end

	while true do
		if reader:IsFinished() then
			return module
		end

		local section = {}

		section.id = reader:ReadVarUInt(7)
		local payloadLen = reader:ReadVarUInt(32)
		if section.id == 0 then
			local nameLen = reader:ReadVarUInt(32)
			section.name = reader:ReadBytes(nameLen)
			payloadLen = payloadLen - nameLen - 4
		end

		if section.id == Constants.ModuleSections.TYPE then
			for _=1,reader:ReadVarUInt(32) do
				module.types[#module.types + 1] = reader:ReadFuncType()
			end
		elseif section.id == Constants.ModuleSections.FUNCTION then
			local count = reader:ReadVarUInt(32)
			for _=1,count do
				module.functions[#module.functions + 1] = reader:ReadVarUInt(32)
			end
		elseif section.id == Constants.ModuleSections.TABLE then
			local count = reader:ReadVarUInt(32)
			local entries = {}
			for _=1,count do
				reader:ReadVarInt(7) -- into the void element_type goes (there is only one)
				reader:ReadResizableLimits() -- lua doesn't have memory restrictions like c does
			end
		elseif section.id == Constants.ModuleSections.MEMORY then
			for _=1,reader:ReadVarUInt(32) do
				reader:ReadResizableLimits()
			end
		elseif section.id == Constants.ModuleSections.GLOBAL then
			local globals = {}
			for _=1,reader:ReadVarUInt(32) do
				globals[#globals + 1] = reader:ReadGlobalType()
			end
		elseif section.id == Constants.ModuleSections.EXPORT then
			for _=1,reader:ReadVarUInt(32) do
				local export = {}
				export.fieldLen = reader:ReadVarUInt(32)
				export.fieldStr = reader:ReadUTF8(export.fieldLen)
				export.kind = reader:ReadExternalKind()
				export.index = reader:ReadVarUInt(32)
				module.exports[export.index] = export
				module.exportsByName[export.fieldStr] = export
			end
		elseif section.id == Constants.ModuleSections.CODE then
			for index=1,reader:ReadVarUInt(32) do
				local procBody = {}
				reader:ReadVarUInt(32)
				procBody.locals = {}
				for _=1,reader:ReadVarUInt(32) do
					local _local = {}
					_local.count = self:ReadVarUInt(32)
					_local.type = self:ReadValueType()
					procBody.locals[#procBody.locals + 1] = _local
				end
				procBody.code = Reader.new(reader:ReadCode())
				--procBody.code = Reader.new(procBody.code)
				module.codeSections[index - 1] = procBody
			end
		elseif section.id == Constants.ModuleSections.DATA then
			for index=1,reader:ReadVarUInt(32) do
				local data = {}
				reader:ReadVarUInt(32) -- index
				data.offset = reader:ReadInitExpr()
				data.data = reader:ReadBytes(reader:ReadVarUInt(32))
				module.data[#module.data + 1] = data
			end
		else
			wasm.error("INVALID_SECTION_ID", "Invalid section id: %d", section.id)
		end
	end

	return module
end

function wasm.instance(module, args)
	local instance = {}
	instance.exports = {}

	local memoryOffsets = {}

	for _,data in pairs(module.data) do
		memoryOffsets[data.offset] = data.data
	end

	for exportName,export in pairs(module.exportsByName) do
		if export.kind == Constants.ExternalKind.FUNCTION then
			local exportId = export.index
			-- make callable
			instance.exports[exportName] = function(...)
				local _type = module.types[module.functions[exportId + 1] + 1]
				local procBody = module.codeSections[exportId]
				local procBodyCode = procBody.code
				local stack = {}
				local locals = {}

				local args = {...}
				for index=1,#_type.parameters do
					locals[index - 1] = args[index]
				end

				while not procBodyCode:IsFinished() do
					local opcode = procBodyCode:ReadByte()
					if opcode == Constants.Opcodes.GetLocal then
						stack[#stack + 1] = locals[procBodyCode:ReadVarUInt(32)]
					elseif opcode == Constants.Opcodes.I32Load then
						local memoryImmediate = procBodyCode:ReadMemoryImmediate()
						stack[#stack + 1] = memoryOffsets[memoryImmediate.offset]
					elseif opcode == Constants.Opcodes.I32Const then
						local constant = procBodyCode:ReadVarUInt(32) --TODO: this is supposed to be varint, but it doesnt work unless its uint? at least with the 42 case
						stack[#stack + 1] = constant
					elseif opcode == Constants.Opcodes.I32Eq then
						local left, right = table.remove(stack), table.remove(stack)
						stack[#stack + 1] = (left == right) and 1 or 0
					elseif opcode == Constants.Opcodes.I32Add then
						local left, right = table.remove(stack), table.remove(stack)
						stack[#stack + 1] = left + right
					else
						wasm.error("UNKNOWN_OPCODE", "Unknown opcode %x", opcode)
					end
				end

				return table.remove(stack)
			end
		end
	end

	return instance
end

return wasm
