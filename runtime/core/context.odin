package core

import "../../bytecode"

Error :: union {
	Raised_Error,
	Read_Only_Binding_Error,
	Frozen_Object_Error,
	Frozen_Class_Error,
	Sealed_Class_Error,
	Final_Superclass_Error,
	Not_Callable_Error,
	Stack_Underflow_Error,
	Parameter_Out_Of_Bounds_Error,
	Arity_Error,
	Missing_Return_Value_Error,
}

Raised_Error :: struct {
	value: Value,
}

Stack_Underflow_Error :: struct {}

Parameter_Out_Of_Bounds_Error :: struct {
	index: u32,
	count: u32,
}

Arity_Error :: struct {
	expected: u32,
	actual:   u32,
}

Missing_Return_Value_Error :: struct {}

Exec_Push_Proc :: proc(data: rawptr, value: Value)
Exec_Peek_Proc :: proc(data: rawptr, offset: int) -> (Value, bool)
Exec_Param_Proc :: proc(data: rawptr, index: u32) -> (Value, bool)
Exec_Call_Proc :: proc(data: rawptr, arg_count: u32) -> Error
Exec_Return_Proc :: proc(data: rawptr) -> Error
Exec_Raise_Proc :: proc(data: rawptr) -> Error
Exec_Switch_Proc :: proc(
	data: rawptr,
	module: rawptr,
	func: bytecode.Func_Idx,
) -> Error

Executor :: struct {
	data:    rawptr,
	push:    Exec_Push_Proc,
	peek:    Exec_Peek_Proc,
	param:   Exec_Param_Proc,
	call:    Exec_Call_Proc,
	return_: Exec_Return_Proc,
	raise:   Exec_Raise_Proc,
	switch_: Exec_Switch_Proc,
}

Context :: struct {
	runtime:  ^Runtime,
	executor: Executor,
}

init_context :: proc(ctx: ^Context, runtime: ^Runtime, executor: Executor) {
	assert(ctx != nil)
	assert(runtime != nil)
	assert(ctx.runtime == nil, "context is already initialized")
	assert(executor.data != nil)
	assert(executor.push != nil)
	assert(executor.peek != nil)
	assert(executor.param != nil)
	assert(executor.call != nil)
	assert(executor.return_ != nil)
	assert(executor.raise != nil)
	assert(executor.switch_ != nil)

	ctx.runtime = runtime
	ctx.executor = executor
}

push :: proc(ctx: ^Context, value: Value) {
	_assert_context(ctx)
	assert(value != nil)
	ctx.executor.push(ctx.executor.data, value)
}

peek :: proc(ctx: ^Context, offset: int = 0) -> (Value, bool) {
	_assert_context(ctx)
	assert(offset >= 0)
	return ctx.executor.peek(ctx.executor.data, offset)
}

param :: proc(ctx: ^Context, index: u32) -> (Value, bool) {
	_assert_context(ctx)
	return ctx.executor.param(ctx.executor.data, index)
}

// Stack effect: ... args callee -> ... result.
// The executor creates the call frame before invoking callee.call.
call :: proc(ctx: ^Context, arg_count: u32) -> Error {
	_assert_context(ctx)
	return ctx.executor.call(ctx.executor.data, arg_count)
}

return_ :: proc(ctx: ^Context) -> Error {
	_assert_context(ctx)
	return ctx.executor.return_(ctx.executor.data)
}

raise :: proc(ctx: ^Context) -> Error {
	_assert_context(ctx)
	return ctx.executor.raise(ctx.executor.data)
}

// Switches the current frame to a bytecode function. The module owner is
// opaque here so runtime packages do not depend on the VM package.
switch_function :: proc(
	ctx: ^Context,
	module: rawptr,
	func: bytecode.Func_Idx,
) -> Error {
	_assert_context(ctx)
	assert(module != nil)
	return ctx.executor.switch_(ctx.executor.data, module, func)
}

@(private)
_assert_context :: proc(ctx: ^Context) {
	assert(ctx != nil)
	assert(ctx.runtime != nil, "context is not initialized")
	assert(ctx.executor.data != nil, "context has no executor")
}
