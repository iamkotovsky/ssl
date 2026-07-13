package assembler

import "../bytecode"
import "core:fmt"

Error_Kind :: enum {
	None,
	Expected_Instruction_Or_Label,
	Unknown_Instruction,
	Expected_Newline,
	Invalid_Label,
	Invalid_Operand,
	Missing_Operand,
	Unexpected_Operand,
	Bad_Integer,
	Bad_Float,
	Label_Not_Defined,
	Invalid_Operand_Type,
	Integer_Out_Of_Range,
	Build_Failed,
}

Error :: struct {
	kind:        Error_Kind,
	line:        int,
	col:         int,
	build_error: bytecode.Builder_Error,
}

@(private)
_error :: proc(kind: Error_Kind) -> Error {
	return {kind = kind}
}

@(private)
_error_at :: proc(kind: Error_Kind, token: _Token) -> Error {
	return {kind = kind, line = token.line, col = token.col}
}

@(private)
_build_error_at :: proc(err: bytecode.Builder_Error, token: _Token = {}) -> Error {
	return {
		kind        = .Build_Failed,
		line        = token.line,
		col         = token.col,
		build_error = err,
	}
}

error_name :: proc(kind: Error_Kind) -> string {
	switch kind {
	case .None:                          return "none"
	case .Expected_Instruction_Or_Label: return "expected instruction or label"
	case .Unknown_Instruction:           return "unknown instruction"
	case .Expected_Newline:              return "expected newline"
	case .Invalid_Label:                 return "invalid label"
	case .Invalid_Operand:               return "invalid operand"
	case .Missing_Operand:               return "missing operand"
	case .Unexpected_Operand:            return "unexpected operand"
	case .Bad_Integer:                   return "bad integer"
	case .Bad_Float:                     return "bad float"
	case .Label_Not_Defined:             return "label is not defined"
	case .Invalid_Operand_Type:          return "invalid operand type"
	case .Integer_Out_Of_Range:          return "integer out of range"
	case .Build_Failed:                  return "bytecode build failed"
	}
	return "unknown error"
}

print_error :: proc(err: Error, name: string = "<virtual>") {
	if err.kind == .None {
		return
	}
	fmt.printfln("%s:%d:%d: asm error: %s", name, err.line, err.col, error_name(err.kind))
}
