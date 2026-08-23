# Repository Guidelines

## Scope and purpose

These instructions apply to the entire repository. This is the
`ChrisLauinger77/ChrisLauinger77` GitHub profile repository and a collection of
personal development assets; it is not a single application with one build or
test command. Keep changes narrowly scoped to the area requested and preserve
unrelated user changes.

## Repository layout

- `README.md` is the public GitHub profile README. Keep it concise and focused
  on profile-facing content.
- `scripts/` contains standalone administration, installation, conversion,
  backup, and desktop helper scripts. They target different environments and
  may intentionally contain machine-specific paths.
- `skills/` contains the canonical personal Codex skills and their supporting
  agent metadata and references.
- `nvim/` is a LazyVim-based Neovim configuration. Lua customizations live in
  `nvim/lua/config/` and `nvim/lua/plugins/`; `nvim/lazy-lock.json` pins plugin
  versions.
- `renovate-config/` contains shareable Renovate presets for other repositories.

## General working rules

- Inspect the relevant files and `git status` before editing. Do not overwrite,
  discard, or reformat unrelated work.
- Prefer small, focused changes that follow the style already used in the file.
  Do not modernize old scripts incidentally unless the task calls for it.
- Keep executable scripts executable. Use the existing interpreter unless a
  requested change requires another one: `install-codex-skills.sh` is POSIX
  `sh`, while most other scripts use Bash.
- Quote new shell variable expansions and paths unless splitting or globbing is
  deliberate. For new or substantially revised scripts, prefer explicit error
  handling and validate required arguments and commands.
- Preserve intentional host-specific paths and commands unless the task is to
  make them portable. Call out any new system dependency or privilege
  requirement.
- Keep JSON valid and retain each file's established indentation. Do not update
  `nvim/lazy-lock.json` unless plugin resolution or dependency changes require
  it.
- Never add credentials, access tokens, private keys, passwords, host secrets,
  or generated personal data to the repository.

## Safety boundaries for scripts

Many scripts can change the host system, use `sudo`, install packages, mount or
unmount storage, delete files, or run `rsync --delete`. Treat them as production
administration tools:

- Read a script completely before modifying or running it.
- Do not execute a system-changing, backup, restore, install, mount, unmount,
  cleanup, or deletion path merely to validate a code change.
- Prefer syntax checks, static inspection, documented dry-run modes, and
  temporary directories. Run a mutating path only when the user explicitly
  requested that operation and its targets are verified.
- Do not replace machine-specific destinations with guessed values. Ask when a
  required target cannot be determined safely.
- Preserve or improve cleanup traps for temporary resources. Never broaden a
  deletion, recursive operation, glob, or synchronization target without
  explicit justification.

## Codex skills

The personal Codex skills in `skills/` are the canonical copies for all
machines. Each skill directory must contain a valid `SKILL.md`; keep related
references under that skill's directory and update `agents/openai.yaml` when
the skill's user-facing metadata changes.

On macOS or Linux, clone this repository and install the skills with:

```sh
./scripts/install-codex-skills.sh
```

The installer creates one symlink per valid skill in `~/.agents/skills`.
Existing regular files or directories are never overwritten. Preview the
changes with:

```sh
./scripts/install-codex-skills.sh --dry-run
```

For isolated tests, set `CODEX_USER_SKILLS_DIR` to a temporary directory rather
than touching the user's real skills directory. After changing a skill, commit
and push it on one machine and run `git pull` on the others. Because Codex reads
the skills through symlinks, no reinstall is needed after pulling. Restart Codex
only if a change is not detected immediately.

When editing a skill:

- Keep the YAML front matter valid and ensure `name` matches the directory.
- Make the description specific enough to state when the skill should trigger.
- Keep workflows explicit, actionable, and safe; distinguish required behavior
  from recommendations.
- Resolve relative reference links from the skill directory and verify every
  referenced file exists.
- Keep repository-specific behavior in these instructions and domain-specific
  behavior in the skill; avoid duplicating guidance unnecessarily.

## Area-specific validation

Run the smallest relevant checks for the files changed and report anything that
could not be run:

- Documentation: inspect the rendered Markdown structure and verify relative
  links and command examples.
- POSIX shell: run `sh -n` on `scripts/install-codex-skills.sh`.
- Bash: run `bash -n` on changed Bash scripts. Use ShellCheck when available,
  but distinguish pre-existing findings from regressions.
- Codex skill installer: use `--dry-run`, preferably with
  `CODEX_USER_SKILLS_DIR` pointing to a temporary directory. Test real symlink
  creation only inside a temporary directory.
- Renovate presets: parse changed files with `jq empty`; when Renovate tooling
  is available, validate presets with it as well.
- Neovim Lua: run `stylua --check nvim/lua` when StyLua is installed. Run a
  headless Neovim/LazyVim startup check only when dependencies are already
  available and it will not unexpectedly install or update plugins.
- Skills: inspect front matter, links, bundled references, and corresponding
  `agents/openai.yaml` metadata. Exercise the documented workflow only when it
  is safe and within the user's requested scope.

There is no repository-wide test suite. Do not claim that all repository
functionality was tested when only area-specific checks were run.

## Commits and handoff

- Follow the existing concise commit style, commonly using prefixes such as
  `feat:`, `fix:`, `docs:`, `chore:`, or a scoped variant.
- Do not commit, tag, push, publish, install, or deploy unless the user asks for
  it or an explicitly invoked workflow includes that action.
- In the final handoff, summarize changed files, checks performed, and any
  remaining risk or unverified behavior.
