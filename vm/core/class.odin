package core

import "../value"
import "core:fmt"
import "core:io"

Class :: struct {
	using _:       Object,
	name:          string,
	proto_fields:  map[string]^Object,
	proto_methods: map[string]^Object,
}

new_class :: proc(vm: ^VM, name: string, parent: ^Class = nil) -> ^Class {
	self := new(Class)
	_object_init(self, vm)
	self.vt.call = auto_cast _class_call
	self.vt.repr = auto_cast _class_repr
	self.name = name
	self.parent = parent
	self.type = vm.base_class
	self.fields["__type"] = vm.base_class
	return self
}

@(private)
_class_call :: proc(self: ^Class, args: int) -> ^value.Value {
	instance := class_instance(self)
	_class_init(self, instance, args)
	return instance
}

@(private)
_class_repr :: proc(self: ^Class, w: io.Writer) {
	fmt.wprintf(w, "<class %s>", self.name)
}

class_instance :: proc(self: ^Class) -> ^Object {
	instance := new(Object)
	_object_init(instance, self.vm)
	instance.type = self
	instance.fields["__type"] = instance.type
	if self.parent != nil {
		instance.parent = class_instance(auto_cast self.parent)
		instance.fields["__parent"] = instance.parent
	}
	return instance
}

@(private)
_class_init :: proc(self: ^Class, object: ^Object, args: int) {
	for k, v in self.proto_fields {
		object.fields[k] = v
	}
	for k, v in self.proto_methods {
		object.methods[k] = v
	}
	__init, exists := object.methods["__init"]
	if !exists {
		return
	}
	vm_push(self.vm, object)
	self.frozen = false
	value.call(__init, args + 1)
	self.frozen = true
}
