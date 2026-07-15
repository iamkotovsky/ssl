package builder

import bytecode ".."
import "core:strings"

Global_Id :: distinct u32

Global_Proto :: struct {
	name: string,
}

Global :: struct {
	module: ^Module,
	id:     Global_Id,
}

Export :: struct {
	name:   string,
	global: Global_Id,
}

Module :: struct {
	init:     Func_Id,
	has_init: bool,
	consts:   [dynamic]Const_Proto,
	globals:  [dynamic]Global_Proto,
	funcs:    [dynamic]Func_Proto,
	exports:  [dynamic]Export,
}

// A stable function construction handle. It remains valid if module.funcs reallocates.
Func :: struct {
	module: ^Module,
	id:     Func_Id,
}

global :: proc(module: ^Module, name: string = "") -> Global {
	assert(module != nil)
	assert(len(module.globals) < int(max(u32)), "bytecode builder global ID overflow")
	id := Global_Id(len(module.globals))
	append(&module.globals, Global_Proto{name = _clone_name(name)})
	return {module, id}
}

export :: proc(module: ^Module, name: string) -> Global {
	assert(module != nil)
	assert(name != "", "bytecode builder export name must not be empty")
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
	assert(int(module.init) < len(module.funcs), "bytecode builder initializer is out of bounds")
	assert(len(module.globals) <= int(max(u32)), "bytecode builder global count overflow")
	assert(len(module.funcs) <= int(max(u32)), "bytecode builder function count overflow")
	assert(
		u64(len(module.consts)) + u64(len(module.exports)) <= u64(max(u32)),
		"bytecode builder constant count overflow",
	)

	consts := make([]bytecode.Const, len(module.consts) + len(module.exports))
	for value, idx in module.consts {
		consts[idx] = _finish_const(value)
	}

	exports := make([]bytecode.Export, len(module.exports))
	for value, idx in module.exports {
		assert(value.name != "", "bytecode builder export name is empty")
		assert(int(value.global) < len(module.globals), "bytecode builder export global is out of bounds")
		for previous in 0 ..< idx {
			assert(
				module.exports[previous].name != value.name,
				"bytecode builder has duplicate export names",
			)
		}
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
	for item in module.globals {
		delete(item.name)
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
_clone_name :: proc(name: string) -> string {
	if name == "" {
		return ""
	}
	return strings.clone(name)
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
	assert(proto != nil)
	assert(len(proto.params) <= int(max(u32)), "bytecode builder function arity overflow")
	arity := u32(len(proto.params))

	targets := _finish_label_targets(func, proto)
	defer delete(targets)
	insts := make([]bytecode.Inst, len(proto.insts))
	for inst, idx in proto.insts {
		insts[idx] = _finish_inst(func, targets, inst)
	}

	debug_params := _finish_debug_params(proto)
	debug_locals := _finish_debug_locals(proto)
	debug_labels := _finish_debug_labels(proto, targets)
	has_debug := proto.name != "" ||
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
	for value in module.globals {
		if value.name != "" {
			count += 1
		}
	}
	if count == 0 {
		return nil
	}

	values := make([]bytecode.Debug_Name, count)
	idx := 0
	for value, raw_idx in module.globals {
		if value.name == "" {
			continue
		}
		values[idx] = {u32(raw_idx), _clone_name(value.name)}
		idx += 1
	}
	return values
}

@(private)
_finish_debug_params :: proc(proto: ^Func_Proto) -> []bytecode.Debug_Name {
	count := 0
	for value in proto.params {
		if value.name != "" {
			count += 1
		}
	}
	if count == 0 {
		return nil
	}

	values := make([]bytecode.Debug_Name, count)
	idx := 0
	for value, raw_idx in proto.params {
		if value.name == "" {
			continue
		}
		values[idx] = {u32(raw_idx), _clone_name(value.name)}
		idx += 1
	}
	return values
}

@(private)
_finish_debug_locals :: proc(proto: ^Func_Proto) -> []bytecode.Debug_Name {
	count := 0
	for value in proto.locals {
		if value.name != "" {
			count += 1
		}
	}
	if count == 0 {
		return nil
	}

	values := make([]bytecode.Debug_Name, count)
	idx := 0
	for value in proto.locals {
		if value.name == "" {
			continue
		}
		values[idx] = {value.idx, _clone_name(value.name)}
		idx += 1
	}
	return values
}

@(private)
_finish_label_targets :: proc(func: Func, proto: ^Func_Proto) -> []bytecode.Inst_Idx {
	targets := make([]bytecode.Inst_Idx, len(proto.labels))
	bound := make([]bool, len(proto.labels))
	defer delete(bound)

	for binding in proto.binds {
		assert(binding.label.func.module == func.module, "bytecode builder label belongs to another module")
		assert(binding.label.func.id == func.id, "bytecode builder label belongs to another function")
		_assert_label(binding.label)
		idx := int(binding.label.id)
		assert(!bound[idx], "bytecode builder label is bound more than once")
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
	for value in proto.labels {
		if value.name != "" {
			count += 1
		}
	}
	if count == 0 {
		return nil
	}

	labels := make([]bytecode.Debug_Label, count)
	idx := 0
	for value, label_idx in proto.labels {
		if value.name == "" {
			continue
		}
		labels[idx] = {_clone_name(value.name), targets[label_idx]}
		idx += 1
	}
	return labels
}

@(private)
_finish_inst :: proc(
	func: Func,
	targets: []bytecode.Inst_Idx,
	inst: Inst,
) -> bytecode.Inst {
	switch bytecode.opcode_operand_kind(inst.opcode) {
	case .None:
		assert(inst.operand == nil, "bytecode builder instruction has an unexpected operand")
		return bytecode.make_inst(inst.opcode)
	case .I64:
		value, ok := inst.operand.(i64)
		assert(ok, "bytecode builder instruction requires an i64 operand")
		return bytecode.make_inst(inst.opcode, value)
	case .F64:
		value, ok := inst.operand.(f64)
		assert(ok, "bytecode builder instruction requires an f64 operand")
		return bytecode.make_inst(inst.opcode, value)
	case .U32:
		value := _finish_u32_operand(func, targets, inst)
		return bytecode.make_inst(inst.opcode, value)
	}
	unreachable()
}

@(private)
_finish_u32_operand :: proc(
	func: Func,
	targets: []bytecode.Inst_Idx,
	inst: Inst,
) -> u32 {
	#partial switch inst.opcode {
	case .Load_Global, .Store_Global:
		value, ok := inst.operand.(Global)
		assert(ok, "bytecode builder instruction requires a global operand")
		_assert_global(value)
		assert(value.module == func.module, "bytecode builder global belongs to another module")
		return u32(value.id)
	case .Load_Param:
		value, ok := inst.operand.(Param)
		assert(ok, "bytecode builder instruction requires a parameter operand")
		_assert_param(value)
		assert(value.func.module == func.module, "bytecode builder parameter belongs to another module")
		assert(value.func.id == func.id, "bytecode builder parameter belongs to another function")
		return u32(value.id)
	case .Load_Local, .Store_Local:
		value, ok := inst.operand.(Local)
		assert(ok, "bytecode builder instruction requires a local operand")
		local := _assert_local(value)
		assert(value.func.module == func.module, "bytecode builder local belongs to another module")
		assert(value.func.id == func.id, "bytecode builder local belongs to another function")
		return local.idx
	case .Make_String, .Make_Class, .Get_Field, .Set_Field:
		value, ok := inst.operand.(Utf8)
		assert(ok, "bytecode builder instruction requires a UTF-8 constant operand")
		_assert_utf8(value)
		const := Const(value)
		assert(const.module == func.module, "bytecode builder constant belongs to another module")
		return u32(const.id)
	case .Make_Func:
		value, ok := inst.operand.(Func)
		assert(ok, "bytecode builder instruction requires a function operand")
		_assert_func(value)
		assert(value.module == func.module, "bytecode builder function belongs to another module")
		return u32(value.id)
	case .Jump:
		value, ok := inst.operand.(Label)
		assert(ok, "bytecode builder jump requires a label operand")
		_assert_label(value)
		assert(value.func.module == func.module, "bytecode builder label belongs to another module")
		assert(value.func.id == func.id, "bytecode builder label belongs to another function")
		return u32(targets[int(value.id)])
	case:
		value, ok := inst.operand.(u32)
		assert(ok, "bytecode builder instruction requires a u32 operand")
		return value
	}
	unreachable()
}
