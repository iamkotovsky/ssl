package bytecode

Func_Idx :: distinct u32
Capture_Idx :: distinct u32

Capture_Kind :: enum u8 {
	Param,
	Local,
	Capture,
}

Capture :: struct {
	kind: Capture_Kind,
	idx:  u32,
}

Func :: struct {
	arity:    u32,
	captures: []Capture,
	insts:    []Inst,
}

// Takes ownership of captures and insts.
make_func :: proc(
	arity: u32,
	captures: []Capture,
	insts: []Inst,
) -> Func {
	return {
		arity    = arity,
		captures = captures,
		insts    = insts,
	}
}

@(private)
_destroy_func :: proc(func: ^Func) {
	delete(func.captures)
	delete(func.insts)
	func^ = {}
}

Global_Idx :: distinct u32

Export :: struct {
	name:   Const_Idx,
	global: Global_Idx,
}

Module :: struct {
	init:    Func_Idx,
	globals: u32,
	consts:  []Const,
	funcs:   []Func,
	exports: []Export,
	debug:   Debug_Info,
}

// Takes ownership of consts, funcs, exports, and debug.
make_module :: proc(
	init: Func_Idx,
	globals: u32,
	consts: []Const,
	funcs: []Func,
	exports: []Export,
	debug: Debug_Info = {},
) -> Module {
	return {
		init    = init,
		globals = globals,
		consts  = consts,
		funcs   = funcs,
		exports = exports,
		debug   = debug,
	}
}

destroy :: proc(module: ^Module) {
	assert(module != nil)
	for value in module.consts {
		_destroy_const(value)
	}
	for &func in module.funcs {
		_destroy_func(&func)
	}
	delete(module.consts)
	delete(module.funcs)
	delete(module.exports)
	_destroy_debug_info(&module.debug)
	module^ = {}
}
