package bytecode

Debug_Info :: struct {
	labels: []Debug_Label,
}

Debug_Label :: struct {
	name:        string,
	instruction: Instruction_Index,
}

Module :: struct {
	constants:    []Constant,
	instructions: []Instruction,
	debug:        Debug_Info,
}

destroy :: proc(m: Module) {
	for constant in m.constants {
		_destroy_constant(constant)
	}
	delete(m.constants)
	delete(m.instructions)
	for label in m.debug.labels {
		delete(label.name)
	}
	delete(m.debug.labels)
}
