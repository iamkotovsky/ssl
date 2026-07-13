package bytecode

emit :: proc {
	emit_none,
	emit_i8,
	emit_i16,
	emit_i32,
	emit_i64,
	emit_f32,
	emit_f64,
	emit_constant,
	emit_label,
}

emit_none :: proc(b: ^Builder, opcode: Opcode) -> (Instruction_Index, Builder_Error) {
	return _emit_operand(b, opcode, _make_none_operand())
}

emit_i8 :: proc(b: ^Builder, opcode: Opcode, value: i8) -> (Instruction_Index, Builder_Error) {
	return _emit_operand(b, opcode, _make_i8_operand(value))
}

emit_i16 :: proc(b: ^Builder, opcode: Opcode, value: i16) -> (Instruction_Index, Builder_Error) {
	return _emit_operand(b, opcode, _make_i16_operand(value))
}

emit_i32 :: proc(b: ^Builder, opcode: Opcode, value: i32) -> (Instruction_Index, Builder_Error) {
	return _emit_operand(b, opcode, _make_i32_operand(value))
}

emit_i64 :: proc(b: ^Builder, opcode: Opcode, value: i64) -> (Instruction_Index, Builder_Error) {
	return _emit_operand(b, opcode, _make_i64_operand(value))
}

emit_f32 :: proc(b: ^Builder, opcode: Opcode, value: f32) -> (Instruction_Index, Builder_Error) {
	return _emit_operand(b, opcode, _make_f32_operand(value))
}

emit_f64 :: proc(b: ^Builder, opcode: Opcode, value: f64) -> (Instruction_Index, Builder_Error) {
	return _emit_operand(b, opcode, _make_f64_operand(value))
}

emit_constant :: proc(b: ^Builder, opcode: Opcode, constant: Constant_Index) -> (instruction: Instruction_Index, err: Builder_Error) {
	instruction = position(b)
	if int(constant) >= len(b.constants) {
		return instruction, Invalid_Constant_Error{instruction, constant}
	}
	return _emit_operand(b, opcode, _make_constant_operand(constant))
}

@(private)
_emit_operand :: proc(b: ^Builder, opcode: Opcode, operand: Operand) -> (instruction: Instruction_Index, err: Builder_Error) {
	instruction = position(b)
	expected := opcode_operand(opcode)
	if expected != operand.kind {
		return instruction, Operand_Mismatch_Error{
			instruction = instruction,
			opcode      = opcode,
			expected    = expected,
			actual      = operand.kind,
		}
	}
	append(&b.instructions, _make_instruction(opcode, operand))
	return instruction, nil
}
