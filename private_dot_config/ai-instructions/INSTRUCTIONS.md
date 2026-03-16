# Global Preferences

## Code Style (C# / .NET)
- Prefer functional constructs: LINQ, lambdas, returning values over assignments
- Every method: single responsibility, single abstraction level
- Allman brace style (braces on new lines), 4-space indent, 120-char line limit
- Use `var` when type is obvious
- No `Async` suffix on async methods
- `ConfigureAwait(false)` in library code
- Favor composition over inheritance

## CHANGELOG Standards
See @CHANGELOG-INSTRUCTIONS.md for requirements to format changelog files.

## Testing
- Prefer fake implementations over mocks (use Moq when fakes aren't practical)
- No "Arrange" / "Act" / "Assert" comments — just follow AAA pattern
- Always verify a new test fails first: temporarily break SUT, confirm failure, then revert
- One behavior per test method

## Tooling
- Build: `mise run dotnet:build`
- Test (no integration): `mise run dotnet:test`
- Test (all): `mise run dotnet:test:full`
- Single test: `dotnet test --filter FullyQualifiedName~Pattern --verbosity minimal --consoleLoggerParameters:ErrorsOnly`
- After changing test code, do NOT use `--no-build` (new code won't be compiled)
- Minimize console output; avoid `--verbosity detailed` unless investigating

## Git
- Do not use `git -C <path>` when already at repo root

## Documentation Lookup

### Microsoft Technologies
Use MCP tools for C#, .NET, ASP.NET Core, Azure, EF Core, etc.:
1. `microsoft_docs_search` for general queries
2. `microsoft_code_sample_search` for code examples
3. `microsoft_docs_fetch` for full page content

### Non-Microsoft Libraries
Use Context7 MCP for up-to-date docs:
1. `context7_resolve-library-id` to find the library
2. `context7_query-docs` with the library ID

## Task Management
- Use TaskCreate for multi-step work
- Set dependencies with addBlockedBy for sequential phases
- Update status to in_progress before starting each task
- Mark completed only after verification
