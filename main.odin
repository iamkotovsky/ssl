package ssl

import as "asm/parser"
import "bytecode"
import "core:fmt"
import "core:os"

main :: proc() {
	source, rerr := os.read_entire_file("source.ssa", context.allocator)
	if rerr != nil {
		fmt.println("failed to read source.ssa")
		return
	}
	defer delete(source)

	m, perr := as.parse(string(source))
	if perr.kind != .None {
		as.print_error(perr)
		return
	}
	defer bytecode.destroy(m)

	bytecode.debug_print(m)
}
