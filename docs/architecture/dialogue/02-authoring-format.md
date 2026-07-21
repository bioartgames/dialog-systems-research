# Authoring Format

**Decisions:** D4.1–D4.9, D7.7, D8.6, D8.7

---

## File format (D4.1, D4.9)

- **Extension:** `.dlg`
- **Scope:** One file per NPC or conversation (MML-style). No cross-file imports in v1 (D5.5).
- **Syntax:** DM-inspired subset trimmed for action-RPG use (D4.2).

---

## Lines

### Dialogue lines (D4.3)

```
Speaker: Dialogue text here.
```

- Left of `:` is `speaker_id` (stored on compiled line).
- Display name resolved **in Presentation** via `tr(speaker_id, "speakers")` (D13.3, ADR-020 D26.16). No speaker registry in v1; the speaker name receives no compiled translation identity (ADR-021 D27.12).

### Stable line IDs (D3.7, D13.2)

Optional author override:

```
[id:quest_intro] Roll: Welcome back, {player_name}.
```

If omitted, compiler generates: `{source_path}::{source_line_number}`.

> **Localization note (ADR-021):** Dialogue line body text and choice labels are localized authored text surfaces that carry a **translation identity** (distinct from the graph traversal `id`). Author-provided translation identity is optional and the compiler generates a deterministic fallback when it is absent (ADR-021 D27.4, D27.8). The authoring **expression** of a choice-label identity override is defined by a future ADR-004 amendment and is not documented here yet.

### Title entries (D3.4, D4.7)

```
~ start
Roll: Hello!
```

Titles map to line IDs in the `titles` dictionary on `CompiledDialogue`. Used as `entry` argument to `start()`.

---

## Choices (D4.4, D5.8)

```
Roll: Need anything?
- Buy items => shop
- Leave => END
- Secret option | if flag("found_cache") => cache_talk
```

- Choice line with optional `if <condition>` and `=> <title>` or `=> END`.
- Hidden when condition is false (D8.3).
- Consecutive CHOICE lines at same indent after LINE (or block start) compile to one group; shared next_id_after; runtime yields single CHOICES at first CHOICE id (D5.8).
- Choice labels are **localized** and carry translation identity (ADR-020 D26.4, ADR-021). In v1 they are delivered as **localized static text**; choice-label interpolation is excluded (ADR-022 D28.14).

---

## Branching (D4.5, D4.7)

Pythonic `if` / `elif` / `else` with indentation:

```
if flag("met_roll"):
    Roll: Good to see you again.
else:
    Roll: Who are you?
```

`=> title` and `=> END` for explicit jumps (D6.6). Goto targets must match a title key in the same file; validated at compile time (D5.9).

---

## Commands (D4.6, D7.7)

Prefix `@` distinguishes commands from dialogue (Dialogic shortcode spirit, simplified):

| Built-in | Syntax | Example |
|----------|--------|---------|
| `wait` | `@wait <seconds>` | `@wait 1.5` |
| `set_flag` | `@set_flag <name> <value>` | `@set_flag met_roll true` |
| `emit` | `@emit <signal_name> [args...]` | `@emit door_opened` |

Game commands (`@camera`, `@anim`, `@open_shop`, `@cutscene`, etc.) must be listed in `CommandManifest` and registered at runtime in `CommandRegistry` (D7.6, D9.6, D10.6).

Arguments are space-separated; strings may be quoted.

---

## Conditions — author DSL (D8.6)

Authors write facade calls directly (not `get_flag`):

| Function | Example |
|----------|---------|
| `flag(name)` | `flag("quest_done")` |
| `has_item(id)` | `has_item("energy_tank")` |
| `get_quest_state(id)` | `get_quest_state("main_01")` |

### Token grammar (D8.7)

Compiled to token arrays; runtime `ConditionEvaluator` interprets:

- **Literals:** `bool`, `int`, `float`, `string`
- **Operators:** `==`, `!=`, `<`, `<=`, `>`, `>=`, `and`, `or`, `not`
- **Calls:** `flag(name)`, `has_item(id)`, `get_quest_state(id)` only

No arbitrary method calls (D8.2).

---

## Interpolation (D8.5)

```
Roll: You have {scrap_count} scrap.
```

- `{name}` keys validated against `FlagManifest` at compile time.
- Resolved at step build via `GameContext.get_display_value(key)`.

Inline text conditionals are not supported in v1 (D8.4).

---

## Tags (D4.8, D11.7, D13.5)

`#tag` or `#key=value` on dialogue lines.

| Tag | Behavior |
|-----|----------|
| `#voice=path` | Presenter plays audio; calls `notify_presentation_finished()` on finish (D11.7). Presenter blips are optional. |
| `#time=auto` | After typewriter, Policy-timed hold (D13.5); then **auto-advance** to next step. Accept during hold skips timer and advances immediately. |
| `#time=N` | After typewriter, wait N seconds; then `notify_presentation_finished()` → `AwaitingInput`. Accept during hold skips timer. Player must press Accept to advance. |

### v1 presentation note (D11.4)

This is a **3D action RPG** with **subtitle-style dialogue only** in v1:

- **No `#portrait` tag** — do not use or document portrait tags.
- **No portrait field** on `ConversationStep`.
- Speaker name shown via Presentation subtitle or world UI.

---

## Related documents

- [03-compilation-and-data.md](03-compilation-and-data.md) — Compile pipeline and validation
- [decisions/004-authoring-format.md](decisions/004-authoring-format.md) — ADR
- [decisions/020-localization-architecture.md](decisions/020-localization-architecture.md) — Localization coverage model
- [decisions/021-localized-authoring-compiled-identity.md](decisions/021-localized-authoring-compiled-identity.md) — Translation identity contract
