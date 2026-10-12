---
name: review-gitlab-mr
description: Review a GitLab merge request with the glab CLI and, after explicit approval, post the findings as MR comments. Use when asked to review a GitLab MR (a gitlab.com/.../-/merge_requests/N link, "!N", or "review MR N" in a GitLab repo).
---

# Review a GitLab merge request

Review a merge request on GitLab using the `glab` CLI, show the review to the
user first, and only post it to GitLab after the user explicitly approves.

## Prerequisites

- `glab` is installed (`brew install glab` on macOS, `apt install glab` on Debian).
- `glab auth status` succeeds for the GitLab host. If it does not, stop and ask
  the user to run `glab auth login`. Never ask for or handle tokens yourself.

## 1. Identify the MR

Accept any of these:

- a URL like `https://gitlab.com/<group>/<project>/-/merge_requests/<iid>`
- `!<iid>` or a bare number while inside a clone of the project
- a branch name (`glab mr view <branch>`)

When working outside the project's clone, pass `-R <group>/<project>` to every
`glab` command. Group paths may be nested (`group/subgroup/project`).

## 2. Gather context

```sh
glab mr view <iid> --comments          # title, description, author, branches, existing discussion
glab mr diff <iid> --raw               # full unified diff
glab api "projects/:id/merge_requests/<iid>" | jq '{diff_refs, target_branch, source_branch, sha}'
```

(`:id` is resolved by glab from the current repo or `-R`.)

If you are inside a clone, prefer reviewing with full repository context:

```sh
git fetch origin "merge-requests/<iid>/head:mr-<iid>"
git diff "origin/<target_branch>...mr-<iid>"
```

Read the surrounding code of changed files, not only the hunks. Respect the
repository's own instructions (`AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`).

If the project's toolchain is available, run the relevant checks (tests, linters,
type checks) and report the results. Say plainly when checks could not be run.

Delete the temporary local branch `mr-<iid>` when done. Never push it.

## 3. Write the review

Focus on things that matter, most severe first:

1. Correctness bugs and regressions (with a concrete failing scenario)
2. Security issues and unsafe handling of data or user files
3. Error handling, resource leaks, concurrency problems
4. Performance problems with real impact
5. Missing or misleading tests
6. Maintainability and clarity; nits last and clearly labeled as nits

For every finding give file, line (in the new version), what is wrong, why it
matters and a concrete suggestion. Skip anything linters or CI already enforce.
Also say briefly what is good about the MR. Do not invent problems to fill the
review; "no blocking issues" is a valid result.

Write the review in the language the user asks for. Default: English for the
text that goes onto GitLab, while talking to the user in their own language.

## 4. Show it first — post only after approval

Present the complete review to the user, including which findings would become
inline comments (file:line) and what goes into the summary note. Then ask
whether to post it. **Never post without an explicit yes.** Apply any edits the
user requests and show the result again if the changes are substantial.

## 5. Post to GitLab

`glab` syntax changed between versions. Check once with `glab mr note --help`
whether the `create` subcommand exists, then use the matching form.

Summary note on the MR:

```sh
glab mr note create <iid> < review-summary.md      # newer glab
glab mr note <iid> -m "$(cat review-summary.md)"   # older glab
```

Inline comment on a specific line (new side of the diff). Newer glab has an
experimental flag for this:

```sh
glab mr note create <iid> --file <path> --line <line> -m "<comment text>"
```

If that flag is missing or fails, use the API with the `diff_refs` from step 2:

```sh
jq -n \
  --arg body "<comment text>" \
  --arg base "<diff_refs.base_sha>" --arg start "<diff_refs.start_sha>" --arg head "<diff_refs.head_sha>" \
  --arg path "<path>" --argjson line <line> \
  '{body: $body, position: {position_type: "text", base_sha: $base, start_sha: $start,
    head_sha: $head, old_path: $path, new_path: $path, new_line: $line}}' \
| glab api --method POST "projects/:id/merge_requests/<iid>/discussions" \
    -H "Content-Type: application/json" --input -
```

Send the body as JSON: `glab api` does not turn bracketed field names such as
`-f 'position[base_sha]=…'` into a nested body for POST requests.

For a comment on a removed line use `old_line` instead of `new_line`. For a
renamed file set `old_path` to the previous name. If GitLab rejects a position
(line not part of the diff), fold that finding into the summary note instead of
retrying blindly.

Do not approve, unapprove, merge, close, rebase or push to the MR. Those
actions are only taken when the user asks for them explicitly.

Finish by telling the user what was posted (summary note plus N inline
comments) and link the MR.
