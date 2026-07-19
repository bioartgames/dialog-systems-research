# Compilation and Data Model

**Decisions:** D3.1–D3.9, D5.1–D5.10, D9.4, D9.6, D15.1–D15.4

---

## CompiledDialogue resource (D3.1, D3.9)

Godot `Resource` (`.tres`) produced at import. Top-level fields:

| Field | Type | Purpose |
|-------|------|---------|
| `resource_uid` | `String` | Stable asset identifier for save/resume |
| `source_path` | `String` | Original `.dlg` path |
| `raw_text` | `String` | Source text for debug/recompile |
| `format_version` | `int` | Schema version |
| `compiler_version` | `int` | Compiler version (D5.2) |
| `titles` | `Dictionary` | Title name → line ID (D3.4) |
| `lines` | `Dictionary` | Line ID → compiled line dict (D3.2) |
| `first_title` | `String` | Default entry title |

---

## CompiledLine schema (D3.3, D3.8)

Each line is a typed dict serialized in `lines`. **LineKind** values: `TITLE`, `LINE`, `CONDITION`, `CHOICE`, `COMMAND`, `GOTO`, `END`.

### Shared fields

| Field | Description |
|-------|-------------|
| `id` | Stable string line ID |
| `kind` | `LineKind` |
| `source_line_number` | Source line for errors/debug (D14.3) |
| `next_id` | Next line in sequence |

### Kind-specific fields

| Kind | Additional fields |
|------|-------------------|
| `LINE` | `speaker_id`, `text`, `tags`, `translation_key` |
| `CONDITION` | `condition_tokens`, `next_sibling_id`, `next_id_after` |
| `CHOICE` | `text`, `condition_tokens`, `target_line_id`, `translation_key` |
| `COMMAND` | `command_name`, `args_tokens` |
| `GOTO` | `resolved_target_line_id` (compile-time resolution per D5.9) |
| `TITLE` | `name` |

No editor metadata on compiled lines in v1 (D19.3).

---

## ConversationStep DTO (D3.6)

Yielded to presenter. **No portrait field** (D11.4).

| Kind | Fields |
|------|--------|
| `LINE` | `line_id`, `speaker_id`, `text`, `tags`, `next_line_id` |
| `CHOICES` | `line_id`, `options[{text, target_line_id, index}]`, `next_line_id_after` |
| `COMMAND` | `line_id`, `command_name`, `args_tokens` |
| `WAIT` | `line_id`, `duration_seconds` |
| `END` | `line_id` |

Runner skips `CONDITION`, `GOTO`, `TITLE` without yielding.

---

## Compilation pipeline (D5.1–D5.11)

1. **EditorImportPlugin** triggers on `.dlg` import (D5.1).
2. **Three stages** (D5.4): raw lines → indent tree → flat graph + tokenize.
3. **Tokenize** conditions and commands at compile time (D5.6).
4. **Choice grouping** (D5.8): consecutive CHOICE lines at same indent after LINE (or block start) compile to one group; shared next_id_after; runtime yields single CHOICES at first CHOICE id.
5. **Condition-block exit wiring** (D5.11): after linear `_wire_next_ids`, each if/elif/else block sets `next_id_after` on all condition headers to the first line after the block; each branch body's **last** line `next_id` is set to the same continuation. Mirrors D5.8 choice grouping.
6. **Goto validation** (D5.9): `=> END` → END node; `=> title` must exist in `titles` map.
7. **Fail import on errors** — no invalid `.tres` (D5.3, D15.1).
8. **`compile_string()`** for dev/tests only; production uses imported `.tres` (D5.7).

---

## Manifests (D5.10, D9.4, D9.6)

### ProjectSettings paths

| Key | Value |
|-----|-------|
| `dialogue_framework/flag_manifest_path` | `res://` path to `FlagManifest` |
| `dialogue_framework/command_manifest_path` | `res://` path to `CommandManifest` |

Import plugin loads both before compiling each `.dlg`.

### FlagManifest

```gdscript
# Game-authored Resource
@export var flags: PackedStringArray
```

Validates `flag()` references and `{brace}` interpolation keys at compile time. `has_item` / `get_quest_state` string args are **not** manifest-validated in v1 (D9.4).

### CommandManifest

```gdscript
@export var commands: PackedStringArray
```

Compile validates `@command` names against built-ins (`wait`, `set_flag`, `emit`) plus manifest entries. `CommandRegistry` is runtime-only (D7.6).

---

## Validation tiers (D15.3, D15.4)

| Context | FlagManifest missing | Unknown flags/commands |
|---------|---------------------|------------------------|
| Editor import (local) | Warn + skip flag validation | Error on non-built-in `@command` if CommandManifest path missing |
| Headless compile (`--strict`) | Error | Error |

If `command_manifest_path` is missing, dialogue files using only built-in commands still compile successfully (D15.3).

CI runs headless Godot compile-all with `--strict` (D15.4, D18.2).

---

## Strict compile checks (D15.1)

- Syntax errors
- Unknown `@commands` (not built-in or in CommandManifest)
- Unknown flags / `{brace}` keys (when manifest present)
- Invalid goto targets (not in `titles` map)

---

## Optional compile processor (D17.3)

`ProjectSettings dialogue_framework/compile_processor_path` → script with:

- `_preprocess_line(raw: String) -> String`
- `_post_process_line(line: CompiledLine) -> void`

Skipped if path empty.

---

## Related documents

- [02-authoring-format.md](02-authoring-format.md) — `.dlg` syntax
- [04-runtime-and-integration.md](04-runtime-and-integration.md) — Runtime consumption
- [decisions/003-data-model.md](decisions/003-data-model.md) — ADR
- [decisions/005-compilation-pipeline.md](decisions/005-compilation-pipeline.md) — ADR
