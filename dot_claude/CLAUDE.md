## C# Coding Standards

### Style
- Prefer functional programming constructs over imperative ones
- Use expression-bodied members for single-line methods and properties
- Every function/method should have a single responsibility and return a value
- Every function/method should have a single abstraction level
- Avoid assigments, prefer returning values
- Use pattern matching instead of `if` statements when possible

### Naming Conventions
- **PascalCase** for:
  - Class names
  - Method names
  - Public properties
  - Namespaces
  - Public fields
  - Enums and enum values
  - Interfaces (prefixed with "I")
  - Events

- **camelCase** for:
  - Local variables
  - Private fields (prefixed with underscore, e.g., `_myField`)

- **ALL_CAPS** for:
  - Constant values

### File Organization

- One class per file (except for small helper/nested classes)
- File name should match the primary class name
- Namespace should reflect the project structure

### Formatting

- Use 4 spaces for indentation (not tabs)
- Keep lines under 120 characters
- Put braces on new lines
- Include a space after keywords like `if`, `for`, etc.
- Include a space around operators
- No trailing whitespace

## Best Practices

### Asynchronous Programming

- Use `async/await` pattern for asynchronous operations
- Do not use the `Async` suffix for methods returning `Task` or `Task<T>`
- Avoid mixing synchronous and asynchronous code
- Use `ConfigureAwait(false)` for library code

### Error Handling

- Use exceptions for exceptional cases, not for control flow
- Create custom exception types for domain-specific errors
- Always include meaningful error messages
- Use try/catch blocks judiciously

### Dependency Injection

- Follow SOLID principles
- Use constructor injection for required dependencies
- Use property injection only for optional dependencies
- Favor composition over inheritance

### Null Checking

- Use null-conditional operator (`?.`) and null-coalescing operator (`??`) when appropriate
- Use the `is null` or `is not null` pattern over `== null` or `!= null`
- Utilize C# 8.0+ nullable reference types
- Validate parameters with guard clauses at the beginning of methods

### LINQ Usage

- Prefer method syntax over query syntax for consistency
- Chain LINQ methods thoughtfully; break long chains into multiple statements
- Avoid multiple enumerations of the same collection

## Testing

### Unit Testing

- Use xUnit, NUnit, or MSTest
- Follow AAA pattern (Arrange, Act, Assert) but do not include comments like "Arrange", "Act", "Assert"
- Mock dependencies using Moq
- Judiciously prefer fake implementations over mocked
- Test one behavior per test method
- Use meaningful test names that describe behavior
