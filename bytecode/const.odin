package bytecode

import "core:strings"

Const_Idx :: distinct u32

Const_Kind :: enum u8 {
	Utf8,
}

Const :: struct {
	kind: Const_Kind,
	using _: struct #raw_union {
		as_utf8: string,
	},
}

make_utf8 :: proc(value: string) -> Const {
	return {kind = .Utf8, as_utf8 = strings.clone(value)}
}

@(private)
_destroy_const :: proc(const: Const) {
	switch const.kind {
	case .Utf8:
		delete(const.as_utf8)
	}
}
