# Project Context

Last updated: 2026-07-15

## Current Status

SSL is an Odin project for a dynamic, object-oriented scripting language. The
repository currently has a usable bytecode memory model and a symbolic
bytecode builder. The object/class runtime foundation also compiles. Execution,
assembly parsing for the new model, and the high-level language front end are
not implemented end to end.

Verified commands:

```powershell
odin test bytecode
odin test bytecode\builder
odin check runtime\core -no-entry-point
odin check lexer -no-entry-point
odin check parser -no-entry-point
odin check .
odin run .
```

At this update:

- `bytecode`: 1 test passes.
- `bytecode/builder`: 8 tests pass.
- `runtime/core`, `lexer`, `parser`, and the root package compile.
- The root demo runs and prints the constructed module.
- `vm` does not compile because `Frame.ip` still uses the removed
  `bytecode.Instruction_Index` name.
- `assembler` does not compile because its parser still targets the removed
  bytecode builder API and old opcodes.

## `bytecode`

`bytecode` is the final in-memory module representation. It deliberately does
not perform symbolic construction or source-level validation.

Implemented data:

- `Const_Idx` and `Const`; the only constant kind is currently UTF-8 text.
- `Inst_Idx`, `Inst`, `Opcode`, and a compact raw operand union.
- Physical operand kinds: `None`, `I64`, `U32`, and `F64`.
- `Func_Idx`, `Func`, captures, globals, exports, and `Module`.
- Per-function instruction arrays rather than one module-wide instruction
  stream.
- A required initializer function index. There is no special entry function
  field.
- Optional debug names for globals, functions, parameters, locals, and labels.
- Ownership-aware constructors and destruction.
- Structural debug printing.

Current opcodes:

```text
None
Load_Global, Load_Param, Load_Local, Load_Capture
Store_Global, Store_Local, Store_Capture
Make_Int, Make_Float, Make_String, Make_Class, Make_Func, Make_List
Call, Return, Jump
Get_Field, Set_Field
Add, Sub, Mul, Div
Halt
```

The opcode-to-physical-operand table remains in `bytecode` because decoding,
serialization, debug printing, and construction all need the physical layout.

The debug dump uses a uniform structural form. Empty collections are printed
as `{}`; non-empty collections use indexed blocks. The constant pool remains in
this developer-oriented full dump.

Not implemented:

- Binary serialization and deserialization.
- Module-format versioning and deserialization validation.
- Imports.
- Execution semantics.

## `bytecode/builder`

Package name: `builder`.

This is a symbolic builder for the bytecode format, not a general-purpose IR.
It depends directly on `bytecode` and lowers to exactly one bytecode module.

Implemented:

- Module-scoped handles for constants, globals, functions, parameters, locals,
  and labels.
- UTF-8 constants, globals, named exports, ordinary functions, and one
  initializer.
- Separate parameter and local handles.
- Typed helpers for global/parameter/local loads, global/local stores, jumps,
  and the currently supported `make` operations.
- Function-scoped labels with forward binding.
- `finish`, which resolves symbolic handles, builds debug metadata, transfers
  data to an independently owned `bytecode.Module`, and consumes the builder.
- Assertions at `finish` for programmer mistakes such as foreign handles,
  invalid indices, duplicate/unbound labels, duplicate export names, and
  missing initialization.

Names are optional debug metadata except for export names. Duplicate debug
names are allowed; symbol-table policy belongs to a source assembler or
compiler, not this builder.

Current limitation: `local` assigns sequential local indices and records debug
metadata, but the builder does not yet model scopes, stack depth, temporary
values, local destruction, or slot reuse. It therefore does not yet enforce the
intended stack-local discipline.

Captures exist in final bytecode but do not yet have public builder APIs.

## `runtime/core`

Implemented:

- A linked heap with allocation, marking, sweeping, and destruction.
- A heap header containing polymorphic mark and destroy procedures.
- `Object` with a class pointer, named fields, binding flags, and freezing.
- `Class` as an object, with superclass and method lookup plus sealed, frozen,
  and final behavior.
- Runtime bootstrapping for the mutually related core `Object` and `Class`
  classes.
- Root traversal for the core runtime state.

Not implemented:

- Concrete runtime integer, float, string, list, tuple, or nil objects.
- Native and bytecode function objects.
- The callable/special-method protocol.
- Closures and open/closed upvalues.
- A complete GC scheduling and error-propagation policy.

## `vm`

The VM package is scaffolding and is temporarily incompatible with the renamed
bytecode API.

Present structures:

- `Program`, which owns a runtime and a module store.
- `VM`, with a shared value stack and frame stack.
- `Module_Store` and lifecycle states.
- `Module_Instance`, which owns a bytecode module and runtime globals.
- Root traversal and destruction paths.

Temporary/stale parts:

- `Frame.ip` refers to the old `Instruction_Index` type.
- Module globals still use `map[string]core.Value`; the intended representation
  is an indexed `[]core.Value` matching `bytecode.Global_Idx`.
- There is no dispatch loop, call/return implementation, module initialization,
  or export linking.

## `assembler`

The lexer and source diagnostic formatter exist. Diagnostics use:

```text
<file>:row:col: asm error: <description>
```

The filename is optional at the API boundary and falls back to `<virtual>`.
Token text is intentionally omitted from the rendered error.

The parser is stale. It still references the removed `bytecode.Module_Builder`,
old instruction/index names, and old integer-width opcodes. It must be rewritten
to construct `bytecode/builder.Module` and call `builder.finish`.

`source.sa` is a design sketch for the future assembly language. It is not
accepted by the current parser.

## High-Level Front End

The root `lexer` and `parser` packages are placeholders. Only an EOF token and
empty package shells exist. `source.ssl` is an example of desired SSL syntax,
not compilable input.

## Root Demo

`main.odin` demonstrates the current builder API:

- Export a `__start` global.
- Build a private `.__start` function.
- Create sequential local metadata and load a local.
- Build the initializer, create the function object, and store it in the
  exported global.
- Finish and print the bytecode module.

This demonstrates the intended startup model: the module has one reserved
initializer, while `__start` is an ordinary exported global populated by that
initializer.
