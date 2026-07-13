package core

import "core:strings"

Class_Flag :: enum {
	Sealed,
	Frozen,
	Final,
}

Class_Flags :: bit_set[Class_Flag]

Final_Superclass_Error :: struct {
	superclass: ^Class,
}

Class_Error :: union {
	Final_Superclass_Error,
}

Class :: struct {
	using object:       Object,
	name:               string,
	superclass:         ^Class,
	methods:            map[string]Binding,
	class_flags:        Class_Flags,
}

init_class :: proc(
	class: ^Class,
	metaclass: ^Class,
	name: string,
	superclass: ^Class,
) {
	assert(class != nil)
	assert(class.descriptor.destroy != nil, "class must be allocated by core.alloc")
	init_object(class, metaclass)
	class.descriptor = {
		mark    = _class_mark,
		destroy = _class_destroy,
	}
	class.name = strings.clone(name)
	class.superclass = superclass
	class.methods = make(map[string]Binding)
}

new_class :: proc(
	runtime: ^Runtime,
	name: string,
	superclass: ^Class = nil,
) -> (^Class, Class_Error) {
	assert(runtime != nil)
	assert(runtime.classes.class != nil, "runtime is not initialized")
	assert(runtime.classes.object != nil, "runtime is not initialized")

	parent := superclass
	if parent == nil {
		parent = runtime.classes.object
	}
	if .Final in parent.class_flags {
		return nil, Final_Superclass_Error{parent}
	}

	class := alloc(&runtime.heap, Class)
	init_class(class, runtime.classes.class, name, parent)
	return class, nil
}

define_method :: proc(
	class: ^Class,
	name: string,
	method: Value,
	flags: Binding_Flags = {},
) -> Binding_Error {
	assert(class != nil)
	if .Frozen in class.class_flags {
		return Frozen_Class_Error{}
	}

	if current, exists := class.methods[name]; exists {
		if .Read_Only in current.flags {
			return Read_Only_Binding_Error{name}
		}
		class.methods[name] = {method, flags}
		return nil
	}

	if .Sealed in class.class_flags {
		return Sealed_Class_Error{}
	}

	class.methods[strings.clone(name)] = {method, flags}
	return nil
}

lookup_method :: proc(class: ^Class, name: string) -> (Binding, bool) {
	for current := class; current != nil; current = current.superclass {
		if binding, exists := current.methods[name]; exists {
			return binding, true
		}
	}
	return {}, false
}

lookup_member :: proc(object: Value, name: string) -> (Binding, bool) {
	assert(object != nil)
	if binding, exists := lookup_field(object, name); exists {
		return binding, true
	}
	return lookup_method(object.class, name)
}

seal_class :: proc(class: ^Class) {
	assert(class != nil)
	class.class_flags |= {.Sealed}
}

freeze_class :: proc(class: ^Class) {
	assert(class != nil)
	class.class_flags |= {.Sealed, .Frozen}
	freeze_object(class)
}

finalize_class :: proc(class: ^Class) {
	assert(class != nil)
	class.class_flags |= {.Final}
}

@(private)
_class_mark :: proc(value: Value) {
	class := cast(^Class)value
	_object_mark(value)
	mark(class.superclass)
	for _, binding in class.methods {
		mark(binding.value)
	}
}

@(private)
_class_destroy :: proc(value: Value) {
	class := cast(^Class)value
	_destroy_fields(&class.fields)
	for name in class.methods {
		delete(name)
	}
	delete(class.methods)
	delete(class.name)
	free(class)
}
