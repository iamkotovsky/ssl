package parser

import "../module"
import "../module/builder"
import "../module/const"
import "../module/inst"
import "../module/inst/operand"
import "ast"

lower :: proc(p: ^ast.Module) -> (module.Module, Error) {
	b: builder.Builder
	for parsed_inst in p.insts {
		op, err := _lower_operand(&b, p.labels, parsed_inst.kind, parsed_inst.operand)
		if err.kind != .None {
			return {}, err
		}
		builder.write_inst(&b, parsed_inst.kind, op)
	}
	for label in p.debug_labels {
		name := builder.write_const(&b, const.make(label.name))
		builder.write_debug_label(&b, name, label.inst)
	}
	return builder.build(&b), _error(.None)
}

@(private)
_lower_operand :: proc(
	b: ^builder.Builder,
	labels: map[string]int,
	kind: inst.Kind,
	parsed: ast.Operand,
) -> (operand.Operand, Error) {
	expected := inst.expected_operand(kind)

	switch expected {
	case .None:
		if parsed.kind != .None {
			return {}, _error_at(.Unexpected_Operand, parsed.token)
		}
		return operand.make_none(), _error(.None)
	case .I8:
		if parsed.kind != .Int {
			return {}, _error_at(.Invalid_Operand_Type, parsed.token)
		}
		if parsed.as_int < -128 || parsed.as_int > 127 {
			return {}, _error_at(.Int_Out_Of_Range, parsed.token)
		}
		return operand.make_i8(i8(parsed.as_int)), _error(.None)
	case .I32:
		if parsed.kind != .Int {
			return {}, _error_at(.Invalid_Operand_Type, parsed.token)
		}
		if parsed.as_int < -2147483648 || parsed.as_int > 2147483647 {
			return {}, _error_at(.Int_Out_Of_Range, parsed.token)
		}
		return operand.make_i32(i32(parsed.as_int)), _error(.None)
	case .I64:
		if parsed.kind != .Int {
			return {}, _error_at(.Invalid_Operand_Type, parsed.token)
		}
		return operand.make_i64(parsed.as_int), _error(.None)
	case .F32:
		if parsed.kind != .Float {
			return {}, _error_at(.Invalid_Operand_Type, parsed.token)
		}
		return operand.make_f32(f32(parsed.as_float)), _error(.None)
	case .F64:
		if parsed.kind != .Float {
			return {}, _error_at(.Invalid_Operand_Type, parsed.token)
		}
		return operand.make_f64(parsed.as_float), _error(.None)
	case .Label:
		if parsed.kind != .Label {
			return {}, _error_at(.Invalid_Operand_Type, parsed.token)
		}
		i, exists := labels[parsed.as_label]
		if !exists {
			return {}, _error_at(.Label_Not_Exists, parsed.token)
		}
		return operand.make_label(i), _error(.None)
	case .Const:
		if parsed.kind != .String {
			return {}, _error_at(.Invalid_Operand_Type, parsed.token)
		}
		i := builder.write_const(b, const.make(parsed.as_string))
		return operand.make_const(i), _error(.None)
	}

	return {}, _error_at(.Invalid_Operand_Type, parsed.token)
}
