package builder

import "core:testing"

@(test)
load_store_and_make :: proc(t: ^testing.T) {
	module: Module
	defer destroy(&module)

	global_id := global(&module, "value")
	func := function(&module, ".main")
	target := function(&module, ".target")
	hello := const_utf8(&module, "hello")

	load(func, global_id)
	store(func, global_id)
	make_int(func, 12)
	make_float(func, 1.5)
	make_string(func, hello)
	make_string(func, hello)
	make_func(func, target)

	proto := &module.funcs[int(func.id)]
	testing.expect(t, len(proto.insts) == 7)
	testing.expect(t, len(module.consts) == 1)
	testing.expect(t, proto.insts[0].opcode == .Load_Global)
	testing.expect(t, proto.insts[1].opcode == .Store_Global)
	testing.expect(t, proto.insts[2].opcode == .Make_Int)
	testing.expect(t, proto.insts[3].opcode == .Make_Float)
	testing.expect(t, proto.insts[4].opcode == .Make_String)
	testing.expect(t, proto.insts[6].opcode == .Make_Func)

	loaded_global, ok := proto.insts[0].operand.(Global)
	testing.expect(t, ok)
	testing.expect(t, loaded_global.module == global_id.module)
	testing.expect(t, loaded_global.id == global_id.id)
	int_value, int_ok := proto.insts[2].operand.(i64)
	testing.expect(t, int_ok)
	testing.expect(t, int_value == 12)
	utf8, const_ok := proto.insts[4].operand.(Utf8)
	testing.expect(t, const_ok)
	const := Const(utf8)
	testing.expect(t, const.module == &module)
	testing.expect(t, const.id == 0)
	value, value_ok := module.consts[int(const.id)].(Utf8_Proto)
	testing.expect(t, value_ok)
	testing.expect(t, string(value) == "hello")
	func_value, func_ok := proto.insts[6].operand.(Func)
	testing.expect(t, func_ok)
	testing.expect(t, func_value.module == target.module)
	testing.expect(t, func_value.id == target.id)
}

@(test)
instruction_handles_are_preserved_for_lowering :: proc(t: ^testing.T) {
	module: Module
	defer destroy(&module)
	func := function(&module)

	other: Module
	defer destroy(&other)
	other_global := global(&other)
	foreign_target := function(&other)
	foreign_string := const_utf8(&other, "foreign")

	load(func, other_global)
	make_func(func, foreign_target)
	make_string(func, foreign_string)
	proto := &module.funcs[int(func.id)]
	stored_global, global_ok := proto.insts[0].operand.(Global)
	stored_func, func_ok := proto.insts[1].operand.(Func)
	stored_utf8, utf8_ok := proto.insts[2].operand.(Utf8)
	testing.expect(t, global_ok)
	testing.expect(t, func_ok)
	testing.expect(t, utf8_ok)
	testing.expect(t, stored_global.module == &other)
	testing.expect(t, stored_func.module == &other)
	testing.expect(t, Const(stored_utf8).module == &other)
}

@(test)
local_handles_are_preserved_for_lowering :: proc(t: ^testing.T) {
	module: Module
	defer destroy(&module)
	func := function(&module)
	value := local(func, "value")

	other := function(&module)
	load(other, value)
	store(other, value)

	proto := &module.funcs[int(other.id)]
	loaded, load_ok := proto.insts[0].operand.(Local)
	stored, store_ok := proto.insts[1].operand.(Local)
	testing.expect(t, load_ok)
	testing.expect(t, store_ok)
	testing.expect(t, loaded.func.id == func.id)
	testing.expect(t, stored.func.id == func.id)
}

@(test)
labels_preserve_bindings_for_lowering :: proc(t: ^testing.T) {
	module: Module
	defer destroy(&module)
	func := function(&module)
	target := label(func, ".done")

	jump(func, target)
	bind(func, target)
	bind(func, target)

	proto := &module.funcs[int(func.id)]
	testing.expect(t, len(proto.labels) == 1)
	testing.expect(t, proto.labels[0].name == ".done")
	testing.expect(t, len(proto.insts) == 1)
	testing.expect(t, len(proto.binds) == 2)
	stored_target, ok := proto.insts[0].operand.(Label)
	testing.expect(t, ok)
	testing.expect(t, stored_target.func.module == &module)
	testing.expect(t, stored_target.func.id == func.id)
	testing.expect(t, stored_target.id == target.id)
	testing.expect(t, proto.binds[0].label.id == target.id)
	testing.expect(t, proto.binds[0].inst == 1)
	testing.expect(t, proto.binds[1].inst == 1)
}

@(test)
foreign_labels_are_preserved_for_lowering :: proc(t: ^testing.T) {
	module: Module
	defer destroy(&module)
	func := function(&module)

	other: Module
	defer destroy(&other)
	other_func := function(&other)
	foreign_label := label(other_func)

	jump(func, foreign_label)
	bind(func, foreign_label)

	proto := &module.funcs[int(func.id)]
	stored_target, target_ok := proto.insts[0].operand.(Label)
	testing.expect(t, target_ok)
	testing.expect(t, stored_target.func.module == &other)
	testing.expect(t, proto.binds[0].label.func.module == &other)
}
