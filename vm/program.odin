package vm

import core "../runtime/core"

Program :: struct {
	runtime: ^core.Runtime,
	modules: Module_Store,
}

init_program :: proc(program: ^Program, runtime: ^core.Runtime) {
	assert(program != nil)
	assert(runtime != nil)
	assert(program.runtime == nil, "program is already initialized")
	program.runtime = runtime
	_init_module_store(&program.modules)
}

mark_program_roots :: proc(program: ^Program) {
	assert(program != nil)
	assert(program.runtime != nil, "program is not initialized")
	core.mark_runtime_roots(program.runtime)
	_mark_module_store_roots(&program.modules)
}

destroy_program :: proc(program: ^Program) {
	assert(program != nil)
	_destroy_module_store(&program.modules)
	program^ = {}
}
