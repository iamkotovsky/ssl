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
_destroy_const :: proc(value: Const) {
	switch value.kind {
	case .Utf8:
		delete(value.as_utf8)
	}
}
