# Design Direction

This document records the current design agreement. It is a target, not a
description of fully implemented behavior.

## Principles

- Bytecode constants are serializable data, not runtime `Value` objects.
- Internal execution uses compact numeric indices.
- Names survive serialization only when required for exports, imports,
  reflection, or optional debug information.
- The builder should reject structurally invalid bytecode before producing a
  `Module`.
- Module-level functions and runtime-created internal functions are distinct.

## Constants and Functions

Function prototypes are stored in the constant pool:

```odin
Constant_Kind :: enum {
	String,
	Function,
}

Function_Prototype :: struct {
	entry:       Instruction_Index,
	arity:       u32,
	local_count: u32,
	captures:    []Capture_Descriptor,
}
```

No function name or code size is required for execution. Names belong to
assembler symbols or optional debug metadata. The builder may track function
boundaries internally without serializing `code_size`.

`Function_Index` is a typed index that must refer to a `.Function` constant.

## Globals and Exports

Runtime globals use indexed slots:

```odin
Global_Index :: distinct u32

Export :: struct {
	name:   Constant_Index,
	global: Global_Index,
}

Function_Binding :: struct {
	global:   Global_Index,
	function: Function_Index,
}
```

The bytecode module stores at least:

```odin
Module :: struct {
	initializer:       Function_Index,
	entry:             Function_Index,
	global_count:      u32,
	exports:           []Export,
	function_bindings: []Function_Binding,
	constants:         []Constant,
	instructions:      []Instruction,
	debug:             Debug_Info,
}
```

The initializer and entry should be optional for library-only or data-only
modules. Their exact optional representation is still open.

`Module_Instance` should own:

```odin
globals: []core.Value
```

It should not own an array of runtime values corresponding to every constant.

Private global names are assembler-only. Exported names are stored as string
constants and map to global slots through the export table. A loader may build
a temporary name lookup index, but global values themselves remain in the
array.

## Module Loading

The intended loading order is:

1. Allocate `global_count` nil global slots.
2. Materialize each module-level function from `function_bindings`.
3. Store those runtime functions in their assigned global slots.
4. Execute the module initializer (`__init`) if present.
5. Mark the module initialized.
6. Execute `__start` only when this is the root program module.

This allows `__init` to load automatically created functions and attach them to
classes or other objects.

`__init` and `__start` are currently planned as reserved assembler function
symbols. They are recorded in module metadata and do not need global slots.

## Assembly Symbols

Planned symbol categories:

- Global symbols: module-wide and compiled to `Global_Index`.
- Export symbols: public name to global-slot mappings.
- Module-level functions: module-wide prototypes automatically assigned global
  slots and function bindings.
- Internal functions: leading-dot symbols such as `.callback`; no automatic
  global slot.
- Blocks: leading-dot control-flow targets scoped to one owning function.

Because internal function and block names may both begin with a dot, the parser
resolves them by context: `make.func .name` expects a function, while
`jump .name` expects a block.

Proposed syntax:

```asm
export Point

global std.fmt
global Point

function __init
    load.module "std.fmt"
    store.global std.fmt
    make.class "Point"
    store.global Point
    return

function Point.__init { arity=3 }
    load.local 0
    load.local 1
    set.field "x"
    return
```

Attribute defaults:

- `arity` defaults to `0`.
- `locals` defaults to `arity`.
- `captures` defaults to an empty list.

## Runtime Function Creation

Module-level functions are materialized automatically by the module loader.

Internal and anonymous functions use `make.func`, even when they capture
nothing:

```asm
function create_callback
    make.func .callback
    return

function .callback { arity=1 }
    load.local 0
    return
```

`make.func` means: instantiate a function prototype, resolve its capture
descriptors against the current frame, create a runtime callable value, and push
it. An empty capture list creates an ordinary noncapturing function value.

## Closures and Captures

Capture descriptors distinguish a parent local from a parent capture:

```odin
Capture_Kind :: enum {
	Local,
	Capture,
}

Capture_Descriptor :: struct {
	kind:  Capture_Kind,
	index: u32,
}
```

Proposed syntax:

```asm
function make_counter { locals=1 }
    make.i32 0
    store.local 0
    make.func .increment
    return

function .increment { captures=[local 0] }
    load.capture 0
    make.i32 1
    add
    store.capture 0
    load.capture 0
    return
```

`captures=[capture 0, local 2]` means that child capture slot 0 references the
parent's capture slot 0, while child capture slot 1 references parent local slot
2.

Captured locals eventually require upvalue/cell objects. While the parent frame
is active, an upvalue may refer to its stack slot. When that frame returns, the
upvalue is closed into heap storage. Multiple closures capturing the same local
must share the same upvalue.

## Frames and Locals

Ordinary locals should use frame-relative slots in the shared VM value stack,
not maps and not one allocation per frame.

```odin
Frame :: struct {
	module:       ^Module_Instance,
	function:     core.Value,
	ip:           Instruction_Index,
	local_base:   int,
	operand_base: int,
}
```

`load.local N` accesses `vm.stack[frame.local_base + N]`. Function metadata
provides the number of local slots to reserve. The complete VM stack is already
a GC root.

## Blocks and Builder Validation

The builder should expose typed `Function_Handle` and `Block_Handle` values.
Blocks belong to exactly one function. Labels should become assembler names for
blocks rather than module-wide untyped targets.

The builder should reject:

- Instructions emitted outside a function.
- Starting a function while another function is active.
- `local_count < arity`.
- Undefined or multiply defined functions.
- Empty functions.
- Unbound or multiply bound blocks.
- Cross-function jumps.
- Blocks bound after their owning function's final instruction.
- `make.func` with a non-function constant.
- Invalid global, constant, function, block, or capture indices.

Forward function and block references remain supported through fixups.

## Imports

The final import representation is not settled. The important requirement is
that exported global reassignment can remain visible to importers if the
language chooses live-binding semantics.

A likely runtime representation is:

```odin
Global_Reference :: struct {
	module: ^Module_Instance,
	index:  Global_Index,
}
```

The loader resolves an exported name once to a module and global slot. Repeated
execution should not require string-keyed global lookup.

## Open Decisions

- Exact lexer grammar for `{ arity=..., locals=..., captures=[...] }`.
- Whether `call` always carries an explicit argument count. Current preference:
  keep it for validation and variadic functions.
- Final opcode spelling: `get.field`/`set.field` versus
  `field.get`/`field.set`, and `return` versus `ret`.
- Optional initializer and entry index representation.
- Static versus dynamic import syntax and live-binding behavior.
- Function identity and whether noncapturing internal functions may be cached.
- Binary serialization layout and versioning.
