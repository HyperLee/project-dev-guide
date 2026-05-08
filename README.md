# project-dev-guide

這個儲存庫是一份 Markdown-first 的 AI 開發資產與 .NET/C# 開發指南集合，主要用來整理 GitHub Copilot / Copilot CLI / Codex 相關的 agents、instructions、skills、prompts、hooks 與研究筆記。

目標是讓新專案可以快速套用一致的 C# 開發規範、README 建立流程、程式碼審查模式與 AI 工具初始化參考。

## 內容導覽

- [儲存庫結構](#儲存庫結構)
- [快速開始](#快速開始)
- [Copilot 資產](#copilot-資產)
- [Hooks](#hooks)
- [專案文件與研究筆記](#專案文件與研究筆記)
- [維護檢查](#維護檢查)

## 儲存庫結構

```text
.
├── .github/
│   ├── agents/
│   │   └── CSharpExpert.agent.md
│   ├── hooks/
│   │   ├── hooks.json
│   │   └── stop-hook.sh
│   ├── instructions/
│   │   └── csharp.instructions.md
│   ├── prompts/
│   │   └── create-readme.prompt.md
│   └── skills/
│       ├── code-review/
│       └── skill-creator/
├── docs/
│   └── readme-template.md
├── ResearchFolder/
├── AGENTS.md
├── project-init.prompt.md
├── README.md
└── 開發新專案整理.md
```

| 路徑 | 用途 |
|------|------|
| `.github/agents/` | 自訂 Copilot agent。 |
| `.github/instructions/` | 依檔案模式套用的開發指示。 |
| `.github/prompts/` | 可重複使用的 Copilot prompt。 |
| `.github/skills/` | 可按需載入的 skill 套件。 |
| `.github/hooks/` | Copilot CLI hook 設定與腳本。 |
| `docs/` | 專案文件範本。 |
| `ResearchFolder/` | 長篇研究、比較與工具筆記。 |
| `AGENTS.md` | 給 AI coding agent 使用的本儲存庫工作規範。 |
| `project-init.prompt.md` | 新 .NET 專案初始化 prompt。 |
| `開發新專案整理.md` | 新專案初始化、開發規範與收尾檢查清單。 |

## 快速開始

### 套用到其他專案

將需要的 `.github/` 子資料夾複製到目標專案後，即可讓 Copilot 使用對應資產：

```text
.github/agents/
.github/instructions/
.github/prompts/
.github/skills/
```

建議至少先套用：

1. `.github/instructions/csharp.instructions.md`：統一 C# 程式碼產生與審查規範。
2. `.github/agents/CSharpExpert.agent.md`：提供 .NET/C# 開發 agent。
3. `.github/skills/code-review/`：提供結構化程式碼審查流程。

> [!CAUTION]
> `.github/hooks/stop-hook.sh` 會在 session 結束時自動暫存、提交並推送變更。只有在確認目標專案需要這種自動化行為時才複製 hooks。

### 初始化新的 .NET 專案

根目錄的 `project-init.prompt.md` 提供基礎初始化步驟，包含：

- 使用 `dotnet new gitignore` 建立 `.gitignore`。
- 使用 `dotnet new editorconfig` 建立 `.editorconfig`。
- 請 AI 產生可直接啟動除錯的 `launch.json` 與 `tasks.json`。
- 使用 CLI 的 `/init` 建立 AI 工具初始化設定。

在 Copilot Chat 或 agent mode 中可引用：

```text
#file:project-init.prompt.md
```

更完整的新專案檢查流程請參考 `開發新專案整理.md`。

### 建立或整理 README

本儲存庫提供兩種 README 相關資產：

- `.github/prompts/create-readme.prompt.md`：給 Copilot 使用的 README 建立 prompt。
- `docs/readme-template.md`：第一次建立 README 時可參考的內容規範與驗證清單。

如果專案已經有 README，請先閱讀現有內容與目前檔案結構，再改寫；不要直接套用初始範本覆蓋。

## Copilot 資產

### Agent：C# Expert

`.github/agents/CSharpExpert.agent.md` 定義一個 .NET/C# 開發 agent，適合用於：

- 產生符合現代 C# / .NET 慣例的程式碼。
- 協助設計 async/await、Dependency Injection、CQRS、Unit of Work 等實作。
- 檢查安全性、效能、可維護性與測試策略。
- 規劃 xUnit、NUnit 或 MSTest 測試。

使用時可在 Copilot Chat 或 agent mode 中選取 `C# Expert`，或以自然語言要求 Copilot 使用該 agent。

### Instructions：C# 開發規範

`.github/instructions/csharp.instructions.md` 會套用到 `**/*.cs`，是本儲存庫的 C# 指示來源。它涵蓋：

- C# 14 語言特性與 file-scoped namespaces。
- PascalCase / camelCase 命名慣例。
- Nullable reference types 與 `is null` / `is not null` 寫法。
- Public API 的 XML documentation comments。
- `nameof`、pattern matching、switch expressions。
- EF Core 資料存取、JWT/OIDC 驗證授權、FluentValidation、RFC 7807 problem details。
- Swagger/OpenAPI、structured logging、Application Insights / OpenTelemetry。
- 單元測試、整合測試、效能最佳化、部署與 DevOps 指引。

修改這個檔案時，請把它視為 C# 程式碼生成與審查的 source of truth。

### Prompt：Create README

`.github/prompts/create-readme.prompt.md` 用來請 Copilot 深度閱讀專案後建立 README。它要求：

- 先檢查整個 workspace。
- 不要捏造不存在的功能、指令、badge 或截圖。
- 使用 GitHub Flavored Markdown。
- 避免加入已由獨立檔案負責的 LICENSE、CONTRIBUTING、CHANGELOG 等章節。
- 保留專案自然語言，例如既有文件為繁體中文時延續繁體中文。

### Skill：code-review

`.github/skills/code-review/` 是結構化程式碼審查 skill，重點包含：

- 先理解被審查程式碼、相關檔案、團隊慣例與風險。
- 從安全性、正確性、效能、可維護性、架構、測試與可及性進行審查。
- 依嚴重度輸出 Critical Issues、Suggestions、Good Practices 與 Metrics。
- 在 `references/` 中提供安全、語言、效能與測試模式參考。
- 在 `evals/` 中保存 skill 評估與觸發測試案例。

範例使用方式：

```text
請使用 code-review skill 審查這次變更，特別注意安全性與測試缺口。
```

### Skill：skill-creator

`.github/skills/skill-creator/` 用於建立、改善與評估新的 skill。它包含：

- `SKILL.md`：建立與迭代 skill 的主要流程。
- `scripts/`：驗證、封裝、評估與 benchmark 輔助腳本。
- `agents/`：分析、比較、評分用的輔助 agent 指引。
- `assets/` 與 `eval-viewer/`：用於檢視評估結果的 HTML 與產生器。
- `references/`：eval schema 與相關資料格式。

這個 skill 適合在需要把重複工作流封裝成可重用能力時使用。

## Hooks

`.github/hooks/hooks.json` 目前設定了 `sessionEnd` hook：

```json
{
  "version": 1,
  "hooks": {
    "sessionEnd": [
      {
        "type": "command",
        "bash": ".github/hooks/stop-hook.sh",
        "cwd": ".",
        "timeoutSec": 30
      }
    ]
  }
}
```

`.github/hooks/stop-hook.sh` 的行為是：

1. 檢查目前是否在 Git work tree 中。
2. 如果有未提交變更，執行 `git add -A`。
3. 依變更檔案類型推斷 Conventional Commits 類型。
4. 產生 commit message。
5. 執行 `git commit --no-verify`。
6. 執行 `git push`。

> [!WARNING]
> 這個 hook 會自動 commit 和 push。修改或套用到其他專案前，請先確認團隊流程、分支策略與遠端權限是否允許這種行為。

## 專案文件與研究筆記

### `docs/readme-template.md`

這是第一次建立 README 時的範本指引。它特別要求：

- 如果 `README.md` 已存在，停止並說明這是初始建立範本。
- README 必須符合目前實作，不要發明不存在的功能。
- 完成前檢查所有路徑、指令與範例。

### `開發新專案整理.md`

這份文件整理 .NET/C# 新專案從初始化到收尾的流程，包括：

- `.gitignore` 與 `.editorconfig` 建立。
- Model / DTO 驗證規則。
- Public API 與主要函式 XML 註解。
- Commander、Mermaid 等 VS Code 工具使用情境。
- README、範例執行與 `git diff --check` 收尾檢查。

### `ResearchFolder/`

`ResearchFolder/` 保存較長篇的研究與比較資料，主題包含：

- GitHub Copilot CLI、Copilot SDK 與 Codex CLI。
- Copilot hooks、agents、skills、MCP 與自訂擴展。
- Spec Kit 與 spec-driven development。
- Hermes Agent、Harness 平台與相關比較。
- code-review skill 的結構、評估案例與改善建議。
- .NET 測試 skill 與 xUnit 實務分析。

README 只保留索引層級說明；深入內容請直接閱讀 `ResearchFolder/` 內的對應文件。

## 維護檢查

這個儲存庫沒有應用程式建置流程或套件管理器。文件或資產更新後，建議執行：

```bash
rg --files
rg "term" README.md .github ResearchFolder docs
git diff --check
git status --short
```

維護 README 時請特別檢查：

- README 列出的檔案與資料夾是否實際存在。
- `.github/skills/*/SKILL.md` 的說明是否與目前目錄一致。
- `.github/instructions/csharp.instructions.md` 是否仍涵蓋 C# 14、EF Core、auth、validation、OpenAPI、logging、testing、performance 與 deployment。
- hook 說明是否清楚標示自動 commit / push 的風險。
- `ResearchFolder/` 新增或搬移研究文件後，README 的主題摘要是否仍準確。

## 需求

- [VS Code](https://code.visualstudio.com/)
- [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot)
- [GitHub Copilot Chat](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)
- .NET SDK 9 或更新版本，供 `dotnet new` 初始化指令使用。
- 支援 agent mode / instructions / prompts / skills 的 Copilot 或相容 CLI 環境。

> [!NOTE]
> Copilot、Copilot CLI、Codex 與 skill 支援狀態會隨工具版本改變。套用本儲存庫資產前，請先確認目前使用的 IDE、CLI 與擴充套件版本支援對應功能。
