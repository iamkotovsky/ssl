# Design Direction

This document separates settled architectural decisions from work that is not
implemented yet.

## Layering

The intended data flow is:

```text
source language or assembly
          -> symbolic bytecode builder
          -> bytecode module
          -> loader and VM
          -> runtime objects
```

`bytecode` owns only the compact executable data model, constructors,
destruction, serialization support, and debug representation. Complicated
construction logic belongs above it.

`bytecode/builder` is allowed to know bytecode details. It provides stable
symbolic handles and lowers them to numeric bytecode indices. It is not a
target-independent compiler IR.

A future high-level compiler may introduce a real IR if control-flow analysis,
optimization, or multiple targets make one useful.

## Bytecode Module

Functions are top-level module entries, not constants. Each function owns its
instruction array:

```odin
Func :: struct {
    arity:    u32,
    captures: []Capture,
    insts:    []Inst,
}
```

A module contains:

```odin
Module :: struct {
    init:    Func_Idx,
    globals: u32,
    consts:  []Const,
    funcs:   []Func,
    exports: []Export,
    debug:   Debug_Info,
}
```

The initializer is special module metadata. There is no reserved entry field.
If a program should expose `__start`, the initializer creates its runtime
function and stores it in an exported global like any other public value.

Function prototypes are private module implementation details unless the
initializer deliberately exposes a function object through a global.

## Constants and Operands

Constants are serialized data, not permanent runtime objects. UTF-8 is the only
constant kind today. Likely later additions are immutable serialized blobs or
metadata such as type hints; runtime integers and floats do not need constant
entries because instructions carry them directly.

Instructions use only physical operand forms:

```text
None, I64, U32, F64
```

Symbolic meanings such as function, global, local, constant, and label belong
to the opcode and to builder handles. The opcode operand table must remain in
`bytecode` so encoders, decoders, debug tools, and constructors agree on the
layout.

Integers use signed `i64` semantically and floats use `f64`. Binary
serialization should use a variable-length integer encoding for compactness
rather than proliferating semantic opcodes such as `Make_I8`, `Make_I16`, and
`Make_I32`.

## Globals, Exports, and Initialization

Runtime module globals are indexed slots. An export maps a UTF-8 name constant
to one global index:

```odin
Export :: struct {
    name:   Const_Idx,
    global: Global_Idx,
}
```

Private global names exist only in optional debug information. Export names are
required runtime data.

The intended loader sequence is:

1. Create a module instance and allocate its indexed global slots.
2. Execute the module initializer.
3. Let the initializer construct functions, classes, or other values and store
   them in globals.
4. Mark the module initialized.
5. Resolve an exported `__start` only when the host wants to run a program.

There is no global function-binding table. Initialization bytecode performs all
bindings explicitly.

## Builder Validation

The builder stores semantic operands as Odin unions of stable handles. It keeps
construction convenient and validates each invariant at the earliest operation
that has enough information.

Loads, stores, function creation, jumps, and label binding immediately reject
invalid handles and module/function ownership mismatches. Export declaration
immediately rejects duplicate names. Label binding immediately rejects a
second binding.

`finish` is still the trust boundary between symbolic construction and raw
bytecode. It resolves valid handles and checks only incomplete whole-program
state that cannot be known earlier: a missing initializer, an unbound label, or
a label whose final target is past the function's instruction array. This
builder is a programming API, so misuse is treated as a programmer error rather
than a recoverable source diagnostic.

Recoverable syntax, duplicate-symbol, and user-input errors belong to an
assembler or compiler before it calls `finish`.

Debug-name duplication is legal in the builder. A debug name is descriptive
metadata, not identity.

## Parameters, Locals, and the Value Stack

Parameters and locals use separate namespaces and separate bytecode operations.
`Load_Param` reads an argument relative to the current frame. Locals are values
kept on the shared VM stack relative to a local base.

The intended frame window is conceptually:

```text
caller values | parameters | local_base | active locals | temporaries
```

There is no fixed local count in bytecode functions. Local declarations are
stack operations:

- An initializer leaves a value on top of the stack.
- Declaring a local makes that value part of the persistent local prefix.
- Temporary operands live above the active locals.
- Leaving a lexical scope drops its locals from the stack.
- Local indices may be reused after scope exit.

The current builder only assigns sequential local indices. Scope tracking,
stack-effect tracking, local drops, slot reuse, and control-flow merging are
still to be designed and implemented.

A crucial invariant for the future builder is that a local can only be declared
when the stack shape makes the top value safely promotable to the local prefix.
Branches must agree on local and temporary stack shape at merge points.

## Calls and Returns

All runtime language values are objects or object references. The VM should
separate execution mechanics from runtime behavior:

- The VM owns frames, instruction pointers, stack windows, calls, and returns.
- Runtime callable objects decide how a value is invoked.
- Native and bytecode functions are different runtime classes behind the same
  call protocol.

`core.Context` is the boundary between these layers. It contains the runtime
and an opaque executor callback table, but it does not depend on the `vm`
package. Runtime operations can therefore inspect parameters, push values,
call other values, dispatch a resolved callable, and return without creating a
package cycle.

Arguments and results are passed through the VM stack so every live language
value remains visible to garbage collection. The initial call contract is:

```text
... arguments callee -> ... result
```

`core.call` asks the executor to create a frame and invoke the callee from the
stack. `core.dispatch` enters an already resolved callable through the current
frame; this is the path used after an operation such as `add` resolves a
special method. Native and bytecode implementations use the same frame shape.
They publish their result on the stack and finish through `core.return_value`.

Every successful call produces exactly one value. Language-level procedures
that have no meaningful result will return a singleton nil-like object rather
than producing a different stack shape.

## Objects, Classes, and Special Methods

The runtime core contains only universal mechanisms: heap allocation, object
storage, classes, fields/methods, and core runtime roots. Concrete built-in
types should be added above this foundation when possible.

Public runtime constructors are stack-facing: for example, `new_object` and
`new_class` push the newly allocated value through `Context` immediately.
Private raw constructors exist only for runtime bootstrapping and other
internal code that must initialize an object before exposing it to execution.

An object will eventually have core operations such as call, arithmetic, field
access, indexing, and representation. The intended pattern is:

- A fast descriptor/dispatch path for the VM.
- Default behavior that resolves language-visible special methods such as
  `__call` or `__add` on the class.
- Specialized native implementations for core types where useful.
- Language-visible special methods still exist as real fields/methods so code
  can access behavior such as `12.__add`.

Class freezing and read-only bindings are the mechanisms for stabilizing core
special methods and enabling safe dispatch caching. Exact mutation rules are
not finalized.

## Closures and Captures

Final bytecode already represents capture sources:

```odin
Capture_Kind :: enum u8 {
    Param,
    Local,
    Capture,
}
```

Builder APIs and VM behavior are not implemented yet. The intended semantics
are that `Make_Func` creates a runtime function object and resolves each child
capture from the current frame's parameter, local, or existing capture.

Captured stack locals require shared upvalue cells. While a frame is active, a
cell may refer to its stack slot; before that slot disappears, the cell must be
closed into heap storage. Multiple closures capturing the same value must share
the same cell.

## Debug Information

Execution uses numeric indices. Optional debug information maps those indices
to names for globals, functions, parameters, locals, and labels.

Names are not required to be unique. Optional names use `Maybe(string)`: `nil`
means that no name was provided. A label's name is debug metadata attached to a
function-scoped instruction target.

The full developer dump prints constants and all structural fields. Empty
collections use `{}`. Serialization should allow debug information to be
stripped without changing executable semantics.

## Imports and Serialization

Neither design is complete.

Serialization should be versioned and encode integers compactly. A decoder must
validate all untrusted counts, operand kinds, indices, function targets, and
allocation sizes before producing a trusted module.

Imports should resolve names once to indexed module slots. If SSL adopts live
bindings, an imported binding can be represented as a module-instance pointer
plus a global index rather than repeated string lookup.
