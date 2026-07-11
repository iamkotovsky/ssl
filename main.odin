package ssl

import "core:os"
import "core:fmt"
import vc "vm/core"
import val "vm/value"

main :: proc() {
	out := os.stream_from_handle(os.stdout)

	vm := vc.new_vm()
	defer vc.destroy_vm(vm)

	cls := vc.new_class(vm, "string")
	val.repr(cls, out)
	fmt.println()

	s := vc.class_instance(cls)
	val.repr(s, out)
	fmt.println()
}
