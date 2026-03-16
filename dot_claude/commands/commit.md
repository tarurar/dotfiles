---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git reset:*)
description: Commit all the changes made
---

# Commit

Create well-formatted conventional commits, splitting when appropriate.

## Workflow

1. Check `git status` for staged files
2. If nothing staged, `git add` all modified and new files
3. Run `git diff --staged` to analyze changes
4. If multiple distinct logical changes detected, split into separate atomic commits
5. Create commit message(s) using conventional commit format
6. Skip pre-commit hooks (`--no-verify`)

## Commit Message Format

`<type>(<scope>): <description>` — scope is optional.

Types: feat, fix, docs, style, refactor, perf, test, ci, chore

**Scope**: Extract task/issue ID from current branch name if present (e.g., branch `1234-add-auth` → `feat(1234): add auth service`).

## Rules

- Present tense, imperative mood ("add feature" not "added feature")
- First line under 72 characters
- Focus on why, not what
- Do NOT add Claude Code as co-author
- Each commit: one logical concern only

## When to Split

Split when the diff contains: unrelated concerns, mixed change types (feature + fix + refactor), or changes that would be clearer reviewed separately.
