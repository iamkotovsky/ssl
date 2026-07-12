package parser

import "../../bytecode"
import "ast"

lower :: proc(p: ^ast.Module) -> (bytecode.Module, Error) {
	b: bytecode.Builder
	for parsed_inst in p.insts {
		op, err := _lower_operand(&b, p.labels, parsed_inst.opcode, parsed_inst.operand)
		if err.kind != .None {
			return {}, err
		}
		bytecode.emit(&b, parsed_inst.opcode, op)
	}
	for label in p.debug_labels {
		name := bytecode.add_constant(&b, bytecode.make_constant(label.name))
		bytecode.add_debug_label(&b, name, label.instruction)
	}
	return bytecode.finish(&b), _error(.None)
}

@(private)
_lower_operand :: proc(
	b: ^bytecode.Builder,
	labels: map[string]int,
	opcode: bytecode.Opcode,
	parsed: ast.Operand,
) -> (bytecode.Operand, Error) {
	expected := bytecode.opcode_operand(opcode)

	switch expected {
	case .None:
		if parsed.kind != .None {
			return {}, _error_at(.Unexpected_Operand, parsed.token)
		}
		return bytecode.make_none_operand(), _error(.None)
	case .I8:
		if parsed.kind != .Int {
			return {}, _error_at(.Invalid_Operand_Type, parsed.token)
		}
		if parsed.as_int < -128 || parsed.as_int > 127 {
			return {}, _error_at(.Int_Out_Of_Range, parsed.token)
		}
		return bytecode.make_i8_operand(i8(parsed.as_int)), _error(.None)
	case .I32:
		if parsed.kind != .Int {
			return {}, _error_at(.Invalid_Operand_Type, parsed.token)
		}
		if parsed.as_int < -2147483648 || parsed.as_int > 2147483647 {
			return {}, _error_at(.Int_Out_Of_Range, parsed.token)
		}
		return bytecode.make_i32_operand(i32(parsed.as_int)), _error(.None)
	case .I64:
		if parsed.kind != .Int {
			return {}, _error_at(.Invalid_Operand_Type, parsed.token)
		}
		return bytecode.make_i64_operand(parsed.as_int), _error(.None)
	case .F32:
		if parsed.kind != .Float {
			return {}, _error_at(.Invalid_Operand_Type, parsed.token)
		}
		return bytecode.make_f32_operand(f32(parsed.as_float)), _error(.None)
	case .F64:
		if parsed.kind != .Float {
			return {}, _error_at(.Invalid_Operand_Type, parsed.token)
		}
		return bytecode.make_f64_operand(parsed.as_float), _error(.None)
	case .Label:
		if parsed.kind != .Label {
			return {}, _error_at(.Invalid_Operand_Type, parsed.token)
		}
		i, exists := labels[parsed.as_label]
		if !exists {
			return {}, _error_at(.Label_Not_Exists, parsed.token)
		}
		return bytecode.make_label_operand(i), _error(.None)
	case .Constant:
		if parsed.kind != .String {
			return {}, _error_at(.Invalid_Operand_Type, parsed.token)
		}
		i := bytecode.add_constant(b, bytecode.make_constant(parsed.as_string))
		return bytecode.make_constant_operand(i), _error(.None)
	}

	return {}, _error_at(.Invalid_Operand_Type, parsed.token)
}
