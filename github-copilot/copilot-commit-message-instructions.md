# Commit Message Convention Guidelines

## Overview

This document outlines our commit message conventions based on the [Conventional Commits](https://www.conventionalcommits.org/) specification. These guidelines should be followed for all commits and used as a reference for GitHub Copilot to ensure consistent and meaningful commit messages.

## Conventional Commits Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Commit Types

The `type` field must be one of the following:

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, etc.)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes that affect the build system or external dependencies
- **ci**: Changes to our CI configuration files and scripts
- **chore**: Other changes that don't modify src or test files
- **revert**: Reverts a previous commit

## Scope

The `scope` is optional and should be a task id from jira. Usually it can be extracted from the branch name since the task id is usually part of the branch name. For example, if the branch name is `feature/ABC-123-add-login` or just `ABC-123-add-login`, the scope would be `ABC-123`.
If task id can't be extracted from the branch name, then omit scope.

## Description

The description should be a short summary of the changes:

- Use imperative, present tense: "change" not "changed" nor "changes"
- Don't capitalize the first letter
- No period (.) at the end

## Body

The body is optional and should include the motivation for the change and contrast with previous behavior.

## Footer

The footer is optional and should contain any information about Breaking Changes and is also the place to reference GitHub issues that this commit Closes.

Breaking changes should start with the word `BREAKING CHANGE:` with a space or two newlines. The rest of the commit message is then used for this.

## Examples

### Simple Feature Addition

```
feat(<task-id>): add email verification endpoint
```

### Bug Fix with Issue Reference

```
fix(<task-id>): resolve token expiration calculation

Closes #123
```

### Documentation Update

```
docs: update API documentation with new endpoints
```

### Breaking Change

```
feat(<task-id>): change authentication mechanism

BREAKING CHANGE: JWT format has been modified and requires client updates
```

### Refactoring Code

```
refactor(<task-id>): simplify error handling logic
```

### Performance Improvement

```
perf(<task-id>): optimize user query with index
```

## Best Practices

1. **Be Descriptive**: Make your commit messages informative but concise
2. **One Change Per Commit**: Each commit should represent a single logical change
3. **Reference Issues**: Include issue/ticket numbers when applicable
4. **Breaking Changes**: Always highlight breaking changes prominently
5. **Consistency**: Follow the format consistently across the team


## Automated Validation

We use commitlint to enforce these conventions. Commit messages that don't follow the convention will be rejected.

## Additional Resources

- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Angular Commit Message Guidelines](https://github.com/angular/angular/blob/master/CONTRIBUTING.md#commit)