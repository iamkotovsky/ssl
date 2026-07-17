package core

Raised_Error :: struct {
	value: Value,
}

Error :: union {
	Raised_Error,
	Read_Only_Binding_Error,
	Frozen_Object_Error,
	Frozen_Class_Error,
	Sealed_Class_Error,
	Final_Superclass_Error,
}

Stack_Len_Proc :: proc(data: rawptr) -> int
Push_Proc :: proc(data: rawptr, value: Value)
Peek_Proc :: proc(data: rawptr, offset: int) -> Value
Param_Count_Proc :: proc(data: rawptr) -> u32
Param_Proc :: proc(data: rawptr, index: u32) -> Value
Call_Stack_Proc :: proc(data: rawptr, arg_count: u32) -> Error
Dispatch_Proc :: proc(
	data: rawptr,
	callee: Value,
	arg_count: u32,
) -> Error
Return_Proc :: proc(data: rawptr) -> Error

Executor :: struct {
	data:         rawptr,
	stack_len:    Stack_Len_Proc,
	push:         Push_Proc,
	peek:         Peek_Proc,
	param_count:  Param_Count_Proc,
	param:        Param_Proc,
	call:         Call_Stack_Proc,
	dispatch:     Dispatch_Proc,
	return_value: Return_Proc,
}

Context :: struct {
	runtime:  ^Runtime,
	executor: Executor,
}

init_context :: proc(
	ctx: ^Context,
	runtime: ^Runtime,
	executor: Executor,
) {
	assert(ctx != nil)
	assert(runtime != nil)
	assert(ctx.runtime == nil, "context is already initialized")
	assert(executor.data != nil)
	assert(executor.stack_len != nil)
	assert(executor.push != nil)
	assert(executor.peek != nil)
	assert(executor.param_count != nil)
	assert(executor.param != nil)
	assert(executor.call != nil)
	assert(executor.dispatch != nil)
	assert(executor.return_value != nil)

	ctx.runtime = runtime
	ctx.executor = executor
}

stack_len :: proc(ctx: ^Context) -> int {
	_assert_context(ctx)
	return ctx.executor.stack_len(ctx.executor.data)
}

push :: proc(ctx: ^Context, value: Value) {
	_assert_context(ctx)
	assert(value != nil)
	ctx.executor.push(ctx.executor.data, value)
}

peek :: proc(ctx: ^Context, offset: int = 0) -> Value {
	_assert_context(ctx)
	assert(offset >= 0)
	return ctx.executor.peek(ctx.executor.data, offset)
}

param_count :: proc(ctx: ^Context) -> u32 {
	_assert_context(ctx)
	return ctx.executor.param_count(ctx.executor.data)
}

param :: proc(ctx: ^Context, index: u32) -> Value {
	_assert_context(ctx)
	assert(index < param_count(ctx), "parameter index is out of bounds")
	return ctx.executor.param(ctx.executor.data, index)
}

// Stack effect: ... args callee -> ... result.
// The executor creates the call frame before invoking callee.call.
call :: proc(ctx: ^Context, arg_count: u32) -> Error {
	_assert_context(ctx)
	return ctx.executor.call(ctx.executor.data, arg_count)
}

// Enters an already resolved callable using the current frame and arguments.
dispatch :: proc(
	ctx: ^Context,
	callee: Value,
	arg_count: u32,
) -> Error {
	_assert_context(ctx)
	assert(callee != nil)
	return ctx.executor.dispatch(ctx.executor.data, callee, arg_count)
}

return_value :: proc(ctx: ^Context) -> Error {
	_assert_context(ctx)
	return ctx.executor.return_value(ctx.executor.data)
}

raise :: proc(value: Value) -> Error {
	assert(value != nil)
	return Raised_Error{value}
}

@(private)
_assert_context :: proc(ctx: ^Context) {
	assert(ctx != nil)
	assert(ctx.runtime != nil, "context is not initialized")
	assert(ctx.executor.data != nil, "context has no executor")
}
