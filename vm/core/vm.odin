package core

import "../value"

VM_State :: enum {
	None,
	Return,
	Error,
}

VM_Error :: struct {}

VM :: struct {
	stack:      [dynamic]^value.Value,
	last_value: ^value.Value,
	
	base_class: ^Class,
	extern_class: ^Class,
}

new_vm :: proc() -> ^VM {
	vm := new(VM)
	_init_vm(vm)
	return vm
}
@(private)
_init_vm :: proc(vm: ^VM) {
	cls := new_class(vm, "type")
	cls.type = cls
	cls.fields["__type"] = cls

	vm.base_class = cls
	vm.extern_class = new_class(vm, "extern")
}
destroy_vm :: proc(vm: ^VM) {
	value.sweep(vm.last_value)
	delete(vm.stack)
	free(vm)
}

vm_gc :: proc(vm: ^VM) {
	for v in vm.stack {
		value.mark(v)
	}
	value.sweep(vm.last_value)
}
vm_push :: proc(vm: ^VM, value: ^value.Value) {
	append(&vm.stack, value)
	vm_gc(vm)
}
vm_pop :: proc(vm: ^VM) -> ^value.Value {
	return pop(&vm.stack)
}
