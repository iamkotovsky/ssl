package runtime_builtin

import "../../bytecode"
import core "../core"

// Function is a runtime handle to a function in a loaded bytecode module.
// module is deliberately opaque; the executor owns and interprets it.
Function :: struct {
	using object: core.Object,
	module:       rawptr,
	func:         bytecode.Func_Idx,
}

// Stack effect: ... -> ... function.
new_function :: proc(
	ctx: ^core.Context,
	class: ^core.Class,
	module: rawptr,
	func: bytecode.Func_Idx,
) {
	assert(ctx != nil)
	assert(class != nil)
	assert(module != nil)

	function := core.alloc(&ctx.runtime.heap, Function)
	core.init_object(function, class)
	function.call = _function_call
	function.module = module
	function.func = func
	core.push(ctx, function)
}

@(private)
_function_call :: proc(ctx: ^core.Context, value: core.Value) -> core.Error {
	function := cast(^Function)value
	return core.switch_function(ctx, function.module, function.func)
}
