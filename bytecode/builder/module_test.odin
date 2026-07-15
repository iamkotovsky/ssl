package builder

import bytecode ".."
import "core:testing"

@(test)
module_level_api :: proc(t: ^testing.T) {
	module: Module
	defer destroy(&module)

	unnamed := global(&module)
	debug_global := global(&module, "debug")
	start := export(&module, "__start")
	testing.expect(t, unnamed.id == 0)
	testing.expect(t, debug_global.id == 1)
	testing.expect(t, start.id == 2)
	testing.expect(t, unnamed.module == &module)
	testing.expect(t, len(module.globals) == 3)
	testing.expect(t, len(module.exports) == 1)
	testing.expect(t, module.exports[0].global == start.id)

	auto := function(&module, ".auto")
	fixed := function(&module, ".fixed")
	_ = param(fixed)
	_ = param(fixed)
	testing.expect(t, len(module.funcs[int(auto.id)].params) == 0)
	testing.expect(t, len(module.funcs[int(fixed.id)].params) == 2)
	_ = global(&module, "debug")
	_ = export(&module, "__start")
	_ = function(&module, ".fixed")
	testing.expect(t, len(module.globals) == 5)
	testing.expect(t, len(module.exports) == 2)
	testing.expect(t, len(module.funcs) == 3)

	initializer := init(&module)
	initializer_again := init(&module)
	testing.expect(t, initializer.id == initializer_again.id)
	testing.expect(t, initializer.module == &module)
	testing.expect(t, module.has_init)
	testing.expect(t, module.init == initializer.id)
}

@(test)
function_owns_locals :: proc(t: ^testing.T) {
	module: Module
	defer destroy(&module)
	func := function(&module)
	x := param(func, "x")
	temporary := local(func, "temporary")

	proto := &module.funcs[int(func.id)]
	testing.expect(t, len(proto.params) == 1)
	testing.expect(t, len(proto.locals) == 1)
	testing.expect(t, proto.params[0].name == "x")
	testing.expect(t, proto.locals[0].idx == 0)
	testing.expect(t, proto.locals[0].name == "temporary")
	testing.expect(t, x.func.id == func.id)
	testing.expect(t, temporary.func.id == func.id)
}

@(test)
finish_builds_owned_bytecode :: proc(t: ^testing.T) {
	source: Module
	start := export(&source, "__start")
	initializer := init(&source)
	work := function(&source, ".same")
	target := function(&source, ".same")
	parameter := param(work, "parameter")
	temporary := local(work, "temporary")
	hello := const_utf8(&source, "hello")
	first := label(work, ".same")
	second := label(work, ".same")

	make_func(initializer, work)
	store(initializer, start)
	bind(work, first)
	load(work, parameter)
	jump(work, second)
	bind(work, second)
	store(work, temporary)
	make_string(work, hello)
	make_func(work, target)

	module := finish(&source)
	defer bytecode.destroy(&module)

	testing.expect(t, !source.has_init)
	testing.expect(t, len(source.consts) == 0)
	testing.expect(t, len(source.funcs) == 0)
	testing.expect(t, module.init == 0)
	testing.expect(t, module.globals == 1)
	testing.expect(t, len(module.consts) == 2)
	testing.expect(t, module.consts[0].as_utf8 == "hello")
	testing.expect(t, module.consts[1].as_utf8 == "__start")
	testing.expect(t, len(module.exports) == 1)
	testing.expect(t, module.exports[0].name == 1)
	testing.expect(t, module.exports[0].global == 0)
	testing.expect(t, len(module.funcs) == 3)

	built := &module.funcs[1]
	testing.expect(t, built.arity == 1)
	testing.expect(t, len(built.insts) == 5)
	testing.expect(t, built.insts[0].opcode == .Load_Param)
	testing.expect(t, built.insts[0].operand.as_u32 == 0)
	testing.expect(t, built.insts[1].operand.as_u32 == 2)
	testing.expect(t, built.insts[2].operand.as_u32 == 0)
	testing.expect(t, built.insts[3].operand.as_u32 == 0)
	testing.expect(t, built.insts[4].operand.as_u32 == 2)

	testing.expect(t, len(module.debug.globals) == 1)
	testing.expect(t, module.debug.globals[0].idx == 0)
	testing.expect(t, module.debug.globals[0].name == "__start")
	testing.expect(t, len(module.debug.funcs) == 2)
	testing.expect(t, module.debug.funcs[0].name == ".same")
	testing.expect(t, module.debug.funcs[1].name == ".same")
	testing.expect(t, len(module.debug.funcs[0].params) == 1)
	testing.expect(t, module.debug.funcs[0].params[0].idx == 0)
	testing.expect(t, module.debug.funcs[0].params[0].name == "parameter")
	testing.expect(t, len(module.debug.funcs[0].locals) == 1)
	testing.expect(t, module.debug.funcs[0].locals[0].idx == 0)
	testing.expect(t, module.debug.funcs[0].locals[0].name == "temporary")
	testing.expect(t, len(module.debug.funcs[0].labels) == 2)
	testing.expect(t, module.debug.funcs[0].labels[0].name == ".same")
	testing.expect(t, module.debug.funcs[0].labels[1].name == ".same")
	testing.expect(t, module.debug.funcs[0].labels[0].inst == 0)
	testing.expect(t, module.debug.funcs[0].labels[1].inst == 2)
}
