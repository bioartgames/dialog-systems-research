# ADR 009: Game Integration

**Status:** Accepted  
**Date:** 2026-07-05  
**Decisions:** D10.1–D10.6

## Context

3D action RPG needs shops, cutscenes, camera, and animations as game modes—not HUD panels inside dialogue UI.

## Decision

1. **GameContext** abstract class with minimum methods: `get_flag`, `set_flag`, `has_item`, `give_item`, `remove_item`, `get_quest_state`, `start_quest`, `complete_quest`, `get_display_value`, `get_binding` (D10.1).
2. **`@open_shop`** pauses/ends dialogue; switches to shop game mode (D10.2).
3. **`@cutscene`** async; UI hidden; requires game `CutsceneDirector` (D10.3).
4. **Quest methods** on context; game `@commands` delegate (D10.4).
5. **Inventory methods** on context; `has_item` in evaluator (D10.5).
6. **Game registers `@camera`, `@anim`** — framework agnostic (D10.6).

## Consequences

- Game implements one `GameContext` subclass (or per-NPC instances), **or** adopts the optional Integration kit reference `GameContext` (ADR-024) — authoritative save remains game-owned.
- Shop/cutscene are not framework features—only command hooks.
- All game commands need `CommandManifest` entries and `CommandRegistry` handlers (optionally via Integration command bridge).

## Localization amendment (ADR-022 D28.15)

`GameContext.get_display_value` continues to own delegated interpolation values (D10.1). During a LINE locale refresh, Runtime re-invokes the delegated value mechanism at reconstruction time so locale-sensitive game values are updated alongside the re-resolved localized body text (ADR-022 D28.15). Ownership of interpolation value content and formatting remains with the game.

## References

- [04-runtime-and-integration.md](../04-runtime-and-integration.md)
- [decisions/022-localized-runtime-delivery-locale-switching.md](022-localized-runtime-delivery-locale-switching.md)
