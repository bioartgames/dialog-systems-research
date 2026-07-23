# Developer Guide

Dialogue Framework notes for working in this repository. For copying into a game, see [PORT.md](../PORT.md).

**Presentation policy:** `DialoguePresentationPolicy.time_auto_seconds_per_char` is seconds per character for `time=auto` holds (formerly misnamed `time_auto_chars_per_sec`). **CompiledDialogue** schema fields use `@export_storage` — serialized by the compiler/import pipeline but hidden from the Inspector so authors do not hand-edit compiled graphs.

For Integration kit adoption, see [addons/dialogue_framework/docs/integration_kit_adoption.md](../addons/dialogue_framework/docs/integration_kit_adoption.md).

**Demo translations:** Showcase strings live in [game/dialogue_demo/translations/](game/dialogue_demo/translations/) as CSV (`showcase_messages.csv`, `showcase_speakers.csv`), imported to `.translation` resources and listed under **Project Settings → Localization** (`project.godot` `[internationalization]`). The demo panel toggles locale with `TranslationServer.set_locale`.
