#!/bin/bash
#MISE description="Git feature branch to development branch merge script"

# Set working directory - default to $MISE_ORIGINAL_CWD or use first argument if provided
WORKING_DIR="${1:-$MISE_ORIGINAL_CWD}"

# Exit on error
set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print step information
print_step() {
    echo -e "\n${BLUE}STEP $1: $2${NC}"
}

# Function to print error and exit
print_error_and_exit() {
    echo -e "\n${RED}ERROR: $1${NC}"
    echo -e "${YELLOW}Details: $2${NC}"
    exit 1
}

# Change to the working directory
print_step "0" "Changing to working directory: $WORKING_DIR"
if [ ! -d "$WORKING_DIR" ]; then
    print_error_and_exit "Invalid working directory" "Directory does not exist: $WORKING_DIR"
fi

cd "$WORKING_DIR" || print_error_and_exit "Failed to change to working directory" "Cannot cd to: $WORKING_DIR"
echo -e "${GREEN}Successfully changed to working directory: $(pwd)${NC}"

# Get the current branch name
current_branch=$(git branch --show-current)
if [ -z "$current_branch" ]; then
    print_error_and_exit "Failed to get current branch name" "Not in a git repository or HEAD is detached"
fi

# Step 1: Check for uncommitted changes
print_step "1" "Checking for uncommitted changes in branch: $current_branch"
if [ -n "$(git status --porcelain)" ]; then
    print_error_and_exit "Uncommitted changes detected in branch $current_branch" "Please commit or stash your changes before running this script"
fi
echo -e "${GREEN}No uncommitted changes detected. Proceeding...${NC}"

# Step 2: Find development branch
print_step "2" "Finding development branch"
dev_branches=$(git branch | grep -E '^\s*(dev|Dev|development)$' | sed 's/^\*\?\s*//')

# Count the number of matching branches
dev_branch_count=$(echo "$dev_branches" | grep -v "^$" | wc -l)

if [ "$dev_branch_count" -eq 0 ]; then
    print_error_and_exit "No development branch found" "Expected branch names: dev, Dev, or development"
elif [ "$dev_branch_count" -gt 1 ]; then
    print_error_and_exit "Multiple development branches found" "Found: $dev_branches"
fi

# Get the exact name of the development branch
dev_branch=$(echo "$dev_branches" | tr -d '[:space:]')
echo -e "${GREEN}Found development branch: $dev_branch${NC}"

# Step 3: Switch to development branch and pull latest changes
print_step "3" "Switching to $dev_branch branch and pulling latest changes"
if ! git checkout "$dev_branch"; then
    print_error_and_exit "Failed to switch to $dev_branch branch" "$(git checkout "$dev_branch" 2>&1)"
fi
echo -e "${GREEN}Successfully switched to $dev_branch branch${NC}"

if ! git pull; then
    print_error_and_exit "Failed to pull latest changes from remote" "$(git pull 2>&1)"
fi
echo -e "${GREEN}Successfully pulled latest changes from remote${NC}"

# Step 4: Merge feature branch into development branch
print_step "4" "Merging $current_branch into $dev_branch"
if ! git merge "$current_branch"; then
    print_error_and_exit "Failed to merge $current_branch into $dev_branch" "$(git merge "$current_branch" 2>&1)"
fi
echo -e "${GREEN}Successfully merged $current_branch into $dev_branch${NC}"

# Step 5: Run tests
print_step "5" "Running tests"
if ! mise run dotnet:test; then
    print_error_and_exit "Tests failed" "$(mise run dotnet:test 2>&1)"
fi
echo -e "${GREEN}Tests passed successfully${NC}"

# Step 6: Push changes to remote
print_step "6" "Pushing changes to remote"
if ! git push; then
    print_error_and_exit "Failed to push changes to remote" "$(git push 2>&1)"
fi
echo -e "${GREEN}Successfully pushed changes to remote${NC}"

echo -e "\n${GREEN}🎉 All steps completed successfully!${NC}"
echo -e "${GREEN}Feature branch '$current_branch' has been merged into '$dev_branch' and pushed to remote.${NC}"
