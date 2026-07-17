package vm

import "../bytecode"
import core "../runtime/core"

Module_State :: enum {
	None,
	Loading,
	Loaded,
	Initializing,
	Initialized,
	Failed,
}

Module_Instance :: struct {
	name:       string,
	definition: bytecode.Module,
	globals:    []core.Value,
	state:      Module_State,
}

@(private)
_mark_module_roots :: proc(module: ^Module_Instance) {
	assert(module != nil)
	for value in module.globals {
		core.mark(value)
	}
}

@(private)
_destroy_module :: proc(module: ^Module_Instance) {
	assert(module != nil)
	bytecode.destroy(&module.definition)
	delete(module.globals)
	delete(module.name)
	free(module)
}
