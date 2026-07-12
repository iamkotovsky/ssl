package core

import "core:fmt"

Value :: struct {
	call:    proc(stdi: ^Interface, self: ^Value, args: []^Value) -> ^Value,
	
	mark:    proc(self: ^Value),
	destroy: proc(self: ^Value),
	
	marked:  bool,
	next:    ^Value,
}

mark :: proc(self: ^Value) {
	if self.marked {
		return
	}
	self.marked = true
	if self.mark != nil {
		self.mark(self)
	}
}
sweep :: proc(self: ^Value) {
	prev: ^Value
	next := self
	for next != nil {
		prev = next
		n := next.next
		if !next.marked {
			prev.next = n
			destroy(next)
		} else {
			next.marked = false
		}
		next = n
	}
}
destroy :: proc(self: ^Value) {
	fmt.printfln("[INFO] <value %p> destroyed", self)
	if self.destroy != nil {
		self.destroy(self)
	}
	free(self)
}

