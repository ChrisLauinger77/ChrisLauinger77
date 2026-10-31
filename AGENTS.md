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
- `skills/` contains the canonical personal agent skills, shared by Codex and
  Claude Code, and their supporting agent metadata and references.
- `nvim/` is a LazyVim-based Neovim configuration. Lua customizations live in
  `nvim/lua/config/` and `nvim/lua/plugins/`; `nvim/lazy-lock.json` pins plugin
  versions.
- `zed/` contains Zed editor configuration; `zed/keymap.json` defines custom
  keybindings.
- `renovate-config/` contains shareable Renovate presets for other repositories.
  `default.json` is the base preset; the other presets extend it through
  `github>ChrisLauinger77/ChrisLauinger77//renovate-config/default`, so a change
  to it affects every repository using these presets once it is pushed.

## General working rules

- Inspect the relevant files and `git status` before editing. Do not overwrite,
  discard, or reformat unrelated work.
- Prefer small, focused changes that follow the style already used in the file.
  Do not modernize old scripts incidentally unless the task calls for it.
- Keep executable scripts executable. Use the existing interpreter, currently
  Bash for every script, unless a requested change requires another one.
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
unmount storage, delete files, or run `rsync --delete`. Others act on remote
services; for example, `github-merge-prs.sh` squash-merges GitHub pull requests
and deletes their branches. Treat them as production administration tools:

- Read a script completely before modifying or running it.
- Do not execute a system-changing, backup, restore, install, mount, unmount,
  cleanup, or deletion path merely to validate a code change.
- Do not run a path that merges, pushes, deletes, or otherwise changes remote
  state, such as GitHub pull requests or branches, merely to validate a code
  change.
- Prefer syntax checks, static inspection, documented dry-run modes, and
  temporary directories. Run a mutating path only when the user explicitly
  requested that operation and its targets are verified.
- Do not replace machine-specific destinations with guessed values. Ask when a
  required target cannot be determined safely.
- Preserve or improve cleanup traps for temporary resources. Never broaden a
  deletion, recursive operation, glob, or synchronization target without
  explicit justification.

## Agent skills

The personal skills in `skills/` are the canonical copies for all machines and
are shared by Codex and Claude Code. Each skill directory must contain a valid
`SKILL.md`; keep related references under that skill's directory. When a skill
has an `agents/openai.yaml`, update it whenever the skill's user-facing
metadata changes.

Codex reads the skills from `~/.agents/skills`, which on each machine is a
symlink to this repository's `skills/` directory. On macOS or Linux, clone this
repository and, from its root, create that link if `~/.agents/skills` does not
exist yet:

```sh
ln -s "$PWD/skills" ~/.agents/skills
```

For Claude Code, `scripts/skill_refresh_claude.sh` links each skill from
`~/.agents/skills`, plus the Codex `gh` skill from `~/.codex/skills/gh`, into
`~/.claude/skills`. It keeps existing symlinks and skips real directories.
Run it again after a skill is added:

```sh
./scripts/skill_refresh_claude.sh
```

After changing a skill, commit and push it on one machine and run `git pull` on
the others. Because both tools read the skills through symlinks, no reinstall is
needed after pulling; only a newly added skill needs
`skill_refresh_claude.sh` again. Restart Codex or Claude Code only if a change
is not detected immediately.

`skills/terminal-browser` is a symlink to an absolute path outside this
repository, where the terminal-browser installation manages the skill. It is
not a canonical copy: do not edit it through this repository, and expect the
link to dangle on machines without that installation.

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
- Bash: run `bash -n` on changed Bash scripts. Use ShellCheck when available,
  but distinguish pre-existing findings from regressions.
- Claude Code skill links: `scripts/skill_refresh_claude.sh` writes to
  `$HOME/.claude/skills`. Test real symlink creation only with `HOME` set to a
  temporary directory that contains a test `.agents/skills` tree.
- Renovate presets: parse changed files with `jq empty`; when Renovate tooling
  is available, validate presets with it as well. Changes to `default.json`
  apply to every preset that extends it, so check those presets too.
- Neovim Lua: run `stylua --check nvim/lua` when StyLua is installed. Run a
  headless Neovim/LazyVim startup check only when dependencies are already
  available and it will not unexpectedly install or update plugins.
- Zed configuration: parse `zed/keymap.json` with `jq empty` after changes.
- Skills: inspect front matter, links, bundled references, and the
  `agents/openai.yaml` metadata when present. For a symlinked external skill,
  check only that the link target exists. Exercise the documented workflow only
  when it is safe and within the user's requested scope.

There is no repository-wide test suite. Do not claim that all repository
functionality was tested when only area-specific checks were run.

## Commits and handoff

- Follow the existing concise commit style, commonly using prefixes such as
  `feat:`, `fix:`, `docs:`, `chore:`, or a scoped variant.
- Do not commit, tag, push, publish, install, or deploy unless the user asks for
  it or an explicitly invoked workflow includes that action.
- In the final handoff, summarize changed files, checks performed, and any
  remaining risk or unverified behavior.
