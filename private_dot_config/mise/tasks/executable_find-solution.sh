#!/usr/bin/env bash
#MISE description="Find the dotnet solution file (.sln or .slnx) in the project directory"

set -e

WORKING_DIR="${1:-$MISE_ORIGINAL_CWD}"

# Prefer .slnx (modern format) over .sln (legacy format).
# Prune dot-directories (.worktrees, .git, .idea, …) — those are tooling/metadata
# and should never host the primary solution file.
# Limit depth to 2 so only repo-root and one-level layouts match; deeper matches
# are almost always ambiguous and fail loudly instead of silently picking one.
SOLUTION_FILE=$(
    find "$WORKING_DIR" -maxdepth 2 \
        \( -type d -name '.?*' -prune \) -o \
        \( -type f -name '*.slnx' -print -quit \)
)
if [ -z "$SOLUTION_FILE" ]; then
    SOLUTION_FILE=$(
        find "$WORKING_DIR" -maxdepth 2 \
            \( -type d -name '.?*' -prune \) -o \
            \( -type f -name '*.sln' -print -quit \)
    )
fi

if [ -z "$SOLUTION_FILE" ]; then
    echo "❌ No .sln or .slnx file found in project directory" >&2
    exit 1
fi

echo "🔍 Found solution file: $SOLUTION_FILE" >&2
echo "$SOLUTION_FILE"
