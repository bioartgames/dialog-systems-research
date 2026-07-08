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
- Display name resolved at runtime via `tr(speaker_id, "speakers")` (D13.3). No speaker registry in v1.

### Stable line IDs (D3.7, D13.2)

Optional author override:

```
[id:quest_intro] Roll: Welcome back, {player_name}.
```

If omitted, compiler generates: `{source_path}::{source_line_number}`.

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
| `#time=auto` | Auto-advance after `visible_text.length() * 0.02` seconds (BBCode stripped); min 0.5s, max 8.0s (D13.5) |
| `#time=N` | Presenter timer for N seconds; then `notify_presentation_finished()` |

### v1 presentation note (D11.4)

This is a **3D action RPG** with **subtitle-style dialogue only** in v1:

- **No `#portrait` tag** — do not use or document portrait tags.
- **No portrait field** on `ConversationStep`.
- Speaker name shown via Presentation subtitle or world UI.

---

## Related documents

- [03-compilation-and-data.md](03-compilation-and-data.md) — Compile pipeline and validation
- [decisions/004-authoring-format.md](decisions/004-authoring-format.md) — ADR
