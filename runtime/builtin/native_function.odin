package runtime_builtin

import core "../core"

// A native procedure reads parameters and publishes one result through ctx.
// The Native_Function wrapper performs the common frame return afterwards.
Native_Proc :: proc(ctx: ^core.Context) -> core.Error

Native_Function :: struct {
	using object: core.Object,
	procedure:    Native_Proc,
}

// Stack effect: ... -> ... function.
new_native_function :: proc(
	ctx: ^core.Context,
	class: ^core.Class,
	procedure: Native_Proc,
) {
	assert(ctx != nil)
	assert(class != nil)
	assert(procedure != nil)

	function := core.alloc(&ctx.runtime.heap, Native_Function)
	core.init_object(function, class)
	function.call = _native_function_call
	function.procedure = procedure
	core.push(ctx, function)
}

@(private)
_native_function_call :: proc(ctx: ^core.Context, value: core.Value) -> core.Error {
	function := cast(^Native_Function)value
	if err := function.procedure(ctx); err != nil {
		return err
	}
	return core.return_(ctx)
}
