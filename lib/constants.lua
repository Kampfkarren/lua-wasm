local Constants = {}

Constants.MODULE_MAGIC_NUMBER = 0x6D736100
Constants.SUPPORTED_VERSION = 0x1
Constants.VARUINT_PADDING = 0x80
Constants.VARINT_SIGN = 0x40
Constants.FUNCTION_BODY_END = 0x0B

Constants.ModuleSections = {}
Constants.ModuleSections.TYPE = 1
Constants.ModuleSections.FUNCTION = 3
Constants.ModuleSections.TABLE = 4
Constants.ModuleSections.MEMORY = 5
Constants.ModuleSections.GLOBAL = 6
Constants.ModuleSections.EXPORT = 7
Constants.ModuleSections.CODE = 10
Constants.ModuleSections.DATA = 11

Constants.ExternalKind = {}
Constants.ExternalKind.FUNCTION = 0
Constants.ExternalKind.MEMORY = 2

Constants.Opcodes = {}
Constants.Opcodes.End = 0x0B
Constants.Opcodes.GetLocal = 0x20
Constants.Opcodes.I32Load = 0x28
Constants.Opcodes.I32Const = 0x41

Constants.ConstantTypes = {}
Constants.ConstantTypes.I32 = 0x41

return Constants
