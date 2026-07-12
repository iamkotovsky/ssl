package bytecode

import "core:fmt"

debug_print :: proc(m: Module) {
	fmt.println("bytecode module")
	fmt.printfln("  constants: %d", len(m.constants))
	if len(m.constants) == 0 {
		fmt.println("    (none)")
	} else {
		for constant, i in m.constants {
			fmt.printf("    %04d  ", i)
			_debug_print_constant(constant)
			fmt.println()
		}
	}

	fmt.printfln("  instructions: %d", len(m.instructions))
	if len(m.instructions) == 0 {
		fmt.println("    (none)")
		return
	}

	for instruction, i in m.instructions {
		_debug_print_labels(m, i)
		fmt.printf("    %04d  %-12s", i, opcode_name(instruction.opcode))
		if opcode_has_operand(instruction.opcode) {
			_debug_print_operand(m, instruction)
		}
		fmt.println()
	}
}

@(private)
_debug_print_labels :: proc(m: Module, inst_index: int) {
	for label in m.debug.labels {
		if label.instruction != inst_index {
			continue
		}
		if label.name_constant >= 0 && label.name_constant < len(m.constants) && m.constants[label.name_constant].kind == .String {
			fmt.printfln("    %s", m.constants[label.name_constant].as_string)
		} else {
			fmt.printfln("    <debug-label #%d>", label.name_constant)
		}
	}
}

@(private)
_debug_print_operand :: proc(m: Module, instruction: Instruction) {
	switch instruction.operand.kind {
	case .None:
		return
	case .I64:
		fmt.printf(" %d", instruction.operand.as_i64)
	case .I32:
		fmt.printf(" %d", instruction.operand.as_i32)
	case .I8:
		fmt.printf(" %d", instruction.operand.as_i8)
	case .F64:
		fmt.printf(" %g", instruction.operand.as_f64)
	case .F32:
		fmt.printf(" %g", instruction.operand.as_f32)
	case .Label:
		fmt.printf(" @%d", instruction.operand.as_label)
		if name, ok := _debug_label_name(m, instruction.operand.as_label); ok {
			fmt.printf(" %s", name)
		}
	case .Constant:
		i := instruction.operand.as_constant
		if i >= 0 && i < len(m.constants) && m.constants[i].kind == .String {
			fmt.printf(" #%d %q", i, m.constants[i].as_string)
		} else {
			fmt.printf(" #%d", i)
		}
	}
}

@(private)
_debug_label_name :: proc(m: Module, inst_index: int) -> (string, bool) {
	for label in m.debug.labels {
		if label.instruction != inst_index {
			continue
		}
		if label.name_constant >= 0 && label.name_constant < len(m.constants) && m.constants[label.name_constant].kind == .String {
			return m.constants[label.name_constant].as_string, true
		}
	}
	return "", false
}

@(private)
_debug_print_constant :: proc(constant: Constant) {
	#partial switch constant.kind {
	case .String:
		fmt.printf("string  %q", constant.as_string)
	}
}
