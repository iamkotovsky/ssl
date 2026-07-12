package operand

Kind :: enum {
	None,
	I64,
	I32,
	I8,
	F64,
	F32,
	Label,
	Const,
}

Operand :: struct {
	kind: Kind,
	using _: struct #raw_union {
		as_i64:   i64,
		as_i32:   i32,
		as_i8:    i8,
		as_f64:   f64,
		as_f32:   f32,
		as_label: int,
		as_const: int,
	},
}

make_none :: proc() -> Operand {
	return {kind = .None}
}

make_i64 :: proc(value: i64) -> Operand {
	return {kind = .I64, as_i64 = value}
}

make_i32 :: proc(value: i32) -> Operand {
	return {kind = .I32, as_i32 = value}
}

make_i8 :: proc(value: i8) -> Operand {
	return {kind = .I8, as_i8 = value}
}

make_f64 :: proc(value: f64) -> Operand {
	return {kind = .F64, as_f64 = value}
}

make_f32 :: proc(value: f32) -> Operand {
	return {kind = .F32, as_f32 = value}
}

make_label :: proc(value: int) -> Operand {
	return {kind = .Label, as_label = value}
}

make_const :: proc(value: int) -> Operand {
	return {kind = .Const, as_const = value}
}
