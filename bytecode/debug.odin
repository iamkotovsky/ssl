package bytecode

import "core:fmt"

Debug_Name :: struct {
	idx:  u32,
	name: string,
}

Debug_Info :: struct {
	globals: []Debug_Name,
	funcs:   []Func_Debug_Info,
}

Func_Debug_Info :: struct {
	func:   Func_Idx,
	name:   Maybe(string),
	params: []Debug_Name,
	locals: []Debug_Name,
	labels: []Debug_Label,
}

Debug_Label :: struct {
	name: string,
	inst: Inst_Idx,
}

print :: proc(module: Module) {
	fmt.println("{")
	_print_consts(module)
	fmt.printfln("\n    init = %d", module.init)
	_print_globals(module)
	_print_exports(module)
	_print_funcs(module)
	fmt.println("}")
}

@(private)
_print_consts :: proc(module: Module) {
	if len(module.consts) == 0 {
		fmt.println("    consts = {}")
		return
	}
	fmt.println("    consts = {")
	for value, idx in module.consts {
		fmt.printf("        [%d] = ", idx)
		switch value.kind {
		case .Utf8:
			fmt.printf("%q", value.as_utf8)
		}
		fmt.println()
	}
	fmt.println("    }")
}

@(private)
_print_globals :: proc(module: Module) {
	fmt.printfln("\n    globals = %d", module.globals)
	for value in module.debug.globals {
		fmt.printfln("    // [%d] = %s", value.idx, value.name)
	}
}

@(private)
_print_exports :: proc(module: Module) {
	if len(module.exports) == 0 {
		fmt.println("\n    exports = {}")
		return
	}
	fmt.println("\n    exports = {")
	for value, idx in module.exports {
		fmt.printf("        [%d] = ", idx)
		fmt.print("{ ")
		fmt.printf("%d, %d", value.name, value.global)
		fmt.print(" }")
		_print_export_comment(module, value)
		fmt.println()
	}
	fmt.println("    }")
}

@(private)
_print_export_comment :: proc(module: Module, value: Export) {
	fmt.print(" //")
	name_idx := int(value.name)
	if name_idx < len(module.consts) {
		constant := module.consts[name_idx]
		if constant.kind == .Utf8 {
			fmt.printf(" %s", constant.as_utf8)
		} else {
			fmt.print(" _")
		}
	} else {
		fmt.print(" _")
	}
	name := _debug_name(module.debug.globals, u32(value.global))
	if name != nil {
		fmt.printf(", %s", name.?)
	} else {
		fmt.print(", _")
	}
}

@(private)
_print_funcs :: proc(module: Module) {
	if len(module.funcs) == 0 {
		fmt.println("\n    funcs = {}")
		return
	}
	fmt.println("\n    funcs = {")
	for &func, raw_idx in module.funcs {
		idx := Func_Idx(raw_idx)
		info, _ := _func_debug_info(module.debug, idx)
		if idx == module.init {
			fmt.println("        // init")
		} else if info.name != nil {
			fmt.printfln("        // %s", info.name.?)
		}
		fmt.printf("        [%d] = ", idx)
		fmt.println("{")
		_print_arity(func.arity, info)
		_print_captures(func.captures)
		_print_insts(module, func.insts, info)
		fmt.println("        }")
		if raw_idx + 1 < len(module.funcs) {
			fmt.println()
		}
	}
	fmt.println("    }")
}

@(private)
_print_arity :: proc(arity: u32, debug: Func_Debug_Info) {
	fmt.printf("            arity = %d", arity)
	if arity != 0 {
		fmt.print(" // ")
		for raw_idx in 0 ..< int(arity) {
			if raw_idx != 0 {
				fmt.print(", ")
			}
			name := _debug_name(debug.params, u32(raw_idx))
			if name != nil {
				fmt.print(name.?)
			} else {
				fmt.print("_")
			}
		}
	}
	fmt.println()
}

@(private)
_print_captures :: proc(captures: []Capture) {
	if len(captures) == 0 {
		fmt.println("            captures = {}")
		return
	}
	fmt.println("            captures = {")
	for value, idx in captures {
		fmt.printf("                [%d] = ", idx)
		fmt.print("{ ")
		fmt.printf("%s %d", _capture_kind_name(value.kind), value.idx)
		fmt.print(" }")
		fmt.println()
	}
	fmt.println("            }")
}

@(private)
_capture_kind_name :: proc(kind: Capture_Kind) -> string {
	switch kind {
	case .Param:
		return "param"
	case .Local:
		return "local"
	case .Capture:
		return "capture"
	}
	unreachable()
}

@(private)
_print_insts :: proc(module: Module, insts: []Inst, debug: Func_Debug_Info) {
	if len(insts) == 0 {
		fmt.println("            insts = {}")
		return
	}
	fmt.println("            insts = {")
	for inst, raw_idx in insts {
		_print_labels(debug.labels, Inst_Idx(raw_idx))
		fmt.printf("                %04d %v", raw_idx, inst.opcode)
		_print_operand(module, debug, inst)
		fmt.println()
	}
	fmt.println("            }")
}

@(private)
_print_labels :: proc(labels: []Debug_Label, inst: Inst_Idx) {
	for label in labels {
		if label.inst == inst {
			fmt.printfln("                %s", label.name)
		}
	}
}

@(private)
_print_operand :: proc(module: Module, debug: Func_Debug_Info, inst: Inst) {
	switch opcode_operand_kind(inst.opcode) {
	case .None:
		return
	case .I64:
		fmt.printf(" %d", inst.operand.as_i64)
	case .U32:
		fmt.printf(" %d", inst.operand.as_u32)
		_print_operand_comment(module, debug, inst.opcode, inst.operand.as_u32)
	case .F64:
		fmt.printf(" %g", inst.operand.as_f64)
	}
}

@(private)
_print_operand_comment :: proc(
	module: Module,
	debug: Func_Debug_Info,
	opcode: Opcode,
	value: u32,
) {
	#partial switch opcode {
	case .Make_String, .Make_Class, .Get_Field, .Set_Field:
		idx := int(value)
		if idx < len(module.consts) {
			constant := module.consts[idx]
			if constant.kind == .Utf8 {
				fmt.printf(" // %q", constant.as_utf8)
			}
		}
	case .Make_Func:
		_print_name_comment(_func_debug_name(module.debug, Func_Idx(value)))
	case .Load_Global, .Store_Global:
		_print_name_comment(_debug_name(module.debug.globals, value))
	case .Load_Param:
		_print_name_comment(_debug_name(debug.params, value))
	case .Load_Local, .Store_Local:
		_print_name_comment(_debug_name(debug.locals, value))
	case .Jump:
		_print_label_comment(debug.labels, Inst_Idx(value))
	case:
	}
}

@(private)
_print_name_comment :: proc(name: Maybe(string)) {
	if name != nil {
		fmt.printf(" // %s", name.?)
	}
}

@(private)
_print_label_comment :: proc(labels: []Debug_Label, inst: Inst_Idx) {
	first := true
	for label in labels {
		if label.inst != inst {
			continue
		}
		if first {
			fmt.print(" //")
			first = false
		}
		fmt.printf(" %s", label.name)
	}
}

@(private)
_debug_name :: proc(values: []Debug_Name, idx: u32) -> Maybe(string) {
	for value in values {
		if value.idx == idx {
			return value.name
		}
	}
	return nil
}

@(private)
_func_debug_info :: proc(debug: Debug_Info, func: Func_Idx) -> (Func_Debug_Info, bool) {
	for info in debug.funcs {
		if info.func == func {
			return info, true
		}
	}
	return {}, false
}

@(private)
_func_debug_name :: proc(debug: Debug_Info, func: Func_Idx) -> Maybe(string) {
	info, ok := _func_debug_info(debug, func)
	if !ok {
		return nil
	}
	return info.name
}

@(private)
_destroy_debug_names :: proc(values: []Debug_Name) {
	for value in values {
		delete(value.name)
	}
	delete(values)
}

@(private)
_destroy_func_debug_info :: proc(info: ^Func_Debug_Info) {
	if info.name != nil {
		delete(info.name.?)
	}
	_destroy_debug_names(info.params)
	_destroy_debug_names(info.locals)
	for label in info.labels {
		delete(label.name)
	}
	delete(info.labels)
	info^ = {}
}

@(private)
_destroy_debug_info :: proc(debug: ^Debug_Info) {
	_destroy_debug_names(debug.globals)
	for &info in debug.funcs {
		_destroy_func_debug_info(&info)
	}
	delete(debug.funcs)
	debug^ = {}
}
