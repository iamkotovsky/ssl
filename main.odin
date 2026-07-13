package ssl

import "assembler"
import "bytecode"
import "core:fmt"
import "core:os"

main :: proc() {
	file_name := "source.sa"
	source, read_error := os.read_entire_file(file_name, context.allocator)
	if read_error != nil {
		fmt.printfln("failed to read %s", file_name)
		return
	}
	defer delete(source)

	m, parse_error := assembler.parse(string(source))
	if parse_error.kind != .None {
		assembler.print_error(parse_error, file_name)
		return
	}
	defer bytecode.destroy(m)

	bytecode.print(m)
}
