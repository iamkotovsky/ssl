package inst

import "operand"

Kind :: enum {
	None,
	Load,
	Load_Local,
	Store,
	Store_Local,
	Make_I8,
	Make_I16,
	Make_I32,
	Make_I64,
	Make_F32,
	Make_F64,
	Make_String,
	Make_Class,
	Make_Func,
	Make_List,
	Call,
	Ret,
	Jump,
	Field_Get,
	Field_Set,
	Add,
	Sub,
	Mul,
	Div,
	Halt,
}

@(private)
@(rodata)
INSTS := [Kind]string {
	.None        = "none",
	.Load        = "load",
	.Load_Local  = "load.local",
	.Store       = "store",
	.Store_Local = "store.local",
	.Make_I8     = "make.i8",
	.Make_I16    = "make.i16",
	.Make_I32    = "make.i32",
	.Make_I64    = "make.i64",
	.Make_F32    = "make.f32",
	.Make_F64    = "make.f64",
	.Make_String = "make.string",
	.Make_Class  = "make.class",
	.Make_Func   = "make.func",
	.Make_List   = "make.list",
	.Call        = "call",
	.Ret         = "ret",
	.Jump        = "jump",
	.Field_Get   = "field.get",
	.Field_Set   = "field.set",
	.Add         = "add",
	.Sub         = "sub",
	.Mul         = "mul",
	.Div         = "div",
	.Halt        = "halt",
}

@(private)
@(rodata)
OPERAND_KIND := #partial [Kind]operand.Kind {
	.Load        = .I64,
	.Load_Local  = .I64,
	.Store       = .I64,
	.Store_Local = .I64,
	.Make_I8     = .I8,
	.Make_I16    = .I32,
	.Make_I32    = .I32,
	.Make_I64    = .I64,
	.Make_F32    = .F32,
	.Make_F64    = .F64,
	.Make_String = .Const,
	.Make_Class  = .Const,
	.Make_Func   = .Label,
	.Make_List   = .I64,
	.Call        = .I64,
	.Jump        = .Label,
	.Field_Get   = .Const,
	.Field_Set   = .Const,
}

Inst :: struct {
	kind:  Kind,
	value: operand.Operand,
}

from_string :: proc(ident: string) -> (Kind, bool) {
	for mnemonic, kind in INSTS {
		if mnemonic == ident {
			return kind, true
		}
	}
	return .None, false
}

to_string :: proc(kind: Kind) -> string {
	return INSTS[kind]
}

has_operand :: proc(kind: Kind) -> bool {
	return expected_operand(kind) != .None
}

expected_operand :: proc(kind: Kind) -> operand.Kind {
	return OPERAND_KIND[kind]
}

make :: proc(kind: Kind = .None, value: operand.Operand = {}) -> Inst {
	return {kind, value}
}
