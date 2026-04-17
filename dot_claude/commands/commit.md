---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git diff:*), Bash(git log:*)
description: Commit all the changes made
---

# Commit

Create well-formatted conventional commits that match the repo's style, splitting when appropriate.

## Workflow

1. Run `git status`, `git diff --staged`, and `git log -10 --oneline` in parallel — confirm what is staged, understand the change, and observe the repo's commit style.
2. If nothing is staged, stage only files that belong to the intended change by explicit path. Do NOT use `git add -A` or `git add .` — they sweep in unrelated, generated, or sensitive files (`.env`, credentials, large binaries).
3. If the diff contains multiple distinct logical changes, split into separate atomic commits.
4. Compose commit message(s) in conventional commit format (see below).
5. Commit using a HEREDOC so multi-line bodies format correctly.
6. Run `git status` after each commit to confirm it landed.

## Commit Message Format

`<type>(<scope>): <description>` — scope is optional.

Types: feat, fix, docs, style, refactor, perf, test, ci, chore

**Scope**: If the current branch encodes a task/issue ID (e.g., `1234-add-auth`), use it: `feat(1234): add auth service`. Otherwise match the repo's observed convention from recent `git log` (often a short word like `tests`, `plan`, `ci`), or omit the scope entirely.

## Commit Command

Always pass the message via HEREDOC:

    git commit -m "$(cat <<'EOF'
    type(scope): short description

    Optional 1–2 sentence body explaining why, not what.
    EOF
    )"

## Rules

- Present tense, imperative mood ("add feature", not "added feature")
- First line under 72 characters
- Focus on why, not what
- Do NOT add Claude Code as co-author
- Each commit: one logical concern only
- **Never bypass hooks** (`--no-verify`, `--no-gpg-sign`, etc.). If a pre-commit hook fails, the commit did not happen — fix the underlying issue, re-stage, and create a NEW commit. Do not `--amend` to recover from a hook failure.
- Do not push to the remote unless explicitly asked.

## When to Split

Split when the diff contains: unrelated concerns, mixed change types (feature + fix + refactor), or changes that would be clearer reviewed separately.
