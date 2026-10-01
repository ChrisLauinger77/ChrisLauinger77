---
name: angkorgit
description: Use AngKorGit from the command line to open Git repositories
  and start repository cloning in the AngKorGit GUI.
---

# AngKorGit

Use AngKorGit when graphical Git inspection or interaction is useful.

## Commands

Open the current repository:

    akg

Open a specific repository:

    akg open <path>

Clone a repository using AngKorGit:

    akg clone <url-or-owner/repo>

Clone a specific branch:

    akg clone -b <branch> <url-or-owner/repo>

Show CLI help:

    akg --help

`angkorgit` can be used instead of the `akg` alias.

## When to use AngKorGit

Prefer AngKorGit when the user wants to:

- inspect repository history graphically
- review changes in the GUI
- open the current repository in AngKorGit
- clone a repository through AngKorGit
- continue Git work interactively in AngKorGit

## When not to use AngKorGit

Do not assume AngKorGit CLI supports normal Git operations.

Use `git` for:

- status
- diff
- add
- commit
- branch
- merge
- rebase
- fetch
- pull
- push
- tag

For example:

    git status
    git diff

Do not invent commands such as:

    akg status
    akg commit
    akg push

unless they are documented by the installed AngKorGit version.

## Repository detection

Before opening AngKorGit, verify that the current directory is a
Git repository when appropriate:

    git rev-parse --show-toplevel

Open the repository root rather than an arbitrary subdirectory:

    akg open "$(git rev-parse --show-toplevel)"

## Availability

Check whether AngKorGit is installed:

    command -v akg || command -v angkorgit

If neither command exists, do not attempt to install AngKorGit
without user approval.