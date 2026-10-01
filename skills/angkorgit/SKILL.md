---
name: angkorgit
description: Open repositories for graphical Git inspection or interactive work
  in AngKorGit, or launch its GUI clone flow. Use normal git for scripted Git
  operations.
---

# AngKorGit

Use AngKorGit when the user wants to open a repository, inspect history or changes
visually, continue work interactively, or clone through its GUI. Opening the GUI
does not authorise subsequent repository changes.

Use `git` for status, diff, staging, commits, branches, merges, rebases, fetch,
pull, push, tags, and other scripted Git operations. The installed AngKorGit CLI
is a GUI launcher, not a replacement for `git`.

## Availability and help

```sh
command -v akg || command -v angkorgit
akg --help
akg open --help
akg clone --help
```

`akg` is the short alias for `angkorgit`; on this Debian installation it is a
symlink to the same launcher. If only `angkorgit` exists, substitute it in every
example. If neither exists, report that AngKorGit is unavailable; install only
when requested. Recheck installed help before relying on additional commands.

The launcher has no `--version` option. On this Debian installation, obtain the
application package version with `dpkg-query -W ang-kor-git`.

## Open a repository

`akg` and `akg open` open the current directory, without finding the Git root.
From a known repository root, either works:

```sh
akg
```

From a subdirectory, resolve the root first and launch only if Git succeeds:

```sh
if repo_root=$(git rev-parse --show-toplevel); then
    akg open "$repo_root"
fi
```

For another repository, use `git -C` to validate the path and resolve its root:

```sh
repo_path=/var/data/dev/sidra
if repo_root=$(git -C "$repo_path" rev-parse --show-toplevel); then
    akg open "$repo_root"
fi
```

Keep paths quoted. A failed lookup must not fall through to opening an empty
path or the current directory. `--show-toplevel` requires a working tree; for a
bare repository, report that limitation rather than guessing a root.

The launcher also accepts a path directly (`akg /var/data/dev/sidra`). Prefer
`akg open "$repo_root"` for clarity. It checks path existence, not Git validity.

## Clone through the GUI

Run from the intended parent directory: the launcher passes the current
directory to the application as the clone destination parent.

```sh
cd /var/data/dev
akg clone <url-or-owner/repo>
akg clone -b <branch> <url-or-owner/repo>
```

Replace angle-bracket placeholders with real arguments; quote URLs and branch
names. An `owner/repo` shorthand such as `torvalds/linux` is supported.
`--branch` is also accepted in place of `-b`. Choose one clone command and use it
only when cloning is requested; there is no documented dry-run option.

Cloning is handed to the GUI, rather than performed synchronously by the
launcher. On Debian it starts `/usr/bin/angkorgit` in the background and discards
its output. A successful launcher exit proves dispatch, not that the window
opened or the clone completed. Verify the GUI or resulting repository before
reporting success. Use `git clone` when a scripted clone is needed.
