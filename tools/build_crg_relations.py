#!/usr/bin/env python3
"""Build crg_relations.json from Linear get_issue raw responses."""
import json
import re
import sys
from pathlib import Path

INCLUDED_RANGES = [
    (186, 275),   # CRG-186 .. CRG-274
    (280, 284),   # CRG-280 .. CRG-283
    (302, 345),   # CRG-302 .. CRG-344
]


def included_ids() -> set[str]:
    ids: set[str] = set()
    for start, end in INCLUDED_RANGES:
        for n in range(start, end):
            ids.add(f"CRG-{n}")
    return ids


def node_from_issue(issue: dict) -> dict:
    rel = issue.get("relations") or {}
    node: dict = {
        "blockedBy": [{"id": r["id"], "title": r["title"]} for r in rel.get("blockedBy", [])],
        "blocks": [{"id": r["id"], "title": r["title"]} for r in rel.get("blocks", [])],
    }
    if issue.get("parentId"):
        node["parentId"] = issue["parentId"]
    if issue.get("legacyId"):
        node["legacyId"] = issue["legacyId"]
    return node


def sort_key(crg_id: str) -> int:
    m = re.match(r"CRG-(\d+)", crg_id)
    return int(m.group(1)) if m else 0


def build(raw_path: Path) -> tuple[dict[str, dict], list[str], list[str]]:
    with raw_path.open(encoding="utf-8") as f:
        payload = json.load(f)

    issues: list[dict] = payload.get("issues", [])
    failed: list[str] = payload.get("failed", [])
    include = included_ids()

    result: dict[str, dict] = {}
    for issue in issues:
        iid = issue["id"]
        if iid in include:
            result[iid] = node_from_issue(issue)

    conflicts: list[str] = []
    for iid, node in result.items():
        for field in ("blockedBy", "blocks"):
            for rel in node[field]:
                rid = rel["id"]
                if rid not in include:
                    conflicts.append(f"{iid}.{field} -> {rid} ({rel['title']})")

    ordered = {k: result[k] for k in sorted(result, key=sort_key)}
    return ordered, failed, conflicts


def main() -> None:
    raw_path = Path(__file__).with_name("_linear_raw.json")
    if not raw_path.exists():
        print(f"Missing {raw_path}", file=sys.stderr)
        sys.exit(1)

    ordered, failed, conflicts = build(raw_path)

    out = Path(__file__).with_name("crg_relations.json")
    with out.open("w", encoding="utf-8") as f:
        json.dump(ordered, f, indent=2, ensure_ascii=False)
        f.write("\n")

    print(f"Wrote {len(ordered)} issues to {out}")
    if failed:
        print(f"Failed: {', '.join(failed)}")
    if conflicts:
        print(f"Conflicts ({len(conflicts)}):")
        for c in conflicts:
            print(f"  {c}")


if __name__ == "__main__":
    main()
