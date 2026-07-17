package builder

import bytecode ".."

@(private)
Inst_Id :: distinct u32

@(private)
Operand :: union {
	i64,
	f64,
	u32,
	Utf8,
	Func,
	Global,
	Param,
	Local,
	Label,
}

@(private)
Inst :: struct {
	opcode:  bytecode.Opcode,
	operand: Operand,
}

load :: proc {
	_load_global,
	_load_param,
	_load_local,
}

store :: proc {
	_store_global,
	_store_local,
}

jump :: proc(func: Func, target: Label) {
	proto := _assert_func(func)
	_assert_label(target)
	assert(
		target.func.module == func.module,
		"bytecode builder label belongs to another module",
	)
	assert(
		target.func.id == func.id,
		"bytecode builder label belongs to another function",
	)
	_emit(proto, .Jump, target)
}

make_int :: proc(func: Func, value: i64) {
	_emit(_assert_func(func), .Make_Int, value)
}

make_float :: proc(func: Func, value: f64) {
	_emit(_assert_func(func), .Make_Float, value)
}

make_string :: proc(func: Func, value: Utf8) {
	proto := _assert_func(func)
	_assert_utf8(value)
	assert(
		value.module == func.module,
		"bytecode builder constant belongs to another module",
	)
	_emit(proto, .Make_String, value)
}

make_func :: proc(func: Func, value: Func) {
	proto := _assert_func(func)
	_assert_func(value)
	assert(
		value.module == func.module,
		"bytecode builder function belongs to another module",
	)
	_emit(proto, .Make_Func, value)
}

@(private)
_load_global :: proc(func: Func, global: Global) {
	proto := _assert_func(func)
	_assert_global(global)
	assert(
		global.module == func.module,
		"bytecode builder global belongs to another module",
	)
	_emit(proto, .Load_Global, global)
}

@(private)
_load_param :: proc(func: Func, param: Param) {
	proto := _assert_func(func)
	_assert_param(param)
	assert(
		param.func.module == func.module,
		"bytecode builder parameter belongs to another module",
	)
	assert(
		param.func.id == func.id,
		"bytecode builder parameter belongs to another function",
	)
	_emit(proto, .Load_Param, param)
}

@(private)
_load_local :: proc(func: Func, local: Local) {
	proto := _assert_func(func)
	_assert_local(local)
	assert(
		local.func.module == func.module,
		"bytecode builder local belongs to another module",
	)
	assert(
		local.func.id == func.id,
		"bytecode builder local belongs to another function",
	)
	_emit(proto, .Load_Local, local)
}

@(private)
_store_global :: proc(func: Func, global: Global) {
	proto := _assert_func(func)
	_assert_global(global)
	assert(
		global.module == func.module,
		"bytecode builder global belongs to another module",
	)
	_emit(proto, .Store_Global, global)
}

@(private)
_store_local :: proc(func: Func, local: Local) {
	proto := _assert_func(func)
	_assert_local(local)
	assert(
		local.func.module == func.module,
		"bytecode builder local belongs to another module",
	)
	assert(
		local.func.id == func.id,
		"bytecode builder local belongs to another function",
	)
	_emit(proto, .Store_Local, local)
}

@(private)
_emit :: proc(
	proto: ^Func_Proto,
	opcode: bytecode.Opcode,
	operand: Operand = nil,
) {
	assert(len(proto.insts) < int(max(u32)), "bytecode builder instruction ID overflow")
	append(&proto.insts, Inst{opcode, operand})
}
