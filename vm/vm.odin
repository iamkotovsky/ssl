package vm

import "../bytecode"
import builtin "../runtime/builtin"
import core "../runtime/core"

// A frame describes a window in the shared value stack:
//
//   caller prefix | parameters | callee | locals and temporaries
//                 ^ stack_base
//
// Keeping the callee in the window means every live language value remains a
// stack root. params is a count, not an absolute stack index.
Frame :: struct {
	params:     int,
	stack_base: int,
}

// Call contains only bytecode execution state. Native calls use Frame too,
// but execute synchronously and therefore do not need an instruction pointer.
Call :: struct {
	module: ^Module_Instance,
	func:   bytecode.Func_Idx,
	ip:     bytecode.Inst_Idx,
}

VM :: struct {
	program: ^Program,
	ctx:     core.Context,
	stack:   [dynamic]core.Value,
	calls:   [dynamic]Call,
	frames:  [dynamic]Frame,
}

init_vm :: proc(vm: ^VM, program: ^Program) {
	assert(vm != nil)
	assert(program != nil)
	assert(program.runtime != nil, "program is not initialized")
	assert(vm.program == nil, "VM is already initialized")
	vm.program = program
	core.init_context(
		&vm.ctx,
		program.runtime,
		{
			data = vm,
			push = _exec_push,
			peek = _exec_peek,
			param = _exec_param,
			call = _exec_call,
			return_ = _exec_return,
			raise = _exec_raise,
			switch_ = _exec_switch,
		},
	)
}

get_context :: proc(vm: ^VM) -> ^core.Context {
	assert(vm != nil)
	assert(vm.program != nil, "VM is not initialized")
	return &vm.ctx
}

mark_vm_roots :: proc(vm: ^VM) {
	assert(vm != nil)
	assert(vm.program != nil, "VM is not initialized")
	mark_program_roots(vm.program)
	for value in vm.stack {
		core.mark(value)
	}
}

destroy_vm :: proc(vm: ^VM) {
	assert(vm != nil)
	delete(vm.stack)
	delete(vm.calls)
	delete(vm.frames)
	vm^ = {}
}

// Calls a bytecode function using arguments already on the value stack, then
// runs until no bytecode calls remain or Halt is encountered.
run_function :: proc(
	vm: ^VM,
	module: ^Module_Instance,
	func: bytecode.Func_Idx,
	arg_count: u32 = 0,
) -> core.Error {
	assert(vm != nil)
	assert(module != nil)
	builtin.new_function(
		&vm.ctx,
		vm.program.builtins.function,
		module,
		func,
	)
	if err := core.call(&vm.ctx, arg_count); err != nil {
		return err
	}
	return execute(vm)
}

// execute is intentionally a small first dispatch loop. It establishes frame
// transitions and the stack-only data path; the remaining value-producing and
// object opcodes will be filled in as their runtime types are introduced.
execute :: proc(vm: ^VM) -> core.Error {
	assert(vm != nil)
	assert(vm.program != nil, "VM is not initialized")

	for len(vm.calls) != 0 {
		call := &vm.calls[len(vm.calls) - 1]
		func := _get_func(call.module, call.func)
		assert(int(call.ip) < len(func.insts), "instruction pointer is out of bounds")

		inst := func.insts[int(call.ip)]
		call.ip = bytecode.Inst_Idx(int(call.ip) + 1)

		#partial switch inst.opcode {
		case .Load_Global:
			idx := int(inst.operand.as_u32)
			assert(idx < len(call.module.globals), "global index is out of bounds")
			value := call.module.globals[idx]
			assert(value != nil, "cannot load an uninitialized global")
			core.push(&vm.ctx, value)
		case .Load_Param:
			value, ok := core.param(&vm.ctx, inst.operand.as_u32)
			assert(ok, "parameter index is out of bounds")
			core.push(&vm.ctx, value)
		case .Load_Local:
			idx := _local_base(vm) + int(inst.operand.as_u32)
			assert(idx < len(vm.stack), "local index is out of bounds")
			core.push(&vm.ctx, vm.stack[idx])
		case .Store_Global:
			idx := int(inst.operand.as_u32)
			assert(idx < len(call.module.globals), "global index is out of bounds")
			call.module.globals[idx] = _pop_value(vm)
		case .Store_Local:
			idx := _local_base(vm) + int(inst.operand.as_u32)
			assert(idx < len(vm.stack) - 1, "local index is out of bounds")
			vm.stack[idx] = _pop_value(vm)
		case .Make_Func:
			builtin.new_function(
				&vm.ctx,
				vm.program.builtins.function,
				call.module,
				bytecode.Func_Idx(inst.operand.as_u32),
			)
		case .Call:
			if err := core.call(&vm.ctx, inst.operand.as_u32); err != nil {
				return err
			}
		case .Return:
			if err := core.return_(&vm.ctx); err != nil {
				return err
			}
			pop(&vm.calls)
		case .Jump:
			call.ip = bytecode.Inst_Idx(inst.operand.as_u32)
		case .Halt:
			_truncate_stack(vm, 0)
			for len(vm.calls) != 0 {
				pop(&vm.calls)
			}
			for len(vm.frames) != 0 {
				pop(&vm.frames)
			}
			return nil
		case:
			assert(false, "opcode is not implemented by the initial execution loop")
		}
	}

	return nil
}

@(private)
_get_func :: proc(module: ^Module_Instance, idx: bytecode.Func_Idx) -> ^bytecode.Func {
	assert(module != nil)
	assert(int(idx) < len(module.definition.funcs), "function index is out of bounds")
	return &module.definition.funcs[int(idx)]
}

@(private)
_current_frame :: proc(vm: ^VM) -> ^Frame {
	assert(len(vm.frames) != 0, "there is no active call frame")
	return &vm.frames[len(vm.frames) - 1]
}

@(private)
_local_base :: proc(vm: ^VM) -> int {
	frame := _current_frame(vm)
	return frame.stack_base + frame.params + 1
}

@(private)
_pop_value :: proc(vm: ^VM) -> core.Value {
	assert(len(vm.stack) != 0, "value stack underflow")
	return pop(&vm.stack)
}

@(private)
_truncate_stack :: proc(vm: ^VM, count: int) {
	assert(count >= 0)
	assert(count <= len(vm.stack))
	for len(vm.stack) > count {
		pop(&vm.stack)
	}
}

@(private)
_exec_push :: proc(data: rawptr, value: core.Value) {
	vm := cast(^VM)data
	append(&vm.stack, value)
}

@(private)
_exec_peek :: proc(data: rawptr, offset: int) -> (core.Value, bool) {
	vm := cast(^VM)data
	if offset < 0 || offset >= len(vm.stack) {
		return nil, false
	}
	return vm.stack[len(vm.stack) - 1 - offset], true
}

@(private)
_exec_param :: proc(data: rawptr, index: u32) -> (core.Value, bool) {
	vm := cast(^VM)data
	if len(vm.frames) == 0 {
		return nil, false
	}
	frame := _current_frame(vm)
	if int(index) >= frame.params {
		return nil, false
	}
	return vm.stack[frame.stack_base + int(index)], true
}

@(private)
_exec_call :: proc(data: rawptr, arg_count: u32) -> core.Error {
	vm := cast(^VM)data
	needed := int(arg_count) + 1
	if len(vm.stack) < needed {
		return core.Stack_Underflow_Error{}
	}

	callee := vm.stack[len(vm.stack) - 1]
	if callee.call == nil {
		return core.Not_Callable_Error{}
	}

	frame_count := len(vm.frames)
	call_count := len(vm.calls)
	append(
		&vm.frames,
		Frame{
			params = int(arg_count),
			stack_base = len(vm.stack) - needed,
		},
	)

	if err := callee.call(&vm.ctx, callee); err != nil {
		if len(vm.calls) > call_count {
			pop(&vm.calls)
		}
		if len(vm.frames) > frame_count {
			pop(&vm.frames)
		}
		return err
	}
	return nil
}

@(private)
_exec_return :: proc(data: rawptr) -> core.Error {
	vm := cast(^VM)data
	if len(vm.frames) == 0 {
		return core.Stack_Underflow_Error{}
	}

	frame := _current_frame(vm)
	local_base := frame.stack_base + frame.params + 1
	if len(vm.stack) <= local_base {
		return core.Missing_Return_Value_Error{}
	}

	result := vm.stack[len(vm.stack) - 1]
	stack_base := frame.stack_base
	pop(&vm.frames)
	_truncate_stack(vm, stack_base)
	append(&vm.stack, result)
	return nil
}

@(private)
_exec_raise :: proc(data: rawptr) -> core.Error {
	value, ok := _exec_peek(data, 0)
	if !ok {
		return core.Stack_Underflow_Error{}
	}
	return core.Raised_Error{value}
}

@(private)
_exec_switch :: proc(
	data: rawptr,
	module_data: rawptr,
	func_idx: bytecode.Func_Idx,
) -> core.Error {
	vm := cast(^VM)data
	module := cast(^Module_Instance)module_data
	func := _get_func(module, func_idx)
	frame := _current_frame(vm)
	if frame.params != int(func.arity) {
		return core.Arity_Error{expected = func.arity, actual = u32(frame.params)}
	}
	append(&vm.calls, Call{module = module, func = func_idx})
	return nil
}
