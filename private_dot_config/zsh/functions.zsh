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