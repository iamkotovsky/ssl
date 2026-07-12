package ssl

import asm_parser "asm/parser"
import "asm/module"
import "core:fmt"
import "core:os"

main :: proc() {
	source, ok := os.read_entire_file("source.ssa")
	if !ok {
		fmt.println("failed to read source.ssa")
		return
	}
	defer delete(source)

	m, err := asm_parser.parse(string(source))
	if err.kind != .None {
		asm_parser.print_error(err)
		return
	}
	defer module.destroy(m)

	module.debug_print(m)
}
