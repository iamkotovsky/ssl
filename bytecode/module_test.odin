package bytecode

import "core:testing"

@(test)
constructors_create_function_based_layout :: proc(t: ^testing.T) {
	name := Const_Idx(0)
	global := Global_Idx(0)
	init := Func_Idx(0)

	consts := make([]Const, 1)
	consts[name] = make_utf8("answer")

	insts := make([]Inst, 5)
	insts[0] = make_inst(.Make_Int, i64(-42))
	insts[1] = make_inst(.Make_Float, f64(1.5))
	insts[2] = make_inst(.Make_String, u32(name))
	insts[3] = make_inst(.Store_Global, u32(global))
	insts[4] = make_inst(.Return)

	funcs := make([]Func, 1)
	funcs[init] = make_func(0, nil, insts)

	exports := make([]Export, 1)
	exports[0] = {name, global}

	module := make_module(init, 1, consts, funcs, exports)
	defer destroy(&module)

	testing.expect(t, module.globals == 1)
	testing.expect(t, len(module.consts) == 1)
	testing.expect(t, module.consts[0].kind == .Utf8)
	testing.expect(t, module.consts[0].as_utf8 == "answer")
	testing.expect(t, len(module.exports) == 1)
	testing.expect(t, module.exports[0].name == name)
	testing.expect(t, module.exports[0].global == global)
	testing.expect(t, len(module.funcs) == 1)
	testing.expect(t, module.init == init)
	testing.expect(t, len(module.funcs[0].insts) == 5)
	testing.expect(t, module.funcs[0].insts[0].operand.as_i64 == -42)
	testing.expect(t, module.funcs[0].insts[1].operand.as_f64 == 1.5)
	store := module.funcs[0].insts[3]
	testing.expect(t, opcode_operand_kind(store.opcode) == .U32)
	testing.expect(t, store.operand.as_u32 == u32(global))
}
