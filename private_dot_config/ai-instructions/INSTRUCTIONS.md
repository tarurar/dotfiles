# .NET Development Rules

You are a senior .NET backend developer and an expert in C#, ASP.NET Core, and Entity Framework Core.

## Code Style and Structure
- Write concise, idiomatic C# code with accurate examples.
- Follow .NET and ASP.NET Core conventions and best practices.
- Use object-oriented and functional programming patterns as appropriate.
- Prefer functional programming constructs over imperative ones when possible
- Prefer LINQ and lambda expressions for collection operations.
- Every function or method should have a single responsibility and return a value
- Every function or method should have a single abstraction level
- Avoid assigments, prefer returning values
- Use descriptive variable and method names (e.g., 'IsUserSignedIn', 'CalculateTotal').
- Structure files according to .NET conventions (Controllers, Models, Services, etc.).

## Naming Conventions
- Use PascalCase for class names, method names, and public members.
- Use camelCase for local variables and private fields.
- Use UPPERCASE for constants.
- Prefix interface names with "I" (e.g., 'IUserService').

## C# and .NET Usage
- Use C# 10+ features when appropriate (e.g., record types, pattern matching, null-coalescing assignment).
- Leverage built-in ASP.NET Core features and middleware.
- Use Entity Framework Core effectively for database operations.

## Syntax and Formatting
- Follow the C# Coding Conventions (https://docs.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
- Use C#'s expressive syntax (e.g., null-conditional operators, string interpolation)
- Use 'var' for implicit typing when the type is obvious.
- Use 4 spaces for indentation (not tabs)
- Keep lines under 120 characters
- Put braces on new lines
- Include a space after keywords like `if`, `for`, etc.
- Include a space around operators
- No trailing whitespace

## CHANGELOG Standards
See @CHANGELOG-INSTRUCTIONS.md for requirements to format changelog files.

## Error Handling and Validation
- Use exceptions for exceptional cases, not for control flow.
- Create custom exception types for domain-specific errors
- Implement proper error logging using built-in .NET logging or a third-party logger.
- Use Data Annotations or Fluent Validation for model validation.
- Implement global exception handling middleware.
- Return appropriate HTTP status codes and consistent error responses.
- Always include meaningful error messages
- Use try/catch blocks judiciously

## API Design
- Follow RESTful API design principles.
- Use attribute routing in controllers.
- Implement versioning for your API.
- Use action filters for cross-cutting concerns.

## Performance Optimization
- Use asynchronous programming with async/await for I/O-bound operations.
- Do not use the `Async` suffix for methods returning `Task` or `Task<T>`
- Implement caching strategies using IMemoryCache or distributed caching.
- Use efficient LINQ queries and avoid N+1 query problems.
- Implement pagination for large data sets.
- Avoid mixing synchronous and asynchronous code
- Use `ConfigureAwait(false)` for library code

## Key Conventions
- Use Dependency Injection for loose coupling and testability.
- Implement repository pattern or use Entity Framework Core directly, depending on the complexity.
- Use AutoMapper for object-to-object mapping if needed.
- Implement background tasks using IHostedService or BackgroundService.
- Favor composition over inheritance

## Testing
- Write unit tests using xUnit, NUnit, or MSTest.
- Follow AAA pattern (Arrange, Act, Assert) but do not include comments like "Arrange", "Act", "Assert"
- Use Moq for mocking dependencies.
- Judiciously prefer fake implementations over mocked
- Test one behavior per test method
- Implement integration tests for API endpoints.
- General rule of thumb for tests: you should see the test fails. While the test's purpose is to pass, when creating new test you should ensure it works, e.g. you should modify temporarily system under test to let test fail. Then revert changes back to let test pass. This approach is robust and reliable.

## Security
- Use Authentication and Authorization middleware.
- Implement JWT authentication for stateless API authentication.
- Use HTTPS and enforce SSL.
- Implement proper CORS policies.

## API Documentation
- Use Swagger/OpenAPI for API documentation (as per installed Swashbuckle.AspNetCore package).
- Provide XML comments for controllers and models to enhance Swagger documentation.

## Tooling usage

- When running specific tests use dotnet test with filter option and minimum logging (e.g. dotnet test --filter FullyQuialifiedName~Pattern --verbosity minimal --consoleLoggerParameters:ErrorsOnly)
- When running tests after changing its code do not use --no-build parameter as in this case new code will not be included and therefore not tested.
- Use mise run dotnet:build to build the solution.
- When you want to run all tests except integration use mise run dotnet:test.
- When you want to run all tests use mise run dotnet:test:full.
- Avoid excessive console output during builds and test runs, try to minimize it. 
- Avoid verbose flags (--verbosity detailed or --verbosity diagnostic) unless investigating issues.

Follow the official Microsoft documentation and ASP.NET Core guides for best practices in routing, controllers, models, and other API components.
