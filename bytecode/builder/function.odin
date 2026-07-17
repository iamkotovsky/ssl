package builder

@(private)
Func_Id :: distinct u32

@(private)
Param_Id :: distinct u32

@(private)
Local_Id :: distinct u32

@(private)
Label_Id :: distinct u32

// A stable function handle. It remains valid if module.funcs reallocates.
Func :: struct {
	module: ^Module,
	id:     Func_Id,
}

Param :: struct {
	func: Func,
	id:   Param_Id,
}

@(private)
Local_Proto :: struct {
	idx:  u32,
	name: Maybe(string),
}

Local :: struct {
	func: Func,
	id:   Local_Id,
}

Label :: struct {
	func: Func,
	id:   Label_Id,
}

@(private)
Label_Bind :: struct {
	label: Label,
	inst:  Inst_Id,
}

@(private)
Func_Proto :: struct {
	name:   Maybe(string),
	params: [dynamic]Maybe(string),
	locals: [dynamic]Local_Proto,
	insts:  [dynamic]Inst,
	labels: [dynamic]Maybe(string),
	binds:  [dynamic]Label_Bind,
}

function :: proc(
	module: ^Module,
	name: Maybe(string) = nil,
) -> Func {
	assert(module != nil)
	return _append_func(module, name)
}

param :: proc(func: Func, name: Maybe(string) = nil) -> Param {
	proto := _assert_func(func)
	assert(len(proto.params) < int(max(u32)), "bytecode builder parameter ID overflow")
	id := Param_Id(len(proto.params))
	append(&proto.params, _clone_name(name))
	return {func, id}
}

local :: proc(func: Func, name: Maybe(string) = nil) -> Local {
	proto := _assert_func(func)
	assert(len(proto.locals) < int(max(u32)), "bytecode builder local ID overflow")
	id := Local_Id(len(proto.locals))
	append(&proto.locals, Local_Proto{idx = u32(id), name = _clone_name(name)})
	return {func, id}
}

label :: proc(func: Func, name: Maybe(string) = nil) -> Label {
	proto := _assert_func(func)
	assert(len(proto.labels) < int(max(u32)), "bytecode builder label ID overflow")
	id := Label_Id(len(proto.labels))
	append(&proto.labels, _clone_name(name))
	return {func, id}
}

bind :: proc(func: Func, value: Label) {
	proto := _assert_func(func)
	_assert_label(value)
	assert(
		value.func.module == func.module,
		"bytecode builder label belongs to another module",
	)
	assert(
		value.func.id == func.id,
		"bytecode builder label belongs to another function",
	)
	for binding in proto.binds {
		assert(
			binding.label.id != value.id,
			"bytecode builder label is bound more than once",
		)
	}
	assert(len(proto.insts) < int(max(u32)), "bytecode builder instruction ID overflow")
	append(&proto.binds, Label_Bind{value, Inst_Id(len(proto.insts))})
}

@(private)
_append_func :: proc(
	module: ^Module,
	name: Maybe(string) = nil,
) -> Func {
	assert(len(module.funcs) < int(max(u32)), "bytecode builder function ID overflow")
	id := Func_Id(len(module.funcs))
	append(
		&module.funcs,
		Func_Proto{name = _clone_name(name)},
	)
	return {module, id}
}

@(private)
_assert_func :: proc(func: Func) -> ^Func_Proto {
	assert(func.module != nil, "bytecode builder function has no module")
	assert(int(func.id) < len(func.module.funcs), "bytecode builder function ID out of bounds")
	return &func.module.funcs[int(func.id)]
}

@(private)
_assert_param :: proc(value: Param) {
	proto := _assert_func(value.func)
	assert(int(value.id) < len(proto.params), "bytecode builder parameter ID out of bounds")
}

@(private)
_assert_local :: proc(value: Local) {
	proto := _assert_func(value.func)
	assert(int(value.id) < len(proto.locals), "bytecode builder local ID out of bounds")
}

@(private)
_assert_label :: proc(value: Label) {
	proto := _assert_func(value.func)
	assert(int(value.id) < len(proto.labels), "bytecode builder label ID out of bounds")
}

@(private)
_destroy_func :: proc(func: ^Func_Proto) {
	_destroy_name(func.name)
	for name in func.params {
		_destroy_name(name)
	}
	for value in func.locals {
		_destroy_name(value.name)
	}
	for name in func.labels {
		_destroy_name(name)
	}
	delete(func.insts)
	delete(func.params)
	delete(func.locals)
	delete(func.labels)
	delete(func.binds)
	func^ = {}
}
