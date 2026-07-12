package const

import "core:strings"

Kind :: enum {
	String,
}

Const :: struct {
	kind:    Kind,
	using _: struct #raw_union {
		as_string: string,
	},
}

make :: proc {
	make_string,
}

destroy :: proc(const: Const) {
	if const.kind == .String {
		delete(const.as_string)
	}
}

make_string :: proc(value: string) -> Const {
	return {kind = .String, as_string = strings.clone(value)}
}
