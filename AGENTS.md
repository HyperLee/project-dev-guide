# Repository Guidelines

## Project Structure & Module Organization

This repository is a Markdown-first resource collection for GitHub Copilot agents, skills, prompts, hooks, and .NET/C# development guidance.

- `README.md` is the main overview and should stay aligned with major changes.
- `.github/agents/` contains custom Copilot agent definitions such as `CSharpExpert.agent.md`.
- `.github/instructions/` stores file-pattern instructions, currently focused on C# conventions.
- `.github/prompts/` contains reusable prompt templates.
- `.github/skills/` contains modular skill packages, each with its own `SKILL.md`.
- `.github/hooks/` contains hook configuration and scripts. Treat `stop-hook.sh` carefully because it can commit and push.
- `ResearchFolder/` stores longer research notes and reports.
- Root Markdown files such as `project-init.prompt.md` and `開發新專案整理.md` are project-level references.

## Build, Test, and Development Commands

There is no application build pipeline or package manager configured. Use lightweight repository checks:

- `rg --files` lists tracked documentation and configuration files quickly.
- `rg "term" README.md .github ResearchFolder` searches guides, agents, prompts, and research notes.
- `git diff --check` catches whitespace problems before committing.
- `git status --short` reviews local changes before using hooks or opening a PR.

## Coding Style & Naming Conventions

Follow `.editorconfig`: spaces are used throughout; JSON, XML, project, and config files use 2-space indentation, while C# examples use 4-space indentation. Keep Markdown headings descriptive and sentence-style content concise. Preserve Traditional Chinese in existing zh-TW documents unless a file is already English or the change requires English. Name agent files with the `.agent.md` suffix, prompt files with `.prompt.md`, and skill directories with a clear lowercase or kebab-case name containing a `SKILL.md`.

## Testing Guidelines

No automated tests are defined for this repository. For documentation changes, validate by previewing Markdown, checking links and referenced paths, and running `git diff --check`. For `.github/skills/*/SKILL.md`, confirm examples match the current directory layout. For hook changes, review shell behavior carefully and avoid running scripts that commit or push unless that is intended.

## Commit & Pull Request Guidelines

Recent history uses concise summaries, often in Traditional Chinese, with occasional prefixes such as `Clarify:` or `翻譯:`. Prefer a short imperative subject, for example `docs: update Copilot skill guide` or `新增 xUnit skill 說明`. PRs should describe the changed documents or Copilot assets, explain why the change is needed, and link related issues or research notes. Include screenshots only when changing rendered Markdown, diagrams, or UI-facing documentation.
