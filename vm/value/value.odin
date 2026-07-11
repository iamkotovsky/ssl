package value

import "core:fmt"
import "core:io"

Field_Get_Proc :: proc(self: ^Value, key: string) -> ^Value
Field_Set_Proc :: proc(self: ^Value, key: string, value: ^Value)
Index_Get_Proc :: proc(self: ^Value, key: ^Value) -> ^Value
Index_Set_Proc :: proc(self: ^Value, key: ^Value, value: ^Value)
Call_Proc :: proc(self: ^Value, args: int) -> ^Value
Mark_Proc :: proc(self: ^Value)
Destroy_Proc :: proc(self: ^Value)
Repr_Proc :: proc(self: ^Value, w: io.Stream)

Value :: struct {
	vt:     struct {
		field_get: Field_Get_Proc,
		field_set: Field_Set_Proc,
		index_get: Index_Get_Proc,
		index_set: Index_Set_Proc,
		call:      Call_Proc,
		mark:      Mark_Proc,
		destroy:   Destroy_Proc,
		repr:      Repr_Proc,
	},
	marked: bool,
	next:   ^Value,
}

get_field :: proc(self: ^Value, key: string) -> ^Value {
	if self.vt.field_get != nil {
		return self.vt.field_get(self, key)
	} else {
		unreachable()
	}
}
call :: proc(self: ^Value, args: int) -> ^Value {
	if self.vt.call != nil {
		return self.vt.call(self, args)
	} else {
		unreachable()
	}
}
mark :: proc(self: ^Value) {
	if self.marked {
		return
	}
	self.marked = true
	if self.vt.mark != nil {
		self.vt.mark(self)
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
	fmt.printfln("destroyed %p", self)
	if self.vt.destroy != nil {
		self.vt.destroy(self)
	}
	free(self)
}
repr :: proc(self: ^Value, w: io.Stream) {
	if self.vt.repr != nil {
		self.vt.repr(self, w)
	} else {
		fmt.wprintf(w, "<value %p>", self)
	}
}
