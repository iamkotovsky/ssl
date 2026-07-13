package assembler

import "../bytecode"

@(private)
_Label_Symbol :: struct {
	name:            string,
	label:           bytecode.Label,
	defined:         bool,
	first_reference: _Token,
}

@(private)
_get_or_create_label :: proc(p: ^_Parser, name: string, reference: _Token = {}) -> bytecode.Label {
	if index, ok := p.label_indices[name]; ok {
		symbol := &p.labels[index]
		if symbol.first_reference.kind == .EOF && reference.kind != .EOF {
			symbol.first_reference = reference
		}
		return symbol.label
	}

	label := bytecode.create_label(&p.builder, name)
	index := len(p.labels)
	append(&p.labels, _Label_Symbol{
		name            = name,
		label           = label,
		first_reference = reference,
	})
	p.label_indices[name] = index
	return label
}
