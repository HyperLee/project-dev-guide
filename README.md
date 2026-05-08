# project-dev-guide

這是一個為 .NET/C# 開發流程整理的 GitHub Copilot agents、skills、prompts 與 instructions 資源集合，目的是強化在 VS Code 中的 AI 輔助開發體驗。

## 概覽

此儲存庫提供可重複使用的 GitHub Copilot 設定資產，用來統一程式碼規範、自動化程式碼審查、建立單元測試骨架，以及引導專案初始化流程。所有資源都依照 VS Code 的 GitHub Copilot Chat 與 agent mode 使用方式進行組織。

## 儲存庫結構

```
.github/
├── agents/                    # 自訂 Copilot 聊天 agents
│   ├── CSharpExpert.agent.md  # 資深 .NET 開發 agent
│   └── code-review.agent.md   # 程式碼審查 agent
├── instructions/              # 編碼規範（依檔案模式自動套用）
│   └── csharp.instructions.md # C# 14 / .NET 慣例
├── prompts/                   # 可重複使用的提示範本
│   ├── create-readme.prompt.md
│   ├── csharp-xunit.prompt.md
│   └── project-init.prompt.md (根目錄也有一份)
└── skills/                    # 模組化 agent skill 套件
    ├── Code-Review/
    ├── csharp-fleet/
    ├── csharp-xunit/
    └── skill-creator/
copilot-cli-guide.md           # GitHub Copilot CLI 深入教學（zh-TW）
github-hooks.md                # .github/hooks/ 詳細參考（zh-TW）
開發新專案整理.md               # 專案初始化參考指南（zh-TW）
```

## Agents

### `C# Expert`

這是一個資深 .NET 開發 agent，可產出乾淨、設計良好、可用於正式環境的 C# 程式碼，涵蓋內容包括：

- 現代 C# 14 / .NET 10 寫法（async/await、Span、records、switch expressions）
- SOLID 原則、Dependency Injection、CQRS、Repository Pattern
- 安全性最佳實務（輸入驗證、最小權限、JWT/OAuth）
- 使用 xUnit、NUnit 或 MSTest 進行 TDD

**使用方式：** 在 Copilot Chat 或 agent mode 中輸入 `@CSharpExpert`。

### `code-review`

這是一個著重於全面程式碼審查的 agent，聚焦於：

- 安全性弱點（OWASP Top 10）
- 效能與演算法複雜度
- 程式碼品質與命名慣例
- 架構與設計模式

**使用方式：** 在 Copilot Chat 中選取程式碼後輸入 `@code-review`。

## Skills

Skills 是可按需載入到 Copilot 上下文中的模組化知識套件。

| Skill | 說明 |
|-------|------|
| `Code-Review` | 結構化程式碼審查，輸出包含 Critical / Suggestions / Good Practices |
| `csharp-fleet` | 透過 7 階段品質關卡流程，協調 5 個 agent 團隊（PM、Dev、QA、Security、Architect） |
| `csharp-xunit` | xUnit 最佳實務，包括 Fact/Theory、InlineData/MemberData/ClassData、fixtures、mocking |
| `skill-creator` | 建立與封裝新 agent skills 的指引 |

### 使用 Skills

在 Copilot Chat 中引用 skill：

```
請用 Code-Review skill 審查 #sym:MyMethod 方法的程式碼品質
```

## Instructions

`.github/instructions/csharp.instructions.md` 會在 VS Code 中開啟所有 `*.cs` 檔案時自動套用，內容會強制遵循以下規範：

- C# 14 語言特性
- PascalCase / camelCase 命名慣例
- Nullable reference type 處理方式（`is null` / `is not null`）
- 公開 API 的 XML 文件註解
- 與 EditorConfig 對齊的格式化規範
- Entity Framework Core 資料存取模式
- 結構化日誌與 OpenTelemetry

不需要手動設定，只要 GitHub Copilot 已啟用，VS Code 就會自動讀取。

## Prompts

可重複使用的提示範本存放於 `.github/prompts/`：

| Prompt | 說明 |
|--------|------|
| `project-init.prompt.md` | 初始化新的 .NET 專案（`.gitignore`、`.editorconfig`、`launch.json`、`tasks.json`） |
| `csharp-xunit.prompt.md` | 依最佳實務產生 xUnit 測試專案 |
| `create-readme.prompt.md` | 建立完整的專案 README |

**在 agent mode 中使用：**

```
#file:.github/prompts/project-init.prompt.md
```

## 快速開始

### 複製並套用到你的專案

將 `.github/` 資料夾複製到你自己的儲存庫後，即可立即獲得：

1. Copilot 建議中的自動 C# 編碼規範
2. 可透過 `@AgentName` 語法呼叫的自訂 agents
3. 可重複使用的提示範本

### 專案初始化流程

對新的 .NET 專案執行初始化 prompt：

```bash
# In Copilot Chat (agent mode)
#file:.github/prompts/project-init.prompt.md
```

這會產生：

- 透過 `dotnet new gitignore` 建立 `.gitignore`
- 使用 UTF-8 並強制保留結尾換行的 `.editorconfig`
- 可一鍵除錯的 `launch.json` / `tasks.json`

完整逐步初始化說明請參考 [開發新專案整理.md](開發新專案整理.md)。

### 產生單元測試

```
#file:.github/prompts/csharp-xunit.prompt.md 幫我為 #sym:MyService 產生單元測試
```

## 實驗性模式（僅 CLI）

GitHub Copilot CLI 提供幾個互動式功能，但這些功能無法直接在 VS Code 內使用：

- **Autopilot**：使用額外旗標執行 Copilot binary，讓助理能主導自己的工作階段：
  ```bash
  copilot --yolo --experimental
  ```
  CLI 啟動後，可以按 `Shift+Tab` 切換 autopilot overlay。

- **艦隊模式（Fleet mode）**：在 CLI 提示列中使用 `/fleet` 指令啟動多 agent 團隊：
  ```
  /fleet [PROMPT]
  ```
  其中 `[PROMPT]` 是要交給 fleet 執行的指示內容。

若需要完整的 Copilot CLI 深入說明（安裝、自訂 instructions、agents、skills、MCP servers、hooks、extensions 等），請參考 **[copilot-cli-guide.md](copilot-cli-guide.md)**。

## 需求

- 已安裝 [VS Code](https://code.visualstudio.com/)、[GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot) 與 [GitHub Copilot Chat](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)
- `.NET 9 SDK` 或更新版本（供 `dotnet new` 指令使用）
- 已在 GitHub Copilot Chat 設定中啟用 agent mode

> [!NOTE]
> Skills 與 agents 需要支援 agent mode 的 GitHub Copilot。請確認你使用的是較新的 Copilot Chat 擴充版本。

> [!TIP]
> 可使用 `F1` → `聊天新增指示 / 提示 / 模式`，直接在 VS Code 中建立新的 instructions、prompts 或 chat modes。
