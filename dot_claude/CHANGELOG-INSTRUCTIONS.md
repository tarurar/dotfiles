# CHANGELOG.md Update Guidelines for LLM Coding Agent

## Core Principles
- **Purpose**: Document all notable changes for humans to read
- **Order**: Reverse chronological (newest entries first)
- **Date Format**: ISO 8601 standard (YYYY-MM-DD)
- **Version Format**: Follow Semantic Versioning (MAJOR.MINOR.PATCH)
- **Language**: Clear, concise descriptions in past tense

## Standard Structure

```markdown
# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [Version] - YYYY-MM-DD
### Category
- Change description
```

## Change Categories
Use ONLY these standardized categories:
- **Added** - New features
- **Changed** - Changes in existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Vulnerability patches

## Formatting Rules
1. Each version gets its own section with `## [version] - date` header
2. Categories use `### Category` format
3. Changes listed as bullet points with `-`
4. One change per bullet point
5. Start descriptions with verb (past tense)
6. Include issue/PR references when available (e.g., `#123`)
7. Empty sections should be omitted
8. Links to version comparisons go at bottom of file

## Semantic Versioning Rules
Increment version numbers as follows:
- **MAJOR** (X.0.0): Breaking/incompatible API changes
- **MINOR** (0.X.0): New functionality (backwards compatible)
- **PATCH** (0.0.X): Bug fixes (backwards compatible)

When MAJOR increases, reset MINOR and PATCH to 0.
When MINOR increases, reset PATCH to 0.

## Placeholder Guidelines for New Entries

**IMPORTANT**: When adding new entries without a specified version number or date, use the following placeholder rules:

### Version and Date Placeholders
When creating a new changelog entry, examine the existing format and maintain consistency:
- Replace version with: `[[tbd]]`
- Replace date with: `[[date]]`

### Pattern Matching Rules

**Example 1 - Simple Version Format:**
If existing entries look like:
```markdown
## 8.15.1 (2025-07-10)
### Changed
- LT-6387: bump <Package-Name> to 17.8.1
```

New entry should be:
```markdown
## [[tbd]] ([[date]])
### [Category]
- [Change description]
```

**Example 2 - Extended Version Format:**
If existing entries look like:
```markdown
## 2.32.0 - <Project-Name-Or-Delivery-Name> (October 16, 2025)
### What's changed
* LT-6448: Wrong commissions archiving.
```

New entry should be:
```markdown
## [[tbd]] - <Project-Name-Or-Delivery-Name> ([[date]])
### [Category]
- [Change description]
```

### Key Rules:
1. Preserve any existing naming patterns or prefixes
2. Only replace the version number and date portions
3. Keep any additional text (like release names or delivery numbers)
4. Match the existing date format style (ISO or full month name)
5. Use the same list marker (- or *) as existing entries

## What NOT to Include
- Maintenance changes not affecting users (dotfiles, CI/CD configs)
- Internal refactoring without user impact
- Documentation formatting changes
- Development-only dependencies

## Best Practices
1. Write for end users, not developers
2. Group related changes together
3. Be specific but concise
4. Reference issues/tickets when available
5. Review before committing - changelogs are documentation
6. Never delete or modify historical entries
7. Keep [Unreleased] section for work-in-progress changes

## Entry Template for New Changes
```markdown
## [[tbd]] ([[date]])
### Added
- Feature description with ticket reference

### Changed
- Modified behavior description

### Fixed
- Bug fix description with issue number
```

Remember: The changelog is for HUMANS. Make it readable, useful, and maintainable.