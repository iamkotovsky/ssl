package bytecode

Operand_Kind :: enum {
	None,
	I8,
	I16,
	I32,
	I64,
	F32,
	F64,
	Constant,
	Target,
}

Constant_Index :: distinct u32
Instruction_Index :: distinct u32

Operand :: struct {
	kind: Operand_Kind,
	using _: struct #raw_union {
		as_i8:       i8,
		as_i16:      i16,
		as_i32:      i32,
		as_i64:      i64,
		as_f32:      f32,
		as_f64:      f64,
		as_constant: Constant_Index,
		as_target:   Instruction_Index,
	},
}

@(private)
_make_none_operand :: proc() -> Operand {
	return {kind = .None}
}

@(private)
_make_i64_operand :: proc(value: i64) -> Operand {
	return {kind = .I64, as_i64 = value}
}

@(private)
_make_i32_operand :: proc(value: i32) -> Operand {
	return {kind = .I32, as_i32 = value}
}

@(private)
_make_i8_operand :: proc(value: i8) -> Operand {
	return {kind = .I8, as_i8 = value}
}

@(private)
_make_i16_operand :: proc(value: i16) -> Operand {
	return {kind = .I16, as_i16 = value}
}

@(private)
_make_f64_operand :: proc(value: f64) -> Operand {
	return {kind = .F64, as_f64 = value}
}

@(private)
_make_f32_operand :: proc(value: f32) -> Operand {
	return {kind = .F32, as_f32 = value}
}

@(private)
_make_constant_operand :: proc(value: Constant_Index) -> Operand {
	return {kind = .Constant, as_constant = value}
}

@(private)
_make_target_operand :: proc(value: Instruction_Index) -> Operand {
	return {kind = .Target, as_target = value}
}
