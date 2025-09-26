---
allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*), Bash(git reset:*)
description: Commit all the changes made
---

# Claude Command: Commit

  This command helps to create well-formatted commits with conventional commit messages.

  ## Usage

  To create a commit, just type:
  /commit

  Or with options:
  /commit --verify

  ## What This Command Does

  1. Unless specified with `--verify`, skips pre-commit checks by default
  2. If `--verify` is specified, runs pre-commit checks:
     - `mise run dotnet:build:fast` to verify the build succeeds
     - `mise run dotnet:test` to run unit tests (excluding integration tests)
  3. Checks which files are staged with `git status`
  4. If 0 files are staged, automatically adds all modified and new files with `git add`
  5. Performs a `git diff` to understand what changes are being committed
  6. Analyzes the diff to determine if multiple distinct logical changes are present
  7. If multiple distinct changes are detected, suggests breaking the commit into multiple smaller commits
  8. For each commit (or the single commit if not split), creates a commit message using conventional commit format

  ## Best Practices for Commits

  - **Atomic commits**: Each commit should contain related changes that serve a single purpose
  - **Split large changes**: If changes touch multiple concerns, split them into separate commits
  - **Conventional commit format**: Use the format `<type>: <description>` where type is one of:
    - `feat`: A new feature
    - `fix`: A bug fix
    - `docs`: Documentation changes
    - `style`: Code style changes (formatting, etc)
    - `refactor`: Code changes that neither fix bugs nor add features
    - `perf`: Performance improvements
    - `test`: Adding or fixing tests
    - `ci`: Changes to the build process, build tools and workflows, deployment
    - `chore`: Unclassified changes
    If changes are being implemented within the scope of particular task then use the format `<type>(<scope>): <description>` where scope is the id of
  the task (GitHub issue id or jira ticket id etc.) if the work is done within such task. Usually, current feature branch contains such task id in the
  beginning of the branch name. Examples, where 1234 and ZZ-432 are task ids:
    - `feat(1234): A new feature`
    - `fix(ZZ-432): a bug fix`
  - **Present tense, imperative mood**: Write commit messages as commands (e.g., "add feature" not "added feature")
  - **Focus on why, not what**: Explain the reason for the change rather than describing what was changed (e.g., "fix memory leak in data processing"
  instead of "change variable allocation")
  - **Concise first line**: Keep the first line under 72 characters
  - **No co-authoring**: Do not mentioned claude code as a co-author, do not mention that commit was created with claude code

  ## Guidelines for Splitting Commits

  When analyzing the diff, consider splitting commits based on these criteria:

  1. **Different concerns**: Changes to unrelated parts of the codebase
  2. **Different types of changes**: Mixing features, fixes, refactoring, etc.
  3. **File patterns**: Changes to different types of files (e.g., .cs files vs .csproj vs documentation)
  4. **Logical grouping**: Changes that would be easier to understand or review separately
  5. **Size**: Very large changes that would be clearer if broken down

  ## Examples

  Good commit messages:
  - feat: add user authentication service with JWT tokens
  - fix: resolve memory leak in data processing pipeline
  - docs: update API documentation with new endpoints
  - refactor: simplify error handling logic in OrderService
  - fix: resolve compiler warnings in domain models
  - chore: improve developer tooling setup with EditorConfig
  - feat: implement business logic for margin calculation
  - fix: address minor null reference exception in controller
  - fix: patch critical security vulnerability in authentication
  - style: reorganize service layer structure for better readability
  - fix: remove deprecated legacy DAL methods
  - feat: add input validation attributes to DTOs
  - fix: resolve failing unit tests in CI pipeline
  - feat: implement telemetry tracking for trading operations
  - fix: strengthen password validation in UserService
  - feat: add nullable reference types to domain models

  Example of splitting commits:
  - First commit: feat: add new trading instrument type definitions
  - Second commit: docs: update documentation for new instrument types
  - Third commit: chore: update NuGet package dependencies
  - Fourth commit: feat: add DTOs for new trading API endpoints
  - Fifth commit: feat: improve async/await handling in OrderProcessor
  - Sixth commit: fix: resolve compiler warnings in new code
  - Seventh commit: test: add unit tests for new instrument features
  - Eighth commit: fix: update dependencies with security vulnerabilities

  ## Command Options

  - `--verify`: Enable pre-commit checks (build, test)

  ## Important Notes

  - By default, pre-commit checks are skipped for faster commits
  - Use `--verify` option to run pre-commit checks (`mise run dotnet:build:fast`, `mise run dotnet:test`) when you want to ensure code quality
  - When using `--verify`, if checks fail, you'll be asked if you want to proceed with the commit anyway or fix the issues first
  - If specific files are already staged, the command will only commit those files
  - If no files are staged, it will automatically stage all modified and new files
  - The commit message will be constructed based on the changes detected
  - Before committing, the command will review the diff to identify if multiple commits would be more appropriate
  - If suggesting multiple commits, it will help you stage and commit the changes separately
  - Always reviews the commit diff to ensure the message matches the changes
  - Unless specified explicitely don't add Claude Code authoring to commit messages
