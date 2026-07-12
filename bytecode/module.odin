package bytecode

Debug_Info :: struct {
	labels: []Debug_Label,
}

Debug_Label :: struct {
	name_constant: int,
	instruction:   int,
}

Module :: struct {
	constants:    []Constant,
	instructions: []Instruction,
	debug:        Debug_Info,
}

destroy :: proc(m: Module) {
	for constant in m.constants {
		destroy_constant(constant)
	}
	delete(m.constants)
	delete(m.instructions)
	delete(m.debug.labels)
}
