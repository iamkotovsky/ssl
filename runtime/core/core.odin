package core

State :: enum {
	None,
	Error,
	Return,
	Continue,
	Break,
}

Interface :: struct {
	state:    State,
	type:     ^Class,
	function: ^Class,
	error:    ^Class,
	slot:     ^Value,
	pause:    proc(self: ^Interface),
	resume:   proc(self: ^Interface),
	register: proc(self: ^Interface, value: ^Value),
	push:     proc(self: ^Interface, value: ^Value),
	pop:      proc(self: ^Interface) -> ^Value,
	at:       proc(self: ^Interface, i: int) -> ^Value,
}

call :: proc(stdi: ^Interface, value: ^Value, args: int) {
	values := make([]^Value, args)
	defer delete(values)
	for i in 0..<args {
		values[i] = stdi->at(i)
	}
	result := value.call(stdi, value, values)
	if stdi.state != .None {
		return
	}
	stdi.state = .Return
	stdi.slot = result
}
