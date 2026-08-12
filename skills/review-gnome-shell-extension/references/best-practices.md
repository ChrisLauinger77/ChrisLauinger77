# GNOME Extension Best Practices

Source: https://gjs.guide/extensions/review-guidelines/best-practices.html

Use this reference to assess implementation quality, maintainability, and reviewability. Consult the source page when details may have changed. Keep best-practice recommendations distinct from mandatory EGO review requirements unless the official review guidelines also require them.

## Maintainership And Generated Code

- Submit an extension to EGO only when its maintainer understands the JavaScript and can debug and maintain it.
- When generating an extension for someone who cannot maintain it, include the source page's personal-use warning. The maintainer must consciously remove that warning only after reviewing and understanding the code before submission.
- Reject incomplete templates, placeholder implementations, and empty lifecycle methods presented as finished extensions.

## Direct And Version-Specific Code

- Avoid `try`/`catch` around operations that do not normally throw, including standard cleanup calls.
- Avoid optional calls and type checks for guaranteed methods or built-in APIs.
- Target the declared GNOME Shell version cleanly. Use the official porting guidance when real multi-version compatibility is required.
- Prefer self-explanatory names. Do not add comments that merely narrate basic syntax or restate each line.
- Keep lines within 200 characters for readability in the EGO review interface.

## Lifecycle Ownership

- Do not use `_destroyed` or `_enabled` boolean guards to compensate for incorrect lifecycle use. Null destroyed instances and do not reuse them.
- In a custom `destroy()`, remove GLib sources, disconnect signals, release child references and resources, then call `super.destroy()` last.
- Override a GObject widget's `destroy()` directly instead of connecting to its own `destroy` signal for cleanup.
- Make each class clean up the signals, sources, cancellables, sessions, and resources it creates.
- When code can create a timeout repeatedly, remove the previous source immediately beside the new source creation.
- Keep `enable()` and `disable()` adjacent so their symmetry is easy to review.

## Structure And Process Isolation

- Keep the default extension entry point small and delegate focused responsibilities to modules.
- Split very large single-file implementations into cohesive, single-responsibility modules.
- Keep Shell-only and preferences-only UI modules visibly separated, for example with a `prefs/` directory.
- Do not let shared modules imported by both processes import Shell UI libraries (`St`, `Clutter`) or preferences UI libraries (`Gtk`, `Gdk`, `Adw`).
- Extract repeated logic into helper functions instead of copying blocks.
- Avoid unnecessary method aliases that obscure lifecycle and cleanup behavior.

## UI, Subprocesses, And Services

- Use `St.Icon` or `icon_name` for Shell UI icons and `Gtk.Image` for preferences; do not use Unicode emoji as UI icons.
- Use Shell UI components such as `BarLevel` or purpose-built widgets instead of ASCII progress indicators.
- Avoid external shell commands where possible.
- Prefer D-Bus for communication with system services or separate background applications.
- Move heavy work out of the GNOME Shell process into a separate application when appropriate.

## Settings

- When the extension owns a GSettings schema, declare `settings-schema` in `metadata.json`.
- In the extension entry point, call `this.getSettings()` without repeating the schema ID.
