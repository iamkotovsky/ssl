package core

import "core:strings"

Object_Flag :: enum {
	Frozen,
}

Object_Flags :: bit_set[Object_Flag]

Call_Proc :: proc(ctx: ^Context, value: Value) -> Error
Add_Proc :: proc(ctx: ^Context, lhs, rhs: Value) -> Error

Object :: struct {
	using header: Heap_Header,
	call:         Call_Proc,
	add:          Add_Proc,
	class:        ^Class,
	fields:       map[string]Binding,
	flags:        Object_Flags,
}

Value :: ^Object

init_object :: proc(
	object: Value,
	class: ^Class,
) {
	assert(object != nil)
	assert(object.destroy != nil, "object must be allocated by core.alloc")
	object.class = class
}

// Stack effect: ... -> ... object.
new_object :: proc(ctx: ^Context, class: ^Class) {
	_assert_context(ctx)
	assert(class != nil)
	object := _new_object(ctx.runtime, class)
	push(ctx, object)
}

@(private)
_new_object :: proc(runtime: ^Runtime, class: ^Class) -> Value {
	object := alloc(&runtime.heap, Object)
	init_object(object, class)
	return object
}

define_field :: proc(
	object: Value,
	name: string,
	value: Value,
	flags: Binding_Flags = {},
) -> Error {
	assert(object != nil)
	if .Frozen in object.flags {
		return Frozen_Object_Error{}
	}

	if current, exists := object.fields[name]; exists {
		if .Read_Only in current.flags {
			return Read_Only_Binding_Error{name}
		}
		object.fields[name] = {value, flags}
		return nil
	}

	object.fields[strings.clone(name)] = {value, flags}
	return nil
}

lookup_field :: proc(object: Value, name: string) -> (Binding, bool) {
	assert(object != nil)
	binding, exists := object.fields[name]
	return binding, exists
}

freeze_object :: proc(object: Value) {
	assert(object != nil)
	object.flags |= {.Frozen}
}

@(private)
_init_object :: proc(object: Value) {
	object.mark = _object_mark
	object.destroy = _object_destroy
	object.fields = make(map[string]Binding)
}

@(private)
_object_mark :: proc(value: Value) {
	mark(value.class)
	for _, binding in value.fields {
		mark(binding.value)
	}
}

@(private)
_destroy_fields :: proc(fields: ^map[string]Binding) {
	for name in fields^ {
		delete(name)
	}
	delete(fields^)
	fields^ = nil
}

@(private)
_object_destroy :: proc(value: Value) {
	_destroy_fields(&value.fields)
	free(value)
}
