package core

Extern_Proc :: proc(stdi: ^Interface, args: int)

Extern :: struct {
	using _: Object,
	procedure: Extern_Proc
}

new_extern :: proc(stdi: ^Interface, procedure: Extern_Proc) -> ^Extern {
	instance := cast(^Extern) alloc(stdi, stdi.function, new(Extern))
	instance.call = auto_cast _extern_call
	instance.procedure = procedure
	return instance
}

@(private)
_extern_call :: proc(stdi: ^Interface, self: ^Extern, args: int) {
	self.procedure(stdi, args)
}

Method :: struct {
	using _: Object,
	target: ^Object,
	function: ^Object, 
}

new_method :: proc(stdi: ^Interface, target: ^Object, function: ^Object) -> ^Method {
	instance := cast(^Method) alloc(stdi, stdi.function, new(Method))
	instance.call = auto_cast _method_call
	instance.function = function
	instance.target = target
	return instance
}

@(private)
_method_call :: proc(stdi: ^Interface, self: ^Method, args: int) {
	stdi.push(stdi, self.target)
	call(stdi, self.function, args+1)
}

@(private)
_method_mark :: proc(self: ^Method) {
	_object_mark(self)
	mark(self.target)
	mark(self.function)
}