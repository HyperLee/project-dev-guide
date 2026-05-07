# Spec Kit 深度研究報告

> **研究主題**：[github/spec-kit](https://github.com/github/spec-kit) — 規格驅動開發 (Spec-Driven Development, SDD) 工具套件
> **重點**：套件本質、架構演進、Release 發佈方式變更（從「每個 AI 工具一個壓縮檔」轉為「單一封裝包」）、新版安裝與使用方式
> **撰寫日期**：2026-04-18
> **研究對象版本**：`v0.7.3`（最新 release）；對照基準：`v0.0.x` ~ `v0.4.4`（舊架構）

---

## 一、Executive Summary（執行摘要）

1. **Spec Kit 是什麼**：GitHub 官方推出的開源 SDD 工具套件，核心 CLI 名稱為 **`specify-cli`**（命令為 `specify`）。它讓 AI Coding Agent（Copilot、Claude Code、Gemini CLI、Codex、Cursor … 共 28+ 種[^9]）以 `/speckit.constitution` → `/speckit.specify` → `/speckit.plan` → `/speckit.tasks` → `/speckit.implement` 的結構化工作流，把「規格」當成可執行成品來驅動開發[^1][^4]。
2. **Release 模式的重大轉變**：在 **v0.4.4–v0.4.5（2026-04-01/02）** 之間，Spec Kit 完成了 6 階段的「Integration Plugin 架構遷移」(#1924, #1925, #2035, #2038, #2050, #2052, #2063)，**移除了舊的「scaffold 路徑」**[^7]。此後 Release 不再為每個 AI 工具產出一個 zip 壓縮檔（過去是 `spec-kit-template-{agent}-{sh|ps}-vX.Y.Z.zip`，數十個檔案），而是只發佈 **單一 Python wheel**：`specify_cli-X.Y.Z-py3-none-any.whl`，所有 templates / scripts / 各 agent integration 全部以 `force-include` 方式打包在 wheel 內[^2][^6]。
3. **新版安裝方式**：使用 [uv](https://docs.astral.sh/uv/) 一行直接從 GitHub 安裝；**不再從 Release Assets 下載 zip**：
   ```bash
   uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@v0.7.3
   specify init my-project --ai copilot   # 或 --integration copilot（v0.7.1+ 推薦）
   ```
   `specify init` 直接從 wheel 內 `core_pack/` 解出對應 agent 的檔案到專案 `.specify/`、`.github/prompts/`、`.claude/commands/` 等資料夾[^3][^6]。
4. **舊版下載 zip 的方式已被棄用**：`--offline` flag 在 **v0.6.0** 起成為預設行為並被宣告為棄用；GitHub download path 將被退役[^3]。
5. **配套機制**：v0.7.0+ 新增「Integration Catalog」(#2130) 讓 agent integration 像 npm 套件那樣可被 discover / version / 安裝[^5][^7]。

---

## 二、什麼是 Spec Kit / Spec-Driven Development

> "Spec-Driven Development **flips the script** on traditional software development… **specifications become executable**, directly generating working implementations rather than just guiding them."[^1]

### 核心 Slash Commands（Core）

| 指令 | Skill 名稱 | 功能 |
|------|-----------|------|
| `/speckit.constitution` | `speckit-constitution` | 建立或更新專案治理原則與開發準則 |
| `/speckit.specify` | `speckit-specify` | 定義要建構什麼（需求 / user story） |
| `/speckit.plan` | `speckit-plan` | 產出技術實作計畫（含 tech stack） |
| `/speckit.tasks` | `speckit-tasks` | 把計畫拆成可執行 task 清單 |
| `/speckit.taskstoissues` | `speckit-taskstoissues` | 把 task 轉為 GitHub Issues |
| `/speckit.implement` | `speckit-implement` | 依計畫執行所有 task |

### 選用 Slash Commands

| 指令 | 功能 |
|------|------|
| `/speckit.clarify` | 在 `/speckit.plan` 前釐清未明確之處（取代舊 `/quizme`） |
| `/speckit.analyze` | 跨 artifact 一致性與 coverage 分析 |
| `/speckit.checklist` | 產生需求完整度／清晰度／一致性的客製檢查清單 |

> 註：Codex CLI 在 skills mode 下使用 `$speckit-*` 而非 `/speckit.*`[^4]。

### 治理工具（v0.7.x 引入）

- **Extensions** — 新增能力（`specify extension search/add`），例如 Jira 整合、安全審查、QA 工作流。共 60+ 個社群 extension 列在 `extensions/catalog.community.json`[^4]。
- **Presets** — 客製既有工作流（不新增能力，例如把 spec template 改為合規導向、改用海盜語腔調 demo）。
- **Project-local Overrides** — 放在 `.specify/templates/overrides/`，最高優先權。
- **Workflows**（v0.7.0 #2158）— 工作流引擎與 catalog 系統。
- **Integrations**（v0.7.2 #2130）— Agent integration 的 catalog 化、版本化與社群分發機制[^5]。

解析優先序（高→低）：Project-local Overrides → Presets → Extensions → Spec Kit Core[^4]。

---

## 三、Release 發佈方式的演進（重點：壓縮檔 → 單一封裝）

### 3.1 舊模式（v0.0.x ~ v0.4.4）— 每個 AI 工具一個 zip

CHANGELOG 中可見的明確證據：

- `v0.0.80`（2025-11-14）：commit `Create create-release-packages.ps1`[^7] — 即「為每個 agent 打包 release zip」的 script。
- `v0.0.82`（2025-11-14）：`fix: incorrect logic to create release packages with subset AGENTS or SCRIPTS`[^7] — 證明當時是按 「AGENTS × SCRIPTS（sh/ps）」矩陣產出多個 zip。
- 內部還有 `.github/workflows/RELEASE-PROCESS.md` 的描述：「Build release package variants (**all agents × shell/powershell**)」[^8]（此段為舊文件，當前 release.yml 已不再執行該步驟）。

當時的安裝流程（舊 README/docs）：
1. 進入 GitHub Releases 頁面
2. 找到對應 AI 工具與作業系統的 zip：
   - `spec-kit-template-copilot-sh-v0.x.y.zip`（macOS/Linux + Copilot）
   - `spec-kit-template-claude-ps-v0.x.y.zip`（Windows + Claude）
   - 以此類推，~30 agents × 2 script types ≈ **60+ zip 檔/版**
3. 由 `specify init` 從 GitHub Release Assets 下載 zip → 解壓到專案。

### 3.2 中間轉換（v0.4.0 → v0.4.5，2026-03-23 ~ 2026-04-02）

這段時間是核心架構大手術，按 PR 順序：

| 版本 | PR | 重點 |
|------|----|------|
| v0.0.93 | #1551 | 加入 modular extension system（後續 plugin 架構的基礎） |
| **v0.4.0** | **#1803** | **`feat(cli): embed core pack in wheel for offline/air-gapped deployment`** — 把 core pack 直接打包進 wheel |
| v0.4.4 | #1925 | **Stage 1**: Integration foundation — base classes、manifest 系統、registry |
| v0.4.4 | #2035 | **Stage 2**: Copilot integration — proof of concept |
| v0.4.5 | #2038 | **Stage 3**: Standard markdown integrations — **19 個 agents 遷移到 plugin 架構** |
| v0.4.5 | #2050 | **Stage 4**: TOML integrations — gemini、tabnine 遷移 |
| v0.4.5 | #2051 | Install Claude Code as native skills，align preset/integration flows |
| v0.4.5 | #2052 | **Stage 5**: Skills、Generic、Option-Driven Integrations |
| **v0.4.5** | **#2063** | **Stage 6: Complete migration — *remove legacy scaffold path*** |
| v0.5.1 | #2083 | 新增 `specify integration` 子命令（post-init 整合管理） |
| v0.6.0 | — | 在 docs 公告 `--offline` 將被移除、bundled assets 成為預設行為[^3] |
| v0.7.0 | #2158 | Workflow engine + catalog system |
| v0.7.1 | #2218 | `--ai` flag 棄用，改推 `--integration` |
| v0.7.2 | #2130 | Integration Catalog — discovery、versioning、community distribution |
| v0.7.3 | #2259 | shell-based context updates → marker-based upsert（修穩定性 bug） |

> 引用來源：CHANGELOG.md 0.0.80–0.7.3 各章節[^7]。

### 3.3 現在的 Release 模式（v0.4.5+）— 單一 wheel

當前 `.github/workflows/release.yml` 流程僅有 5 個步驟：checkout → 取版本 → 檢查 release 是否已存在 → **生成 release notes** → **建立 GitHub Release**[^10]。**完全沒有再為各 agent 打包 zip 的步驟**。

關鍵證據在 `pyproject.toml` 的 `[tool.hatch.build.targets.wheel.force-include]`[^6]：

```toml
[tool.hatch.build.targets.wheel.force-include]
# Bundle core assets so `specify init` works without network access (air-gapped / enterprise)
"templates/checklist-template.md"     = "specify_cli/core_pack/templates/checklist-template.md"
"templates/constitution-template.md"  = "specify_cli/core_pack/templates/constitution-template.md"
"templates/plan-template.md"          = "specify_cli/core_pack/templates/plan-template.md"
"templates/spec-template.md"          = "specify_cli/core_pack/templates/spec-template.md"
"templates/tasks-template.md"         = "specify_cli/core_pack/templates/tasks-template.md"
"templates/vscode-settings.json"      = "specify_cli/core_pack/templates/vscode-settings.json"
"templates/commands"                  = "specify_cli/core_pack/commands"
"scripts/bash"                        = "specify_cli/core_pack/scripts/bash"
"scripts/powershell"                  = "specify_cli/core_pack/scripts/powershell"
"extensions/git"                      = "specify_cli/core_pack/extensions/git"
"workflows/speckit"                   = "specify_cli/core_pack/workflows/speckit"
"presets/lean"                        = "specify_cli/core_pack/presets/lean"
```

也就是說，**所有以前要分別下載的 templates、commands、bash/powershell scripts、bundled extensions、workflows、presets 全部「force-include」進同一個 wheel**。Agent integration 的差異則由 `src/specify_cli/integrations/` 內各 agent 的 plugin（base class + manifest）在 `specify init` 執行時動態組裝[^11]。

### 3.4 新舊模式對照表

| 維度 | 舊模式（≤ v0.4.4） | 新模式（v0.4.5+） |
|------|---|---|
| Release artifacts 數量 | ~60 個 zip（agents × script types） | **1 個 wheel** + 自動產生的 release notes |
| Artifact 命名 | `spec-kit-template-{agent}-{sh\|ps}-vX.Y.Z.zip` | `specify_cli-X.Y.Z-py3-none-any.whl` |
| 安裝來源 | GitHub Releases Assets 下載 zip | `git+https://github.com/github/spec-kit.git@vX.Y.Z`（透過 uv / pip） |
| Agent 適配 | 不同 agent → 下載不同 zip | 同一 wheel，`--ai`/`--integration` 動態解出對應檔案 |
| Script 類型 | bash 或 powershell 二選一發行 | 兩者皆內建，初始化時由 OS 自動判斷或 `--script sh\|ps` 指定 |
| 離線 / Air-gapped | 需要手動下載 zip 帶入 | `pip download` wheel + deps 後 `pip install --no-index`，**不需要再下載 templates** |
| 加入新 agent | 需要在 release workflow 加新 zip 矩陣項 | 在 `src/specify_cli/integrations/` 加 plugin + 在 `integrations/catalog.json` 註冊 |
| 版本同步 | wheel 與 zip 可能不一致 | wheel 內含一切 → templates 永遠等於 CLI 版本 |
| 升級複雜度 | 高（要重抓 zip 解壓、合併） | 低（`uv tool install --force` 加 `specify init --here --force`） |

### 3.5 為何要改？官方理由（摘自 docs）

> "bundled assets eliminate the need for network access, avoid proxy/firewall issues, and **guarantee that templates always match the installed CLI version**. No action will be needed — `specify init` will simply work without network access out of the box."[^3]

簡單講三大好處：① 版本一致性 ② 企業 / 防火牆環境免設定 ③ 安裝步驟單純化。

---

## 四、新版安裝與使用完整指南（v0.7.x 為基準）

### 4.1 系統需求

- **作業系統**：Linux / macOS / Windows（Windows 不再需要 WSL，PowerShell 7+ 即可）
- **Python**：3.11+（pyproject `requires-python = ">=3.11"`[^6]）
- **uv**：[Astral uv](https://docs.astral.sh/uv/) — 套件管理器（強烈建議）
- **Git**
- **目標 AI Agent**：Copilot / Claude Code / Codex / Gemini / Cursor / Codebuddy / Pi … 共 28+[^9]

### 4.2 安裝方式（三選一）

#### Option 1 — Persistent install（**官方推薦**）

```bash
# 釘選穩定版（vX.Y.Z 替換為最新 tag，如 v0.7.3）
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@v0.7.3

# 或安裝最新 main 分支（含未發佈變更）
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

specify version          # 驗證版本
specify check            # 驗證所需工具是否到位
```

#### Option 2 — One-time `uvx`

```bash
uvx --from git+https://github.com/github/spec-kit.git@v0.7.3 specify init my-project
uvx --from git+https://github.com/github/spec-kit.git@v0.7.3 specify init . --ai copilot
uvx --from git+https://github.com/github/spec-kit.git@v0.7.3 specify init --here --ai copilot
```

#### Option 3 — Enterprise / Air-Gapped[^3]

```bash
# Step 1 — 在有網路的機器上 build wheel + 下載依賴
git clone https://github.com/github/spec-kit.git && cd spec-kit
pip install build && python -m build --wheel --outdir dist/
pip download -d dist/ dist/specify_cli-*.whl

# Step 2 — 把整個 dist/ 目錄複製到 air-gapped 機器

# Step 3 — 離線安裝
pip install --no-index --find-links=./dist specify-cli

# Step 4 — 初始化（不需網路；v0.6+ 起 --offline 為預設行為，將被棄用）
specify init my-project --ai claude --offline
```

> ⚠️ `pip download` 會解析平台相關 wheel（如 PyYAML 含原生擴充），請在與目標機器**相同 OS 與 Python 版本**的環境執行，否則需多次重複 Step 1。

### 4.3 升級 CLI 與既有專案

| 目標 | 命令 |
|------|------|
| 只升級 CLI | `uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git@v0.7.3` |
| 只更新專案內 spec-kit 檔案 | `specify init --here --force --ai copilot` |
| 兩者都升級 | 先做 CLI 升級，再做專案更新 |

⚠️ **已知問題**：`specify init --here --force` 會覆蓋 `.specify/memory/constitution.md`。升級前務必先 `cp` 備份，或升級後 `git restore .specify/memory/constitution.md`[^3]。

`specs/`（你的 spec、plan、tasks）絕對安全，從不會被升級流程觸碰[^3]。

### 4.4 標準 SDD 工作流（六步）

```bash
# 0) 安裝 CLI、初始化專案
specify init my-photo-app --ai copilot

# 進入專案目錄並啟動 AI agent，依序執行：
# 1) 治理原則
/speckit.constitution Create principles focused on code quality, testing standards, UX consistency, and performance

# 2) 寫規格（What & Why；不寫技術細節）
/speckit.specify Build a photo album organizer that groups by date, drag-and-drop reorganize, no nested albums, tile preview

# 3) 寫實作計畫（技術選型）
/speckit.plan Use Vite + vanilla HTML/CSS/JS, store metadata in local SQLite, images stay local

# 4)（建議）澄清不明處
/speckit.clarify

# 5) 拆 task
/speckit.tasks

# 6)（建議）跨 artifact 一致性檢查
/speckit.analyze

# 7) 執行
/speckit.implement
```

### 4.5 常用 CLI 子命令

```bash
specify init <project> [--ai|--integration <agent>] [--script sh|ps] [--here] [--force] [--no-git] [--offline]
specify version
specify check                       # 驗證需要的 CLI 工具
specify status                      # 顯示當前 SDD 進度（v0.3.1+）
specify doctor                      # 專案健康度診斷（v0.3.0+）
specify integration list [--catalog]
specify integration install <id>
specify integration upgrade [--force]   # diff-aware 升級
specify extension search|add|list
specify preset search|add
```

> v0.7.1 起，**`--ai` 標記被宣告棄用**，建議改用 **`--integration`**[^7]。

### 4.6 Integration（Agent）的新運作方式

`integrations/catalog.json` 列出 28 個官方 integration（`claude`、`copilot`、`gemini`、`cursor-agent`、`codex`、`windsurf`、`amp`、`qwen`、`opencode`、`forge`、`kiro-cli`、`junie`、`auggie`、`shai`、`tabnine`、`kilocode`、`roo`、`bob`、`trae`、`codebuddy`、`qodercli`、`kimi`、`pi`、`iflow`、`vibe`、`agy`、`generic`、`goose`），每個含 id / name / version / repository / tags[^11]。

每個 integration 可帶 `integration.yml` 描述符：

```yaml
schema_version: "1.0"
integration:
  id: "my-agent"
  name: "My Agent"
  version: "1.0.0"
requires:
  speckit_version: ">=0.6.0"
  tools:
    - name: "my-agent"
      required: true
provides:
  commands:
    - name: "speckit.specify"
      file: "templates/speckit.specify.md"
  scripts:
    - update-context.sh
    - update-context.ps1
```

Catalog 解析順序（first-match-wins）[^11]：
1. 環境變數 `SPECKIT_INTEGRATION_CATALOG_URL`
2. 專案 config `.specify/integration-catalogs.yml`
3. 使用者 config `~/.specify/integration-catalogs.yml`
4. 內建預設 `catalog.json` + `catalog.community.json`

---

## 五、CLI 與專案結構

### 5.1 Wheel 安裝後的內部結構（自 `pyproject.toml` 推得[^6]）

```
specify_cli/
├── __init__.py            # CLI 入口（typer app；~217KB）
├── agents.py              # Agent 行為共用邏輯
├── extensions.py          # Extension 系統（~101KB）
├── presets.py             # Preset 系統（~70KB）
├── integrations/          # 各 agent plugin 集中地（v0.4.4 Stage 1 引入）
├── workflows/             # Workflow 引擎（v0.7.0）
└── core_pack/             # 透過 force-include 內嵌的核心資產
    ├── templates/         # spec / plan / tasks / constitution / checklist
    ├── commands/          # /speckit.* slash command 定義
    ├── scripts/
    │   ├── bash/
    │   └── powershell/
    ├── extensions/git/    # 內建 git extension
    ├── workflows/speckit/ # 內建 SDD workflow
    └── presets/lean/      # 內建精簡 preset
```

### 5.2 `specify init` 後的專案結構

```
my-project/
├── .specify/
│   ├── memory/constitution.md         # /speckit.constitution 產出
│   ├── templates/                     # 可被 overrides/ 覆寫
│   ├── scripts/                       # 同時包含 .sh 與 .ps1
│   ├── extensions/                    # specify extension add 的目的地
│   └── presets/
├── specs/                             # 你的 spec/plan/tasks（永不被升級覆蓋）
└── <agent 專屬目錄>/                  # 依 --ai/--integration 而異
    # GitHub Copilot:    .github/prompts/
    # Claude Code:       .claude/commands/   或 skills 目錄
    # Gemini:            .gemini/commands/
    # Cursor:            .cursor/skills/     （v0.6.1 從 commands 遷移過來）
    # Pi:                .pi/prompts/
    # Codex:             需要 CODEX_HOME 環境變數
```

---

## 六、Release 流程內部運作（給維護者參考）

`.github/workflows/RELEASE-PROCESS.md` 描述當前流程[^8]：

1. **Release Trigger Workflow**（`release-trigger.yml`，手動觸發）
   - 決定版號（自動 patch++ 或手動指定）
   - 更新 `pyproject.toml` 的 `version`
   - 從 git commits 自動產生 `CHANGELOG.md` 區塊
   - 建立 `chore/release-vX.Y.Z` 分支與同名 tag
   - 推 tag → 觸發 release workflow
   - 開 PR 把版號 bump merge 回 `main`

2. **Release Workflow**（`release.yml`，由 `v*` tag push 觸發）[^10]
   - Checkout
   - 由 tag 名稱解析版號
   - 檢查同名 release 是否已存在（避免重複）
   - 產生 release notes（包含 `## Install` 區段，提供 `uv tool install` 指令）
   - 用 `gh release create` 建立 GitHub Release
   - **不再為每個 agent 打包 zip**（這是與舊版本最大的差別）

> 註：`RELEASE-PROCESS.md` 仍保留「Build release package variants (all agents × shell/powershell)」一句，但對照 `release.yml` 實作可知此描述已過時，是文件未同步的歷史遺留。

CLI 套件本身則由 `hatchling` build 成 wheel，由 GitHub Action 在 release tag 推送後一併產出（亦可由本地 `python -m build` 重現）。

---

## 七、社群生態

- **Community Extensions**（60+）：Jira / Azure DevOps / Confluence 整合、安全審查、Brownfield Bootstrap、Bugfix Workflow、QA Testing、Reconcile、Spec Diagram、Project Health Check 等。完整目錄在 [`extensions/catalog.community.json`](https://github.com/github/spec-kit/blob/main/extensions/catalog.community.json)，並有獨立網站 <https://speckit-community.github.io/extensions/>[^4]。
- **Community Presets**：`pirate-speak demo`、`fiction-book-writing`、`vscode-ask-questions`、`toc-navigation`、`canon-core`、`multi-repo-branching`、`explicit-task-dependencies` 等。
- **Community Friends**：基於 Spec Kit 衍生的 IDE extension、視覺化工具等（如 Spec Kit Assistant VS Code extension、SpecKit Companion）。

---

## 八、實務建議（升級 / 採用）

| 場景 | 建議 |
|------|------|
| 你還在使用 0.4.4 之前的版本 | 直接升級到 0.7.3，不用再煩惱 zip 對應；`uv tool install --force …@v0.7.3` 即可 |
| 你還在從 GitHub Releases 下載 zip | 停掉這個流程，改用 `uvx --from git+...@vX.Y.Z specify init`；省掉 60 個 zip 對應的選擇障礙 |
| 你有客製過 templates 或 constitution | 升級前 `git commit` 或備份；升級後依需要 `git restore .specify/memory/constitution.md` |
| 你在企業 air-gapped 環境 | 走 Option 3 wheel + `pip download`；之後 `specify init` 完全不需要連網 |
| 你想加自家 AI agent | 走新的 integration plugin 架構：在 `src/specify_cli/integrations/` 加 plugin、在 `integrations/catalog.json` 註冊；不要再去動 release workflow |
| 你還在用 `--ai` flag | 0.7.1 起改用 `--integration`（`--ai` 已被宣告棄用） |
| 你想拆 monorepo 或 多 agent 並行 | 看 v0.7.0 的 Workflow Engine + Catalog 與 community 的 Worktrees / MAQA extension |

---

## 九、Confidence Assessment

| 主張 | 信心 | 證據 |
|---|---|---|
| Spec Kit 為 GitHub 官方 SDD 工具，CLI 名稱 `specify-cli` | **高** | README、pyproject.toml[^1][^6] |
| v0.4.5 完成 6 階段 plugin 架構遷移、移除 legacy scaffold path | **高** | CHANGELOG #1924/#1925/#2035/#2038/#2050/#2052/#2063[^7] |
| 當前 release.yml **不再產出多個 per-agent zip**，只建立 release + notes | **高** | 直接讀 `.github/workflows/release.yml`[^10] |
| 所有 templates / scripts / 部分 extensions / presets 均以 `force-include` 嵌入 wheel | **高** | pyproject.toml `[tool.hatch.build.targets.wheel.force-include]`[^6] |
| 舊模式為 `spec-kit-template-{agent}-{sh\|ps}-vX.Y.Z.zip` 命名格式 | **中-高** | 由 v0.0.80/v0.0.82 的 `create-release-packages.ps1` + `subset AGENTS or SCRIPTS` 線索[^7] 與當前 docs 描述推得；確切舊檔名請對照 [Spec Kit Releases 頁面](https://github.com/github/spec-kit/releases) 早期版本驗證 |
| `--offline` 將在 v0.6.0+ 棄用、bundled 變預設 | **高** | docs/installation.md 明文 deprecation notice[^3] |
| `--ai` flag 在 v0.7.1 棄用、改 `--integration` | **高** | CHANGELOG 0.7.1 #2218[^7] |
| Integration Catalog 在 v0.7.2 引入 | **高** | CHANGELOG 0.7.2 #2130[^7]、`integrations/README.md`[^11] |

> **不確定處**：CHANGELOG 標示日期為 2026 年（如 v0.7.3 為 `2026-04-17`）。本報告以倉庫自身標示的時間軸為準；如需與真實時序對照，請以 GitHub commit timestamp 為準。

---

## 十、關鍵檔案 / 倉庫一覽

| 用途 | 位置 |
|------|------|
| 主倉庫 | [github/spec-kit](https://github.com/github/spec-kit) |
| README（含安裝、Slash 指令） | [`README.md`](https://github.com/github/spec-kit/blob/main/README.md) |
| 完整 Changelog | [`CHANGELOG.md`](https://github.com/github/spec-kit/blob/main/CHANGELOG.md) |
| 安裝指南（含 air-gapped） | [`docs/installation.md`](https://github.com/github/spec-kit/blob/main/docs/installation.md) |
| 升級指南 | [`docs/upgrade.md`](https://github.com/github/spec-kit/blob/main/docs/upgrade.md) |
| pyproject（看 wheel 內嵌資產） | [`pyproject.toml`](https://github.com/github/spec-kit/blob/main/pyproject.toml) |
| 當前 release workflow | [`.github/workflows/release.yml`](https://github.com/github/spec-kit/blob/main/.github/workflows/release.yml) |
| Release process 說明 | [`.github/workflows/RELEASE-PROCESS.md`](https://github.com/github/spec-kit/blob/main/.github/workflows/RELEASE-PROCESS.md) |
| Integration catalog 與機制 | [`integrations/README.md`](https://github.com/github/spec-kit/blob/main/integrations/README.md)、[`integrations/catalog.json`](https://github.com/github/spec-kit/blob/main/integrations/catalog.json) |
| CLI 入口（Typer） | [`src/specify_cli/__init__.py`](https://github.com/github/spec-kit/blob/main/src/specify_cli/__init__.py) |
| Integration plugin 集中地 | [`src/specify_cli/integrations/`](https://github.com/github/spec-kit/tree/main/src/specify_cli/integrations) |
| Spec-Driven 方法論深入 | [`spec-driven.md`](https://github.com/github/spec-kit/blob/main/spec-driven.md) |
| 文件站 | <https://github.github.io/spec-kit/> |
| Releases 頁面 | <https://github.com/github/spec-kit/releases> |

---

## Footnotes

[^1]: [github/spec-kit](https://github.com/github/spec-kit) — `README.md`，"What is Spec-Driven Development?" 章節（行 43-45）。
[^2]: 當前 release artifact 僅為 `specify_cli-X.Y.Z-py3-none-any.whl`，由 `hatchling` 依 `pyproject.toml` 設定 build。
[^3]: `docs/installation.md` — Air-Gapped Installation 與 v0.6.0 起 `--offline` 棄用通告：「Starting with v0.6.0, `specify init` will use bundled assets by default and the `--offline` flag will be removed」。
[^4]: `README.md` — Slash Commands、Extensions、Presets、Catalog community 區段（行 316-405、169-264）。
[^5]: CHANGELOG `[0.7.0]` #2158（Workflow engine + catalog system）、`[0.7.2]` #2130（Integration catalog — discovery, versioning, community distribution）。
[^6]: `pyproject.toml` — `[tool.hatch.build.targets.wheel.force-include]` 區段，列舉所有被打包進 wheel 的 templates / scripts / extensions / workflows / presets；`requires-python = ">=3.11"`、`version = "0.7.4.dev0"`（main 開發中）。
[^7]: `CHANGELOG.md` — 各版本說明，重點包含 v0.0.80、v0.0.82（per-agent release packages script）、v0.4.0 #1803（embed core pack in wheel）、v0.4.4 #1925（Stage 1）/ #2035（Stage 2）、v0.4.5 #2038（Stage 3）/ #2050（Stage 4）/ #2052（Stage 5）/ #2063（Stage 6 — remove legacy scaffold path）、v0.7.1 #2218（deprecate `--ai` for `--integration`）。
[^8]: [`.github/workflows/RELEASE-PROCESS.md`](https://github.com/github/spec-kit/blob/main/.github/workflows/RELEASE-PROCESS.md) — Release 流程說明文件（部分描述「all agents × shell/powershell」屬未同步歷史遺留）。
[^9]: 「Spec Kit works with 30+ AI coding agents」— `README.md` 行 312；`integrations/catalog.json` 列出 28 個官方 integration[^11]。
[^10]: [`.github/workflows/release.yml`](https://github.com/github/spec-kit/blob/main/.github/workflows/release.yml) — 當前 release workflow，由 `v*` tag 觸發；步驟僅含 checkout / extract version / check existing release / generate notes / `gh release create`，**未含任何 zip 打包步驟**。
[^11]: [`integrations/README.md`](https://github.com/github/spec-kit/blob/main/integrations/README.md) 與 [`integrations/catalog.json`](https://github.com/github/spec-kit/blob/main/integrations/catalog.json) — Integration Catalog 機制、解析順序與 28 個官方 integration 清單。
