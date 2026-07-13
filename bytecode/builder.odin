package bytecode

Builder :: struct {
	constants:    [dynamic]Constant,
	instructions: [dynamic]Instruction,
	debug_labels: [dynamic]Debug_Label,
	labels:       [dynamic]Label_Info,
	fixups:       [dynamic]Fixup,
}

position :: proc(b: ^Builder) -> Instruction_Index {
	assert(len(b.instructions) <= int(max(u32)), "bytecode instruction index overflow")
	return Instruction_Index(len(b.instructions))
}

make_constant :: proc(b: ^Builder, value: string) -> Constant_Index {
	return _add_constant(b, _make_string_constant(value))
}

@(private)
_add_constant :: proc(b: ^Builder, constant: Constant) -> Constant_Index {
	assert(len(b.constants) <= int(max(u32)), "bytecode constant index overflow")
	index := Constant_Index(len(b.constants))
	append(&b.constants, constant)
	return index
}

finish :: proc(b: ^Builder) -> (Module, Builder_Error) {
	for fixup in b.fixups {
		slot, ok := _label_slot(b, fixup.target)
		if !ok {
			return {}, Invalid_Label_Error{fixup.instruction, fixup.target}
		}
		label := b.labels[slot]
		if !label.bound {
			return {}, Unbound_Label_Error{fixup.instruction, fixup.target}
		}
		if int(label.instruction) >= len(b.instructions) {
			return {}, Label_Target_Out_Of_Range_Error{label.instruction, fixup.target}
		}
		b.instructions[int(fixup.instruction)].operand = _make_target_operand(label.instruction)
	}

	for instruction, raw_index in b.instructions {
		index := Instruction_Index(raw_index)
		expected := opcode_operand(instruction.opcode)
		if expected != instruction.operand.kind {
			return {}, Operand_Mismatch_Error{
				instruction = index,
				opcode      = instruction.opcode,
				expected    = expected,
				actual      = instruction.operand.kind,
			}
		}
		#partial switch instruction.operand.kind {
		case .Constant:
			if int(instruction.operand.as_constant) >= len(b.constants) {
				return {}, Invalid_Constant_Error{index, instruction.operand.as_constant}
			}
		case .Target:
			assert(
				int(instruction.operand.as_target) < len(b.instructions),
				"resolved bytecode target points outside instruction storage",
			)
		case:
		}
	}

	for i in 0 ..< len(b.labels) {
		label := &b.labels[i]
		if label.name == "" {
			continue
		}
		if !label.bound {
			return {}, Unbound_Label_Error{label = Label(i + 1)}
		}
		if int(label.instruction) >= len(b.instructions) {
			return {}, Label_Target_Out_Of_Range_Error{
				instruction = label.instruction,
				label       = Label(i + 1),
			}
		}
		append(
			&b.debug_labels,
			Debug_Label{name = label.name, instruction = label.instruction},
		)
		label.name = ""
	}

	delete(b.labels)
	delete(b.fixups)
	m := Module {
		constants    = b.constants[:],
		instructions = b.instructions[:],
		debug        = {labels = b.debug_labels[:]},
	}
	b^ = {}
	return m, nil
}

destroy_builder :: proc(b: ^Builder) {
	for constant in b.constants {
		_destroy_constant(constant)
	}
	for label in b.debug_labels {
		delete(label.name)
	}
	for label in b.labels {
		delete(label.name)
	}
	delete(b.constants)
	delete(b.instructions)
	delete(b.debug_labels)
	delete(b.labels)
	delete(b.fixups)
	b^ = {}
}
