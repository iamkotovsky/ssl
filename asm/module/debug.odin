package module

import "core:fmt"

import "const"
import "inst"

debug_print :: proc(m: Module) {
	fmt.println("asm module")
	fmt.printfln("  consts: %d", len(m.consts))
	if len(m.consts) == 0 {
		fmt.println("    (none)")
	} else {
		for c, i in m.consts {
			fmt.printf("    %04d  ", i)
			_debug_print_const(c)
			fmt.println()
		}
	}

	fmt.printfln("  insts: %d", len(m.insts))
	if len(m.insts) == 0 {
		fmt.println("    (none)")
		return
	}

	for it, i in m.insts {
		_debug_print_labels(m, i)
		fmt.printf("    %04d  %-12s", i, inst.to_string(it.kind))
		if inst.has_operand(it.kind) {
			_debug_print_operand(m, it)
		}
		fmt.println()
	}
}

@(private)
_debug_print_labels :: proc(m: Module, inst_index: int) {
	for label in m.debug.labels {
		if label.inst != inst_index {
			continue
		}
		if label.name >= 0 && label.name < len(m.consts) && m.consts[label.name].kind == .String {
			fmt.printfln("    %s", m.consts[label.name].as_string)
		} else {
			fmt.printfln("    <debug-label #%d>", label.name)
		}
	}
}

@(private)
_debug_print_operand :: proc(m: Module, it: inst.Inst) {
	switch it.value.kind {
	case .None:
		return
	case .I64:
		fmt.printf(" %d", it.value.as_i64)
	case .I32:
		fmt.printf(" %d", it.value.as_i32)
	case .I8:
		fmt.printf(" %d", it.value.as_i8)
	case .F64:
		fmt.printf(" %g", it.value.as_f64)
	case .F32:
		fmt.printf(" %g", it.value.as_f32)
	case .Label:
		fmt.printf(" @%d", it.value.as_label)
		if name, ok := _debug_label_name(m, it.value.as_label); ok {
			fmt.printf(" %s", name)
		}
	case .Const:
		i := it.value.as_const
		if i >= 0 && i < len(m.consts) && m.consts[i].kind == .String {
			fmt.printf(" #%d %q", i, m.consts[i].as_string)
		} else {
			fmt.printf(" #%d", i)
		}
	}
}

@(private)
_debug_label_name :: proc(m: Module, inst_index: int) -> (string, bool) {
	for label in m.debug.labels {
		if label.inst != inst_index {
			continue
		}
		if label.name >= 0 && label.name < len(m.consts) && m.consts[label.name].kind == .String {
			return m.consts[label.name].as_string, true
		}
	}
	return "", false
}

@(private)
_debug_print_const :: proc(c: const.Const) {
	#partial switch c.kind {
	case .String:
		fmt.printf("string  %q", c.as_string)
	}
}
