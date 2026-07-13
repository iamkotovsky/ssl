package vm

import core "../runtime/core"

VM :: struct {
	program: ^Program,
	stack:   [dynamic]core.Value,
	frames:  [dynamic]Frame,
}

init_vm :: proc(vm: ^VM, program: ^Program) {
	assert(vm != nil)
	assert(program != nil)
	assert(program.runtime != nil, "program is not initialized")
	assert(vm.program == nil, "VM is already initialized")
	vm.program = program
}

mark_vm_roots :: proc(vm: ^VM) {
	assert(vm != nil)
	assert(vm.program != nil, "VM is not initialized")
	mark_program_roots(vm.program)
	for value in vm.stack {
		core.mark(value)
	}
	for &frame in vm.frames {
		_mark_frame_roots(&frame)
	}
}

destroy_vm :: proc(vm: ^VM) {
	assert(vm != nil)
	delete(vm.stack)
	delete(vm.frames)
	vm^ = {}
}
