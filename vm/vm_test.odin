package vm

import "../bytecode"
import builtin "../runtime/builtin"
import core "../runtime/core"
import "core:testing"

@(test)
bytecode_function_uses_stack_frame_window :: proc(t: ^testing.T) {
	runtime: core.Runtime
	program: Program
	machine: VM
	_init_test_vm(&runtime, &program, &machine)
	defer core.destroy_runtime(&runtime)
	defer destroy_program(&program)
	defer destroy_vm(&machine)

	insts := make([]bytecode.Inst, 2)
	insts[0] = bytecode.make_inst(.Load_Param, u32(0))
	insts[1] = bytecode.make_inst(.Return)
	funcs := make([]bytecode.Func, 1)
	funcs[0] = bytecode.make_func(1, nil, insts)
	definition := bytecode.make_module(0, 0, nil, funcs, nil)
	module, add_err := add_module(&program.modules, "test", definition)
	testing.expect(t, add_err == nil)

	argument := core.alloc(&runtime.heap, core.Object)
	core.init_object(argument, runtime.classes.object)
	core.push(&machine.ctx, argument)

	err := run_function(&machine, module, 0, 1)
	testing.expect(t, err == nil)
	testing.expect(t, len(machine.frames) == 0)
	testing.expect(t, len(machine.calls) == 0)
	testing.expect(t, len(machine.stack) == 1)
	testing.expect(t, machine.stack[0] == argument)
}

@(test)
native_function_returns_through_common_frame_path :: proc(t: ^testing.T) {
	runtime: core.Runtime
	program: Program
	machine: VM
	_init_test_vm(&runtime, &program, &machine)
	defer core.destroy_runtime(&runtime)
	defer destroy_program(&program)
	defer destroy_vm(&machine)

	argument := core.alloc(&runtime.heap, core.Object)
	core.init_object(argument, runtime.classes.object)
	core.push(&machine.ctx, argument)
	builtin.new_native_function(
		&machine.ctx,
		program.builtins.native_function,
		_test_identity,
	)

	err := core.call(&machine.ctx, 1)
	testing.expect(t, err == nil)
	testing.expect(t, len(machine.frames) == 0)
	testing.expect(t, len(machine.stack) == 1)
	testing.expect(t, machine.stack[0] == argument)
}

@(private)
_test_identity :: proc(ctx: ^core.Context) -> core.Error {
	value, ok := core.param(ctx, 0)
	if !ok {
		return core.Parameter_Out_Of_Bounds_Error{index = 0, count = 0}
	}
	core.push(ctx, value)
	return nil
}

@(private)
_init_test_vm :: proc(runtime: ^core.Runtime, program: ^Program, machine: ^VM) {
	core.init_runtime(runtime)
	init_program(program, runtime)
	init_vm(machine, program)
}
