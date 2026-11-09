# agent-artifacts

Shared Agent Skill for Codex and Claude Code. Uses a Nextcloud-synchronized folder exposed as `~/agent-artifacts` on each host.

## 1. Make the shared folder and symlink (on each machine)

Create an `Agent-Artifacts` directory inside your already synchronized Nextcloud folder. Point the symlink to its absolute path:

```sh
ln -s "/ABSOLUTE/PATH/TO/Nextcloud/Agent-Artifacts" "$HOME/agent-artifacts"
```

Use your actual macOS path on the Mac and your actual Debian path on Debian. Check with:

```sh
test -d "$HOME/agent-artifacts" && printf 'OK: %s\n' "$(realpath "$HOME/agent-artifacts")"
```

If `$HOME/agent-artifacts` already exists, inspect it first; do not overwrite it blindly.

## 2. Install for both agents (on each host)

Extract the zip, `cd` to the directory containing `agent-artifacts/`, and run:

```sh
mkdir -p "$HOME/.local/share/agent-skills" "$HOME/.agents/skills" "$HOME/.claude/skills"
cp -R agent-artifacts "$HOME/.local/share/agent-skills/"
ln -s "$HOME/.local/share/agent-skills/agent-artifacts" "$HOME/.agents/skills/agent-artifacts"
ln -s "$HOME/.local/share/agent-skills/agent-artifacts" "$HOME/.claude/skills/agent-artifacts"
```

This creates one shared skill source per host with symlinks for Codex and Claude Code. Do not overwrite an existing skill installation without reviewing it. Restart agent sessions if they do not pick up the new skill.

## 3. Test in Paseo

Ask either agent: `Speichere einen kleinen Test-Handoff als Artefakt.` Then open the created Markdown document in Nextcloud Web. Do not assume sync is instantaneous.

## Important

The Nextcloud client syncs files; the skill itself does not publish native Claude Artifacts or ChatGPT Spaces. Agent sandbox permissions may require approval for writing outside the project workspace.
