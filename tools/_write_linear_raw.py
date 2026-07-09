#!/usr/bin/env python3
"""Assemble tools/_linear_raw.json from list_issues export + relations sources."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

INCLUDED_RANGES = [
    (186, 275),
    (280, 284),
    (302, 345),
]

# Relations for CRG-280..283 and CRG-302..344 from Linear get_issue (includeRelations=true).
RELATIONS_EXT: dict[str, dict] = {
    "CRG-280": {
        "blocks": [],
        "blockedBy": [],
        "relatedTo": [{"id": "CRG-226", "title": "Fail import on compile errors"}],
        "duplicateOf": None,
    },
    "CRG-281": {
        "blocks": [],
        "blockedBy": [],
        "relatedTo": [{"id": "CRG-197", "title": "Implement FlagManifest Resource"}],
        "duplicateOf": None,
    },
    "CRG-282": {
        "blocks": [],
        "blockedBy": [],
        "relatedTo": [{"id": "CRG-244", "title": "Implement ConversationController.cancel()"}],
        "duplicateOf": None,
    },
    "CRG-283": {
        "blocks": [],
        "blockedBy": [],
        "relatedTo": [{"id": "CRG-224", "title": "Implement FlagManifest compile-time validation"}],
        "duplicateOf": None,
    },
    "CRG-302": {"blocks": [], "blockedBy": [], "relatedTo": [], "duplicateOf": None},
    "CRG-303": {"blocks": [], "blockedBy": [], "relatedTo": [], "duplicateOf": None},
    "CRG-304": {"blocks": [], "blockedBy": [], "relatedTo": [], "duplicateOf": None},
    "CRG-305": {"blocks": [], "blockedBy": [], "relatedTo": [], "duplicateOf": None},
    "CRG-306": {"blocks": [], "blockedBy": [], "relatedTo": [], "duplicateOf": None},
    "CRG-307": {"blocks": [], "blockedBy": [], "relatedTo": [], "duplicateOf": None},
    "CRG-308": {
        "blocks": [],
        "blockedBy": [],
        "relatedTo": [
            {
                "id": "CRG-186",
                "title": "Create addons/dialogue_framework package directory structure",
            }
        ],
        "duplicateOf": None,
    },
    "CRG-309": {
        "blocks": [],
        "blockedBy": [],
        "relatedTo": [
            {"id": "CRG-201", "title": "Implement IDialoguePresenter interface"},
            {"id": "CRG-323", "title": "Implement DialoguePresentationTheme Resource type"},
            {"id": "CRG-320", "title": "Implement DialoguePresentationInput Resource type"},
            {"id": "CRG-319", "title": "Implement DialoguePresentationPolicy Resource type"},
        ],
        "duplicateOf": None,
    },
    "CRG-310": {
        "blocks": [
            {"id": "CRG-316", "title": "Retarget demo HUD to presentation reference assets"},
            {"id": "CRG-314", "title": "Add GUT presentation integration tests for native presenter/HUD"},
            {"id": "CRG-325", "title": "Wire default input listener in native reference layout"},
        ],
        "blockedBy": [],
        "relatedTo": [
            {"id": "CRG-325", "title": "Wire default input listener in native reference layout"},
            {"id": "CRG-323", "title": "Implement DialoguePresentationTheme Resource type"},
            {"id": "CRG-321", "title": "Enforce layout slot convention in reference layouts"},
            {"id": "CRG-320", "title": "Implement DialoguePresentationInput Resource type"},
            {"id": "CRG-319", "title": "Implement DialoguePresentationPolicy Resource type"},
            {"id": "CRG-315", "title": "Update Presentation README with concrete reference assets"},
        ],
        "duplicateOf": None,
    },
    "CRG-311": {
        "blocks": [
            {"id": "CRG-324", "title": "Refactor UiReact presenter to consume Theme and Policy resources"},
        ],
        "blockedBy": [],
        "relatedTo": [
            {"id": "CRG-201", "title": "Implement IDialoguePresenter interface"},
        ],
        "duplicateOf": None,
    },
    "CRG-312": {
        "blocks": [
            {"id": "CRG-316", "title": "Retarget demo HUD to presentation reference assets"},
            {"id": "CRG-330", "title": "Wire default input listener in UiReact reference layout"},
        ],
        "blockedBy": [],
        "relatedTo": [
            {"id": "CRG-330", "title": "Wire default input listener in UiReact reference layout"},
            {"id": "CRG-321", "title": "Enforce layout slot convention in reference layouts"},
            {"id": "CRG-315", "title": "Update Presentation README with concrete reference assets"},
        ],
        "duplicateOf": None,
    },
    "CRG-313": {"blocks": [], "blockedBy": [], "relatedTo": [], "duplicateOf": None},
    "CRG-314": {
        "blocks": [{"id": "CRG-318", "title": "Document running presentation integration tests"}],
        "blockedBy": [{"id": "CRG-310", "title": "Implement native dialogue HUD scene wiring"}],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-315": {
        "blocks": [],
        "blockedBy": [],
        "relatedTo": [
            {"id": "CRG-310", "title": "Implement native dialogue HUD scene wiring"},
            {"id": "CRG-312", "title": "Migrate UiReact HUD and ui_states into presentation/"},
        ],
        "duplicateOf": None,
    },
    "CRG-316": {
        "blocks": [{"id": "CRG-317", "title": "Remove duplicated demo presentation assets after retarget"}],
        "blockedBy": [
            {"id": "CRG-312", "title": "Migrate UiReact HUD and ui_states into presentation/"},
            {"id": "CRG-310", "title": "Implement native dialogue HUD scene wiring"},
        ],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-317": {
        "blocks": [],
        "blockedBy": [{"id": "CRG-316", "title": "Retarget demo HUD to presentation reference assets"}],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-318": {
        "blocks": [],
        "blockedBy": [{"id": "CRG-314", "title": "Add GUT presentation integration tests for native presenter/HUD"}],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-319": {
        "blocks": [
            {"id": "CRG-337", "title": "Add Inspector exports for Theme Policy Input on reference presenters"},
            {"id": "CRG-336", "title": "Implement Policy text overflow modes grow/clamp/scroll"},
            {"id": "CRG-326", "title": "Ship default reference Policy resource"},
            {"id": "CRG-322", "title": "Refactor native presenter to consume Theme and Policy resources"},
            {"id": "CRG-324", "title": "Refactor UiReact presenter to consume Theme and Policy resources"},
        ],
        "blockedBy": [],
        "relatedTo": [
            {"id": "CRG-309", "title": "Implement native Godot IDialoguePresenter reference"},
            {"id": "CRG-310", "title": "Implement native dialogue HUD scene wiring"},
        ],
        "duplicateOf": None,
    },
    "CRG-320": {
        "blocks": [
            {"id": "CRG-337", "title": "Add Inspector exports for Theme Policy Input on reference presenters"},
            {"id": "CRG-328", "title": "Ship default reference Input resource"},
            {"id": "CRG-329", "title": "Implement default presentation input listener component"},
        ],
        "blockedBy": [],
        "relatedTo": [
            {"id": "CRG-309", "title": "Implement native Godot IDialoguePresenter reference"},
            {"id": "CRG-310", "title": "Implement native dialogue HUD scene wiring"},
        ],
        "duplicateOf": None,
    },
    "CRG-321": {
        "blocks": [{"id": "CRG-338", "title": "Create choices-right native layout variant"}],
        "blockedBy": [],
        "relatedTo": [
            {"id": "CRG-310", "title": "Implement native dialogue HUD scene wiring"},
            {"id": "CRG-312", "title": "Migrate UiReact HUD and ui_states into presentation/"},
        ],
        "duplicateOf": None,
    },
    "CRG-322": {
        "blocks": [
            {"id": "CRG-336", "title": "Implement Policy text overflow modes grow/clamp/scroll"},
            {"id": "CRG-326", "title": "Ship default reference Policy resource"},
            {"id": "CRG-327", "title": "Ship default reference Theme resource"},
        ],
        "blockedBy": [
            {"id": "CRG-319", "title": "Implement DialoguePresentationPolicy Resource type"},
            {"id": "CRG-323", "title": "Implement DialoguePresentationTheme Resource type"},
        ],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-323": {
        "blocks": [
            {"id": "CRG-337", "title": "Add Inspector exports for Theme Policy Input on reference presenters"},
            {"id": "CRG-327", "title": "Ship default reference Theme resource"},
            {"id": "CRG-322", "title": "Refactor native presenter to consume Theme and Policy resources"},
            {"id": "CRG-324", "title": "Refactor UiReact presenter to consume Theme and Policy resources"},
        ],
        "blockedBy": [],
        "relatedTo": [
            {"id": "CRG-309", "title": "Implement native Godot IDialoguePresenter reference"},
            {"id": "CRG-310", "title": "Implement native dialogue HUD scene wiring"},
        ],
        "duplicateOf": None,
    },
    "CRG-324": {
        "blocks": [],
        "blockedBy": [
            {"id": "CRG-319", "title": "Implement DialoguePresentationPolicy Resource type"},
            {"id": "CRG-323", "title": "Implement DialoguePresentationTheme Resource type"},
            {"id": "CRG-311", "title": "Migrate UiReact presenter into presentation/"},
        ],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-325": {
        "blocks": [{"id": "CRG-331", "title": "Refactor demo orchestrator to use default presentation input"}],
        "blockedBy": [
            {"id": "CRG-329", "title": "Implement default presentation input listener component"},
            {"id": "CRG-310", "title": "Implement native dialogue HUD scene wiring"},
        ],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-326": {
        "blocks": [{"id": "CRG-334", "title": "Implement Policy reduced-motion behavior"}],
        "blockedBy": [
            {"id": "CRG-322", "title": "Refactor native presenter to consume Theme and Policy resources"},
            {"id": "CRG-319", "title": "Implement DialoguePresentationPolicy Resource type"},
        ],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-327": {
        "blocks": [{"id": "CRG-332", "title": "Ship Theme accessibility variant resources"}],
        "blockedBy": [
            {"id": "CRG-322", "title": "Refactor native presenter to consume Theme and Policy resources"},
            {"id": "CRG-323", "title": "Implement DialoguePresentationTheme Resource type"},
        ],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-328": {
        "blocks": [],
        "blockedBy": [{"id": "CRG-320", "title": "Implement DialoguePresentationInput Resource type"}],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-329": {
        "blocks": [
            {"id": "CRG-325", "title": "Wire default input listener in native reference layout"},
            {"id": "CRG-330", "title": "Wire default input listener in UiReact reference layout"},
        ],
        "blockedBy": [{"id": "CRG-320", "title": "Implement DialoguePresentationInput Resource type"}],
        "relatedTo": [
            {
                "id": "CRG-333",
                "title": "Document presentation input vs game orchestration boundary",
            }
        ],
        "duplicateOf": None,
    },
    "CRG-330": {
        "blocks": [{"id": "CRG-331", "title": "Refactor demo orchestrator to use default presentation input"}],
        "blockedBy": [
            {"id": "CRG-329", "title": "Implement default presentation input listener component"},
            {"id": "CRG-312", "title": "Migrate UiReact HUD and ui_states into presentation/"},
        ],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-331": {
        "blocks": [],
        "blockedBy": [
            {"id": "CRG-325", "title": "Wire default input listener in native reference layout"},
            {"id": "CRG-330", "title": "Wire default input listener in UiReact reference layout"},
        ],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-332": {
        "blocks": [],
        "blockedBy": [{"id": "CRG-327", "title": "Ship default reference Theme resource"}],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-333": {
        "blocks": [],
        "blockedBy": [],
        "relatedTo": [
            {
                "id": "CRG-329",
                "title": "Implement default presentation input listener component",
            }
        ],
        "duplicateOf": None,
    },
    "CRG-334": {
        "blocks": [{"id": "CRG-335", "title": "Add tests for reduced-motion Policy on native layout"}],
        "blockedBy": [{"id": "CRG-326", "title": "Ship default reference Policy resource"}],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-335": {
        "blocks": [],
        "blockedBy": [{"id": "CRG-334", "title": "Implement Policy reduced-motion behavior"}],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-336": {
        "blocks": [],
        "blockedBy": [
            {"id": "CRG-322", "title": "Refactor native presenter to consume Theme and Policy resources"},
            {"id": "CRG-319", "title": "Implement DialoguePresentationPolicy Resource type"},
            {"id": "CRG-324", "title": "Refactor UiReact presenter to consume Theme and Policy resources"},
        ],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-337": {
        "blocks": [],
        "blockedBy": [
            {"id": "CRG-319", "title": "Implement DialoguePresentationPolicy Resource type"},
            {"id": "CRG-320", "title": "Implement DialoguePresentationInput Resource type"},
            {"id": "CRG-323", "title": "Implement DialoguePresentationTheme Resource type"},
        ],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-338": {
        "blocks": [],
        "blockedBy": [{"id": "CRG-321", "title": "Enforce layout slot convention in reference layouts"}],
        "relatedTo": [],
        "duplicateOf": None,
    },
    "CRG-339": {
        "blocks": [],
        "blockedBy": [],
        "relatedTo": [{"id": "CRG-196", "title": "Implement ConversationStep DTO"}],
        "duplicateOf": None,
    },
    "CRG-340": {"blocks": [], "blockedBy": [], "relatedTo": [], "duplicateOf": None},
    "CRG-341": {
        "blocks": [],
        "blockedBy": [],
        "relatedTo": [{"id": "CRG-211", "title": "Implement tag parser (#tag, #key=value)"}],
        "duplicateOf": None,
    },
    "CRG-342": {"blocks": [], "blockedBy": [], "relatedTo": [], "duplicateOf": None},
    "CRG-343": {"blocks": [], "blockedBy": [], "relatedTo": [], "duplicateOf": None},
    "CRG-344": {"blocks": [], "blockedBy": [], "relatedTo": [], "duplicateOf": None},
}


def target_ids() -> list[str]:
    ids: list[str] = []
    for start, end in INCLUDED_RANGES:
        ids.extend(f"CRG-{n}" for n in range(start, end))
    return ids


def sort_key(crg_id: str) -> int:
    match = re.match(r"CRG-(\d+)", crg_id)
    return int(match.group(1)) if match else 0


def load_build_relations(tools_dir: Path) -> dict[str, dict]:
    src = (tools_dir / "build_crg_relations.py").read_text(encoding="utf-8")
    marker = "RAW: dict[str, dict] = "
    raw_text = src.split(marker, 1)[1].rsplit("\n\n", 1)[0]
    namespace: dict = {}
    exec(f"RAW = {raw_text}", namespace)
    raw = namespace["RAW"]
    relations: dict[str, dict] = {}
    for issue_id, node in raw.items():
        relations[issue_id] = {
            "blocks": node.get("blocks", []),
            "blockedBy": node.get("blockedBy", []),
            "relatedTo": [],
            "duplicateOf": None,
        }
    return relations


def enrich_issue(issue: dict, relations: dict) -> dict:
    enriched = dict(issue)
    enriched.setdefault("attachments", [])
    enriched.setdefault("documents", [])
    enriched.setdefault("stateHistory", [])
    enriched["relations"] = relations
    return enriched


def main() -> int:
    tools_dir = Path(__file__).resolve().parent
    list_path = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    if list_path is None:
        print("Usage: _write_linear_raw.py <list_issues.json>", file=sys.stderr)
        return 1

    payload = json.loads(list_path.read_text(encoding="utf-8"))
    by_id = {issue["id"]: issue for issue in payload.get("issues", [])}

    relations_map = load_build_relations(tools_dir)
    relations_map.update(RELATIONS_EXT)

    wanted = target_ids()
    issues: list[dict] = []
    failed: list[str] = []

    for issue_id in wanted:
        base = by_id.get(issue_id)
        rel = relations_map.get(issue_id)
        if base is None or rel is None:
            failed.append(issue_id)
            continue
        issues.append(enrich_issue(base, rel))

    out = {"issues": issues, "failed": failed}
    out_path = tools_dir / "_linear_raw.json"
    out_path.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print(f"wrote={out_path}")
    print(f"issues={len(issues)} failed={len(failed)}")
    if failed:
        print("FAILED:", ", ".join(failed))
    return 0 if not failed else 1


if __name__ == "__main__":
    raise SystemExit(main())
