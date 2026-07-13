package core

Core_Classes :: struct {
	object: ^Class,
	class:  ^Class,
}

Runtime :: struct {
	heap:    Heap,
	classes: Core_Classes,
}

init_runtime :: proc(runtime: ^Runtime) {
	assert(runtime != nil)
	assert(runtime.heap.first == nil, "runtime is already initialized")
	assert(runtime.classes.object == nil, "runtime is already initialized")
	assert(runtime.classes.class == nil, "runtime is already initialized")

	class_class := alloc(&runtime.heap, Class)
	object_class := alloc(&runtime.heap, Class)

	init_class(object_class, class_class, "Object", nil)
	init_class(class_class, class_class, "Class", object_class)

	runtime.classes = {
		object = object_class,
		class  = class_class,
	}
}

mark_runtime_roots :: proc(runtime: ^Runtime) {
	assert(runtime != nil)
	mark(runtime.classes.object)
	mark(runtime.classes.class)
}

destroy_runtime :: proc(runtime: ^Runtime) {
	assert(runtime != nil)
	destroy_heap(&runtime.heap)
	runtime^ = {}
}
