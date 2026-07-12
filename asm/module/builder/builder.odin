package builder

import "../const"
import "../inst"
import "../inst/operand"
import module ".."

Builder :: struct {
	consts:       [dynamic]const.Const,
	insts:        [dynamic]inst.Inst,
	debug_labels: [dynamic]module.Debug_Label,
}

write_const :: proc(b: ^Builder, const: const.Const) -> int {
	i := len(b.consts)
	append(&b.consts, const)
	return i
}

write_inst :: proc(b: ^Builder, kind: inst.Kind, value: operand.Operand = {}) {
	append(&b.insts, inst.make(kind, value))
}

write_debug_label :: proc(b: ^Builder, name: int, inst: int) {
	append(&b.debug_labels, module.Debug_Label{name = name, inst = inst})
}

build :: proc(b: ^Builder) -> module.Module {
	return {
		consts = b.consts[:],
		insts  = b.insts[:],
		debug  = {
			labels = b.debug_labels[:],
		},
	}
}
