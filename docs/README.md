# SSL Project Documentation

These documents describe the repository as it exists now and the design being
built toward.

- [project-context.md](project-context.md) is the factual snapshot: packages,
  APIs, examples, tests, and known incompatibilities.
- [design.md](design.md) records the current architectural decisions and marks
  unfinished parts explicitly.
- [roadmap.md](roadmap.md) gives the next implementation order from the current
  codebase.

The important package boundary is:

```text
assembler / future compiler
            |
            v
    bytecode/builder
            |
            v
        bytecode
            |
            v
       VM + runtime
```

`bytecode` is the compact, owned module representation. `bytecode/builder` is
the convenient symbolic construction layer. The assembler, VM, and high-level
front end are not complete yet.

Keep these files synchronized with source changes. Do not describe a planned
feature as implemented until its code and focused tests exist.
