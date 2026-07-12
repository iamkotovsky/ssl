package core

Object :: struct {
	using _: Value,
	class:   ^Object,
	parent:  ^Object,
	fields:  map[string]^Object,
	frozen:  bool,
}

_init_object :: proc(self: ^Object) {
	self.call = auto_cast _object_call
	self.mark = auto_cast _object_mark
	self.destroy = auto_cast _object_destroy
	self.fields = make(map[string]^Object)
	self.frozen = true
}

init :: proc(stdi: ^Interface, self: ^Object, args: int) {
	__init, exists := self.fields["__init"]
	if !exists {
		return
	}
	stdi.push(stdi, self)
	self.frozen = false
	call(stdi, __init, args + 1)
	self.frozen = true
}

@(private)
_object_call :: proc(stdi: ^Interface, self: ^Object, args: int) {
	__call, exists := self.fields["__call"]
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
}

@(private)
_object_destroy :: proc(self: ^Object) {
	delete(self.fields)
}
