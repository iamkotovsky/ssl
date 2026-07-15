package assembler

import "../bytecode"

@(private)
_Label_Symbol :: struct {
	name:            string,
	instruction:     bytecode.Instruction_Index,
	defined:         bool,
	first_reference: _Token,
}

@(private)
_Label_Fixup :: struct {
	instruction: bytecode.Instruction_Index,
	label:       int,
}

@(private)
_get_or_create_label :: proc(
	p: ^_Parser,
	name: string,
	reference: _Token = {},
) -> int {
	if index, ok := p.label_indices[name]; ok {
		symbol := &p.labels[index]
		if symbol.first_reference.kind == .EOF && reference.kind != .EOF {
			symbol.first_reference = reference
		}
		return index
	}

	index := len(p.labels)
	append(&p.labels, _Label_Symbol{name = name, first_reference = reference})
	p.label_indices[name] = index
	return index
}
