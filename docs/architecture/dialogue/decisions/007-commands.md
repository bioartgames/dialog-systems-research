# ADR 007: Commands

**Status:** Accepted  
**Date:** 2026-07-05  
**Decisions:** D7.1–D7.8, D9.6

## Context

Dialogic uses typed events; DM tokenizes mutations at compile. Need compile-time closed command set separate from runtime registration (HC1 resolution).

## Decision

1. **CommandRegistry** for runtime dispatch (D7.1).
2. **Built-ins:** `wait`, `set_flag`, `emit` (D7.2).
3. **Pre-tokenized args** at compile (D7.3).
4. **Async handlers awaited** by controller (D7.4).
5. **`command_executed` signal**; `@emit` uses `("emit", args)` (D7.5).
6. **Unknown commands fail at compile** against built-ins + CommandManifest (D7.6).
7. **Syntax:** space-separated — `@wait 1.5`, `@set_flag name true`, `@emit signal arg` (D7.7).
8. **`register(name, handler: Callable)`** — `handler(args: PackedStringArray)` may await (D7.8).
9. **CommandManifest** Resource with `@export var commands: PackedStringArray` (D9.6).

## Consequences

- Game commands must be in manifest AND registered at runtime.
- Compile never inspects `CommandRegistry`.
- `@open_shop`, `@cutscene`, `@camera`, `@anim` require manifest entries.

## References

- [02-authoring-format.md](../02-authoring-format.md)
- [03-compilation-and-data.md](../03-compilation-and-data.md)
