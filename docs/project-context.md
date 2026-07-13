# Project Context

Last updated: 2026-07-13

## Repository State

- Language: Odin.
- Branch at last inspection: `main`.
- Base commit: `3e9b74b` (`added vm package`).
- The working tree contains uncommitted builder, opcode, VM module, test, and
  `source.sa` changes.
- Odin is installed and available when running outside the restricted sandbox.

Useful verification commands:

```powershell
odin test ./assembler
odin test ./vm
odin check ./bytecode -no-entry-point
odin check ./runtime/core -no-entry-point
odin check ./vm -no-entry-point
odin check .
```

At the last verification, the assembler tests (3), VM test (1), bytecode check,
runtime check, VM check, and root check passed.

## Package Overview

### `bytecode`

Implemented:

- `Opcode`, `Instruction`, and tagged `Operand` types.
- Integer, float, constant, and instruction-target operands.
- A constant pool whose only implemented constant kind is `String`.
- A builder with typed emit overloads.
- Forward label creation, binding, and fixup resolution.
- Module ownership and a readable bytecode debug print.
- Builder validation for operand kinds and constant/target ranges.
- Trailing labels return `Label_Target_Out_Of_Range_Error` instead of asserting.
- Global mnemonics are named `load.global` and `store.global` in the working
  tree.

Temporary behavior that does not match the target design:

- `load.global` and `store.global` currently use string constant operands.
- Labels are module-wide and are not scoped to functions.
- Function prototypes, global slots, exports, and imports are not represented.
- Serialization and deserialization do not exist yet.

### `assembler`

Implemented:

- A lexer for instruction names, labels, strings, integers, and floats.
- A direct parser that emits bytecode through `bytecode.Builder`.
- Forward label symbols.
- Operand type/range checks and basic source locations.
- Tests for trailing labels and named global operands.

Not implemented:

- `global`, `export`, and `function` declarations.
- Function attributes such as `arity`, `locals`, and `captures`.
- Function, block, global, import, and export symbol namespaces.
- The syntax currently written in `source.sa`.

### `runtime/core`

Implemented:

- Heap objects with polymorphic mark and destroy procedures.
- Mark/sweep collection primitives.
- Runtime roots for the core `Object` and `Class` classes.
- Objects, classes, fields, methods, binding flags, and class flags.

Not implemented:

- Runtime function/closure objects.
- Boxed or immediate numeric/string values.
- Upvalues for captured locals.
- A complete garbage-collection orchestration policy.

### `vm`

Implemented:

- `Program`, `VM`, `Module_Store`, `Module_Instance`, and `Frame` scaffolding.
- Module lifecycle state.
- GC root traversal for programs, modules, stacks, and frames.
- Module and VM destruction.

Temporary behavior that must be replaced:

- `Module_Instance.globals` is currently `map[string]core.Value`.
- `set_global` and `find_global` clone and look up string keys.
- The target design uses `[]core.Value` indexed by serialized `Global_Index`.

The old runtime constant cache (`Module_Instance.constants []core.Value`) was
removed intentionally. Bytecode constants are serialized data, not permanent
runtime values. Instructions may materialize runtime values from constant data
when needed.

Not implemented:

- An instruction execution loop.
- Function calls and returns.
- Module initialization or program entry execution.
- Export/import linking.
- Runtime function construction.

### Front-end placeholders

The root `lexer` and `parser` packages are placeholders for the high-level SSL
language. `source.ssl` is only an example. The current root `main.odin` is a
small allocation experiment and does not run the assembler or VM.

## Current Working Example

`source.sa` records proposed future assembly syntax. It currently explores:

- Exported and private globals.
- Reserved `__init` and `__start` functions.
- Automatically bound module-level functions.
- Internal anonymous function prototypes with leading-dot names.
- Local and captured variables.

It is not a regression test and does not parse with the current assembler.

Known issues in the sketch at the time of writing:

- `artity` should be `arity`.
- `capture=0` is ambiguous; the target syntax uses a typed capture list.
- `make.func` remains the preferred general operation for internal functions,
  whether their capture list is empty or non-empty.
- Calls should probably retain an explicit argument count (`call 2`, `call 0`)
  to support validation and variadic callables.
