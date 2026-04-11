# Agent Instructions Design

## Overview

AI agent instructions (coding preferences, architecture guidelines, tooling) are maintained as a
single source of truth and distributed to each agent via chezmoi. Agents that need identical content
receive a symlink; agents that need agent-specific additions receive a chezmoi-generated file.

## Single Source of Truth

**File:** `.chezmoitemplates/agent-instructions`

This is a [chezmoi named template](https://www.chezmoi.io/user-guide/templating/#use-templates-in-templates).
Edit this file to change the shared instructions. Run `chezmoi apply` to propagate changes to all agents.

> Do not edit the deployed files (`~/.config/ai-instructions/INSTRUCTIONS.md`,
> `~/.claude/CLAUDE.md`, etc.) directly — they are generated or symlinked and
> changes will be overwritten on the next `chezmoi apply`.

## Architecture

```
.chezmoitemplates/
  agent-instructions                    ← shared base content (edit this)

private_dot_config/ai-instructions/
  INSTRUCTIONS.md.tmpl                  ← generates ~/.config/ai-instructions/INSTRUCTIONS.md
                                          (shared content only, no agent-specific additions)

dot_claude/
  CLAUDE.md.tmpl                        ← generates ~/.claude/CLAUDE.md
                                          (shared content + @RTK.md)
```

Agents that use the **symlink pattern** point to `~/.config/ai-instructions/INSTRUCTIONS.md`:

| Agent | Chezmoi source | Target |
|-------|---------------|--------|
| Codex | `dot_codex/symlink_AGENTS.md.tmpl` | `~/.codex/AGENTS.md` |
| Gemini | `dot_gemini/symlink_GEMINI.md.tmpl` | `~/.gemini/GEMINI.md` |
| OpenCode | *(manual symlink, not chezmoi-managed)* | `~/.config/opencode/AGENTS.md` |

## Editing Shared Instructions

1. Open the source file: `chezmoi edit ~/.config/ai-instructions/INSTRUCTIONS.md`
   - This opens `.chezmoitemplates/agent-instructions` via the template chain
   - Or edit the file directly: `$EDITOR ~/.local/share/chezmoi/.chezmoitemplates/agent-instructions`
2. Save and apply: `chezmoi apply`
3. All agents pick up the change immediately (symlinks) or after the next session start (generated files)

## Adding a New Agent — Symlink Pattern

Use this when the agent needs the shared content unchanged.

1. Create `dot_<agentdir>/symlink_<filename>.tmpl`:
   ```
   {{ .chezmoi.homeDir }}/.config/ai-instructions/INSTRUCTIONS.md
   ```
2. Run `chezmoi apply`

Example: adding Aider (`~/.aider/CONVENTIONS.md`):
```bash
mkdir -p ~/.local/share/chezmoi/dot_aider
echo '{{ .chezmoi.homeDir }}/.config/ai-instructions/INSTRUCTIONS.md' \
  > ~/.local/share/chezmoi/dot_aider/symlink_CONVENTIONS.md.tmpl
chezmoi apply
```

## Adding a New Agent — Template Pattern (Agent-Specific Additions)

Use this when the agent needs the shared content **plus** agent-specific instructions.

1. Create `dot_<agentdir>/<filename>.tmpl`:
   ```
   {{ template "agent-instructions" . -}}
   
   ## <Agent Name>-Specific Instructions
   - ...
   ```
2. Remove the symlink source file if it exists (they cannot coexist for the same target)
3. Run `chezmoi apply`

Example: adding Gemini-specific instructions:
```bash
# Replace symlink_GEMINI.md.tmpl with a template file
rm ~/.local/share/chezmoi/dot_gemini/symlink_GEMINI.md.tmpl
cat > ~/.local/share/chezmoi/dot_gemini/GEMINI.md.tmpl << 'EOF'
{{ template "agent-instructions" . -}}

## Gemini-Specific Instructions
- Use `gemini_tool_xyz` for ...
EOF
chezmoi apply
```

## Current Agent Inventory

| Agent | Pattern | File | Agent-Specific Additions |
|-------|---------|------|--------------------------|
| Claude Code | template | `dot_claude/CLAUDE.md.tmpl` | `@RTK.md` (RTK token-saver awareness) |
| OpenCode | manual symlink | `~/.config/opencode/AGENTS.md` | none |
| Codex | symlink | `dot_codex/symlink_AGENTS.md.tmpl` | none |
| Gemini | symlink | `dot_gemini/symlink_GEMINI.md.tmpl` | none |
