package core

Class :: struct {
	using _:       Object,
	name:          string,
	proto_fields:  map[string]^Object,
	proto_methods: map[string]^Object,
}

new_class :: proc(stdi: ^Interface, name: string, parent: ^Class = nil) -> ^Class {
	self := cast(^Class) alloc(stdi, stdi.object, new(Class))
	self.destroy = auto_cast _class_destroy

	self.name = name
	self.proto_fields = make(map[string]^Object)
	self.proto_methods = make(map[string]^Object)
	
	if parent != nil {	
		self.parent = parent
		self.fields["__parent"] = parent
	}
	
	return self
}

alloc :: proc(stdi: ^Interface, self: ^Class, instance: ^Object = nil) -> ^Object {
	instance := instance
	if instance == nil {
		instance = new(Object)
	}
	_init_object(instance)
	stdi.register(stdi, instance)
	for k, v in self.proto_fields {
		instance.fields[k] = v
	}
	for k, v in self.proto_methods {
		instance.methods[k] = v
	}
	instance.class = self
	instance.fields["__class"] = self
	if self.parent != nil {
		parent := alloc(stdi, auto_cast self.parent)
		instance.parent = parent
		instance.fields["__parent"] = parent
	}
	return instance
}

@(private)
_class_call :: proc(self: ^Class) {
	_object_destroy(self)
	delete(self.proto_fields)
	delete(self.proto_methods)
}

@(private)
_class_destroy :: proc(self: ^Class) {
	_object_destroy(self)
	delete(self.proto_fields)
	delete(self.proto_methods)
}