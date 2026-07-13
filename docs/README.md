# SSL Project Documentation

These documents are the portable context for continuing development in another
Codex task or on another computer.

Start with:

1. [project-context.md](project-context.md) for the repository state and package
   overview.
2. [design.md](design.md) for the agreed bytecode, module, function, and closure
   direction.
3. [roadmap.md](roadmap.md) for the intended implementation order.

The documents deliberately distinguish implemented behavior from planned
behavior. `source.sa` is currently a design example, not input accepted by the
implemented assembler.

When continuing on another computer, commit and push both the source changes
and this directory. Ask the new model to inspect the repository and read these
documents before making changes.

Keep these files updated when a design decision changes or a roadmap stage is
implemented. In particular, move items from "planned" to "implemented" only
after code and tests exist.
