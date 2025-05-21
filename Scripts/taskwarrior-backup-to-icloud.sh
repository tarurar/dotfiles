#!/bin/bash

SOURCE_DIR="$HOME/.task"
ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/TaskWarrior"

cd "$SOURCE_DIR" || exit 1

FILE="taskwarrior-backup-$(date +'%Y%m%d').tar.gz"
tar czf "$FILE" *

mkdir -p "$ICLOUD_DIR"

mv "$FILE" "$ICLOUD_DIR" || {
    exit 1
}
