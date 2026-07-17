package builder

import bytecode ".."
import "core:testing"

@(test)
finish_builds_module :: proc(t: ^testing.T) {
	builder: Module
	defer destroy(&builder)

	start := export(&builder, "__start")
	value := global(&builder, "value")
	hello := const_utf8(&builder, "hello")

	main := function(&builder, ".__start")
	parameter := param(main, "parameter")
	temporary := local(main, "temporary")
	target := function(&builder, ".target")
	done := label(main, ".done")

	load(main, parameter)
	store(main, temporary)
	load(main, temporary)
	load(main, value)
	store(main, value)
	make_int(main, 12)
	make_float(main, 1.5)
	make_string(main, hello)
	make_func(main, target)
	jump(main, done)
	bind(main, done)
	make_int(main, 0)

	initializer := init(&builder)
	make_func(initializer, main)
	store(initializer, start)

	module := finish(&builder)
	defer bytecode.destroy(&module)

	testing.expect(t, module.init == 2)
	testing.expect(t, module.globals == 2)
	testing.expect(t, len(module.consts) == 2)
	testing.expect(t, module.consts[0].as_utf8 == "hello")
	testing.expect(t, module.consts[1].as_utf8 == "__start")
	testing.expect(t, len(module.exports) == 1)
	testing.expect(t, module.exports[0].name == 1)
	testing.expect(t, module.exports[0].global == 0)
	testing.expect(t, len(module.funcs) == 3)

	built := module.funcs[0]
	testing.expect(t, built.arity == 1)
	testing.expect(t, len(built.insts) == 11)
	testing.expect(t, built.insts[0].opcode == .Load_Param)
	testing.expect(t, built.insts[1].opcode == .Store_Local)
	testing.expect(t, built.insts[3].opcode == .Load_Global)
	testing.expect(t, built.insts[5].operand.as_i64 == 12)
	testing.expect(t, built.insts[6].operand.as_f64 == 1.5)
	testing.expect(t, built.insts[7].operand.as_u32 == 0)
	testing.expect(t, built.insts[8].operand.as_u32 == 1)
	testing.expect(t, built.insts[9].operand.as_u32 == 10)

	testing.expect(t, len(module.debug.globals) == 2)
	testing.expect(t, module.debug.globals[0].name == "__start")
	testing.expect(t, module.debug.globals[1].name == "value")
	testing.expect(t, len(module.debug.funcs) == 2)
	testing.expect(t, module.debug.funcs[0].name.? == ".__start")
	testing.expect(t, module.debug.funcs[0].params[0].name == "parameter")
	testing.expect(t, module.debug.funcs[0].locals[0].name == "temporary")
	testing.expect(t, module.debug.funcs[0].labels[0].name == ".done")
	testing.expect(t, module.debug.funcs[0].labels[0].inst == 10)
}
