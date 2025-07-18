#!/usr/bin/env bash
#MISE description="Find the dotnet solution file (.sln) in the project directory"

set -e

WORKING_DIR="${1:-$MISE_ORIGINAL_CWD}"

SOLUTION_FILE=$(find "$WORKING_DIR" -maxdepth 3 -name "*.sln" -print -quit)

if [ -z "$SOLUTION_FILE" ]; then
    echo "❌ No .sln file found in project directory" >&2
    exit 1
fi

echo "🔍 Found solution file: $SOLUTION_FILE" >&2
echo "$SOLUTION_FILE"
