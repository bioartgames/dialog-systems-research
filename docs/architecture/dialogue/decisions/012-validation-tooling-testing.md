# ADR 012: Validation, Tooling, and Testing

**Status:** Accepted  
**Date:** 2026-07-05  
**Decisions:** D15.1–D15.4, D16.1–D16.4, D17.1–D17.4, D18.1–D18.4

## Context

Strict compile prevents runtime surprises. CI needs headless validation. Extension points should mirror DM processor hook without over-engineering v1.

## Decision

### Validation (D15.x)

1. **Strict compile:** syntax, commands, flags, gotos (D15.1).
2. **Graceful end** on invalid cursor — `push_error`, dismiss, `conversation_ended(compiled)` (D15.2).
3. **Tiered manifests:** editor warn+skip; `--strict` errors; CommandManifest missing → error on non-built-in commands (D15.3).
4. **Headless Godot compile-all in CI** with `--strict` (D15.4).

### Testing (D16.x)

1. **Three layers:** unit / integration / optional game (D16.1).
2. **GUT only** — tests in addon `tests/` (D16.2).
3. **MockGameContext** for runner tests (D16.3).
4. **Golden compile snapshots** for compiler regression (D16.4).

### Extensions (D17.x)

1. **Extension points:** Registry, GameContext, Presenter, CompileProcessor (D17.1).
2. **No custom line types v1** (D17.2).
3. **DialogueCompileProcessor** optional via ProjectSettings path (D17.3).
4. **Semver on addon** (D17.4).

### Tooling (D18.x)

1. **Import plugin only v1** — no visual editor (D18.1).
2. **Headless Godot script for CI** (D18.2).
3. **Author in external text IDE** (D18.3).
4. **Godot Import tab errors + console** (D18.4).

## Consequences

- CI must run Godot headless with `--strict`.
- Games without manifests get lenient local import, strict CI failures.
- Compile processor is optional advanced hook.

## References

- [03-compilation-and-data.md](../03-compilation-and-data.md)
- [05-open-questions.md](../05-open-questions.md)
