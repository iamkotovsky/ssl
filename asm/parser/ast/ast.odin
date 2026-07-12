package ast

import "../../lexer"
import "../../../bytecode"

Module :: struct {
	labels:       map[string]int,
	insts:        [dynamic]Inst,
	debug_labels: [dynamic]Debug_Label,
}

destroy :: proc(m: ^Module) {
	delete(m.labels)
	delete(m.insts)
	delete(m.debug_labels)
}

Operand_Kind :: enum {
	None,
	Int,
	Float,
	Label,
	String,
}

Operand :: struct {
	kind:  Operand_Kind,
	token: lexer.Token,
	using _: struct #raw_union {
		as_int:    i64,
		as_float:  f64,
		as_label:  string,
		as_string: string,
	},
}

make_none :: proc() -> Operand {
	return {kind = .None}
}

make_int :: proc(value: i64, token: lexer.Token) -> Operand {
	return {kind = .Int, token = token, as_int = value}
}

make_float :: proc(value: f64, token: lexer.Token) -> Operand {
	return {kind = .Float, token = token, as_float = value}
}

make_label :: proc(value: string, token: lexer.Token) -> Operand {
	return {kind = .Label, token = token, as_label = value}
}

make_string :: proc(value: string, token: lexer.Token) -> Operand {
	return {kind = .String, token = token, as_string = value}
}

Inst :: struct {
	opcode:  bytecode.Opcode,
	operand: Operand,
}

Debug_Label :: struct {
	name:        string,
	instruction: int,
}
