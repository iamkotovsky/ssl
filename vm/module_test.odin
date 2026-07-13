package vm

import "core:testing"

@(test)
module_globals_are_name_addressed :: proc(t: ^testing.T) {
	store: Module_Store
	_init_module_store(&store)
	defer _destroy_module_store(&store)

	module, err := add_module(&store, "test", {})
	testing.expect(t, err == nil)

	set_global(module, "answer", nil)
	value, exists := find_global(module, "answer")
	testing.expect(t, exists)
	testing.expect(t, value == nil)
}
