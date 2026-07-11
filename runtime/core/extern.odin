package core

new_extern :: proc(stdi: ^Interface, function: proc(stdi: ^Interface, self: ^Object, args: int)) -> ^Object {
	instance := alloc(stdi, stdi.extern)
	instance.call = function
	return instance
}
