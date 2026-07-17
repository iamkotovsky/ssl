package builder

import bytecode ".."
import "core:strings"

@(private)
Global_Id :: distinct u32

Global :: struct {
	module: ^Module,
	id:     Global_Id,
}

@(private)
Export :: struct {
	name:   string,
	global: Global_Id,
}

Module :: struct {
	init:     Func_Id,
	has_init: bool,
	consts:   [dynamic]Const_Proto,
	globals:  [dynamic]Maybe(string),
	funcs:    [dynamic]Func_Proto,
	exports:  [dynamic]Export,
}

global :: proc(module: ^Module, name: Maybe(string) = nil) -> Global {
	assert(module != nil)
	assert(len(module.globals) < int(max(u32)), "bytecode builder global ID overflow")
	id := Global_Id(len(module.globals))
	append(&module.globals, _clone_name(name))
	return {module, id}
}

export :: proc(module: ^Module, name: string) -> Global {
	assert(module != nil)
	assert(name != "", "bytecode builder export name must not be empty")
	_assert_const_capacity(module)
	for value in module.exports {
		assert(value.name != name, "bytecode builder has duplicate export names")
	}
	value := global(module, name)
	append(&module.exports, Export{name = strings.clone(name), global = value.id})
	return value
}

init :: proc(module: ^Module) -> Func {
	assert(module != nil)
	if module.has_init {
		return {module, module.init}
	}

	func := _append_func(module)
	module.init = func.id
	module.has_init = true
	return func
}

// Consumes the builder and returns an independently owned bytecode module.
finish :: proc(module: ^Module) -> bytecode.Module {
	assert(module != nil)
	assert(module.has_init, "bytecode builder has no initializer")

	consts := make([]bytecode.Const, len(module.consts) + len(module.exports))
	for value, idx in module.consts {
		consts[idx] = _finish_const(value)
	}

	exports := make([]bytecode.Export, len(module.exports))
	for value, idx in module.exports {
		name := bytecode.Const_Idx(len(module.consts) + idx)
		consts[int(name)] = bytecode.make_utf8(value.name)
		exports[idx] = {name, bytecode.Global_Idx(value.global)}
	}

	funcs := make([]bytecode.Func, len(module.funcs))
	debug_funcs := make([]bytecode.Func_Debug_Info, len(module.funcs))
	debug_count := 0
	for &proto, raw_idx in module.funcs {
		func := Func{module, Func_Id(raw_idx)}
		info: bytecode.Func_Debug_Info
		has_debug: bool
		funcs[raw_idx], info, has_debug = _finish_func(func, &proto)
		if has_debug {
			debug_funcs[debug_count] = info
			debug_count += 1
		}
	}
	if debug_count == 0 {
		delete(debug_funcs)
		debug_funcs = nil
	} else {
		debug_funcs = debug_funcs[:debug_count]
	}
	debug_globals := _finish_debug_globals(module)

	result := bytecode.make_module(
		bytecode.Func_Idx(module.init),
		u32(len(module.globals)),
		consts,
		funcs,
		exports,
		{globals = debug_globals, funcs = debug_funcs},
	)
	destroy(module)
	return result
}

destroy :: proc(module: ^Module) {
	assert(module != nil)
	for &const in module.consts {
		_destroy_const(&const)
	}
	for name in module.globals {
		_destroy_name(name)
	}
	for &func in module.funcs {
		_destroy_func(&func)
	}
	for item in module.exports {
		delete(item.name)
	}
	delete(module.consts)
	delete(module.globals)
	delete(module.funcs)
	delete(module.exports)
	module^ = {}
}

@(private)
_clone_name :: proc(name: Maybe(string)) -> Maybe(string) {
	if name == nil {
		return nil
	}
	return strings.clone(name.?)
}

@(private)
_destroy_name :: proc(name: Maybe(string)) {
	if name != nil {
		delete(name.?)
	}
}

@(private)
_assert_const_capacity :: proc(module: ^Module) {
	assert(module != nil)
	assert(
		u64(len(module.consts)) + u64(len(module.exports)) < u64(max(u32)),
		"bytecode builder constant ID overflow",
	)
}

@(private)
_assert_global :: proc(global: Global) {
	assert(global.module != nil, "bytecode builder global has no module")
	assert(int(global.id) < len(global.module.globals), "bytecode builder global ID out of bounds")
}

@(private)
_finish_const :: proc(value: Const_Proto) -> bytecode.Const {
	switch data in value {
	case Utf8_Proto:
		return bytecode.make_utf8(string(data))
	}
	unreachable()
}

@(private)
_finish_func :: proc(
	func: Func,
	proto: ^Func_Proto,
) -> (bytecode.Func, bytecode.Func_Debug_Info, bool) {
	arity := u32(len(proto.params))

	targets := _finish_label_targets(proto)
	defer delete(targets)
	insts := make([]bytecode.Inst, len(proto.insts))
	for inst, idx in proto.insts {
		insts[idx] = _finish_inst(targets, inst)
	}

	debug_params := _finish_debug_params(proto)
	debug_locals := _finish_debug_locals(proto)
	debug_labels := _finish_debug_labels(proto, targets)
	has_debug := proto.name != nil ||
		len(debug_params) != 0 ||
		len(debug_locals) != 0 ||
		len(debug_labels) != 0
	debug: bytecode.Func_Debug_Info
	if has_debug {
		debug = {
			func   = bytecode.Func_Idx(func.id),
			name   = _clone_name(proto.name),
			params = debug_params,
			locals = debug_locals,
			labels = debug_labels,
		}
	}

	return bytecode.make_func(arity, nil, insts), debug, has_debug
}

@(private)
_finish_debug_globals :: proc(module: ^Module) -> []bytecode.Debug_Name {
	count := 0
	for name in module.globals {
		if name != nil {
			count += 1
		}
	}
	if count == 0 {
		return nil
	}

	values := make([]bytecode.Debug_Name, count)
	idx := 0
	for name, raw_idx in module.globals {
		if name == nil {
			continue
		}
		values[idx] = {u32(raw_idx), strings.clone(name.?)}
		idx += 1
	}
	return values
}

@(private)
_finish_debug_params :: proc(proto: ^Func_Proto) -> []bytecode.Debug_Name {
	count := 0
	for name in proto.params {
		if name != nil {
			count += 1
		}
	}
	if count == 0 {
		return nil
	}

	values := make([]bytecode.Debug_Name, count)
	idx := 0
	for name, raw_idx in proto.params {
		if name == nil {
			continue
		}
		values[idx] = {u32(raw_idx), strings.clone(name.?)}
		idx += 1
	}
	return values
}

@(private)
_finish_debug_locals :: proc(proto: ^Func_Proto) -> []bytecode.Debug_Name {
	count := 0
	for value in proto.locals {
		if value.name != nil {
			count += 1
		}
	}
	if count == 0 {
		return nil
	}

	values := make([]bytecode.Debug_Name, count)
	idx := 0
	for value in proto.locals {
		if value.name == nil {
			continue
		}
		values[idx] = {value.idx, strings.clone(value.name.?)}
		idx += 1
	}
	return values
}

@(private)
_finish_label_targets :: proc(proto: ^Func_Proto) -> []bytecode.Inst_Idx {
	targets := make([]bytecode.Inst_Idx, len(proto.labels))
	bound := make([]bool, len(proto.labels))
	defer delete(bound)

	for binding in proto.binds {
		idx := int(binding.label.id)
		assert(int(binding.inst) < len(proto.insts), "bytecode builder label target is out of bounds")
		bound[idx] = true
		targets[idx] = bytecode.Inst_Idx(binding.inst)
	}
	for is_bound in bound {
		assert(is_bound, "bytecode builder label is not bound")
	}
	return targets
}

@(private)
_finish_debug_labels :: proc(
	proto: ^Func_Proto,
	targets: []bytecode.Inst_Idx,
) -> []bytecode.Debug_Label {
	count := 0
	for name in proto.labels {
		if name != nil {
			count += 1
		}
	}
	if count == 0 {
		return nil
	}

	labels := make([]bytecode.Debug_Label, count)
	idx := 0
	for name, label_idx in proto.labels {
		if name == nil {
			continue
		}
		labels[idx] = {strings.clone(name.?), targets[label_idx]}
		idx += 1
	}
	return labels
}

@(private)
_finish_inst :: proc(
	targets: []bytecode.Inst_Idx,
	inst: Inst,
) -> bytecode.Inst {
	switch bytecode.opcode_operand_kind(inst.opcode) {
	case .None:
		return bytecode.make_inst(inst.opcode)
	case .I64:
		value := inst.operand.(i64) or_else unreachable()
		return bytecode.make_inst(inst.opcode, value)
	case .F64:
		value := inst.operand.(f64) or_else unreachable()
		return bytecode.make_inst(inst.opcode, value)
	case .U32:
		value := _finish_u32_operand(targets, inst)
		return bytecode.make_inst(inst.opcode, value)
	}
	unreachable()
}

@(private)
_finish_u32_operand :: proc(
	targets: []bytecode.Inst_Idx,
	inst: Inst,
) -> u32 {
	#partial switch inst.opcode {
	case .Load_Global, .Store_Global:
		value := inst.operand.(Global) or_else unreachable()
		return u32(value.id)
	case .Load_Param:
		value := inst.operand.(Param) or_else unreachable()
		return u32(value.id)
	case .Load_Local, .Store_Local:
		value := inst.operand.(Local) or_else unreachable()
		proto := &value.func.module.funcs[int(value.func.id)]
		return proto.locals[int(value.id)].idx
	case .Make_String, .Make_Class, .Get_Field, .Set_Field:
		value := inst.operand.(Utf8) or_else unreachable()
		return u32(Const(value).id)
	case .Make_Func:
		value := inst.operand.(Func) or_else unreachable()
		return u32(value.id)
	case .Jump:
		value := inst.operand.(Label) or_else unreachable()
		return u32(targets[int(value.id)])
	case:
		value := inst.operand.(u32) or_else unreachable()
		return value
	}
	unreachable()
}
