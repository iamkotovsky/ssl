# Implementation Roadmap

This roadmap starts from the current code, not from the older bytecode design.
Each stage should leave the packages it touches compiling with focused tests.

## Completed Foundation

- Compact bytecode constants, instructions, functions, modules, and ownership.
- Per-function instruction arrays and a dedicated initializer index.
- Indexed globals and named exports.
- Optional structured debug metadata and readable module dumps.
- Symbolic bytecode builder with handles for constants, globals, functions,
  parameters, locals, and labels.
- Builder lowering through `finish` with ownership and invariant checks.
- Runtime heap, object, class, binding, and core-runtime bootstrapping.
- VM/program/module scaffolding.

## Stage 1: Finish the Builder Execution Model

- Define exact stack effects for every opcode.
- Define the `Call` and `Return` stack contracts.
- Add builder helpers for the remaining opcodes instead of exposing raw
  operands casually.
- Design lexical scope APIs.
- Track active locals separately from temporary operand depth.
- Drop scope locals and reuse their indices safely.
- Validate stack shape at labels and control-flow joins.
- Add local lifetime, nested scope, branch, loop, call, and return tests.

This is the immediate design task. The current sequential `local` metadata is
not sufficient for real control flow.

## Stage 2: Complete Runtime Value and Callable Foundations

- Add nil, integer, float, UTF-8 string, and basic collection runtime objects.
- Define the core callable protocol shared by native and bytecode functions.
- Add native-function and bytecode-function classes.
- Define special-method fallback and optimized descriptor dispatch.
- Finalize freezing/read-only rules for core classes and special methods.
- Add GC tests covering the new values and callable objects.

## Stage 3: Repair and Implement the VM

- Replace stale bytecode type names in `Frame`.
- Replace string-keyed module globals with indexed `[]core.Value` storage.
- Define frame layout for parameters, local base, active locals, and
  temporaries.
- Implement the fetch/decode/dispatch loop.
- Implement constants, global/parameter/local access, arithmetic, jumps,
  fields, classes, calls, returns, and halt.
- Execute the initializer during module loading.
- Resolve and call exported `__start` only for program execution.
- Add instruction, frame, module lifecycle, and GC-root tests.

## Stage 4: Closures

- Add capture declarations and operands to the symbolic builder.
- Lower parameter, local, and parent-capture sources to bytecode captures.
- Implement `Load_Capture` and `Store_Capture`.
- Implement open and closed upvalue cells.
- Close locals before scope exit or frame return.
- Verify shared cells across sibling and nested closures.

## Stage 5: Rewrite the Assembler

- Keep the existing lexer/error-reporting pieces that still fit.
- Replace all old bytecode builder usage with `bytecode/builder`.
- Parse globals, exports, functions, parameters, scopes, labels, and
  instructions.
- Keep assembler symbol tables and duplicate-name diagnostics outside the
  builder.
- Lower `source.sa` or a smaller canonical subset end to end.
- Add source-location and malformed-program tests.

The assembler should be repaired after the builder's stack and call semantics
are stable, otherwise its syntax would target a moving API.

## Stage 6: Serialization and Module Linking

- Define a versioned binary format.
- Add variable-length integer encoding and fixed `f64` encoding.
- Serialize constants, functions, captures, instructions, globals, exports,
  and optional debug metadata.
- Validate all untrusted data while decoding.
- Define imports and indexed linking, including live-binding behavior if the
  language adopts it.
- Add round-trip, malformed-input, compatibility, and stripped-debug tests.

## Stage 7: High-Level SSL Front End

- Define tokens, AST, and source diagnostics.
- Parse the language represented by `source.ssl` incrementally.
- Introduce a target-independent IR only when control-flow analysis or other
  compiler needs justify it.
- Lower the compiler output through `bytecode/builder`.
- Add source-to-bytecode and source-to-execution tests.

## Immediate Next Step

Specify the builder's stack, scope, call, and return invariants on paper and in
tests before adding more instruction helpers. That decision controls locals,
branches, loops, frames, closures, and the future assembler grammar.
