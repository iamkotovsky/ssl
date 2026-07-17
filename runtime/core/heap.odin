package core

Mark_Proc :: proc(value: ^Heap_Header)
Destroy_Proc :: proc(value: ^Heap_Header)

Heap_Header :: struct {
	mark:    Mark_Proc,
	destroy: Destroy_Proc,
	next:    ^Heap_Header,
	marked:  bool,
}

Heap :: struct {
	first: ^Heap_Header,
	count: int,
}

alloc :: proc(heap: ^Heap, $T: typeid) -> ^T {
	assert(heap != nil)

	value := new(T)
	object := cast(Value)value
	_init_object(object)
	object.next = heap.first
	heap.first = &object.header
	heap.count += 1

	return value
}

mark :: proc(value: Value) {
	if value == nil || value.marked {
		return
	}

	value.marked = true
	if value.mark != nil {
		value.mark(value)
	}
}

sweep :: proc(heap: ^Heap) {
	assert(heap != nil)

	link := &heap.first
	for link^ != nil {
		header := link^
		if header.marked {
			header.marked = false
			link = &header.next
			continue
		}

		link^ = header.next
		heap.count -= 1
		_destroy_header(header)
	}
}

destroy_heap :: proc(heap: ^Heap) {
	assert(heap != nil)

	header := heap.first
	for header != nil {
		next := header.next
		_destroy_header(header)
		header = next
	}
	heap^ = {}
}

@(private)
_destroy_header :: proc(header: ^Heap_Header) {
	assert(header != nil)
	assert(header.destroy != nil)
	header.destroy(header)
}
