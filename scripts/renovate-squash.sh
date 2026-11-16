#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Aufruf: renovate-squash.sh [--dry-run | --apply] OWNER/REPO [OWNER/REPO ...]
Ohne Option läuft das Skript im Dry Run. Ziel ist github.com.
USAGE
}

mode=dry-run
case ${1:-} in
  --apply) mode=apply; shift ;;
  --dry-run) shift ;;
  -h|--help) usage; exit 0 ;;
esac

if (( $# == 0 )); then
  usage >&2
  exit 2
fi
for repo in "$@"; do
  if [[ ! $repo =~ ^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9_.-]+$ ||
        ${repo#*/} == . || ${repo#*/} == .. ]]; then
    printf 'Ungültiges Repository: %s\n' "$repo" >&2
    exit 2
  fi
done
for dependency in gh jq; do
  if ! command -v "$dependency" >/dev/null; then
    printf 'Fehlendes Programm: %s\n' "$dependency" >&2
    exit 2
  fi
done

# Expliziter Host und keine interaktiven Rückfragen im Batch.
export GH_PROMPT_DISABLED=1
gh auth status --hostname github.com

rest() {
  gh api --hostname github.com \
    -H 'Accept: application/vnd.github+json' \
    -H 'X-GitHub-Api-Version: 2026-03-10' "$@"
}

query=$(cat <<'GRAPHQL'
query ($owner: String!, $repo: String!, $number: Int!, $base: String!) {
  repository(owner: $owner, name: $repo) {
    mergeQueue(branch: $base) { id }
    pullRequest(number: $number) {
      state
      isDraft
      baseRefName
      headRefOid
      mergeable
      mergeStateStatus
      reviewDecision
      commits(last: 1) {
        nodes {
          commit {
            oid
            statusCheckRollup {
              contexts(first: 1) {
                totalCount
                checkRunCountsByState { state count }
                statusContextCountsByState { state count }
              }
            }
          }
        }
      }
    }
  }
}
GRAPHQL
)

repos=$(jq -nr --args '$ARGS.positional | map(ascii_downcase) | unique[]' -- "$@")
for repo in $repos; do
  metadata=$(rest "repos/$repo")
  if ! jq -e '.permissions.push == true and .archived == false
    and .disabled == false and .allow_squash_merge == true' \
    <<< "$metadata" >/dev/null; then
    printf 'SKIP %s – Schreibrecht fehlt, Repo gesperrt oder Squash deaktiviert\n' "$repo"
    continue
  fi

  # Alle offenen PRs dieses Repos abfragen und erst dann den Bot filtern.
  pages=$(rest --paginate "repos/$repo/pulls?state=open&per_page=100")
  candidates=$(jq -rs '
    if length > 0 and all(.[]; type == "array") then
      [ .[][] | select(.user.login == "renovate[bot]" and .user.type == "Bot") ]
      | unique_by(.number)[] | [.number, .base.ref] | @tsv
    else error("Unerwartete Antwort beim Auflisten der PRs") end
  ' <<< "$pages")

  if [[ -z $candidates ]]; then
    printf 'INFO %s – keine offenen Renovate-PRs\n' "$repo"
    continue
  fi

  while IFS=$'\t' read -r number base; do
    url="https://github.com/$repo/pull/$number"
    snapshot=$(gh api --hostname github.com graphql -f query="$query" \
      -f owner="${repo%/*}" -f repo="${repo#*/}" -F number="$number" -f base="$base")
    decision=$(jq -er --arg base "$base" '
      if ((.errors // []) | length) > 0 then error("GraphQL-Fehler")
      else .data.repository as $repo
        | $repo.pullRequest as $pr
        | $pr.commits.nodes[0].commit as $head
        | $head.statusCheckRollup.contexts as $checks
        | ($checks.checkRunCountsByState // []) as $runs
        | ($checks.statusContextCountsByState // []) as $statuses
        | if $pr == null then error("PR-Daten fehlen")
          elif $pr.state != "OPEN" then "PR nicht mehr offen"
          elif $pr.isDraft != false then "Entwurf"
          elif $pr.baseRefName != $base then "Zielbranch wurde geändert"
          elif $repo.mergeQueue != null then "Zielbranch verwendet eine Merge Queue"
          elif $pr.mergeable == "CONFLICTING" then "Merge-Konflikt"
          elif $pr.mergeStateStatus == "BEHIND" then "PR-Branch ist hinter dem Zielbranch"
          elif $pr.mergeable != "MERGEABLE" then "Merge-Fähigkeit unklar"
          elif ($pr.reviewDecision == "CHANGES_REQUESTED" or
                $pr.reviewDecision == "REVIEW_REQUIRED") then $pr.reviewDecision
          elif ($pr.headRefOid | type != "string") or
               ($pr.headRefOid != $head.oid) then "Head-Commit unklar"
          elif ($checks.totalCount // 0) <= 0 then "keine sichtbaren CI-Checks"
          elif (([$runs[], $statuses[]] | map(.count) | add) !=
                 $checks.totalCount) then "CI-Status unvollständig"
          elif (any($runs[]; .state != "SUCCESS" and .state != "NEUTRAL" and
                             .state != "SKIPPED") or
                any($statuses[]; .state != "SUCCESS")) then
            "CI nicht grün (" + ([$runs[], $statuses[] | .state] | unique | join(", ")) + ")"
          elif $pr.mergeStateStatus != "CLEAN" then
            "Merge-Status " + ($pr.mergeStateStatus // "unbekannt")
          else "READY " + $pr.headRefOid end
      end
    ' <<< "$snapshot")

    if [[ $decision != READY\ * ]]; then
      printf 'SKIP %s – %s\n' "$url" "$decision"
      continue
    fi
    sha=${decision#READY }
    if [[ ! $sha =~ ^[0-9a-f]{40}$ ]]; then
      printf 'FEHLER %s – ungültige Head-SHA\n' "$url" >&2
      exit 1
    fi
    if [[ $mode == dry-run ]]; then
      printf 'DRY-RUN %s – Squash nach %s bei %s\n' "$url" "$base" "$sha"
      continue
    fi

    # GitHub akzeptiert den Merge nur bei passender Head-SHA.
    if result=$(rest --method PUT "repos/$repo/pulls/$number/merge" \
         -f merge_method=squash -f sha="$sha") &&
       merged_sha=$(jq -er 'select(.merged == true)
         | .sha | strings | select(test("^[0-9a-f]{40}$"))' <<< "$result"); then
      printf 'MERGED %s – %s\n' "$url" "$merged_sha"
    else
      printf 'FEHLER %s – Merge abgelehnt oder Ergebnis unklar. PR prüfen.\n' "$url" >&2
      exit 1
    fi
  done <<< "$candidates"
done
