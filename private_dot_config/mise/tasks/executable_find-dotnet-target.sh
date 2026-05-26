#!/usr/bin/env bash
#MISE description="Find the dotnet build target (.slnx, .sln, or single .csproj)"

set -e

WORKING_DIR="${1:-$MISE_ORIGINAL_CWD}"

find_first() {
    local PATTERN=$1

    find "$WORKING_DIR" -maxdepth 2 \
        \( -type d \( -name '.?*' -o -name bin -o -name obj \) -prune \) -o \
        \( -type f -name "$PATTERN" -print -quit \)
}

TARGET_FILE=$(find_first '*.slnx')
if [ -z "$TARGET_FILE" ]; then
    TARGET_FILE=$(find_first '*.sln')
fi

if [ -n "$TARGET_FILE" ]; then
    echo "Found dotnet target: $TARGET_FILE" >&2
    echo "$TARGET_FILE"
    exit 0
fi

mapfile -t PROJECT_FILES < <(
    find "$WORKING_DIR" -maxdepth 2 \
        \( -type d \( -name '.?*' -o -name bin -o -name obj \) -prune \) -o \
        \( -type f -name '*.csproj' -print \) \
        2>/dev/null | sort
)

case "${#PROJECT_FILES[@]}" in
    0)
        echo "No .slnx, .sln, or .csproj file found in project directory" >&2
        exit 1
        ;;
    1)
        echo "Found dotnet target: ${PROJECT_FILES[0]}" >&2
        echo "${PROJECT_FILES[0]}"
        ;;
    *)
        echo "Multiple .csproj files found and no solution file exists:" >&2
        printf '  %s\n' "${PROJECT_FILES[@]}" >&2
        exit 1
        ;;
esac
