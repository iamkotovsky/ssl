package builder

import "core:strings"

Const_Id :: distinct u32

Utf8_Proto :: distinct string

Const_Proto :: union {
	Utf8_Proto,
}

Const :: struct {
	module: ^Module,
	id:     Const_Id,
}

Utf8 :: distinct Const

const_utf8 :: proc(module: ^Module, value: string) -> Utf8 {
	assert(module != nil)
	const := _append_const(module, Utf8_Proto(strings.clone(value)))
	return Utf8(const)
}

@(private)
_append_const :: proc(module: ^Module, const: Const_Proto) -> Const {
	assert(len(module.consts) < int(max(u32)), "bytecode builder constant ID overflow")
	id := Const_Id(len(module.consts))
	append(&module.consts, const)
	return {module, id}
}

@(private)
_destroy_const :: proc(const: ^Const_Proto) {
	switch v in const {
	case Utf8_Proto:
		delete(string(v))
	}
}
