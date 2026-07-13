package vm

import "../bytecode"
import core "../runtime/core"

Frame :: struct {
	module:    ^Module_Instance,
	function:  core.Value,
	ip:        bytecode.Instruction_Index,
	stack_base: int,
}

@(private)
_mark_frame_roots :: proc(frame: ^Frame) {
	assert(frame != nil)
	core.mark(frame.function)
}
