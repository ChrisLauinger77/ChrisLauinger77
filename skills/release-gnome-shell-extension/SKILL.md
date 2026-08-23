---
name: release-gnome-shell-extension
description: Create and publish a GNOME Shell extension release by updating metadata.json version-name and package.json version when present, committing the release, creating a default or explicitly requested Git tag, and pushing the commit and tag to trigger GitHub or GitLab CI. Use for requests such as "create release 50.4", "create release 50.4 with tag 1.2.3", "create release and tag 50.4", or equivalent release requests in GNOME Shell extension repositories.
---

# Release GNOME Shell Extension

Publish a release with an explicit version. Treat pushing the release commit and tag as part of "create release" even when the user does not separately mention tagging or pushing.

## Release contract

- Require an explicit version from the user. If none is present, ask for it; never infer or increment it.
- Write the release version exactly as supplied to the top-level `version-name` field in `metadata.json`. Treat it as a string and preserve unrelated formatting and content.
- When the extension release has a tracked `package.json`, write the same exact release version to its top-level `version` field. Do not normalize the version to npm SemVer. Preserve unrelated formatting and content.
- Never edit the top-level `version` field in `metadata.json`. Extensions.gnome.org (EGO) owns that field.
- When the user does not supply a separate tag, prefix the exact release version with `v`. Example: release `50.4` maps to tag `v50.4`.
- When the user explicitly supplies a tag, use it exactly as written without adding, removing, or normalizing a prefix. Example: `create release 50.4 with tag 1.2.3` writes `version-name` as `50.4` and creates tag `1.2.3`.
- Use the repository's existing release conventions when they do not conflict with this contract. Read applicable `AGENTS.md` files and release documentation before changing anything.

## Workflow

1. Resolve the repository root with `git rev-parse --show-toplevel`.
2. Inspect `git status --short --branch`, the current branch, remotes, recent tags, and applicable repository instructions.
3. Locate the release `metadata.json` and any tracked `package.json` governing the extension build. Prefer the packaged metadata and the root or build-configured package file. If multiple package files are plausible, determine the release package from the build configuration or ask the user when ambiguity remains. Do not update unrelated workspace packages. A release may proceed without a package update when no applicable `package.json` exists.
4. Validate before editing:
   - The repository is on its expected release branch and has a configured push remote.
   - Neither a local nor remote tag with the resolved tag name already exists. Fetch tag information when needed before deciding.
   - The requested release version is valid for the existing `version-name` field.
   - When an applicable `package.json` exists, it has a top-level `version` field that can be updated as a string.
   - Uncommitted changes are understood and belong to the intended release. Never include unrelated changes. If unrelated changes make a safe release impossible, stop and explain.
5. Update only the top-level `version-name` in `metadata.json` and, when applicable, the top-level `version` in `package.json`. Preserve all unrelated fields and formatting, including the EGO-managed `version` in `metadata.json`.
6. Run the repository's documented validation, test, lint, build, and packaging commands that are relevant to a release. At minimum, parse each changed JSON file, verify `metadata.json`'s `version-name` equals the requested release version, verify its `version` is unchanged, and verify the applicable `package.json` version equals the exact requested release version.
7. Review `git diff`, `git status`, and the exact files that will be committed. Confirm no generated secrets, unrelated files, or accidental formatting rewrites are included.
8. Commit the intended release changes. Follow the repository's commit convention; otherwise use `Release <version>`.
9. Create an annotated tag with the resolved tag name pointing at the new release commit, with message `Release <version>`.
10. Reconfirm the commit and tag targets, then push the release commit to its configured remote and push the exact tag. Do not use `--force`, `--force-with-lease`, or broad `git push --tags`.
11. Verify that the expected GitHub Actions or GitLab CI pipeline was created for the tag. Use available repository tooling, such as `gh`, `glab`, or the provider connector. Report the commit, tag, remote, and CI status or URL. If CI verification is unavailable, clearly state that the push succeeded but pipeline creation was not verified.

## Safety boundaries

- Treat commit, tag creation, and their normal push as authorized parts of an explicit release request.
- Never rewrite, move, or delete an existing tag without separate explicit approval.
- Never bypass branch protections, failing checks, signing requirements, or repository release policy.
- If commit or tag signing is configured, preserve it. Do not silently disable signing to make the release succeed.
- Stop before pushing if validation fails or if `version-name`, the applicable package version, the release commit, and the resolved tag do not match the user's request.
- If pushing the commit succeeds but pushing the tag fails, report the partial state precisely and resolve only with safe, non-destructive actions.

## Completion report

Report the released `version-name`, the package version when applicable, commit hash, exact tag, pushed remote/branch, validation performed, and CI result. Mention when no applicable `package.json` exists and identify any unverified or partially completed step explicitly.
