package bytecode

Operand_Kind :: enum {
	None,
	I64,
	I32,
	I8,
	F64,
	F32,
	Label,
	Constant,
}

Operand :: struct {
	kind: Operand_Kind,
	using _: struct #raw_union {
		as_i64:   i64,
		as_i32:   i32,
		as_i8:    i8,
		as_f64:   f64,
		as_f32:   f32,
		as_label: int,
		as_constant: int,
	},
}

make_none_operand :: proc() -> Operand {
	return {kind = .None}
}

make_i64_operand :: proc(value: i64) -> Operand {
	return {kind = .I64, as_i64 = value}
}

make_i32_operand :: proc(value: i32) -> Operand {
	return {kind = .I32, as_i32 = value}
}

make_i8_operand :: proc(value: i8) -> Operand {
	return {kind = .I8, as_i8 = value}
}

make_f64_operand :: proc(value: f64) -> Operand {
	return {kind = .F64, as_f64 = value}
}

make_f32_operand :: proc(value: f32) -> Operand {
	return {kind = .F32, as_f32 = value}
}

make_label_operand :: proc(value: int) -> Operand {
	return {kind = .Label, as_label = value}
}

make_constant_operand :: proc(value: int) -> Operand {
	return {kind = .Constant, as_constant = value}
}
