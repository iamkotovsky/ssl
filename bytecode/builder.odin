package bytecode

Builder :: struct {
	constants:    [dynamic]Constant,
	instructions: [dynamic]Instruction,
	debug_labels: [dynamic]Debug_Label,
}

add_constant :: proc(b: ^Builder, constant: Constant) -> int {
	i := len(b.constants)
	append(&b.constants, constant)
	return i
}

emit :: proc(b: ^Builder, opcode: Opcode, operand: Operand = {}) {
	append(&b.instructions, make_instruction(opcode, operand))
}

add_debug_label :: proc(b: ^Builder, name_constant: int, instruction: int) {
	append(&b.debug_labels, Debug_Label{name_constant = name_constant, instruction = instruction})
}

finish :: proc(b: ^Builder) -> Module {
	return {
		constants    = b.constants[:],
		instructions = b.instructions[:],
		debug  = {
			labels = b.debug_labels[:],
		},
	}
}
