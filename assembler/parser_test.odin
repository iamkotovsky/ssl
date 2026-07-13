package assembler

import "../bytecode"
import "core:testing"

@(test)
trailing_label_returns_error :: proc(t: ^testing.T) {
	module, err := parse("halt\n.end\n")
	defer bytecode.destroy(module)

	testing.expect(t, err.kind == .Build_Failed)
}

@(test)
referenced_trailing_label_returns_error :: proc(t: ^testing.T) {
	module, err := parse("jump .end\n.end\n")
	defer bytecode.destroy(module)

	testing.expect(t, err.kind == .Build_Failed)
}

@(test)
global_operands_use_names :: proc(t: ^testing.T) {
	module, err := parse("load.global \"answer\"\nstore.global \"answer\"\n")
	defer bytecode.destroy(module)

	testing.expect(t, err.kind == .None)
	testing.expect(t, len(module.instructions) == 2)
	testing.expect(t, module.instructions[0].operand.kind == .Constant)
	testing.expect(t, module.instructions[1].operand.kind == .Constant)
}
