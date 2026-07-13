package bytecode

import "core:strings"

Label :: distinct u32

Label_Info :: struct {
	name:        string,
	instruction: Instruction_Index,
	bound:       bool,
}

Fixup :: struct {
	instruction: Instruction_Index,
	target:      Label,
}

create_label :: proc(b: ^Builder, name: string = "") -> Label {
	assert(len(b.labels) < int(max(u32)), "bytecode label index overflow")
	label := Label_Info{}
	if name != "" {
		label.name = strings.clone(name)
	}
	append(&b.labels, label)
	return Label(len(b.labels))
}

bind_label :: proc(b: ^Builder, label: Label) -> Builder_Error {
	instruction := position(b)
	slot, ok := _label_slot(b, label)
	if !ok {
		return Invalid_Label_Error{instruction, label}
	}
	if b.labels[slot].bound {
		return Label_Already_Bound_Error{instruction, label}
	}
	b.labels[slot].instruction = instruction
	b.labels[slot].bound = true
	return nil
}

emit_label :: proc(b: ^Builder, opcode: Opcode, target: Label) -> (instruction: Instruction_Index, err: Builder_Error) {
	instruction = position(b)
	if _, ok := _label_slot(b, target); !ok {
		return instruction, Invalid_Label_Error{instruction, target}
	}
	if opcode_operand(opcode) != .Target {
		return instruction, Invalid_Target_Opcode_Error{instruction, opcode, target}
	}
	instruction = _emit_operand(b, opcode, _make_target_operand({})) or_return
	append(&b.fixups, Fixup{instruction = instruction, target = target})
	return instruction, nil
}

@(private)
_label_slot :: proc(b: ^Builder, label: Label) -> (int, bool) {
	raw := u32(label)
	if raw == 0 {
		return 0, false
	}
	slot := int(raw - 1)
	return slot, slot < len(b.labels)
}
