package ssl

import "core:fmt"
import "core:os"

Heap_Header :: struct {
	marked: bool,
	next: 	^Heap_Header
}

Heap :: struct {
	start: ^Heap_Header,
	count: int
}

alloc :: proc(heap: ^Heap, $T: typeid) -> ^T {
	object := new(T)
	object.next = heap.start
	heap.start = object
	heap.count += 1
	return object
}

Object :: struct {
	using header: Heap_Header,
}

main :: proc() {
	heap: Heap
	obj := alloc(&heap, Object)
	
}
