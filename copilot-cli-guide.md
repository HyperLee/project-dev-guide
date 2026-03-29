# GitHub Copilot CLI 深度教學指南

> **最後更新**：2026-03  
> **適用版本**：GitHub Copilot CLI GA（2026 年 3 月正式發布）  
> **語言**：繁體中文（技術指令保留英文）

---

## 目錄

- [一、概述與官方資源](#一概述與官方資源)
- [二、安裝與啟動](#二安裝與啟動)
- [三、基本使用教學](#三基本使用教學)
- [四、斜線命令完整參考](#四斜線命令完整參考)
- [五、模型選擇與管理](#五模型選擇與管理)
- [六、自訂指示（Custom Instructions）](#六自訂指示custom-instructions)
- [七、自訂代理（Custom Agents）](#七自訂代理custom-agents)
- [八、Agent Skills](#八agent-skills)
- [九、MCP Server 設定](#九mcp-server-設定)
- [十、Hooks 機制](#十hooks-機制)
- [十一、Extensions 系統](#十一extensions-系統)
- [十二、LSP Server 設定](#十二lsp-server-設定)
- [十三、安全性與權限管理](#十三安全性與權限管理)
- [十四、會話管理與進階技巧](#十四會話管理與進階技巧)
- [十五、程式化（Non-interactive）使用](#十五程式化non-interactive使用)
- [十六、常用環境變數](#十六常用環境變數)
- [十七、配置檔案總整理](#十七配置檔案總整理)
- [附錄 A：快捷鍵一覽表](#附錄-a快捷鍵一覽表)
- [附錄 B：常見問題 FAQ](#附錄-b常見問題-faq)
- [Footnotes](#footnotes)

---

## 一、概述與官方資源

### 1.1 什麼是 GitHub Copilot CLI？

GitHub Copilot CLI 是 GitHub 推出的**終端機原生 AI 代理**（Terminal-native AI Agent），將 GitHub Copilot coding agent 的能力直接帶入命令列[^1]。你可以透過自然語言對話，在不離開終端機的情況下完成以下任務：

- 建立、編輯、除錯、重構程式碼
- 建立 Pull Request、管理 Issue
- 執行 Git 操作與 GitHub Actions
- 進行程式碼審查
- 與 GitHub.com 資源互動

Copilot CLI 基於與 GitHub Copilot coding agent 相同的代理框架（agentic harness），提供完整的規劃、執行、與多代理協作能力[^2]。

### 1.2 官方資源

| 資源 | 連結 |
|------|------|
| 🌐 官方產品頁面 | https://github.com/features/copilot/cli |
| 📦 官方 GitHub Repo | https://github.com/github/copilot-cli |
| 📖 官方文件 | https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli |
| 📖 概念說明 | https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli |
| 🎓 GitHub Skills 課程 | https://github.com/skills/create-applications-with-the-copilot-cli |
| 🔌 MCP Registry | https://github.com/mcp |
| 🛠️ Copilot SDK | https://github.com/github/copilot-sdk |
| 📝 最佳實踐 | https://docs.github.com/en/copilot/how-tos/copilot-cli/cli-best-practices |

### 1.3 支援平台與訂閱

**支援平台：**
- macOS
- Linux
- Windows（PowerShell v6+ 或 WSL）[^3]

**訂閱方案：** Copilot CLI 包含在所有 GitHub Copilot 方案中[^4]：

| 方案 | 包含 Copilot CLI |
|------|:---:|
| Copilot Free | ✅ |
| Copilot Pro | ✅ |
| Copilot Pro+ | ✅ |
| Copilot Business | ✅（需管理員啟用） |
| Copilot Enterprise | ✅（需管理員啟用） |

> ⚠️ 如果你透過組織或企業存取 Copilot，你的組織管理員必須在設定中啟用 Copilot CLI[^5]。

---

## 二、安裝與啟動

### 2.1 安裝方式

提供四種安裝方式[^6]：

#### 方式一：Install Script（macOS / Linux，推薦）

```bash
curl -fsSL https://gh.io/copilot-install | bash
```

或使用 `wget`：

```bash
wget -qO- https://gh.io/copilot-install | bash
```

**進階選項：**

```bash
# 以 root 安裝到 /usr/local/bin
curl -fsSL https://gh.io/copilot-install | sudo bash

# 安裝特定版本到自訂目錄
curl -fsSL https://gh.io/copilot-install | VERSION="v0.0.369" PREFIX="$HOME/custom" bash
```

#### 方式二：Homebrew（macOS / Linux）

```bash
# 正式版
brew install copilot-cli

# 預覽版
brew install copilot-cli@prerelease
```

#### 方式三：WinGet（Windows）

```bash
# 正式版
winget install GitHub.Copilot

# 預覽版
winget install GitHub.Copilot.Prerelease
```

#### 方式四：npm（全平台）

```bash
# 正式版
npm install -g @github/copilot

# 預覽版
npm install -g @github/copilot@prerelease
```

### 2.2 啟動與首次使用

```bash
copilot
```

首次啟動流程：

```
copilot 啟動
    │
    ▼
┌─────────────────────────────┐
│ 是否信任當前目錄的檔案？       │
├─────────────────────────────┤
│ 1. Yes, proceed             │ ← 僅限本次會話
│ 2. Yes, and remember        │ ← 永久信任此目錄
│ 3. No, exit (Esc)           │ ← 結束
└─────────────────────────────┘
    │
    ▼
┌─────────────────────────────┐
│ 是否已登入 GitHub？           │
├─────────────────────────────┤
│ 已登入 → 進入互動介面         │
│ 未登入 → 執行 /login          │
└─────────────────────────────┘
```

> 💡 加上 `--banner` 旗標可以再次看到啟動動畫：`copilot --banner`

### 2.3 認證方式

**方式一：OAuth 裝置授權（預設）**

執行 `/login` 後依照畫面指示在瀏覽器中完成授權。

**方式二：Personal Access Token（PAT）**

1. 前往 https://github.com/settings/personal-access-tokens/new
2. 在「Permissions」下選擇「Copilot Requests」權限
3. 產生 Token
4. 設定環境變數[^7]：

```bash
# 優先順序：GH_TOKEN > GITHUB_TOKEN
export GH_TOKEN="ghp_xxxxxxxxxxxx"
```

### 2.4 更新

```bash
# 在 CLI 互動介面中
/update

# 或使用 npm
npm update -g @github/copilot
```

---

## 三、基本使用教學

### 3.1 兩種介面

GitHub Copilot CLI 提供兩種使用介面[^8]：

| 介面 | 說明 | 啟動方式 |
|------|------|---------|
| **互動式（Interactive）** | 多輪對話，可持續與 Copilot 互動 | `copilot` |
| **程式化（Programmatic）** | 單次任務，完成後自動退出 | `copilot -p "..."` |

### 3.2 三種操作模式

在互動式介面中，使用 `Shift+Tab` 循環切換三種模式[^9]：

| 模式 | 說明 | 適用場景 |
|------|------|---------|
| **Interactive**（預設） | 每個動作都需要你的確認 | 需要精確控制的任務 |
| **Plan** | Copilot 先建立計畫再執行 | 複雜的多步驟任務 |
| **Autopilot**（實驗功能） | Copilot 自主完成整個任務 | 信任 Copilot 處理的任務 |

> ⚠️ Autopilot 模式需要先啟用實驗功能：`/experimental` 或 `copilot --experimental`[^10]

### 3.3 檔案引用語法

使用 `@` 符號可以將檔案內容加入提示的上下文[^11]：

```
# 引用單一檔案
Explain @config/ci/ci-required-checks.yml

# 引用並要求修改
Fix the bug in @src/app.js

# 輸入 @ 後，使用方向鍵選擇檔案，按 Tab 自動完成路徑
```

### 3.4 直接執行 Shell 命令

在提示前加上 `!` 可以直接執行 Shell 命令，不經過 AI 模型[^12]：

```bash
!git status
!ls -la
!docker ps
```

### 3.5 工具權限審批

當 Copilot 需要使用可能修改或執行檔案的工具時（如 `touch`、`chmod`、`node`、`sed`），會請求你的批准[^13]：

```
┌─────────────────────────────────────────────────────────┐
│ Copilot wants to run: npm install express               │
├─────────────────────────────────────────────────────────┤
│ 1. Yes                                                  │
│ 2. Yes, and approve npm for the rest of the session     │
│ 3. No, and tell Copilot what to do differently (Esc)    │
└─────────────────────────────────────────────────────────┘
```

| 選項 | 效果 |
|------|------|
| **Yes** | 僅允許這次，下次再問 |
| **Yes, and approve for session** | 本次會話期間，此工具不再詢問 |
| **No (Esc)** | 拒絕並可給予替代指示 |

> ⚠️ 選擇「approve for session」後，該工具的**所有用法**都會被允許（例如批准 `rm` 後，`rm -rf ./*` 也不會再詢問）[^13]。

### 3.6 引導對話

你可以在 Copilot 思考時進行互動引導[^14]：

- **排隊追加訊息**：在 Copilot 回應期間發送後續指示，它會在完成當前回應後處理
- **拒絕時給予回饋**：拒絕工具權限時，可以內嵌說明讓 Copilot 調整方向

### 3.7 常用提示範例

**本地任務：**

```
# 修改程式碼
Change the background-color of H1 headings to dark blue

# 查看檔案歷史
Show me the last 5 changes made to the CHANGELOG.md file

# 從零建立應用
Use create-next-app and tailwind CSS to create a dashboard app

# 排錯
You said the app is running on localhost:3002 but I get "This site can't be reached"
```

**GitHub.com 任務：**

```
# 列出 PR
List my open PRs

# 處理 Issue
I've been assigned this issue: https://github.com/org/repo/issues/1234. Start working on this.

# 建立 PR
Create a PR that updates the README, changing "How to run" to "Example usage"

# 審查 PR
Check the changes made in PR https://github.com/org/repo/pull/57575

# 合併 PR
Merge all of the open PRs that I've created in org/repo

# 建立 GitHub Actions
Create a GitHub Actions workflow that runs eslint on pull requests
```

---

## 四、斜線命令完整參考

所有斜線命令（Slash Commands）按功能分類整理如下[^15]：

### 4.1 模型與代理

| 命令 | 說明 |
|------|------|
| `/model` | 選擇 AI 模型 |
| `/fleet` | 啟用艦隊模式，平行執行多個子代理 |
| `/delegate` | 將當前會話委派給 GitHub，由 Copilot 建立 PR |
| `/tasks` | 查看與管理背景任務（子代理和 Shell 會話） |

### 4.2 程式碼操作

| 命令 | 說明 |
|------|------|
| `/ide` | 連接到 IDE 工作區 |
| `/diff` | 檢視當前目錄的變更 |
| `/pr` | 操作當前分支的 Pull Request |
| `/review` | 執行程式碼審查代理 |
| `/lsp` | 管理語言伺服器設定 |
| `/terminal-setup` | 設定終端機的多行輸入支援（`Shift+Enter`） |

### 4.3 權限管理

| 命令 | 說明 |
|------|------|
| `/allow-all` | 啟用所有權限（工具、路徑、URL） |
| `/add-dir` | 新增允許存取的目錄 |
| `/list-dirs` | 顯示所有允許的目錄 |
| `/cwd` | 切換工作目錄或顯示當前目錄 |
| `/reset-allowed-tools` | 重設已允許的工具清單 |

### 4.4 會話管理

| 命令 | 說明 |
|------|------|
| `/resume` | 切換到其他會話（可指定會話 ID） |
| `/rename` | 重新命名當前會話 |
| `/context` | 顯示上下文視窗的 Token 用量 |
| `/usage` | 顯示會話統計（Premium Request、時長、Token 用量） |
| `/compact` | 壓縮對話歷史以釋放上下文空間 |
| `/share` | 分享會話為 Markdown 或 GitHub Gist |
| `/copy` | 複製最後一個回應到剪貼簿 |
| `/rewind` | 回退上一輪並還原檔案變更 |
| `/session` | 查看與管理會話 |

### 4.5 自訂與擴展

| 命令 | 說明 |
|------|------|
| `/init` | 初始化倉庫的 Copilot 指示檔 |
| `/agent` | 瀏覽並選擇可用的代理 |
| `/skills` | 管理 Agent Skills |
| `/mcp` | 管理 MCP Server 設定 |
| `/plugin` | 管理插件與插件市場 |
| `/instructions` | 查看與切換自訂指示檔 |

### 4.6 幫助與回饋

| 命令 | 說明 |
|------|------|
| `/help` | 顯示幫助資訊 |
| `/changelog` | 顯示版本更新日誌（加 `summarize` 可獲得 AI 摘要） |
| `/feedback` | 提供回饋（調查問卷、Bug 回報、功能建議） |
| `/version` | 顯示版本資訊並檢查更新 |
| `/update` | 更新 CLI 到最新版本 |
| `/experimental` | 顯示或啟用/停用實驗功能 |

### 4.7 其他

| 命令 | 說明 |
|------|------|
| `/clear` | 放棄當前會話，重新開始 |
| `/new` | 開始新對話 |
| `/plan` | 建立實作計畫後再寫程式碼 |
| `/research` | 執行深度研究（使用 GitHub 搜尋與網頁資源） |
| `/login` / `/logout` | 登入 / 登出 |
| `/exit` / `/quit` | 退出 CLI |
| `/streamer-mode` | 切換直播模式（隱藏模型名稱與配額資訊） |

---

## 五、模型選擇與管理

### 5.1 支援的模型

Copilot CLI 支援來自多家供應商的模型[^16]：

| 供應商 | 模型範例 |
|--------|---------|
| **Anthropic** | Claude Sonnet 4.5（預設）、Claude Sonnet 4、Claude Opus 4.6 |
| **OpenAI** | GPT-5、GPT-5 mini |
| **Google** | Gemini 3 Pro |

### 5.2 切換模型

```bash
# 在互動式介面中
/model

# 使用命令列選項
copilot --model claude-sonnet-4
```

### 5.3 Premium Request 計費

每次提交提示都會消耗你的月度 Premium Request 配額，消耗量依模型而異[^17]：

| 模型 | 乘數 | 說明 |
|------|------|------|
| Claude Sonnet 4.5 | 1x | 預設模型，每次提示消耗 1 個 |
| Claude Opus 4.6 | 多倍 | 更強推理能力，消耗更多 |
| GPT-5 mini | 低於 1x | 較快速、較便宜 |

> 💡 使用 `/usage` 命令可以檢視當前會話的消耗統計。

---

## 六、自訂指示（Custom Instructions）

自訂指示讓 Copilot 自動獲得你的專案上下文、編碼慣例、測試策略等資訊，不需要每次都在提示中重複說明[^18]。

### 6.1 四種層級

```
優先順序（由高到低）：
┌─────────────────────────────────────────────┐
│ ① 路徑專屬指示                                │
│    .github/instructions/**/*.instructions.md │
├─────────────────────────────────────────────┤
│ ② 倉庫全域指示                                │
│    .github/copilot-instructions.md           │
├─────────────────────────────────────────────┤
│ ③ 代理指示                                    │
│    AGENTS.md / CLAUDE.md / GEMINI.md         │
├─────────────────────────────────────────────┤
│ ④ 本地個人指示                                │
│    ~/.copilot/copilot-instructions.md        │
└─────────────────────────────────────────────┘
```

> 📝 所有找到的指示檔都會**合併使用**，而非互相覆蓋[^19]。

### 6.2 倉庫全域指示

建立 `.github/copilot-instructions.md`，適用於此倉庫的所有請求：

```markdown
# 倉庫指示

- 使用 C# 14 語法
- 遵循 SOLID 原則
- 所有 public API 必須有 XML 文件註解
- 使用 xUnit 進行單元測試
```

### 6.3 路徑專屬指示

建立 `.github/instructions/<名稱>.instructions.md`，使用 `applyTo` frontmatter 指定適用的檔案模式[^20]：

```markdown
---
applyTo: "**/*.cs"
---

# C# Development

- Always use the latest version C#, currently C# 14 features.
- Use `is null` or `is not null` instead of `== null` or `!= null`.
- Follow PascalCase for public members.
```

**Glob 語法範例：**

| 模式 | 匹配 |
|------|------|
| `*.py` | 當前目錄下的 `.py` 檔案 |
| `**/*.py` | 所有目錄下的 `.py` 檔案（遞迴） |
| `src/**/*.ts` | `src/` 下所有 `.ts` 檔案 |
| `**/*.ts,**/*.tsx` | 所有 TypeScript 檔案（多模式用逗號） |

**可選的 `excludeAgent` 欄位：**

```markdown
---
applyTo: "**"
excludeAgent: "code-review"
---
```

此指示僅供 Copilot coding agent 使用，不適用於 Copilot code review。

### 6.4 代理指示

在倉庫根目錄或工作目錄建立以下檔案[^21]：

- `AGENTS.md`（主要指示）
- `CLAUDE.md`（Anthropic 模型專用）
- `GEMINI.md`（Google 模型專用）

### 6.5 本地個人指示

```bash
# 建立全域個人指示
mkdir -p ~/.copilot
cat > ~/.copilot/copilot-instructions.md << 'EOF'
- 回覆請使用繁體中文
- 程式碼註解使用英文
- 偏好使用函數式程式設計風格
EOF
```

### 6.6 環境變數擴展

透過 `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` 環境變數，可以指定額外的指示搜尋目錄[^22]：

```bash
export COPILOT_CUSTOM_INSTRUCTIONS_DIRS="/path/to/team-standards,/path/to/org-policies"
```

Copilot CLI 會在這些目錄中尋找 `AGENTS.md` 檔案與 `.github/instructions/**/*.instructions.md` 檔案。

### 6.7 本專案範例

本專案使用路徑專屬指示 `.github/instructions/csharp.instructions.md`，自動套用到所有 `**/*.cs` 檔案：

```
.github/
└── instructions/
    └── csharp.instructions.md    ← applyTo: "**/*.cs"
```

內容涵蓋 C# 14 語法要求、命名慣例、Nullable Reference Types、Entity Framework Core 模式等。

---

## 七、自訂代理（Custom Agents）

### 7.1 內建代理

Copilot CLI 內建四種專用代理[^23]：

| 代理 | 用途 | 特點 |
|------|------|------|
| **Explore** | 快速分析程式碼庫 | 不佔用主對話上下文 |
| **Task** | 執行測試、建置等命令 | 成功時簡要摘要，失敗時完整輸出 |
| **General-purpose** | 處理複雜多步驟任務 | 在獨立上下文視窗中執行 |
| **Code-review** | 審查程式碼變更 | 僅顯示真正重要的問題 |

AI 模型會**自動判斷**是否需要委派任務給子代理，你也可以手動指定。

### 7.2 定義位置

自訂代理可以存放在三個層級[^24]：

| 層級 | 位置 | 適用範圍 |
|------|------|---------|
| 使用者級 | `~/.copilot/agents/` | 所有專案 |
| 倉庫級 | `.github/agents/` | 當前專案 |
| 組織/企業級 | `.github-private` 倉庫的 `/agents/` | 組織下所有專案 |

**優先順序**：系統級 > 倉庫級 > 組織級（同名時高優先覆蓋低優先）。

### 7.3 Agent 檔案格式

Agent 檔案使用 Markdown + YAML frontmatter 格式：

```markdown
---
name: "C# Expert"
description: An agent designed to assist with software development tasks for .NET projects.
---

# C# Expert Agent

You are a senior .NET developer agent. You produce clean, well-designed,
production-ready C# code following these principles:

- Modern C# 14 / .NET 10 patterns
- SOLID principles and Dependency Injection
- TDD with xUnit
- Security best practices (input validation, JWT/OAuth)
```

### 7.4 三種使用方式

```bash
# 方式一：斜線命令（從清單選擇）
/agent

# 方式二：自然語言指名
Use the refactoring agent to refactor this code block

# 方式三：命令列選項
copilot --agent=CSharpExpert --prompt "Review this code"
```

### 7.5 本專案範例

```
.github/
└── agents/
    └── CSharpExpert.agent.md     ← 高級 .NET 開發者代理
```

使用 `C# Expert` 代理時，它會自動套用 C# 14 語法、SOLID 原則、TDD 等專業知識。

---

## 八、Agent Skills

### 8.1 什麼是 Skills？

Skills 是**模組化的知識套件**，包含指示、腳本與資源，Copilot 會根據任務需求**動態載入**相關的 Skill[^25]。

**Skills vs Custom Instructions 的差異：**

| 面向 | Custom Instructions | Skills |
|------|-------------------|--------|
| 載入時機 | **每次**都自動載入 | **按需**才載入 |
| 適用場景 | 通用的編碼標準 | 特定任務的專業知識 |
| 內容複雜度 | 簡單的文字指示 | 可包含腳本、範例、參考資料 |

### 8.2 目錄結構

```
.github/skills/                          ← 專案 Skills
├── code-review/
│   ├── SKILL.md                         ← 必須的入口檔
│   ├── references/
│   │   ├── security-checklist.md
│   │   ├── performance-patterns.md
│   │   └── ...
│   └── evals/
│       └── evals.json
├── csharp-fleet/
│   ├── SKILL.md
│   └── references/
│       └── workflow-phases.md
└── skill-creator/
    ├── SKILL.md
    ├── scripts/
    │   ├── run_eval.py
    │   └── ...
    └── agents/
        ├── grader.md
        └── ...

~/.copilot/skills/                       ← 個人 Skills（跨專案共用）
```

### 8.3 SKILL.md 格式

```markdown
---
name: code-review
description: "Perform a thorough, senior-engineer-level code review with actionable
feedback. Triggers on: code review, PR review, diff inspection, code audit..."
---

# Code Review Skill

When performing code review, follow this structured approach:

1. **Security** — Check for OWASP Top 10 vulnerabilities
2. **Performance** — Analyze algorithm complexity
3. **Quality** — Review naming conventions and code structure
4. **Architecture** — Evaluate design patterns usage

## References
See the files in the `references/` directory for detailed checklists.
```

**YAML frontmatter 欄位：**

| 欄位 | 必填 | 說明 |
|------|:---:|------|
| `name` | ✅ | 唯一識別名稱，小寫加連字號 |
| `description` | ✅ | 描述技能用途與觸發條件 |
| `license` | ❌ | 授權資訊 |

### 8.4 Skills 管理命令

```bash
# 列出可用的 Skills
/skills list
# 或用自然語言
What skills do you have?

# 啟用/停用特定 Skills（使用方向鍵與空白鍵切換）
/skills

# 查看 Skill 詳細資訊
/skills info

# 新增 Skill 搜尋路徑
/skills add

# 重新載入 Skills（修改後不需重啟 CLI）
/skills reload

# 移除 Skill
/skills remove <skill-directory>
```

### 8.5 使用 Skill

**自動觸發：** Copilot 會根據你的提示與 Skill 的 `description` 自動判斷是否載入。

**手動指定：** 在提示中使用斜線加 Skill 名稱：

```
Use the /code-review skill to review my changes

Use the /csharp-fleet skill to implement this feature with quality gates
```

### 8.6 本專案 Skills

| Skill | 說明 |
|-------|------|
| `code-review` | 結構化程式碼審查，輸出 Critical / Suggestions / Good Practices |
| `csharp-fleet` | 模擬 5 代理團隊（PM、Dev、QA、Security、Architect）通過 7 階段品質閘門 |
| `skill-creator` | 建立與打包新 Agent Skill 的指引 |

---

## 九、MCP Server 設定

### 9.1 什麼是 MCP？

**Model Context Protocol（MCP）** 是一個開放標準，讓 Copilot CLI 能夠與外部資料來源和工具互動[^26]。MCP Server 充當 Copilot 與外部資源之間的橋樑。

```
┌──────────────┐     MCP 協定      ┌──────────────────┐
│ Copilot CLI  │ ◄──────────────► │ MCP Server       │
│ （AI 代理）   │                  │ （工具提供者）     │
└──────────────┘                  ├──────────────────┤
                                  │ • GitHub API     │
                                  │ • 資料庫         │
                                  │ • 檔案系統       │
                                  │ • 自訂 API       │
                                  └──────────────────┘
```

### 9.2 內建的 GitHub MCP Server

Copilot CLI **預設**內建 GitHub MCP Server[^27]，提供以下功能：

- 管理 Issue 與 Pull Request
- 搜尋倉庫與程式碼
- 操作 GitHub Actions
- 管理分支與合併

### 9.3 新增 MCP Server

**方式一：互動式新增**

```bash
/mcp add
# 使用 Tab 鍵在欄位間移動，Ctrl+S 儲存
```

**方式二：手動編輯設定檔**

編輯 `~/.copilot/mcp-config.json`[^28]：

```json
{
  "mcpServers": {
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/dir"],
      "env": {}
    },
    "postgres": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "postgresql://user:pass@localhost:5432/mydb"
      }
    }
  }
}
```

**設定檔欄位說明：**

| 欄位 | 說明 |
|------|------|
| `type` | 通訊方式，通常為 `"stdio"` |
| `command` | 執行的命令 |
| `args` | 命令參數陣列 |
| `env` | 環境變數（用於密鑰等） |
| `tools` | 可選，限制此 Server 可用的工具 |

### 9.4 MCP Server 管理命令

```bash
# 查看已設定的 MCP Server
/mcp

# 新增 MCP Server
/mcp add

# 查看 Server 詳情
/mcp show
```

### 9.5 發現更多 MCP Server

前往 [GitHub MCP Registry](https://github.com/mcp) 瀏覽社群與合作夥伴開發的 MCP Server。

---

## 十、Hooks 機制

> 📖 **詳細說明**請參考本專案的 [github-hooks.md](github-hooks.md)，以下為摘要。

### 10.1 概述

Hooks 讓你在 Copilot 代理執行流程中的**關鍵生命週期節點**插入自訂 Shell 命令[^29]。

### 10.2 事件類型

| 事件 | 觸發時機 | 可控制執行？ |
|------|---------|:----------:|
| `sessionStart` | 會話開始或恢復 | ❌ |
| `sessionEnd` | 會話結束 | ❌ |
| `userPromptSubmitted` | 使用者提交提示 | ❌ |
| `preToolUse` | 工具執行前 | ✅ 可允許/拒絕 |
| `postToolUse` | 工具執行後 | ❌ |
| `agentStop` | 主代理完成回應 | ✅ 可強制繼續 |
| `subagentStop` | 子代理完成 | ✅ 可強制繼續 |
| `errorOccurred` | 發生錯誤 | ❌ |

### 10.3 設定檔位置

```
.github/hooks/*.json     ← 倉庫的所有 JSON 設定檔都會被載入
```

### 10.4 本專案範例

本專案在 `.github/hooks/hooks.json` 設定了 `sessionEnd` hook，在會話結束時自動 commit 並 push 所有變更（詳見 [github-hooks.md](github-hooks.md)）。

---

## 十一、Extensions 系統

### 11.1 概述

Extensions 是 Copilot CLI 的**插件系統**，讓你可以在 AI 代理迴圈中執行自訂工具與邏輯[^30]。每個 Extension 以獨立的 Node.js 子程序執行，透過 JSON-RPC over stdio 與 Copilot 通訊。

### 11.2 目錄結構

| 層級 | 位置 | 說明 |
|------|------|------|
| 專案級 | `.github/extensions/<name>/extension.mjs` | 僅限當前專案 |
| 使用者級 | `~/.copilot/extensions/<name>/extension.mjs` | 跨專案共用 |

> 同名 Extension 時，專案級覆蓋使用者級。

### 11.3 建立 Extension

```
.github/
└── extensions/
    └── my-tool/
        └── extension.mjs    ← ES Module 入口
```

**範例 `extension.mjs`：**

```javascript
import { joinSession } from "@github/copilot-sdk";

export default async function main() {
  const session = await joinSession({
    tools: {
      greet: {
        description: "Greet the user by name.",
        params: { name: { type: "string" } },
        handler: async ({ name }) => `Hello, ${name}!`
      }
    }
  });
}

main();
```

### 11.4 熱重載

編輯 `extension.mjs` 後，在 CLI 中執行 `/clear` 即可重新載入，不需重啟[^30]。

### 11.5 關鍵特性

- **自訂工具**：任何函式都可以註冊為 CLI 可呼叫的工具
- **生命週期鉤子**：攔截與自訂代理動作
- **安全治理**：可阻擋特定操作或實作自訂審批流程
- **隔離執行**：每個 Extension 在獨立子程序中執行，保護會話穩定性

---

## 十二、LSP Server 設定

### 12.1 概述

Copilot CLI 支援 **Language Server Protocol（LSP）**，提供 go-to-definition、hover 資訊、診斷等智慧程式碼功能[^31]。

### 12.2 安裝語言伺服器

Copilot CLI **不內建**語言伺服器，需要自行安裝。例如：

```bash
# TypeScript
npm install -g typescript-language-server

# Python
pip install python-lsp-server

# C#
dotnet tool install -g csharp-ls
```

### 12.3 設定檔

| 層級 | 位置 | 說明 |
|------|------|------|
| 使用者級 | `~/.copilot/lsp-config.json` | 適用所有專案 |
| 倉庫級 | `.github/lsp.json` | 適用特定專案 |

**範例設定：**

```json
{
  "lspServers": {
    "typescript": {
      "command": "typescript-language-server",
      "args": ["--stdio"],
      "fileExtensions": {
        ".ts": "typescript",
        ".tsx": "typescript"
      }
    },
    "csharp": {
      "command": "csharp-ls",
      "args": [],
      "fileExtensions": {
        ".cs": "csharp"
      }
    }
  }
}
```

### 12.4 查看狀態

```bash
/lsp
```

---

## 十三、安全性與權限管理

### 13.1 信任目錄機制

啟動 Copilot CLI 時，你需要確認是否信任當前目錄的檔案[^32]。建議：

- ✅ 在你的專案目錄中啟動
- ❌ **不要**在 Home 目錄啟動
- ❌ **不要**在包含不信任執行檔的目錄啟動

### 13.2 工具審批命令列選項

三個命令列選項控制工具自動批准[^33]：

```bash
# 允許所有工具（慎用！）
copilot --allow-all-tools

# 允許特定工具
copilot --allow-tool='shell(git)'
copilot --allow-tool='shell(npm)'
copilot --allow-tool='write'                    # 允許檔案寫入
copilot --allow-tool='My-MCP-Server'            # 允許某 MCP Server 的所有工具
copilot --allow-tool='My-MCP-Server(tool_name)' # 允許某 MCP Server 的特定工具

# 拒絕特定工具（優先於 allow）
copilot --deny-tool='shell(rm)'
copilot --deny-tool='shell(git push)'

# 組合使用：允許全部但拒絕危險操作
copilot --allow-all-tools --deny-tool='shell(rm)' --deny-tool='shell(git push)'
```

### 13.3 安全最佳實踐

1. **確保 `.gitignore` 完善** — 避免 `git add -A` 意外加入 `.env`、金鑰等
2. **使用最小權限** — 只 allow 需要的工具，避免 `--allow-all-tools`
3. **在受限環境中執行** — 對於無人值守場景，使用 VM、容器、或權限受限的系統
4. **審查 MCP Server 來源** — 僅使用信任的 MCP Server
5. **定期更新** — `/update` 保持 CLI 在最新版本

---

## 十四、會話管理與進階技巧

### 14.1 會話恢復

```bash
# 從清單選擇會話恢復
/resume

# 命令列選項
copilot --resume

# 快速恢復最近的會話
copilot --continue
```

> 💡 你可以在 GitHub 上發起 Copilot coding agent 會話，然後用 CLI 的 `/resume` 將它拉回本地繼續[^34]。

### 14.2 上下文管理

Copilot CLI 提供自動與手動的上下文管理[^35]：

| 功能 | 說明 |
|------|------|
| **自動壓縮** | 接近 95% Token 上限時，自動在背景壓縮歷史 |
| **手動壓縮** | `/compact` — 立即壓縮對話歷史 |
| **Token 用量** | `/context` — 視覺化的 Token 使用分佈 |
| **會話統計** | `/usage` — Premium Request 數、時長、編輯行數、各模型 Token 用量 |

### 14.3 推理過程顯示

按 `Ctrl+T` 切換模型推理過程的顯示/隱藏，此設定跨會話持久化[^36]。

### 14.4 分享會話

```bash
# 分享為 Markdown 檔案或 GitHub Gist
/share
```

### 14.5 CLI 與 IDE 互通

```bash
# 連接到 IDE 工作區
/ide

# 在 CLI 建立計畫，然後在 VS Code 中精修
/plan
```

### 14.6 艦隊模式（Fleet Mode）

使用 `/fleet` 在多個子代理之間平行執行任務[^37]：

```bash
# 啟用艦隊模式
/fleet

# 可以同時使用多個模型並比較結果
/fleet Implement authentication using JWT
```

### 14.7 委派到 GitHub

```bash
# 將會話委派給 GitHub，Copilot 會建立 PR
/delegate
```

### 14.8 ACP Server

**Agent Client Protocol（ACP）** 是一個開放標準，允許你在任何支援此協定的第三方工具、IDE 或自動化系統中使用 Copilot CLI 作為代理[^38]。

---

## 十五、程式化（Non-interactive）使用

### 15.1 單次任務

```bash
copilot -p "Show me this week's commits and summarize them" --allow-tool='shell(git)'
```

### 15.2 無人值守模式

```bash
# 允許所有工具，完全自動執行
copilot -p "Fix all TypeScript errors in src/" --allow-all-tools

# 允許全部但排除危險操作
copilot -p "Refactor the auth module" --allow-all-tools --deny-tool='shell(rm)'
```

### 15.3 管線輸入

```bash
# 從腳本輸出管線到 Copilot
./generate-options.sh | copilot
```

### 15.4 CI/CD 整合場景

```bash
# 在 CI 環境中使用 PAT 認證
export GH_TOKEN="${{ secrets.COPILOT_TOKEN }}"
copilot -p "Review the changes in this PR and comment any issues" --allow-all-tools
```

---

## 十六、常用環境變數

| 環境變數 | 說明 | 範例 |
|---------|------|------|
| `GH_TOKEN` | GitHub 認證 Token（最高優先） | `ghp_xxxx` |
| `GITHUB_TOKEN` | GitHub 認證 Token（次優先） | `ghp_xxxx` |
| `COPILOT_HOME` | Copilot 設定目錄（預設 `~/.copilot`） | `$HOME/.my-copilot` |
| `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` | 額外的指示搜尋目錄（逗號分隔） | `/path/a,/path/b` |

> 💡 使用 `copilot help environment` 查看完整的環境變數列表[^39]。

其他有用的 `copilot help` 子命令：

```bash
copilot help config        # 配置設定說明
copilot help environment   # 環境變數說明
copilot help logging       # 日誌等級說明
copilot help permissions   # 權限管理說明
```

---

## 十七、配置檔案總整理

| 檔案 | 位置 | 用途 |
|------|------|------|
| `config.json` | `~/.copilot/config.json` | CLI 全域設定（模型、實驗功能等） |
| `mcp-config.json` | `~/.copilot/mcp-config.json` | MCP Server 設定 |
| `lsp-config.json` | `~/.copilot/lsp-config.json` | LSP Server 設定（使用者級） |
| `copilot-instructions.md` | `~/.copilot/copilot-instructions.md` | 個人全域指示 |
| `agents/*.md` | `~/.copilot/agents/` | 個人自訂代理 |
| `skills/*/SKILL.md` | `~/.copilot/skills/` | 個人 Skills |
| `extensions/*/extension.mjs` | `~/.copilot/extensions/` | 個人 Extensions |
| `copilot-instructions.md` | `.github/copilot-instructions.md` | 倉庫全域指示 |
| `*.instructions.md` | `.github/instructions/` | 倉庫路徑專屬指示 |
| `*.agent.md` | `.github/agents/` | 倉庫自訂代理 |
| `*/SKILL.md` | `.github/skills/` | 倉庫 Skills |
| `*/extension.mjs` | `.github/extensions/` | 倉庫 Extensions |
| `*.json` | `.github/hooks/` | Hooks 設定 |
| `lsp.json` | `.github/lsp.json` | LSP Server 設定（倉庫級） |
| `AGENTS.md` | 倉庫根目錄 | 代理指示 |
| `CLAUDE.md` | 倉庫根目錄 | Anthropic 模型指示 |
| `GEMINI.md` | 倉庫根目錄 | Google 模型指示 |

---

## 附錄 A：快捷鍵一覽表

### 全域快捷鍵

| 快捷鍵 | 功能 |
|--------|------|
| `@` | 提及檔案，將內容加入上下文 |
| `Ctrl+S` | 執行命令並保留輸入 |
| `Shift+Tab` | 循環切換模式（Interactive → Plan → Autopilot） |
| `Ctrl+T` | 切換模型推理過程顯示 |
| `Ctrl+O` | 展開最近的時間軸（無輸入時） |
| `Ctrl+E` | 展開所有時間軸（無輸入時） |
| `↑` `↓` | 瀏覽命令歷史 |
| `Ctrl+C` | 取消 / 清除輸入 / 複製選取 |
| `Ctrl+C` ×2 | 退出 CLI |
| `!` | 直接執行 Shell 命令（繞過 Copilot） |
| `Esc` | 取消當前操作 |
| `Ctrl+D` | 關閉 CLI |
| `Ctrl+L` | 清除畫面 |
| `Ctrl+X` → `O` | 從最近的時間軸事件開啟連結 |

### 編輯快捷鍵

| 快捷鍵 | 功能 |
|--------|------|
| `Ctrl+A` | 移到行首 |
| `Ctrl+E` | 移到行尾 |
| `Ctrl+H` | 刪除前一個字元 |
| `Ctrl+W` | 刪除前一個單字 |
| `Ctrl+U` | 刪除到行首 |
| `Ctrl+K` | 刪除到行尾 |
| `Meta+←` `→` | 以單字為單位移動游標 |
| `Ctrl+G` | 在外部編輯器中編輯提示 |

---

## 附錄 B：常見問題 FAQ

**Q：Copilot CLI 與舊版 `gh copilot` 有什麼不同？**

A：`gh copilot` 是 GitHub CLI 的擴充，僅提供命令建議與解釋功能。Copilot CLI 是獨立的代理工具，具備完整的代碼編輯、多代理協作、MCP 整合等能力[^1]。

**Q：每次提示都會消耗 Premium Request 嗎？**

A：是的，每次在互動式或程式化介面中提交提示，都會減少你的月度配額，數量依模型乘數而定[^17]。

**Q：可以離線使用嗎？**

A：不行。Copilot CLI 需要網路連線來存取 AI 模型服務。

**Q：如何查看當前使用了多少 Premium Request？**

A：使用 `/usage` 命令查看詳細的會話統計。

**Q：信任目錄設定存在哪裡？可以手動修改嗎？**

A：存在 `~/.copilot/config.json` 中，可以手動編輯或使用 `copilot help config` 了解詳情。

---

## Footnotes

[^1]: [GitHub Copilot CLI README](https://github.com/github/copilot-cli#readme)：「GitHub Copilot CLI brings AI-powered coding assistance directly to your command line...Powered by the same agentic harness as GitHub's Copilot coding agent.」

[^2]: [GitHub Blog — Power agentic workflows in your terminal](https://github.blog/ai-and-ml/github-copilot/power-agentic-workflows-in-your-terminal-with-github-copilot-cli/)

[^3]: [GitHub Docs — About Copilot CLI](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli#supported-operating-systems)：「Linux, macOS, Windows from within PowerShell and WSL.」

[^4]: [GitHub Features — Copilot CLI](https://github.com/features/copilot/cli)：「Included in Copilot Free, Pro, Pro+, Business, and Enterprise subscriptions.」

[^5]: [GitHub Docs — About Copilot CLI](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli)：「If you have access via your organization...you cannot use Copilot CLI if your administrator has disabled it.」

[^6]: [GitHub Copilot CLI README — Installation](https://github.com/github/copilot-cli#installation)

[^7]: [GitHub Copilot CLI README — Authenticate with PAT](https://github.com/github/copilot-cli#authenticate-with-a-personal-access-token-pat)

[^8]: [GitHub Docs — About Copilot CLI, Modes of use](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli#modes-of-use)

[^9]: [GitHub Docs — Using Copilot CLI, Use plan mode](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli#use-plan-mode)

[^10]: [GitHub Copilot CLI README — Experimental Mode](https://github.com/github/copilot-cli#experimental-mode)：「Autopilot is a new mode (press Shift+Tab to cycle through modes).」

[^11]: [GitHub Docs — Using Copilot CLI, Include a specific file](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli#include-a-specific-file-in-your-prompt)

[^12]: [GitHub Docs — Using Copilot CLI, Run shell commands](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli#run-shell-commands)

[^13]: [GitHub Docs — About Copilot CLI, Allowed tools](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli#allowed-tools)

[^14]: [GitHub Docs — About Copilot CLI, Steering the conversation](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli#steering-the-conversation)

[^15]: [GitHub Copilot CLI — Help command output](https://github.com/github/copilot-cli#readme)：完整的 `/help` 輸出。

[^16]: [GitHub Features — Copilot CLI](https://github.com/features/copilot/cli)：「Copilot CLI supports models from multiple foundation model providers, such as Anthropic, Google, and OpenAI.」

[^17]: [GitHub Docs — About Copilot CLI, Model usage](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli#model-usage)

[^18]: [GitHub Docs — Adding custom instructions for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/add-custom-instructions)

[^19]: [GitHub Docs — About Copilot CLI, Customizing](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli#customizing-github-copilot-cli)：「All custom instruction files now combine instead of using priority-based fallbacks.」

[^20]: [GitHub Docs — Adding custom instructions, Path-specific](https://docs.github.com/en/copilot/how-tos/copilot-cli/add-custom-instructions#creating-path-specific-custom-instructions)

[^21]: [GitHub Docs — Adding custom instructions, Agent instructions](https://docs.github.com/en/copilot/how-tos/copilot-cli/add-custom-instructions#agent-instructions)

[^22]: [GitHub Docs — Adding custom instructions, Local instructions](https://docs.github.com/en/copilot/how-tos/copilot-cli/add-custom-instructions#local-instructions)

[^23]: [GitHub Docs — Using Copilot CLI, Use custom agents](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli#use-custom-agents)

[^24]: [GitHub Docs — Using Copilot CLI, Custom agent locations](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli#use-custom-agents)：表格列出 User-level / Repository-level / Organization-level 三種位置。

[^25]: [GitHub Docs — Creating agent skills for Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/create-skills)

[^26]: [GitHub Docs — Using Copilot CLI, Add an MCP server](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli#add-an-mcp-server)

[^27]: [GitHub Copilot CLI README](https://github.com/github/copilot-cli#readme)：「MCP-powered extensibility: the coding agent ships with GitHub's MCP server by default.」

[^28]: [GitHub Docs — Using Copilot CLI, MCP config](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli#add-an-mcp-server)：「Details are stored in mcp-config.json in the ~/.copilot directory.」

[^29]: [GitHub Docs — About hooks](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-hooks)

[^30]: [GitHub Copilot CLI Extensions Guide](https://htek.dev/articles/github-copilot-cli-extensions-complete-guide/)：Extensions 系統與熱重載說明。

[^31]: [GitHub Copilot CLI README — Configuring LSP Servers](https://github.com/github/copilot-cli#-configuring-lsp-servers)

[^32]: [GitHub Docs — About Copilot CLI, Trusted directories](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli#trusted-directories)

[^33]: [GitHub Docs — About Copilot CLI, Allowing tools](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli#allowing-tools-to-be-used-without-manual-approval)

[^34]: [GitHub Docs — Using Copilot CLI, Resume an interactive session](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli#resume-an-interactive-session)

[^35]: [GitHub Docs — About Copilot CLI, Automatic context management](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli#automatic-context-management)

[^36]: [GitHub Docs — Using Copilot CLI, Toggle reasoning visibility](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli#toggle-reasoning-visibility)

[^37]: [GitHub Features — Copilot CLI](https://github.com/features/copilot/cli)：「Use /model to switch, then /fleet to execute in parallel or run multiple models at once.」

[^38]: [GitHub Docs — About Copilot CLI, ACP](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli#use-copilot-cli-via-acp)

[^39]: [GitHub Docs — Using Copilot CLI, Find out more](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/use-copilot-cli#find-out-more)
