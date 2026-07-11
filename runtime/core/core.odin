package core

Interface :: struct {
	object:   ^Class,
	extern:   ^Class,
	error:    ^Class,
	slot:     ^Object,
	register: proc(self: ^Interface, value: ^Object),
	push:     proc(self: ^Interface, value: ^Object),
	pop:      proc(self: ^Interface) -> ^Object,
}
