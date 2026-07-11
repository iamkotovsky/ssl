package core

import "core:fmt"
import "core:io"

// Get_Proc :: proc(stdi: ^Interface, self: ^Value, key: string) -> ^Value
// Set_Proc :: proc(stdi: ^Interface, self: ^Value, key: string, value: ^Value)
// Call_Proc :: proc(stdi: ^Interface, self: ^Value, args: int) -> ^Value
// Mark_Proc :: proc(stdi: ^Interface, self: ^Value)
// Destroy_Proc :: proc(stdi: ^Interface, self: ^Value)
// Repr_Proc :: proc(stdi: ^Interface, self: ^Value, w: io.Stream)

Value :: struct {
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
