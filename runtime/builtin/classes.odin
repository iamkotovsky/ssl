package runtime_builtin

import core "../core"

Classes :: struct {
	function:        ^core.Class,
	native_function: ^core.Class,
}

init_classes :: proc(classes: ^Classes, runtime: ^core.Runtime) {
	assert(classes != nil)
	assert(runtime != nil)
	assert(runtime.classes.class != nil, "runtime is not initialized")
	assert(classes.function == nil, "builtin classes are already initialized")

	classes.function = core.alloc(&runtime.heap, core.Class)
	core.init_class(
		classes.function,
		runtime.classes.class,
		"Function",
		runtime.classes.object,
	)

	classes.native_function = core.alloc(&runtime.heap, core.Class)
	core.init_class(
		classes.native_function,
		runtime.classes.class,
		"Native_Function",
		runtime.classes.object,
	)
}

mark_class_roots :: proc(classes: ^Classes) {
	assert(classes != nil)
	core.mark(classes.function)
	core.mark(classes.native_function)
}
