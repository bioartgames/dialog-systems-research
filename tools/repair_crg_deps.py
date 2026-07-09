#!/usr/bin/env python3
"""Apply hard prerequisite edges to crg_relations.json and validate DAG."""
from __future__ import annotations

import json
import sys
from pathlib import Path

DAG_PATH = Path(__file__).with_name("crg_relations.json")

# (blocker, blocked, justification)
NEW_EDGES: list[tuple[str, str, str]] = [
    ("CRG-334", "CRG-335", "CRG-335 tests reduced-motion Policy behavior implemented by CRG-334"),
    ("CRG-324", "CRG-336", "CRG-336 AC requires Ui React presenter to apply Policy overflow semantics"),
]

TITLES: dict[str, str] = {
    "CRG-324": "Refactor UiReact presenter to consume Theme and Policy resources",
    "CRG-334": "Implement Policy reduced-motion behavior",
    "CRG-335": "Add tests for reduced-motion Policy on native layout",
    "CRG-336": "Implement Policy text overflow modes grow/clamp/scroll",
}


def has_edge(graph: dict, blocker: str, blocked: str) -> bool:
    return any(e["id"] == blocker for e in graph[blocked]["blockedBy"])


def add_edge(graph: dict, blocker: str, blocked: str) -> bool:
    if has_edge(graph, blocker, blocked):
        return False
    title = TITLES.get(blocker, blocker)
    graph[blocked]["blockedBy"].append({"id": blocker, "title": title})
    blocked_title = TITLES.get(blocked, blocked)
    graph[blocker]["blocks"].append({"id": blocked, "title": blocked_title})
    return True


def detect_cycle(graph: dict) -> list[str] | None:
    visiting: set[str] = set()
    visited: set[str] = set()
    stack: list[str] = []

    def dfs(node: str) -> list[str] | None:
        visiting.add(node)
        stack.append(node)
        for rel in graph[node]["blockedBy"]:
            pred = rel["id"]
            if pred not in graph:
                continue
            if pred in visiting:
                idx = stack.index(pred)
                return stack[idx:] + [pred]
            if pred not in visited:
                cycle = dfs(pred)
                if cycle:
                    return cycle
        stack.pop()
        visiting.remove(node)
        visited.add(node)
        return None

    for node in graph:
        if node not in visited:
            cycle = dfs(node)
            if cycle:
                return cycle
    return None


def compute_layer(graph: dict, node: str, memo: dict[str, int]) -> int:
    if node in memo:
        return memo[node]
    blockers = [b["id"] for b in graph[node]["blockedBy"] if b["id"] in graph]
    layer = 0 if not blockers else 1 + max(compute_layer(graph, b, memo) for b in blockers)
    memo[node] = layer
    return layer


def fanout(graph: dict, node: str) -> int:
    return len(graph[node]["blocks"])


def topo_order(graph: dict, exclude: set[str]) -> list[str]:
    remaining = {k for k in graph if k not in exclude}
    order: list[str] = []
    while remaining:
        ready = sorted(
            [n for n in remaining if all(b["id"] not in remaining for b in graph[n]["blockedBy"])],
            key=lambda x: int(x.split("-")[1]),
        )
        if not ready:
            raise RuntimeError(f"cycle among {remaining}")
        order.extend(ready)
        remaining -= set(ready)
    return order


def main() -> int:
    graph: dict = json.loads(DAG_PATH.read_text(encoding="utf-8"))
    added: list[tuple[str, str, str]] = []

    for blocker, blocked, why in NEW_EDGES:
        if blocker not in graph or blocked not in graph:
            print(f"SKIP missing node: {blocker} -> {blocked}", file=sys.stderr)
            continue
        if add_edge(graph, blocker, blocked):
            added.append((blocker, blocked, why))

    cycle = detect_cycle(graph)
    if cycle:
        print(f"CYCLE: {' -> '.join(cycle)}", file=sys.stderr)
        return 1

    DAG_PATH.write_text(json.dumps(graph, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    exclude_epics = {f"CRG-{n}" for n in range(302, 308)}
    backlog_impl = [
        n
        for n in graph
        if n not in exclude_epics and 302 <= int(n.split("-")[1]) <= 344
    ]
    order = topo_order(graph, exclude_epics | {n for n in graph if n not in backlog_impl and int(n.split("-")[1]) < 302})
    # eligible backlog only
    eligible = [n for n in backlog_impl if all(b["id"] not in backlog_impl or b["id"] in exclude_epics for b in graph[n]["blockedBy"])]
    layers = {n: compute_layer(graph, n, {}) for n in backlog_impl}

    print("ADDED:")
    for blocker, blocked, why in added:
        print(f"  {blocker} -> {blocked}: {why}")

    print(f"\nAcyclic: True")
    print(f"Eligible backlog (no impl blockers in 302-344): {len(eligible)}")
    layer0 = sorted([n for n in eligible if layers[n] == 0], key=lambda x: int(x.split("-")[1]))
    print(f"Layer 0 eligible: {layer0}")

    full_backlog_order = topo_order(
        graph,
        {n for n in graph if n not in backlog_impl},
    )
    print("\nBacklog topological order (CRG-302..344 impl):")
    for n in full_backlog_order:
        if n in backlog_impl:
            print(f"  L{layers[n]:2d} {n} fanout={fanout(graph, n)}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
