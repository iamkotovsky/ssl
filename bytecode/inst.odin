package bytecode

Inst_Idx :: distinct u32

Operand_Kind :: enum u8 {
	None,
	I64,
	U32,
	F64,
}

Operand :: struct #raw_union {
	as_i64: i64,
	as_u32: u32,
	as_f64: f64,
}

Opcode :: enum u8 {
	None,
	Load_Global,
	Load_Param,
	Load_Local,
	Load_Capture,
	Store_Global,
	Store_Local,
	Store_Capture,
	Make_Int,
	Make_Float,
	Make_String,
	Make_Class,
	Make_Func,
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
_OPCODE_OPERANDS := [Opcode]Operand_Kind {
	.None          = .None,
	.Load_Global   = .U32,
	.Load_Param    = .U32,
	.Load_Local    = .U32,
	.Load_Capture  = .U32,
	.Store_Global  = .U32,
	.Store_Local   = .U32,
	.Store_Capture = .U32,
	.Make_Int      = .I64,
	.Make_Float    = .F64,
	.Make_String   = .U32,
	.Make_Class    = .U32,
	.Make_Func     = .U32,
	.Make_List     = .U32,
	.Call          = .U32,
	.Return        = .None,
	.Jump          = .U32,
	.Get_Field     = .U32,
	.Set_Field     = .U32,
	.Add           = .None,
	.Sub           = .None,
	.Mul           = .None,
	.Div           = .None,
	.Halt          = .None,
}

Inst :: struct {
	opcode:  Opcode,
	operand: Operand,
}

opcode_operand_kind :: proc(opcode: Opcode) -> Operand_Kind {
	return _OPCODE_OPERANDS[opcode]
}

make_inst :: proc {
	_make_inst_none,
	_make_inst_i64,
	_make_inst_u32,
	_make_inst_f64,
}

@(private)
_make_inst_none :: proc(opcode: Opcode) -> Inst {
	return _make_inst(opcode, .None)
}

@(private)
_make_inst_i64 :: proc(opcode: Opcode, value: i64) -> Inst {
	return _make_inst(opcode, .I64, {as_i64 = value})
}

@(private)
_make_inst_u32 :: proc(opcode: Opcode, value: u32) -> Inst {
	return _make_inst(opcode, .U32, {as_u32 = value})
}

@(private)
_make_inst_f64 :: proc(opcode: Opcode, value: f64) -> Inst {
	return _make_inst(opcode, .F64, {as_f64 = value})
}

@(private)
_make_inst :: proc(opcode: Opcode, kind: Operand_Kind, operand: Operand = {}) -> Inst {
	assert(opcode_operand_kind(opcode) == kind, "bytecode opcode and operand kind mismatch")
	return {opcode, operand}
}
