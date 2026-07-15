package builder

Func_Id :: distinct u32
Label_Id :: distinct u32
Param_Id :: distinct u32
Local_Id :: distinct u32

Param_Proto :: struct {
	name: string,
}

Param :: struct {
	func: Func,
	id:   Param_Id,
}

Local_Proto :: struct {
	idx:  u32,
	name: string,
}

Local :: struct {
	func: Func,
	id:   Local_Id,
}

Label_Proto :: struct {
	name: string,
}

Label :: struct {
	func: Func,
	id:   Label_Id,
}

Label_Bind :: struct {
	label: Label,
	inst:  Inst_Id,
}

Func_Proto :: struct {
	name:   string,
	params: [dynamic]Param_Proto,
	locals: [dynamic]Local_Proto,
	insts:  [dynamic]Inst,
	labels: [dynamic]Label_Proto,
	binds:  [dynamic]Label_Bind,
}

function :: proc(
	module: ^Module,
	name: string = "",
) -> Func {
	assert(module != nil)
	return _append_func(module, name)
}

param :: proc(func: Func, name: string = "") -> Param {
	proto := _assert_func(func)
	assert(len(proto.params) < int(max(u32)), "bytecode builder parameter ID overflow")
	id := Param_Id(len(proto.params))
	append(&proto.params, Param_Proto{name = _clone_name(name)})
	return {func, id}
}

local :: proc(func: Func, name: string = "") -> Local {
	proto := _assert_func(func)
	assert(len(proto.locals) < int(max(u32)), "bytecode builder local ID overflow")
	id := Local_Id(len(proto.locals))
	append(&proto.locals, Local_Proto{idx = u32(id), name = _clone_name(name)})
	return {func, id}
}

label :: proc(func: Func, name: string = "") -> Label {
	proto := _assert_func(func)
	assert(len(proto.labels) < int(max(u32)), "bytecode builder label ID overflow")
	id := Label_Id(len(proto.labels))
	append(&proto.labels, Label_Proto{name = _clone_name(name)})
	return {func, id}
}

bind :: proc(func: Func, value: Label) {
	proto := _assert_func(func)
	_assert_label(value)
	assert(len(proto.insts) <= int(max(u32)), "bytecode builder instruction ID overflow")
	append(&proto.binds, Label_Bind{value, Inst_Id(len(proto.insts))})
}

@(private)
_append_func :: proc(
	module: ^Module,
	name: string = "",
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
_assert_param :: proc(value: Param) -> ^Param_Proto {
	proto := _assert_func(value.func)
	assert(int(value.id) < len(proto.params), "bytecode builder parameter ID out of bounds")
	return &proto.params[int(value.id)]
}

@(private)
_assert_label :: proc(value: Label) -> ^Label_Proto {
	proto := _assert_func(value.func)
	assert(int(value.id) < len(proto.labels), "bytecode builder label ID out of bounds")
	return &proto.labels[int(value.id)]
}

@(private)
_assert_local :: proc(value: Local) -> ^Local_Proto {
	proto := _assert_func(value.func)
	assert(int(value.id) < len(proto.locals), "bytecode builder local ID out of bounds")
	return &proto.locals[int(value.id)]
}

@(private)
_destroy_func :: proc(func: ^Func_Proto) {
	delete(func.name)
	for value in func.params {
		delete(value.name)
	}
	for value in func.locals {
		delete(value.name)
	}
	for label in func.labels {
		delete(label.name)
	}
	delete(func.insts)
	delete(func.params)
	delete(func.locals)
	delete(func.labels)
	delete(func.binds)
	func^ = {}
}
