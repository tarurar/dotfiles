---
name: commit
description: >-
  Create one or more conventional Git commits from current repository changes.
  Use when the user asks to commit, including with "$commit"; inspect all work,
  stage only the intended changes, honor exclusions known from the current
  context, and never push unless explicitly asked.
---

# Commit

Create focused commits that match the repository's existing message style.

## Workflow

1. Inspect `git status --short`, the staged and unstaged diffs, relevant
   untracked files, and recent commit subjects. Use the user request,
   conversation context, repository instructions, and diffs to identify the
   intended change and any paths that must be skipped.
2. Keep skipped paths out of every commit. Preserve their working-tree
   contents; if a skipped path is already staged, unstage it. Record each path
   and the reason it was skipped for the final report. Do not invent exclusions
   when the context is ambiguous.
3. Decide whether the intended change needs one commit or several. Split
   unrelated concerns or changes that are independently useful or reversible.
4. For each commit, stage only its paths or hunks using explicit pathspecs.
   Never use `git add .` or `git add -A`. Review `git diff --staged` before
   committing to confirm it contains no skipped or unrelated changes.
5. Commit with a conventional message, then inspect `git status --short` to
   verify the result before continuing.
6. Report the commits created, any remaining changes, and every skipped path
   with its reason.

## Commit Message Format

Use `<type>(<scope>): <summary>`, with the scope omitted when it adds no useful
context.

Follow the repository's observed types and scopes. When it has no clear
convention, use an appropriate common type: `feat`, `fix`, `docs`, `style`,
`refactor`, `perf`, `test`, `build`, `ci`, or `chore`.

Write the summary in imperative mood and keep the first line under 72
characters. Add a short body only when the motivation or non-obvious context
would help a reviewer; do not merely restate the diff.

## Safeguards

- Do not bypass hooks or signing requirements. If a commit command fails,
  verify whether `HEAD` changed before retrying, then review and re-stage the
  intended changes as needed.
- Do not add an AI assistant as a co-author.
- Do not push unless the user explicitly asks.
