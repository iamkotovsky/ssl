package module

import "const"
import "inst"

Debug_Info :: struct {
	labels: []Debug_Label,
}

Debug_Label :: struct {
	name: int,
	inst: int,
}

Module :: struct {
	consts: []const.Const,
	insts:  []inst.Inst,
	debug:  Debug_Info,
}

destroy :: proc(m: Module) {
	for c in m.consts {
		const.destroy(c)
	}
	delete(m.consts)
	delete(m.insts)
	delete(m.debug.labels)
}
