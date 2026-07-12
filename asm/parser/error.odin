package parser

import "../lexer"
import "core:fmt"

Error_Kind :: enum {
	None = 0,
	Expected_Inst_Or_Label,
	Unknown_Inst,
	Expected_Newline,
	Invalid_Label,
	Invalid_Operand,
	Missing_Operand,
	Unexpected_Operand,
	Bad_Int,
	Bad_Float,
	Label_Not_Exists,
	Invalid_Operand_Type,
	Int_Out_Of_Range,
}

Error :: struct {
	kind:  Error_Kind,
	line:  int,
	col:   int,
	token: string,
}

@(private)
_error :: proc(kind: Error_Kind) -> Error {
	return {kind = kind}
}

@(private)
_error_at :: proc(kind: Error_Kind, token: lexer.Token) -> Error {
	return {kind = kind, line = token.line, col = token.col, token = token.value}
}

error_name :: proc(kind: Error_Kind) -> string {
	switch kind {
	case .None:
		return "none"
	case .Expected_Inst_Or_Label:
		return "expected instruction or label"
	case .Unknown_Inst:
		return "unknown instruction"
	case .Expected_Newline:
		return "expected newline"
	case .Invalid_Label:
		return "invalid label"
	case .Invalid_Operand:
		return "invalid operand"
	case .Missing_Operand:
		return "missing operand"
	case .Unexpected_Operand:
		return "unexpected operand"
	case .Bad_Int:
		return "bad integer"
	case .Bad_Float:
		return "bad float"
	case .Label_Not_Exists:
		return "label does not exist"
	case .Invalid_Operand_Type:
		return "invalid operand type"
	case .Int_Out_Of_Range:
		return "integer out of range"
	}
	return "unknown error"
}

print_error :: proc(err: Error) {
	if err.kind == .None {
		return
	}

	if err.line > 0 {
		fmt.printfln("asm error: %s at %d:%d", error_name(err.kind), err.line, err.col)
	} else {
		fmt.printfln("asm error: %s", error_name(err.kind))
	}

	if len(err.token) > 0 {
		fmt.printfln("  token: %q", err.token)
	}
}
