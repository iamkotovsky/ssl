package core

import "../value"


new_extern :: proc(vm: ^VM, func: value.Call_Proc) -> ^Object {
	self := class_instance(vm.base_class)
	self.vt.call = func
	return self
}
