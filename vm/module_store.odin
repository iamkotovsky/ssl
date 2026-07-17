package vm

import "../bytecode"
import core "../runtime/core"
import "core:strings"

Duplicate_Module_Error :: struct {
	name: string,
}

Module_Store_Error :: union {
	Duplicate_Module_Error,
}

Module_Store :: struct {
	modules: map[string]^Module_Instance,
}

add_module :: proc(
	store: ^Module_Store,
	name: string,
	definition: bytecode.Module,
) -> (^Module_Instance, Module_Store_Error) {
	assert(store != nil)
	if _, exists := store.modules[name]; exists {
		return nil, Duplicate_Module_Error{name}
	}

	module := new(Module_Instance)
	module.name = strings.clone(name)
	module.definition = definition
	module.globals = make([]core.Value, definition.globals)
	module.state = .Loaded
	store.modules[module.name] = module
	return module, nil
}

find_module :: proc(store: ^Module_Store, name: string) -> (^Module_Instance, bool) {
	assert(store != nil)
	module, exists := store.modules[name]
	return module, exists
}

@(private)
_init_module_store :: proc(store: ^Module_Store) {
	assert(store != nil)
	store.modules = make(map[string]^Module_Instance)
}

@(private)
_mark_module_store_roots :: proc(store: ^Module_Store) {
	assert(store != nil)
	for _, module in store.modules {
		_mark_module_roots(module)
	}
}

@(private)
_destroy_module_store :: proc(store: ^Module_Store) {
	assert(store != nil)
	for _, module in store.modules {
		_destroy_module(module)
	}
	delete(store.modules)
	store^ = {}
}
