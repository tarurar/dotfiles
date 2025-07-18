# Claude Command: Describe

This command helps you understand and explore unknown source code repositories by providing comprehensive analysis and documentation of the codebase structure, patterns, and key components.

## Usage

To analyze a repository, just type:
```
/describe
```

Or with specific focus areas:
```
/describe --architecture
/describe --dependencies
/describe --entry-points
/describe --patterns
/describe --quick
```

## What This Command Does

1. **Repository Overview**: Identifies the project type, language(s), and primary purpose
2. **Architecture Analysis**: Maps out the overall structure and key architectural patterns
3. **Dependency Analysis**: Lists external dependencies, frameworks, and tools used
4. **Entry Points Discovery**: Identifies main entry points, startup files, and key executables
5. **Code Patterns**: Analyzes common patterns, conventions, and coding styles used
6. **Key Components**: Highlights important classes, modules, and their relationships
7. **Configuration Analysis**: Reviews configuration files and environment setup
8. **Documentation Summary**: Extracts and summarizes existing documentation
9. **Testing Strategy**: Identifies testing frameworks and test organization
10. **Build and Deployment**: Analyzes build systems and deployment configurations

## Analysis Areas

### Architecture (`--architecture`)
- Project structure and organization
- Layer separation and boundaries
- Design patterns used
- Module dependencies and relationships
- Data flow and communication patterns

### Dependencies (`--dependencies`)
- Package managers and dependency files
- External libraries and frameworks
- Version constraints and compatibility
- Security vulnerabilities (if detectable)
- Unused or outdated dependencies

### Entry Points (`--entry-points`)
- Main application entry points
- API endpoints and routes
- CLI commands and scripts
- Background services and workers
- Database migrations and seed data

### Patterns (`--patterns`)
- Coding conventions and style
- Common architectural patterns
- Error handling approaches
- Logging and monitoring patterns
- Configuration management patterns

### Quick Overview (`--quick`)
- High-level summary only
- Key technologies and frameworks
- Main purpose and functionality
- Basic project structure

## What This Command Provides

### Repository Summary
- **Project Type**: Web API, Desktop App, Library, CLI tool, etc.
- **Primary Language(s)**: Main programming languages used
- **Framework/Platform**: .NET, Node.js, React, etc.
- **Purpose**: Brief description of what the application does

### Structure Analysis
- **Directory Layout**: Explanation of folder organization
- **Key Files**: Important configuration and entry point files
- **Module Organization**: How code is organized into modules/packages
- **Separation of Concerns**: How different responsibilities are separated

### Technology Stack
- **Runtime/Platform**: .NET version, Node.js version, etc.
- **Frameworks**: Express, ASP.NET Core, React, Angular, etc.
- **Databases**: SQL Server, PostgreSQL, MongoDB, etc.
- **Tools and Utilities**: Build tools, testing frameworks, linters, etc.

### Code Insights
- **Architectural Patterns**: MVC, DDD, Clean Architecture, Microservices, etc.
- **Design Patterns**: Repository, Factory, Strategy, etc.
- **Conventions**: Naming conventions, file organization, etc.
- **Code Quality**: Testing coverage, documentation level, etc.

### Getting Started Guide
- **Prerequisites**: Required tools and versions
- **Setup Instructions**: How to get the project running locally
- **Key Commands**: Important scripts and commands to know
- **Development Workflow**: How to contribute or modify the code

## Command Options

- `--architecture`: Focus on architectural analysis and design patterns
- `--dependencies`: Deep dive into dependencies and external libraries
- `--entry-points`: Identify and analyze all application entry points
- `--patterns`: Analyze coding patterns and conventions used
- `--quick`: Provide only a high-level overview (faster analysis)

## Output Format

The command generates a comprehensive report including:

1. **Executive Summary**: High-level overview and key findings
2. **Technology Stack**: Complete list of technologies and versions
3. **Architecture Overview**: Visual and textual architecture description
4. **Directory Structure**: Annotated directory tree with explanations
5. **Key Components**: Important classes/modules with their purposes
6. **Configuration**: Environment variables, config files, and settings
7. **Development Setup**: Step-by-step setup instructions
8. **Common Tasks**: Frequently used commands and workflows
9. **Next Steps**: Recommended areas to explore further

## Best Practices

- **Start with Quick**: Use `--quick` first to get an overview, then dive deeper
- **Focus Areas**: Use specific flags to focus on areas most relevant to your goals
- **Follow References**: Pay attention to referenced files and components for deeper exploration
- **Check Documentation**: Always review existing documentation mentioned in the analysis
- **Validate Setup**: Try following the setup instructions to validate the analysis

## Use Cases

- **New Team Member Onboarding**: Understanding a codebase you'll be working on
- **Code Review Preparation**: Getting context before reviewing code changes
- **Architecture Assessment**: Evaluating the design and structure of a system
- **Dependency Audit**: Understanding what external libraries are being used
- **Refactoring Planning**: Identifying patterns and structures before making changes
- **Documentation Generation**: Creating documentation for undocumented projects
- **Security Review**: Understanding entry points and data flow for security analysis

## Important Notes

- The analysis is based on static code analysis and file inspection
- For complete understanding, combine with running the application and reading existing documentation
- Large repositories may take longer to analyze completely
- Some patterns and relationships may only be apparent at runtime
- The command focuses on code structure and doesn't execute any code for security reasons
- Generated documentation is a starting point - manual verification is recommended
