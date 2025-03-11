# Copilot Instructions for .NET C# Backend Team

## Overview

This document outlines coding standards and conventions for .NET C# backend team. These guidelines should be followed when writing code and used as a reference for GitHub Copilot to ensure consistent and high-quality code generation.

## C# Coding Standards

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

### Examples

```csharp
// Class and interface
public interface IUserService
{
    Task<User> GetUserByIdAsync(int userId);
}

// Class implementation
public class UserService : IUserService
{
    private readonly IUserRepository _userRepository;
    private const string CACHE_KEY_PREFIX = "user_";
    
    public UserService(IUserRepository userRepository)
    {
        _userRepository = userRepository;
    }
    
    public async Task<User> GetUserByIdAsync(int userId)
    {
        var cacheKey = $"{CACHE_KEY_PREFIX}{userId}";
        // Implementation
    }
}
```

### File Organization

- One class per file (except for small helper/nested classes)
- File name should match the primary class name
- Namespace should reflect the project structure

### Code Structure

- Use the following order for class members:
  1. Private fields
  2. Constructors
  3. Properties
  4. Public methods
  5. Private methods
  6. Nested types

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

```csharp
// Good
public async Task<User> GetUserAsync(int id)
{
    return await _repository.GetById(id).ConfigureAwait(false);
}

// Avoid
public User GetUser(int id)
{
    return _repository.GetByIdAsync(id).Result; // Potential deadlock
}
```

### Error Handling

- Use exceptions for exceptional cases, not for control flow
- Create custom exception types for domain-specific errors
- Always include meaningful error messages
- Use try/catch blocks judiciously

```csharp
public async Task<User> GetUserAsync(int id)
{
    try
    {
        var user = await _repository.GetByIdAsync(id);
        if (user == null)
        {
            throw new UserNotFoundException($"User with ID {id} not found");
        }
        return user;
    }
    catch (DatabaseConnectionException ex)
    {
        _logger.LogError(ex, "Database connection failed while retrieving user {UserId}", id);
        throw new ServiceUnavailableException("Service temporarily unavailable", ex);
    }
}
```

### Dependency Injection

- Follow SOLID principles
- Use constructor injection for required dependencies
- Use property injection only for optional dependencies
- Favor composition over inheritance

```csharp
// Good
public class OrderService
{
    private readonly IOrderRepository _orderRepository;
    private readonly ILogger<OrderService> _logger;
    
    public OrderService(IOrderRepository orderRepository, ILogger<OrderService> logger)
    {
        _orderRepository = orderRepository ?? throw new ArgumentNullException(nameof(orderRepository));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }
}
```

### Null Checking

- Use null-conditional operator (`?.`) and null-coalescing operator (`??`) when appropriate
- Use the `is null` or `is not null` pattern over `== null` or `!= null`
- Utilize C# 8.0+ nullable reference types
- Validate parameters with guard clauses at the beginning of methods

```csharp
public void ProcessOrder(Order order)
{
    if (order is null)
    {
        throw new ArgumentNullException(nameof(order));
    }
    
    var customerName = order.Customer?.Name ?? "Unknown";
}
```
or 
```csharp
public void ProcessOrder(Order order)
{
    ArgumentNullException.ThrowIfNull(order, nameof(order));
    
    var customerName = order.Customer?.Name ?? "Unknown";
}
```

### LINQ Usage

- Prefer method syntax over query syntax for consistency
- Chain LINQ methods thoughtfully; break long chains into multiple statements
- Avoid multiple enumerations of the same collection

```csharp
// Good
var activeUsers = users
    .Where(u => u.IsActive)
    .OrderBy(u => u.LastName)
    .Select(u => new UserDto(u.Id, u.FullName));

// Avoid
var results = users.Where(u => u.IsActive); // First enumeration
if (results.Count() > 0) // Second enumeration
{
    foreach (var user in results) // Third enumeration
    {
        // Do something
    }
}
```

## API Design

### REST API Conventions

- Use proper HTTP methods (GET, POST, PUT, DELETE)
- Return appropriate HTTP status codes
- Use pluralized nouns for resource endpoints
- Version your APIs (e.g., `/api/v1/users`)
- Return consistent response formats

### Controller Structure

```csharp
[ApiController]
[Route("api/v1/[controller]")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly ILogger<UsersController> _logger;
    
    public UsersController(IUserService userService, ILogger<UsersController> logger)
    {
        _userService = userService;
        _logger = logger;
    }
    
    [HttpGet("{id}")]
    [ProducesResponseType(StatusCodes.Status200OK, Type = typeof(UserResponse))]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetUserByIdAsync(int id)
    {
        var user = await _userService.GetUserByIdAsync(id);
        if (user == null)
        {
            return NotFound();
        }
        
        return Ok(new UserResponse(user));
    }
}
```

## Database Access

### Entity Framework Conventions

- Use DbContext with dependency injection
- Define entity configurations in separate classes using Fluent API
- Avoid lazy loading in web applications
- Use migrations for database schema changes
- Implement repository pattern for testability

```csharp
public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
    {
    }
    
    public DbSet<User> Users { get; set; }
    public DbSet<Order> Orders { get; set; }
    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfiguration(new UserConfiguration());
        modelBuilder.ApplyConfiguration(new OrderConfiguration());
    }
}

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.HasKey(u => u.Id);
        builder.Property(u => u.Email).IsRequired().HasMaxLength(255);
        builder.HasIndex(u => u.Email).IsUnique();
    }
}
```

## Testing

### Unit Testing

- Use xUnit, NUnit, or MSTest
- Follow AAA pattern (Arrange, Act, Assert) but do not include comments like "Arrange", "Act", "Assert"
- Mock dependencies using Moq
- Test one behavior per test method
- Use meaningful test names that describe behavior

```csharp
[Fact]
public async Task GetUserByIdAsync_WhenUserExists_ReturnsUser()
{
    var userId = 1;
    var expectedUser = new User { Id = userId, Name = "Test User" };
    
    _repositoryMock.Setup(r => r.GetByIdAsync(userId))
        .ReturnsAsync(expectedUser);
    
    var result = await _userService.GetUserByIdAsync(userId);
    
    Assert.Equal(expectedUser.Id, result.Id);
    Assert.Equal(expectedUser.Name, result.Name);
}
```

## Security

- Never store sensitive data in plaintext
- Use parameterized queries to prevent SQL injection
- Validate all user input
- Implement proper authentication and authorization
- Follow the principle of least privilege

## Performance

- Use async/await for I/O-bound operations
- Implement caching where appropriate
- Optimize database queries (include only needed fields, use pagination)
- Use profiling tools to identify bottlenecks
- Consider using compiled LINQ queries for frequently executed queries

## Copilot-Specific Instructions

When using GitHub Copilot, keep these additional guidelines in mind:

1. Always review Copilot suggestions for adherence to our coding standards
2. Ensure Copilot doesn't generate duplicated code
3. Check generated code for security vulnerabilities
4. Verify that Copilot-generated code follows our naming conventions
5. Make sure exception handling follows our standards
6. Review complex LINQ queries for performance