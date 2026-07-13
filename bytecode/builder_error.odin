package bytecode

Operand_Mismatch_Error :: struct {
	instruction: Instruction_Index,
	opcode:      Opcode,
	expected:    Operand_Kind,
	actual:      Operand_Kind,
}

Invalid_Constant_Error :: struct {
	instruction: Instruction_Index,
	constant:    Constant_Index,
}

Invalid_Label_Error :: struct {
	instruction: Instruction_Index,
	label:       Label,
}

Label_Already_Bound_Error :: struct {
	instruction: Instruction_Index,
	label:       Label,
}

Unbound_Label_Error :: struct {
	instruction: Instruction_Index,
	label:       Label,
}

Label_Target_Out_Of_Range_Error :: struct {
	instruction: Instruction_Index,
	label:       Label,
}

Invalid_Target_Opcode_Error :: struct {
	instruction: Instruction_Index,
	opcode:      Opcode,
	label:       Label,
}

Builder_Error :: union {
	Operand_Mismatch_Error,
	Invalid_Constant_Error,
	Invalid_Label_Error,
	Label_Already_Bound_Error,
	Unbound_Label_Error,
	Label_Target_Out_Of_Range_Error,
	Invalid_Target_Opcode_Error,
}
