package vm

import core "../runtime/core"
import builtin "../runtime/builtin"

Program :: struct {
	runtime: ^core.Runtime,
	builtins: builtin.Classes,
	modules: Module_Store,
}

init_program :: proc(program: ^Program, runtime: ^core.Runtime) {
	assert(program != nil)
	assert(runtime != nil)
	assert(program.runtime == nil, "program is already initialized")
	program.runtime = runtime
	builtin.init_classes(&program.builtins, runtime)
	_init_module_store(&program.modules)
}

mark_program_roots :: proc(program: ^Program) {
	assert(program != nil)
	assert(program.runtime != nil, "program is not initialized")
	core.mark_runtime_roots(program.runtime)
	builtin.mark_class_roots(&program.builtins)
	_mark_module_store_roots(&program.modules)
}

destroy_program :: proc(program: ^Program) {
	assert(program != nil)
	_destroy_module_store(&program.modules)
	program^ = {}
}
