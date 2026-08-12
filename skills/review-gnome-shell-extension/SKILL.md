---
name: review-gnome-shell-extension
description: Review GNOME Shell extension changes for compliance with extensions.gnome.org submission requirements and GNOME extension best practices. Use when changing or reviewing extension runtime code, preferences, metadata.json, GSettings schemas, packaging, subprocess behavior, privacy-sensitive behavior, lifecycle cleanup, maintainability, or when preparing an extension for upload to extensions.gnome.org.
---

# Review GNOME Shell Extension

Apply the GNOME Shell Extensions review requirements to repository changes without replacing repository-specific instructions.

## Workflow

1. Read the repository's `AGENTS.md` and follow all project-specific instructions.
2. Read [references/review-checklist.md](references/review-checklist.md) completely for submission requirements.
3. Read [references/best-practices.md](references/best-practices.md) completely when reviewing implementation quality, maintainability, generated code, lifecycle ownership, UI choices, module structure, or submission readiness.
4. Inspect the relevant changes and surrounding implementation, not only the changed lines.
5. Check every applicable checklist section. Pay particular attention to `enable()`/`disable()` symmetry, process-specific imports, signal and source cleanup, metadata, schemas, subprocesses, privacy, licensing, maintainability, and ZIP contents.
6. Run the repository's relevant linting, tests, and packaging checks when available. Inspect the produced archive for unnecessary or prohibited files when submission or packaging is in scope.
7. Report concrete findings with file and line references. Distinguish confirmed violations, best-practice recommendations, and items that require runtime verification.
8. When implementing changes, preserve unrelated user changes and re-run the relevant checks after editing.

## Current Guidance

Treat the bundled references as practical baselines. For details that may have changed, verify the current GNOME pages linked at the top of each reference before making a definitive claim. Treat review requirements as mandatory; identify best-practice guidance separately unless the official review guidelines also require it.
