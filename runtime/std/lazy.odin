package core

Lazy_Load :: proc(stdi: ^Interface) -> ^Value

Lazy :: struct {
	using _: Value,
	load: Lazy_Load,
	target: ^Value,
}

new_lazy :: proc(stdi: ^Interface, load: Lazy_Load) -> ^Lazy {
	instance := new(Lazy)
	stdi.register(stdi, instance)
	instance.load = load
	instance.target = nil
	return instance
}