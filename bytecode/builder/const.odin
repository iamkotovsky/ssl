package builder

import "core:strings"

@(private)
Const_Id :: distinct u32

@(private)
Utf8_Proto :: distinct string

@(private)
Const_Proto :: union {
	Utf8_Proto,
}

@(private)
Const :: struct {
	module: ^Module,
	id:     Const_Id,
}

Utf8 :: distinct Const

const_utf8 :: proc(module: ^Module, value: string) -> Utf8 {
	assert(module != nil)
	_assert_const_capacity(module)
	id := Const_Id(len(module.consts))
	append(&module.consts, Utf8_Proto(strings.clone(value)))
	return Utf8(Const{module, id})
}

@(private)
_destroy_const :: proc(const: ^Const_Proto) {
	switch v in const {
	case Utf8_Proto:
		delete(string(v))
	}
}

@(private)
_assert_utf8 :: proc(value: Utf8) {
	const := Const(value)
	assert(const.module != nil, "bytecode builder UTF-8 constant has no module")
	assert(int(const.id) < len(const.module.consts), "bytecode builder constant ID out of bounds")
	_, ok := const.module.consts[int(const.id)].(Utf8_Proto)
	assert(ok, "bytecode builder constant is not UTF-8")
}
