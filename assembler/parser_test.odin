package assembler

import "../bytecode"
import "core:testing"

@(test)
trailing_label_returns_error :: proc(t: ^testing.T) {
	module, err := parse("halt\n.end\n")
	defer bytecode.destroy(&module)

	testing.expect(t, err.kind == .Build_Failed)
}

@(test)
referenced_trailing_label_returns_error :: proc(t: ^testing.T) {
	module, err := parse("jump .end\n.end\n")
	defer bytecode.destroy(&module)

	testing.expect(t, err.kind == .Build_Failed)
}

@(test)
global_operands_use_indices :: proc(t: ^testing.T) {
	module, err := parse("load.global 0\nstore.global 0\n")
	defer bytecode.destroy(&module)

	testing.expect(t, err.kind == .None)
	testing.expect(t, len(module.functions) == 1)
	instructions := module.functions[int(module.init)].insts
	testing.expect(t, len(instructions) == 2)
	testing.expect(t, instructions[0].operand.kind == .Global)
	testing.expect(t, instructions[1].operand.kind == .Global)
}
