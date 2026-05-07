# Repository Guidelines

## Project Structure & Module Organization

This repository is a Markdown-first collection of Copilot assets and .NET/C# guidance.

- `README.md` is the main overview; keep it aligned with major changes.
- `.github/agents/` contains custom agents such as `CSharpExpert.agent.md`.
- `.github/instructions/` stores file-pattern instructions; `csharp.instructions.md` applies to `**/*.cs`.
- `.github/prompts/` stores reusable prompt templates.
- `.github/skills/` stores modular skill packages with `SKILL.md` entry points.
- `.github/hooks/` stores hook config and scripts. Treat `stop-hook.sh` carefully because it can commit and push.
- `ResearchFolder/` stores longer research notes.
- Root Markdown files such as `project-init.prompt.md` and `開發新專案整理.md` are project-level references.

## Build, Test, and Development Commands

There is no application build pipeline or package manager. Use lightweight checks:

- `rg --files` lists documentation and configuration files.
- `rg "term" README.md .github ResearchFolder` searches the core guides and assets.
- `git diff --check` catches whitespace problems.
- `git status --short` reviews local changes before using hooks or opening a PR.

## Coding Style & Naming Conventions

Follow `.editorconfig`: spaces throughout; JSON, XML, project, and config files use 2-space indentation; C# examples use 4 spaces. Keep Markdown headings descriptive and concise. Preserve Traditional Chinese in existing zh-TW documents unless the file is already English or the change requires English. Use `.agent.md` for agents, `.prompt.md` for prompts, and clear lowercase or kebab-case skill directories containing `SKILL.md`.

## C# Instruction Asset Guidance

When changing `.github/instructions/csharp.instructions.md`, keep it as the source of truth for generated/reviewed C# code. Preserve C# 14, file-scoped namespaces, XML docs for public APIs, `nameof`, pattern matching, `is null` / `is not null`, high-confidence review guidance, and the API topics it covers: EF Core, JWT/OIDC auth, validation, RFC 7807, OpenAPI, structured logging, testing, performance, and deployment.

## Testing Guidelines

No automated tests are defined. For documentation changes, preview Markdown, check links and paths, and run `git diff --check`. For `.github/skills/*/SKILL.md` and instruction files, confirm examples match the current layout. For hook changes, review shell behavior carefully and avoid running scripts that commit or push unless intended.

## Commit & Pull Request Guidelines

Recent history uses concise summaries, often in Traditional Chinese, with occasional prefixes such as `Clarify:` or `翻譯:`. Prefer a short imperative subject, for example `docs: update Copilot skill guide` or `新增 xUnit skill 說明`. PRs should describe changed documents or assets, explain why, and link related issues or research notes. Include screenshots only for rendered Markdown, diagrams, or UI-facing documentation.
