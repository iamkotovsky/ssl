package core

import "../value"
import "core:fmt"
import "core:io"

Object :: struct {
	using _: value.Value,
	vm:      ^VM,
	type:    ^Class,
	parent:  ^Object,
	methods: map[string]^value.Value,
	fields:  map[string]^value.Value,
	frozen:  bool,
}

@(private)
_object_init :: proc(self: ^Object, vm: ^VM) {
	self.vt.field_get = auto_cast _object_field_get
	self.vt.repr = auto_cast _object_repr
	self.vt.mark = auto_cast _object_mark
	self.vt.destroy = auto_cast _object_destroy

	self.vm = vm
	self.methods = make(map[string]^value.Value)
	self.fields = make(map[string]^value.Value)
	self.frozen = true

	self.next = vm.last_value
	vm.last_value = self
}

@(private)
_object_field_get :: proc(self: ^Object, key: string) -> ^value.Value {
	value: ^value.Value
	exists: bool

	value, exists = self.fields[key]
	if exists {
		return value
	}

	value, exists = self.methods[key]
	if exists {
		return value
	}

	if self.parent != nil {
		return _object_field_get(self.parent, key)
	}

	unreachable()
}

@(private)
_object_repr :: proc(self: ^Object, w: io.Writer) {
	if repr, exists := self.methods["__repr"]; exists {
		vm_push(self.vm, self)
		value.call(repr, 1)
	} else {
		fmt.wprintf(w, "<%s %p>", self.type.name, self)
	}
}

@(private)
_object_mark :: proc(self: ^Object) {
	value.mark(self.parent)
	value.mark(self.type)
	for _, v in self.fields {
		value.mark(v)
	}
	for _, v in self.methods {
		value.mark(v)
	}
}

@(private)
_object_destroy :: proc(self: ^Object) {
	delete(self.methods)
	delete(self.fields)
}
