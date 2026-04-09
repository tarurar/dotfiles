# Global Preferences

## Code Style (C# / .NET)
- Prefer functional constructs: LINQ, lambdas, returning values over assignments
- Every method: single responsibility, single abstraction level
- Allman brace style (braces on new lines), 4-space indent, 120-char line limit
- Use `var` when type is obvious
- No `Async` suffix on async methods
- `ConfigureAwait(false)` only in true class libraries, not in ASP.NET Core apps or worker services (no `SynchronizationContext`)
- Favor composition over inheritance
- Never call `DateTime.UtcNow` / `DateTimeOffset.UtcNow` directly; inject `TimeProvider` and call `provider.GetUtcNow()`. Use `FakeTimeProvider` (from `Microsoft.Extensions.TimeProvider.Testing`) in tests when time control is required.

## Architecture: Functional Core / Imperative Shell
- Business logic in pure static functions: no dependencies, no mutation, no I/O. Take inputs, return outputs.
- A single orchestrating method (impure shell) handles all side effects (HTTP, file I/O, database) and wires results through the pure functions.
- Do not pass mutable state through multiple methods that each mutate it independently.
- Keep wiring and dependency usage in one place — the orchestrator.
- Pure functions are trivially testable with plain assertions, no mocks needed.

## Error Handling
- Use exceptions for truly exceptional conditions (infrastructure failures, programming errors)
- Use Result<T> / discriminated unions for expected failure paths (validation, not-found, business rules)
- Surface errors at the shell layer; pure functions return failure values, not throw

## Code Complexity Limits
- Methods: stay within ~80 chars x ~24 lines (80/24 rule)
- Cyclomatic complexity ≤ 7 per method
- Limit variables per method (locals + params + fields); consider Parameter Object if too many
- No more than 7 things happening in a single piece of code

## Design Principles
- Parse, don't validate: convert DTOs to domain objects, don't use IsValid booleans
- Objects must guarantee they are never in invalid state (protection of invariants)
- Postel's Law: accept input liberally, return values conservatively
- Hierarchy of communication: types > method names > comments > tests > commits > docs
- X-out names: if replacing a method name with "X" loses no info, the types are doing their job
- Numeric comparisons in number-line order: `2 < x && x <= 5` (ascending left to right)

## Testing
- Prefer fake implementations over mocks (use Moq when fakes aren't practical)
- No "Arrange" / "Act" / "Assert" comments — just follow AAA pattern
- Always verify a new test fails first: temporarily break SUT, confirm failure, then revert
- One behavior per test method
- Devil's advocate: deliberately break SUT to discover missing test cases
- Never refactor test and production code in the same commit

## Refactoring & Change
- Vertical slices: implement minimal end-to-end functionality per change
- Justify exceptions: when breaking a rule, document why (e.g., `[SuppressMessage("Usage", "CA2234", Justification = "URL is a literal, not a variable")]`)
- Log only impure actions; pure functions can be re-executed to reproduce state

## Tooling
- Build: `mise run dotnet:build`
- Test (no integration): `mise run dotnet:test`
- Test (all): `mise run dotnet:test:full`
- Formatting: `csharpier format .` (auto-runs on session end via stop hook)
- Single test: `dotnet test --filter FullyQualifiedName~Pattern --verbosity minimal --consoleLoggerParameters:ErrorsOnly`
- After changing test code, do NOT use `--no-build` (new code won't be compiled)
- Minimize console output; avoid `--verbosity detailed` unless investigating

## Documentation Lookup
Use Context7 MCP for up-to-date docs:
1. `context7_resolve-library-id` to find the library
2. `context7_query-docs` with the library ID

## Task Management
- Use TaskCreate for multi-step work
- Set dependencies with addBlockedBy for sequential phases
- Update status to in_progress before starting each task
- Mark completed only after verification
