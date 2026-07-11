package core

Object :: struct {
	using _: Value,
	call:    proc(stdi: ^Interface, self: ^Object, args: int),
	class:   ^Object,
	parent:  ^Object,
	fields:  map[string]^Object,
	methods: map[string]^Object,
	frozen:  bool,
}

_init_object :: proc(self: ^Object) {
	self.call = auto_cast _object_call
	self.mark = auto_cast _object_mark
	self.destroy = auto_cast _object_destroy
	self.fields = make(map[string]^Object)
	self.methods = make(map[string]^Object)
	self.frozen = true
}

init :: proc(stdi: ^Interface, self: ^Object) {
	__init, exists := self.methods["__init"]
	if !exists {
		return
	}
	stdi.push(stdi, self)
	self.frozen = false
	call(stdi, __init, 1)
	self.frozen = true
}

call :: proc(stdi: ^Interface, self: ^Object, args: int) {
	self.call(stdi, self, args)
}

@(private)
_object_call :: proc(stdi: ^Interface, self: ^Object, args: int) {
	__call, exists := self.methods["__call"]
	if !exists {
		stdi.slot = new_error(stdi, .No_Meta_Call)
		return
	}
	stdi.push(stdi, self)
	call(stdi, __call, args + 1)
}

@(private)
_object_mark :: proc(self: ^Object) {
	for _, v in self.fields {
		mark(v)
	}
	for _, v in self.methods {
		mark(v)
	}
}

@(private)
_object_destroy :: proc(self: ^Object) {
	delete(self.fields)
	delete(self.methods)
}
