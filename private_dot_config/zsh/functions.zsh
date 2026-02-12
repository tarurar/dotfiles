zellij_tab_name_update() {
    # Check if we're in a Zellij session
    if [[ -z "$ZELLIJ" ]]; then
        return
    fi
    
    local tab_name
    local current_dir="$(pwd)"
    
    # Check if we're in the home directory
    if [[ "$current_dir" == "$HOME" ]]; then
        tab_name="~"
    else
        # Check if we're in a git repository
        local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
        
        if [[ -n "$git_root" ]]; then
            # We're in a git repo, use the repository root directory name
            tab_name="$(basename "$git_root")"
        else
            # Not in git repo, use current directory name
            tab_name="$(basename "$current_dir")"
        fi
        
        # Remove common prefixes
        if [[ "$tab_name" == MarginTrading.* ]]; then
            tab_name="${tab_name#MarginTrading.}"
        elif [[ "$tab_name" == Codedoc.* ]]; then
            tab_name="${tab_name#Codedoc.}"
        fi
    fi
    
    # Set the Zellij tab name
    zellij action rename-tab "$tab_name"
}

# Some useful functions
# -----------------------------------------------------------------------------
# Description:
#   Extracts the latest version entry for each component from a CSV file.
#
# Usage:
#   services_latest_versions <csv_file>
#
# The function assumes the CSV has the following columns:
# component, tag, date, url
#
# It preserves the header and outputs only the row with the latest tag (version) for each component.
# The version comparison is version-aware (handles semantic versions correctly).
#
# Example:
#   services_latest_versions components.csv
services_latest_versions() {
    local file="$1"
    (head -n 1 "$file" && tail -n +2 "$file" | sort -t, -k1,1 -k2,2Vr | awk -F, '!seen[$1]++')
}

# -----------------------------------------------------------------------------
# Description:
#   Converts a CSV file into HTML <tr> table rows.
#   Skips the header line and processes each row into the following format:
#
#   <tr>
#       <td></td>
#       <td>component</td>
#       <td>tag</td>
#       <td><a href="url">Link</a></td>
#   </tr>
#
# Usage:
#   csv_to_html_rows <path-to-csv-file>
#   Example:
#       csv_to_html_rows ./data.csv > output.html
#
# Dependencies:
#   - Requires 'mlr' (Miller) for proper CSV parsing.
#   - Install it using: brew install miller  (on macOS)
#
# Notes:
#   - Properly handles CSV fields with spaces, commas, and quotes.
#   - Designed for quick generation of HTML tables from release version files.
# -----------------------------------------------------------------------------
# Description:
#   Checks if any Claude Code CLI instances are running and lists their
#   working directories.
#
# Usage:
#   ccs         Show running instances
#   ccs -k      Kill all instances (with confirmation)
#   (short for "claude code status")

# -----------------------------------------------------------------------------
# Description:
#   Shortcut to run Claude Code CLI, passing all arguments through.
#
# Usage:
#   cc [args...]
#   (short for "claude code")
cc() {
    claude "$@"
}

ccs() {
    local kill_mode=false
    [[ "$1" == "-k" ]] && kill_mode=true

    local pids=($(pgrep -x claude))

    if [[ ${#pids[@]} -eq 0 ]]; then
        echo "No Claude Code instances running."
        return 0
    fi

    echo "${#pids[@]} Claude Code instance(s) running:\n"
    for pid in "${pids[@]}"; do
        local cwd=$(readlink /proc/$pid/cwd 2>/dev/null)
        if [[ -n "$cwd" ]]; then
            echo "  PID $pid  →  $cwd"
        else
            echo "  PID $pid  →  (directory unknown)"
        fi
    done

    if $kill_mode; then
        echo ""
        read -q "reply?Kill all ${#pids[@]} instance(s)? [y/N] "
        echo ""
        if [[ "$reply" == "y" ]]; then
            kill "${pids[@]}" 2>/dev/null
            echo "Sent SIGTERM to ${#pids[@]} instance(s)."
        else
            echo "Aborted."
        fi
    fi
}

# -----------------------------------------------------------------------------
# Description:
#   Converts a CSV file into HTML <tr> table rows.
csv_to_html_rows() {
    local file="$1"
    mlr --csv --from "$file" cat | tail -n +2 | while IFS=, read -r component tag date url; do
        cat <<EOF
<tr>
        <td></td>
        <td>${component}</td>
        <td>${tag}</td>
        <td><a href="${url}">Link</a></td>
</tr>
EOF
    done
}
