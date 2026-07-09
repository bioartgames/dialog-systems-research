#!/usr/bin/env python3
"""Validate crg_relations.json against Dialogue Framework Linear backlog."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DAG_PATH = ROOT / "tools" / "crg_relations.json"

IMPL_RANGES = [(186, 275), (280, 284), (302, 345)]


def expected_ids() -> set[str]:
    ids: set[str] = set()
    for start, end in IMPL_RANGES:
        for n in range(start, end):
            ids.add(f"CRG-{n}")
    return ids


def main() -> None:
    dag: dict = json.load(DAG_PATH.open(encoding="utf-8"))
    dag_ids = set(dag.keys())
    expected = expected_ids()

    print(f"Nodes: {len(dag_ids)} (expected {len(expected)})")
    print(f"ID set match: {dag_ids == expected}")
    if dag_ids != expected:
        print("  extra:", sorted(dag_ids - expected))
        print("  missing:", sorted(expected - dag_ids))

    keys = list(dag.keys())
    sorted_ok = keys == sorted(keys, key=lambda x: int(x.split("-")[1]))
    print(f"Numerically sorted: {sorted_ok}")

    removed = [k for k in dag if 290 <= int(k.split("-")[1]) <= 301]
    print(f"CRG-290..301 present (should be empty): {removed}")

    schema_errors: list[str] = []
    for node_id, node in dag.items():
        if "layer" in node:
            schema_errors.append(f"{node_id}: unexpected layer")
        for field in ("blockedBy", "blocks"):
            if field not in node:
                schema_errors.append(f"{node_id}: missing {field}")
            else:
                for entry in node[field]:
                    if set(entry) - {"id", "title"}:
                        schema_errors.append(f"{node_id}: bad keys in {field}")
                    if entry["id"] not in dag_ids:
                        schema_errors.append(f"{node_id}: dangling ref {entry['id']}")

    print(f"Schema/ref errors: {len(schema_errors)}")
    for err in schema_errors[:10]:
        print(f"  {err}")

    sys.exit(1 if schema_errors or dag_ids != expected or removed else 0)


if __name__ == "__main__":
    main()
