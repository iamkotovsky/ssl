package vm

import "../bytecode"
import core "../runtime/core"
import "core:strings"

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
	globals:    map[string]core.Value,
	state:      Module_State,
}

set_global :: proc(module: ^Module_Instance, name: string, value: core.Value) {
	assert(module != nil)
	assert(module.state != .None, "module is not initialized")

	if _, exists := module.globals[name]; exists {
		module.globals[name] = value
		return
	}
	module.globals[strings.clone(name)] = value
}

find_global :: proc(module: ^Module_Instance, name: string) -> (core.Value, bool) {
	assert(module != nil)
	value, exists := module.globals[name]
	return value, exists
}

@(private)
_mark_module_roots :: proc(module: ^Module_Instance) {
	assert(module != nil)
	for _, value in module.globals {
		core.mark(value)
	}
}

@(private)
_destroy_module :: proc(module: ^Module_Instance) {
	assert(module != nil)
	bytecode.destroy(module.definition)
	for name in module.globals {
		delete(name)
	}
	delete(module.globals)
	delete(module.name)
	free(module)
}
