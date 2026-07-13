# Implementation Roadmap

The stages are intentionally ordered so each stage leaves a compiling and
testable project.

## Stage 1: Bytecode Data Model

- Add `Function` to `Constant_Kind`.
- Add `Function_Prototype`, `Function_Index`, `Global_Index`, and capture
  descriptors.
- Add typed function and global operands.
- Change `load.global` and `store.global` from string constants to
  `Global_Index` operands.
- Add module `global_count`, initializer, entry, exports, and function bindings.
- Extend destruction and debug printing for every new structure.
- Add focused bytecode tests.

## Stage 2: Builder Functions, Globals, and Blocks

- Add builder-only `Function_Handle` and `Block_Handle` types.
- Support declaring functions before defining them.
- Add begin/end function lifecycle APIs.
- Add global declaration, export, initializer, entry, and static function
  binding APIs.
- Replace label fixups with function-scoped block fixups.
- Validate function metadata, block ownership, and all typed indices.
- Keep all builder failures recoverable; user input must not reach assertions.

## Stage 3: Assembler Syntax

- Expand the lexer for declarations, braces, brackets, commas, and equals.
- Parse `global`, `export`, and `function` declarations.
- Parse function attributes with explicit defaults.
- Add separate symbol tables for globals, functions, and per-function blocks.
- Reserve `__init` and `__start` and record them in module metadata.
- Resolve plain module functions to automatic global bindings.
- Resolve dotted internal functions only through `make.func`.
- Add pretty source diagnostics and end-to-end assembly tests.

## Stage 4: VM Module Representation

- Replace the temporary string-keyed global map with `[]core.Value`.
- Allocate globals from `bytecode.Module.global_count`.
- Keep bytecode constants as data; do not restore the runtime constant cache.
- Resolve exports through the serialized export table.
- Materialize static module functions before running `__init`.
- Define ownership and failure behavior for partially initialized modules.

## Stage 5: Execution Core

- Add runtime function objects containing module and function indices.
- Implement frame creation using stack windows for locals and operands.
- Implement constants, local/global loads and stores, arithmetic, branches,
  calls, returns, fields, classes, and module loading.
- Run `__init` during module loading and `__start` for the root module.
- Add stack, arity, index, and callable validation errors.

## Stage 6: Closures

- Add capture metadata parsing and builder validation.
- Add `load.capture` and `store.capture`.
- Implement `make.func` for internal functions with empty or non-empty capture
  lists.
- Implement open and closed upvalues.
- Ensure closures sharing one local share one upvalue.
- Add nested closure and garbage-collection tests.

## Stage 7: Imports, Serialization, and Debug Information

- Finalize static imports and live-binding behavior.
- Define a versioned binary module format.
- Serialize constants, functions, globals, imports, exports, instructions, and
  optional debug data.
- Verify all indices and kinds during deserialization before execution.
- Keep debug names optional and removable.

## Immediate Next Step

Do not implement assembler syntax first. Start with Stage 1 so the builder and
assembler have stable bytecode structures to target. Preserve the existing
trailing-label regression tests while replacing labels with blocks.
