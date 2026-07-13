package bytecode

import "core:strings"

Constant_Kind :: enum {
	String,
}

Constant :: struct {
	kind:    Constant_Kind,
	using _: struct #raw_union {
		as_string: string,
	},
}

@(private)
_destroy_constant :: proc(constant: Constant) {
	if constant.kind == .String {
		delete(constant.as_string)
	}
}

@(private)
_make_string_constant :: proc(value: string) -> Constant {
	return {kind = .String, as_string = strings.clone(value)}
}
