#!/usr/bin/env python3
"""Archive Linear issues via GraphQL issueArchive mutation.

Requires LINEAR_API_KEY (Personal API key from Linear Settings → API).
Usage:
  set LINEAR_API_KEY=lin_api_...
  python game/dialogue_demo/tools/linear_archive_issues.py .linear_archive_ids.txt
"""

from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.request

GRAPHQL_URL = "https://api.linear.app/graphql"
ARCHIVE_MUTATION = """
mutation IssueArchive($id: String!) {
  issueArchive(id: $id) {
    success
    issue { id archivedAt }
  }
}
"""


def archive_issue(api_key: str, issue_id: str) -> dict:
    payload = json.dumps(
        {"query": ARCHIVE_MUTATION, "variables": {"id": issue_id}}
    ).encode("utf-8")
    req = urllib.request.Request(
        GRAPHQL_URL,
        data=payload,
        headers={
            "Content-Type": "application/json",
            "Authorization": api_key,
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        body = json.loads(resp.read().decode("utf-8"))
    if body.get("errors"):
        raise RuntimeError(f"{issue_id}: {body['errors']}")
    data = body.get("data", {}).get("issueArchive")
    if not data or not data.get("success"):
        raise RuntimeError(f"{issue_id}: archive failed: {body}")
    return data


def main() -> int:
    api_key = os.environ.get("LINEAR_API_KEY", "").strip()
    if not api_key:
        print("ERROR: Set LINEAR_API_KEY to a Linear personal API key.", file=sys.stderr)
        return 1

    ids_path = sys.argv[1] if len(sys.argv) > 1 else ".linear_archive_ids.txt"
    with open(ids_path, encoding="utf-8") as f:
        issue_ids = [line.strip() for line in f if line.strip()]

    ok = 0
    failed: list[str] = []
    for i, issue_id in enumerate(issue_ids, 1):
        try:
            result = archive_issue(api_key, issue_id)
            archived_at = result.get("issue", {}).get("archivedAt", "?")
            print(f"[{i}/{len(issue_ids)}] OK {issue_id} archivedAt={archived_at}")
            ok += 1
        except (urllib.error.HTTPError, RuntimeError, urllib.error.URLError) as exc:
            print(f"[{i}/{len(issue_ids)}] FAIL {issue_id}: {exc}", file=sys.stderr)
            failed.append(issue_id)
        time.sleep(0.15)

    print(f"\nDone: {ok}/{len(issue_ids)} archived, {len(failed)} failed")
    if failed:
        print("Failed:", ", ".join(failed), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
