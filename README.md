# project-dev-guide

A curated collection of GitHub Copilot agents, skills, prompts, and instructions for .NET/C# development workflows — designed to supercharge AI-assisted coding in VS Code.

## Overview

This repository provides reusable GitHub Copilot configuration assets that enforce coding standards, automate code review, scaffold unit tests, and guide project initialization. All resources are structured for use with VS Code's GitHub Copilot Chat and agent mode.

## Repository Structure

```
.github/
├── agents/                    # Custom Copilot chat agents
│   ├── CSharpExpert.agent.md  # Senior .NET developer agent
│   └── code-review.agent.md   # Code review agent
├── instructions/              # Coding guidelines (auto-applied by file pattern)
│   └── csharp.instructions.md # C# 14 / .NET conventions
├── prompts/                   # Reusable prompt templates
│   ├── create-readme.prompt.md
│   ├── csharp-xunit.prompt.md
│   └── project-init.prompt.md (also at root)
└── skills/                    # Modular agent skill packages
    ├── Code-Review/
    ├── csharp-fleet/
    ├── csharp-xunit/
    └── skill-creator/
開發新專案整理.md               # Project initialization reference guide (zh-TW)
```

## Agents

### `C# Expert`
A senior .NET developer agent that produces clean, well-designed, production-ready C# code. It covers:
- Modern C# 14 / .NET 10 patterns (async/await, Span, records, switch expressions)
- SOLID principles, Dependency Injection, CQRS, Repository Pattern
- Security best practices (input validation, least privilege, JWT/OAuth)
- TDD with xUnit, NUnit, or MSTest

**Usage:** Type `@CSharpExpert` in Copilot Chat or agent mode.

### `code-review`
A thorough code review agent focused on:
- Security vulnerabilities (OWASP Top 10)
- Performance and algorithm complexity
- Code quality and naming conventions
- Architecture and design patterns

**Usage:** Type `@code-review` in Copilot Chat with code selected.

## Skills

Skills are modular knowledge packages loaded into Copilot's context on demand.

| Skill | Description |
|-------|-------------|
| `Code-Review` | Structured code review with Critical / Suggestions / Good Practices output |
| `csharp-fleet` | Orchestrates a 5-agent team (PM, Dev, QA, Security, Architect) through a 7-phase quality gate workflow |
| `csharp-xunit` | Best practices for xUnit — Fact/Theory, InlineData/MemberData/ClassData, fixtures, mocking |
| `skill-creator` | Guidance for creating and packaging new agent skills |

### Using Skills

Reference a skill in Copilot Chat:

```
請用 Code-Review skill 審查 #sym:MyMethod 方法的程式碼品質
```

## Instructions

The file `.github/instructions/csharp.instructions.md` is automatically applied to all `*.cs` files opened in VS Code. It enforces:

- C# 14 language features
- PascalCase / camelCase naming conventions
- Nullable reference type handling (`is null` / `is not null`)
- XML doc comments for public APIs
- EditorConfig-aligned formatting
- Entity Framework Core data access patterns
- Structured logging and OpenTelemetry

No manual configuration is required — VS Code picks this up automatically when GitHub Copilot is active.

## Prompts

Reusable prompt templates stored in `.github/prompts/`:

| Prompt | Description |
|--------|-------------|
| `project-init.prompt.md` | Initializes a new .NET project (`.gitignore`, `.editorconfig`, `launch.json`, `tasks.json`) |
| `csharp-xunit.prompt.md` | Generates xUnit test projects following best practices |
| `create-readme.prompt.md` | Creates a comprehensive project README |

**Usage in agent mode:**

```
#file:.github/prompts/project-init.prompt.md
```

## Getting Started

### Clone and use in your project

Copy the `.github/` folder into your own repository to immediately gain:

1. Automatic C# coding guidelines in Copilot suggestions
2. Custom agents accessible via `@AgentName` syntax
3. Reusable prompt templates

### Project initialization workflow

For a new .NET project, run the initialization prompt:

```bash
# In Copilot Chat (agent mode)
#file:.github/prompts/project-init.prompt.md
```

This generates:
- `.gitignore` via `dotnet new gitignore`
- `.editorconfig` with UTF-8-BOM and final newline enforcement
- `launch.json` / `tasks.json` for one-click debugging

See [開發新專案整理.md](開發新專案整理.md) for the full step-by-step initialization guide.

### Generate unit tests

```
#file:.github/prompts/csharp-xunit.prompt.md 幫我為 #sym:MyService 產生單元測試
```

## Requirements

- [VS Code](https://code.visualstudio.com/) with [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot) and [GitHub Copilot Chat](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)
- .NET 9 SDK or later (for `dotnet new` commands)
- Agent mode enabled in GitHub Copilot Chat settings

> [!NOTE]
> Skills and agents require GitHub Copilot with agent mode support. Make sure you are on a recent version of the Copilot Chat extension.

> [!TIP]
> Use `F1` → `聊天新增指示 / 提示 / 模式` to create new instructions, prompts, or chat modes directly from VS Code.
