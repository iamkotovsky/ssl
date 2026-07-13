package bytecode

Opcode :: enum {
	None,
	Load,
	Load_Local,
	Store,
	Store_Local,
	Make_I8,
	Make_I16,
	Make_I32,
	Make_I64,
	Make_F32,
	Make_F64,
	Make_String,
	Make_Class,
	Make_Function,
	Make_List,
	Call,
	Return,
	Jump,
	Get_Field,
	Set_Field,
	Add,
	Sub,
	Mul,
	Div,
	Halt,
}

@(private)
@(rodata)
_OPCODE_NAMES := [Opcode]string {
	.None        = "none",
	.Load        = "load",
	.Load_Local  = "load.local",
	.Store       = "store",
	.Store_Local = "store.local",
	.Make_I8     = "make.i8",
	.Make_I16    = "make.i16",
	.Make_I32    = "make.i32",
	.Make_I64    = "make.i64",
	.Make_F32    = "make.f32",
	.Make_F64    = "make.f64",
	.Make_String = "make.string",
	.Make_Class  = "make.class",
	.Make_Function = "make.func",
	.Make_List   = "make.list",
	.Call        = "call",
	.Return      = "ret",
	.Jump        = "jump",
	.Get_Field   = "field.get",
	.Set_Field   = "field.set",
	.Add         = "add",
	.Sub         = "sub",
	.Mul         = "mul",
	.Div         = "div",
	.Halt        = "halt",
}

@(private)
@(rodata)
_OPCODE_OPERANDS := #partial [Opcode]Operand_Kind {
	.Load        = .I64,
	.Load_Local  = .I64,
	.Store       = .I64,
	.Store_Local = .I64,
	.Make_I8     = .I8,
	.Make_I16    = .I16,
	.Make_I32    = .I32,
	.Make_I64    = .I64,
	.Make_F32    = .F32,
	.Make_F64    = .F64,
	.Make_String = .Constant,
	.Make_Class  = .Constant,
	.Make_Function = .Target,
	.Make_List   = .I64,
	.Call        = .I64,
	.Jump        = .Target,
	.Get_Field   = .Constant,
	.Set_Field   = .Constant,
}

Instruction :: struct {
	opcode:  Opcode,
	operand: Operand,
}

opcode_name :: proc(opcode: Opcode) -> string {
	return _OPCODE_NAMES[opcode]
}

opcode_has_operand :: proc(opcode: Opcode) -> bool {
	return opcode_operand(opcode) != .None
}

opcode_operand :: proc(opcode: Opcode) -> Operand_Kind {
	return _OPCODE_OPERANDS[opcode]
}

@(private)
_make_instruction :: proc(opcode: Opcode = .None, operand: Operand = {}) -> Instruction {
	return {opcode, operand}
}
