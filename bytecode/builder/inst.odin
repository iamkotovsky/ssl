package builder

import bytecode ".."

Inst_Id :: distinct u32

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
	_assert_label(target)
	_emit(func, .Jump, target)
}

@(private)
_load_global :: proc(func: Func, global: Global) {
	_assert_global(global)
	_emit(func, .Load_Global, global)
}

@(private)
_load_param :: proc(func: Func, param: Param) {
	_assert_param(param)
	_emit(func, .Load_Param, param)
}

@(private)
_load_local :: proc(func: Func, local: Local) {
	_assert_local(local)
	_emit(func, .Load_Local, local)
}

@(private)
_store_global :: proc(func: Func, global: Global) {
	_assert_global(global)
	_emit(func, .Store_Global, global)
}

@(private)
_store_local :: proc(func: Func, local: Local) {
	_assert_local(local)
	_emit(func, .Store_Local, local)
}

make_int :: proc(func: Func, value: i64) {
	_emit(func, .Make_Int, value)
}

make_float :: proc(func: Func, value: f64) {
	_emit(func, .Make_Float, value)
}

make_string :: proc(func: Func, value: Utf8) {
	_assert_func(func)
	_assert_utf8(value)
	_emit(func, .Make_String, value)
}

make_func :: proc(func: Func, value: Func) {
	_assert_func(value)
	_emit(func, .Make_Func, value)
}

@(private)
_emit :: proc(func: Func, opcode: bytecode.Opcode, operand: Operand = nil) {
	proto := _assert_func(func)
	assert(len(proto.insts) < int(max(u32)), "bytecode builder instruction ID overflow")
	append(&proto.insts, Inst{opcode, operand})
}

@(private)
_assert_func :: proc(func: Func) -> ^Func_Proto {
	assert(func.module != nil, "bytecode builder function has no module")
	assert(int(func.id) < len(func.module.funcs), "bytecode builder function ID out of bounds")
	return &func.module.funcs[int(func.id)]
}

@(private)
_assert_global :: proc(global: Global) {
	assert(global.module != nil, "bytecode builder global has no module")
	assert(int(global.id) < len(global.module.globals), "bytecode builder global ID out of bounds")
}

@(private)
_assert_utf8 :: proc(value: Utf8) {
	const := Const(value)
	assert(const.module != nil, "bytecode builder UTF-8 constant has no module")
	assert(int(const.id) < len(const.module.consts), "bytecode builder constant ID out of bounds")
	_, ok := const.module.consts[int(const.id)].(Utf8_Proto)
	assert(ok, "bytecode builder constant is not UTF-8")
}
