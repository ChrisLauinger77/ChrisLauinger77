#!/usr/bin/env python3
"""Fasst alle offenen Renovate Dependency Dashboards repo-übergreifend zusammen.

Nutzt die GitHub-CLI (gh) zur Authentifizierung und holt alle Dashboards
mit einer GraphQL-Suche.

Beispiele:
  renovate-dashboards                       # eigene Repos
  renovate-dashboards -o meine-org -o ich   # mehrere Owner/Orgs
  renovate-dashboards --details             # zusätzlich alle Einträge auflisten
  renovate-dashboards --markdown            # Markdown-Tabelle mit Links
  renovate-dashboards --json                # Rohdaten als JSON
"""

import argparse
import json
import os
import re
import subprocess
import sys

# Known dashboard sections in display order: (heading, column label, is_problem)
KNOWN_SECTIONS = [
    ("Repository problems", "Probleme", True),
    ("Config Migration Needed", "Migration", True),
    ("Errored", "Fehler", True),
    ("Edited/Blocked", "Blockiert", False),
    ("Rate-Limited", "RateLimit", False),
    ("Pending Approval", "Approval", False),
    ("PR Creation Approval Required", "PR-Approval", False),
    ("Pending Status Checks", "Checks", False),
    ("Pending Branch Automerge", "Automerge", False),
    ("Awaiting Schedule", "Schedule", False),
    ("Open", "Offen", False),
    ("Other Branches", "Branches", False),
    ("Ignored or Blocked", "Ignoriert", False),
    ("Deprecations / Replacements", "Deprecated", True),
    ("Vulnerabilities", "Vulns", True),
]
DETECTED = "Detected Dependencies"

QUERY = """
query($q: String!, $cursor: String) {
  search(query: $q, type: ISSUE, first: 50, after: $cursor) {
    pageInfo { hasNextPage endCursor }
    nodes {
      ... on Issue {
        number url title updatedAt body
        repository { nameWithOwner isArchived }
      }
    }
  }
}
"""


def gh(*args):
    try:
        out = subprocess.run(["gh", *args], check=True, capture_output=True, text=True)
    except FileNotFoundError:
        sys.exit("Fehler: GitHub-CLI 'gh' nicht gefunden.")
    except subprocess.CalledProcessError as e:
        sys.exit(f"Fehler bei 'gh {' '.join(args[:2])}': {e.stderr.strip()}")
    return out.stdout


def fetch_dashboards(owners, author, title):
    owner_q = " ".join(f"user:{o}" for o in owners)
    q = f'is:issue is:open author:{author} in:title "{title}" {owner_q}'
    cursor, issues = None, []
    while True:
        args = ["api", "graphql", "-f", f"query={QUERY}", "-f", f"q={q}"]
        if cursor:
            args += ["-f", f"cursor={cursor}"]
        data = json.loads(gh(*args))["data"]["search"]
        issues += [n for n in data["nodes"] if n]
        if not data["pageInfo"]["hasNextPage"]:
            return issues
        cursor = data["pageInfo"]["endCursor"]


def clean(text):
    text = re.sub(r"<!--.*?-->", "", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)  # strip markdown links
    return text.strip()


def parse_body(body):
    """Return ({section: [items]}, updates_available, callouts)."""
    sections, current = {}, None
    updates = callouts = 0
    for line in body.splitlines():
        if m := re.match(r"^##\s+(.+?)\s*$", line):
            current = m.group(1)
            sections.setdefault(current, [])
            continue
        if line.strip() == "---":
            current = None
            continue
        if re.match(r"^>\s*\[!(WARNING|CAUTION|IMPORTANT)\]", line):
            callouts += 1
        if current is None:
            continue
        if current == DETECTED:
            if "[Updates:" in line:
                updates += 1
            continue
        if m := re.match(r"^\s*- (?:\[[ xX]\] )?(.*)", line):
            # Skip "do this for all" meta checkboxes
            if re.search(r"<!--\s*[\w-]*-all-[\w-]*\s*-->|approveAll", m.group(1)):
                continue
            sections[current].append(clean(m.group(1)))
    sections.pop(DETECTED, None)
    return {k: v for k, v in sections.items() if v}, updates, callouts


def label_for(heading):
    for known, label, problem in KNOWN_SECTIONS:
        if heading.lower().startswith(known.lower()):
            return label, problem
    return heading[:12], False


def order_key(heading):
    for i, (known, _, _) in enumerate(KNOWN_SECTIONS):
        if heading.lower().startswith(known.lower()):
            return (i, heading)
    return (len(KNOWN_SECTIONS), heading)


def use_color():
    return sys.stdout.isatty() and "NO_COLOR" not in os.environ


def paint(text, code, enabled):
    return f"\033[{code}m{text}\033[0m" if enabled else text


def main():
    p = argparse.ArgumentParser(
        description="Renovate Dependency Dashboards repo-übergreifend anzeigen.")
    p.add_argument("-o", "--owner", action="append",
                   help="GitHub-User oder Org (mehrfach möglich; Standard: eigener Login)")
    p.add_argument("--author", default="app/renovate",
                   help="Autor der Dashboard-Issues (Standard: app/renovate; "
                        "bei Self-Hosted z.B. den Bot-User)")
    p.add_argument("--title", default="Dependency Dashboard",
                   help="Titel der Dashboard-Issues (Standard: 'Dependency Dashboard')")
    p.add_argument("--include-archived", action="store_true",
                   help="auch archivierte Repos anzeigen")
    p.add_argument("-a", "--all", action="store_true",
                   help="auch Repos ohne offene Einträge anzeigen")
    fmt = p.add_mutually_exclusive_group()
    fmt.add_argument("-d", "--details", action="store_true",
                     help="Tabelle plus alle Einträge je Repo")
    fmt.add_argument("--markdown", action="store_true", help="Markdown-Tabelle ausgeben")
    fmt.add_argument("--json", action="store_true", help="Rohdaten als JSON ausgeben")
    args = p.parse_args()

    owners = args.owner or [gh("api", "user", "--jq", ".login").strip()]
    rows = []
    for issue in fetch_dashboards(owners, args.author, args.title):
        repo = issue["repository"]
        if repo["isArchived"] and not args.include_archived:
            continue
        sections, updates, callouts = parse_body(issue["body"] or "")
        rows.append({
            "repo": repo["nameWithOwner"],
            "url": issue["url"],
            "updated": issue["updatedAt"][:10],
            "sections": sections,
            "updates": updates,
            "callouts": callouts,
            "total": sum(len(v) for v in sections.values()),
        })
    rows.sort(key=lambda r: (-r["total"], -r["updates"], r["repo"].lower()))

    if args.json:
        print(json.dumps(rows, indent=2, ensure_ascii=False))
        return
    if not rows:
        print(f"Keine offenen Dashboards gefunden für: {', '.join(owners)}")
        return

    shown = rows if args.all else [r for r in rows if r["total"] or r["updates"] or r["callouts"]]
    headings = sorted({h for r in rows for h in r["sections"]}, key=order_key)
    columns = [(h, *label_for(h)) for h in headings]
    show_warn = any(r["callouts"] for r in rows)

    header = ["Repo", *(label for _, label, _ in columns), "Updates"]
    header += ["Hinweise"] if show_warn else []
    header += ["Summe", "Stand"]

    def cells(r):
        vals = [len(r["sections"].get(h, [])) for h, _, _ in columns]
        vals += [r["updates"]] + ([r["callouts"]] if show_warn else []) + [r["total"]]
        return vals

    if args.markdown:
        print("| " + " | ".join(header) + " |")
        print("|" + "|".join(["---"] + ["--:"] * (len(header) - 2) + ["---"]) + "|")
        for r in shown:
            vals = [str(v) if v else "·" for v in cells(r)]
            print(f"| [{r['repo']}]({r['url']}) | " + " | ".join(vals) + f" | {r['updated']} |")
        return

    color = use_color()
    problem_cols = [problem for _, _, problem in columns] + [False] + ([True] if show_warn else []) + [False]
    table = [[r["repo"], *[str(v) if v else "·" for v in cells(r)], r["updated"]] for r in shown]
    widths = [max(len(row[i]) for row in [header, *table]) for i in range(len(header))]

    def fmt_row(row, is_header=False):
        out = []
        for i, val in enumerate(row):
            padded = val.ljust(widths[i]) if i in (0, len(row) - 1) else val.rjust(widths[i])
            if is_header:
                padded = paint(padded, "1", color)
            elif 0 < i < len(row) - 1:
                if val == "·":
                    padded = paint(padded, "2", color)
                elif i == len(row) - 2:
                    padded = paint(padded, "1", color)
                else:
                    padded = paint(padded, "31" if problem_cols[i - 1] else "33", color)
            out.append(padded)
        return "  ".join(out)

    print(fmt_row(header, True))
    for row in table:
        print(fmt_row(row))
    hidden = len(rows) - len(shown)
    footer = f"\n{len(rows)} Dashboards"
    footer += f", {hidden} ohne offene Einträge ausgeblendet (-a zeigt alle)" if hidden else ""
    print(paint(footer, "2", color))

    if args.details:
        for r in shown:
            print("\n" + paint(f"{r['repo']}", "1", color) + "  " + paint(r["url"], "2", color))
            for h in sorted(r["sections"], key=order_key):
                print(f"  {h}:")
                for item in r["sections"][h]:
                    print(f"    - {item}")
            if r["updates"] and not r["sections"]:
                print(f"  {r['updates']} Abhängigkeit(en) mit verfügbaren Updates")


if __name__ == "__main__":
    main()
