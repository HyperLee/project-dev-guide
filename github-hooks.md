# `.github/hooks/` 資料夾超完整詳細說明

## Executive Summary

`.github/hooks/` 是 GitHub Copilot 代理（Copilot CLI 與 Copilot coding agent）的 **Hooks 機制設定資料夾**，用於在代理工作階段的特定生命週期時刻（如啟動、結束、工具執行前後等）自動執行自訂的 Shell 腳本。Copilot agents 會自動從 `.github/hooks/*.json` 讀取所有 JSON 設定檔[^1]，然後根據其中定義的事件觸發對應腳本。

在本專案（`project-dev-guide`）中，`.github/hooks/` 內包含兩個檔案[^2]：
1. **`hooks.json`** — Hook 設定檔，定義在 `sessionEnd` 事件觸發時執行 `stop-hook.sh`
2. **`stop-hook.sh`** — Shell 腳本，在 Copilot 會話結束時自動將所有變更 commit 並 push 至遠端

---

## 一、`.github/hooks/` 資料夾的作用

### 1.1 定位與用途

`.github/hooks/` 是 **GitHub Copilot Hooks 系統**的標準存放位置[^3]。它與 Git hooks（`.git/hooks/`）完全不同，是專門為 Copilot 代理設計的擴展機制。

Hooks 讓你可以在 Copilot 代理執行流程中的**關鍵生命週期節點**插入自訂邏輯[^4]，包括：

| 事件名稱 | 觸發時機 | 輸出是否被處理 |
|---------|---------|-------------|
| `sessionStart` | 新會話開始或恢復既有會話 | 否（僅側效果） |
| `sessionEnd` | 會話結束或被終止 | 否 |
| `userPromptSubmitted` | 使用者提交 prompt | 否 |
| `preToolUse` | 工具執行前（如 bash、edit、view） | **是** — 可允許、拒絕或修改 |
| `postToolUse` | 工具執行完成後 | 否 |
| `agentStop` | 主代理完成一輪回應 | **是** — 可阻擋並強制繼續 |
| `subagentStop` | 子代理完成 | **是** — 可阻擋並強制繼續 |
| `errorOccurred` | 執行期間發生錯誤 | 否 |

### 1.2 載入機制

- **Copilot coding agent（GitHub 線上）**：hooks 設定檔必須存在於倉庫的**預設分支（default branch）**上才會被使用[^5]
- **Copilot CLI（本地終端機）**：hooks 從你**當前工作目錄**的 `.github/hooks/` 載入[^5]
- 系統會掃描 `.github/hooks/*.json`，所有符合的 JSON 檔案都會被載入
- 同一事件有多個 hook 時，依陣列順序依次執行[^6]

### 1.3 適用場景

根據官方文件與教程[^7][^8]，常見用途包括：

- **安全策略執行**：用 `preToolUse` 阻擋高風險命令（如 `sudo`、`rm -rf /`、`curl | bash`）
- **稽核日誌**：記錄使用者 prompt、工具呼叫、執行結果
- **環境初始化**：在 `sessionStart` 顯示政策橫幅、設定臨時資源
- **清理作業**：在 `sessionEnd` 清除臨時檔案、推送變更
- **通知系統**：在錯誤發生時發送 Slack 告警或 email
- **成本追蹤**：記錄工具使用量供計費分配

### 1.4 與 `.github/` 其他目錄的關係

```
.github/
├── agents/          ← 自訂代理定義檔（如 CSharpExpert.agent.md）
├── hooks/           ← ★ Hooks 設定與腳本（本報告主題）
│   ├── hooks.json
│   └── stop-hook.sh
├── instructions/    ← 路徑專屬指示（*.instructions.md）
├── prompts/         ← Prompt 模板
└── skills/          ← Agent 技能擴展
```

---

## 二、`hooks.json` 詳細說明

### 2.1 檔案完整內容

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
[^9]

### 2.2 結構分析

#### `version` 欄位

```json
"version": 1
```

- **必填欄位**，目前唯一有效值為 `1`[^10]
- 標識 hooks 設定檔的 schema 版本，確保 Copilot 能正確解析
- 若缺少此欄位，hooks 可能不會被載入[^11]

#### `hooks` 物件

```json
"hooks": {
    "sessionEnd": [...]
}
```

- 以事件名稱為 key，值為 hook 定義陣列
- 每個事件可以對應多個 hook（依序執行）

#### `"sessionEnd"` 事件

本專案使用 `sessionEnd` 作為 hook 觸發事件，代表在 Copilot 代理會話結束或被終止時執行。根據官方文件[^12]，`sessionEnd` 的輸入 JSON 包含：

- `timestamp`：Unix 時間戳（毫秒）
- `cwd`：當前工作目錄
- `reason`：結束原因，可能為 `"complete"`、`"error"`、`"abort"`、`"timeout"` 或 `"user_exit"`

此事件的輸出會被忽略（僅用於側效果，如日誌記錄或清理作業）。

#### Hook 定義物件

```json
{
    "type": "command",
    "bash": ".github/hooks/stop-hook.sh",
    "cwd": ".",
    "timeoutSec": 30
}
```

| 欄位 | 值 | 說明 |
|-----|---|-----|
| `type` | `"command"` | **必填**。目前唯一支援的類型（另有 `"prompt"` 僅用於 `sessionStart`）[^13] |
| `bash` | `".github/hooks/stop-hook.sh"` | Unix 系統要執行的腳本路徑 |
| `cwd` | `"."` | 腳本工作目錄（相對於 repo root） |
| `timeoutSec` | `30` | 最大執行秒數 |

### 2.3 目前設定與官方標準格式一致

目前的 `hooks.json` 已完全符合官方建議的標準格式，使用 `sessionEnd` 事件名稱、`bash` 欄位、並明確指定 `cwd` 與 `timeoutSec`。

### 2.4 可選的額外設定欄位

根據官方 Hook 設定參考[^14]，每個 hook 定義支援以下欄位：

| 欄位 | 類型 | 必填 | 說明 |
|------|------|-----|------|
| `type` | `"command"` | 是 | 必須為 `"command"` |
| `bash` | string | 是（Unix） | Unix 系統的 Shell 命令/腳本路徑 |
| `powershell` | string | 是（Windows） | Windows 的 PowerShell 命令/腳本路徑 |
| `cwd` | string | 否 | 腳本工作目錄（相對於 repo root 或絕對路徑） |
| `env` | object | 否 | 額外環境變數（支援 `$VAR` 展開） |
| `timeoutSec` | number | 否 | 最大執行秒數（預設 30 秒） |

---

## 三、`stop-hook.sh` 詳細說明

### 3.1 檔案完整內容

```bash
#!/bin/bash

# Stop Hook - Auto-commit and push changes on session exit
# Generates Conventional Commits style messages with file change details.

set -euo pipefail

# Infer Conventional Commits type from file extensions.
# Tallies each file into a category and returns the predominant type.
infer_commit_type() {
  local files="$1"
  local docs=0 config=0 code=0 tests=0 ci=0

  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    case "$f" in
      *.md|*.txt|*.rst|*.adoc)              ((docs++))   || true ;;
      .github/workflows/*|.github/actions/*) ((ci++))     || true ;;
      *.test.*|*.spec.*|*_test.*|*Test.*|*Tests.*|*_spec.*) ((tests++)) || true ;;
      *.json|*.yml|*.yaml|*.toml|*.xml|*.editorconfig|*.gitignore|*.sh|*.ps1|*.bash) ((config++)) || true ;;
      *)                                     ((code++))   || true ;;
    esac
  done <<< "$files"

  local max=$docs type="docs"
  [[ $config -gt $max ]] && max=$config && type="chore"
  [[ $code   -gt $max ]] && max=$code   && type="feat"
  [[ $tests  -gt $max ]] && max=$tests  && type="test"
  [[ $ci     -gt $max ]] && max=$ci     && type="ci"
  echo "$type"
}

# Build a Conventional Commits message from the staged changes.
generate_commit_message() {
  local name_status file_list
  name_status=$(git diff --cached --name-status)
  file_list=$(echo "$name_status" | awk '{print $NF}')

  local added modified deleted
  added=$(echo "$name_status"   | grep -c '^A' || true)
  modified=$(echo "$name_status" | grep -c '^M' || true)
  deleted=$(echo "$name_status"  | grep -c '^D' || true)

  # --- type ---
  local type
  type=$(infer_commit_type "$file_list")

  # --- summary line ---
  local parts=()
  [[ $modified -gt 0 ]] && parts+=("update ${modified} file(s)")
  [[ $added    -gt 0 ]] && parts+=("add ${added} file(s)")
  [[ $deleted  -gt 0 ]] && parts+=("remove ${deleted} file(s)")
  local summary
  summary=$(IFS=', '; echo "${parts[*]}")

  # --- body: file list (truncated at 15) + shortstat ---
  local file_count body shortstat
  file_count=$(echo "$name_status" | grep -c . || true)

  if [[ $file_count -le 15 ]]; then
    body="$name_status"
  else
    body=$(echo "$name_status" | head -15)
    body+=$'\n'"... and $((file_count - 15)) more file(s)"
  fi

  shortstat=$(git diff --cached --shortstat)

  printf '%s: %s\n\n%s\n\n%s' "$type" "$summary" "$body" "$shortstat"
}

if git rev-parse --is-inside-work-tree &>/dev/null; then
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "📦 Auto-committing and pushing changes..."
    git add -A

    COMMIT_MSG=$(generate_commit_message)

    git commit -m "$COMMIT_MSG" --no-verify 2>/dev/null || true
    git push 2>/dev/null && echo "✅ Changes pushed successfully." || echo "⚠️  Push failed."
  else
    echo "📦 No changes to push."
  fi
fi

exit 0
```
[^15]

### 3.2 核心邏輯解析

#### Shebang 與註解

```bash
#!/bin/bash
# Stop Hook - Auto-commit and push changes on session exit
# Generates Conventional Commits style messages with file change details.
```

- `#!/bin/bash`：指定使用 Bash 作為直譯器（hooks 腳本需要正確的 shebang）[^11]
- 註解明確說明用途與 commit message 格式

#### 嚴格模式設定

```bash
set -euo pipefail
```

| 旗標 | 作用 |
|------|------|
| `-e` | 任何命令回傳非零結束碼時立即退出 |
| `-u` | 使用未定義變數時報錯退出 |
| `-o pipefail` | 管線中任何一個命令失敗時，整個管線的結束碼為失敗 |

#### `infer_commit_type()` — 推斷 Commit 類型

根據變更檔案的副檔名，統計各類別數量後回傳**佔比最高的類型**：

| 檔案模式 | 對應類型 | 範例 |
|---------|---------|------|
| `*.md`, `*.txt`, `*.rst`, `*.adoc` | `docs` | README.md、CHANGELOG.md |
| `.github/workflows/*`, `.github/actions/*` | `ci` | ci.yml |
| `*.test.*`, `*.spec.*`, `*Test.*` | `test` | UserTest.cs、app.spec.ts |
| `*.json`, `*.yml`, `*.sh`, `*.editorconfig` 等 | `chore` | hooks.json、stop-hook.sh |
| 其他所有檔案 | `feat` | main.cs、index.ts |

> 注意：使用 `((count++)) || true` 避免 `set -e` 下算術結果為 0 時觸發退出。

#### `generate_commit_message()` — 產生 Commit 訊息

此函式在 `git add -A` 之後呼叫，分三個步驟：

1. **分析暫存區**：`git diff --cached --name-status` 取得檔案狀態（A/M/D）
2. **組合 summary 行**：統計新增、修改、刪除數量（如 `update 2 file(s), add 1 file(s)`）
3. **組合 body**：列出具體檔案清單（超過 15 個時截斷）+ `git diff --cached --shortstat`

輸出格式遵循 [Conventional Commits](https://www.conventionalcommits.org/)：

```
<type>: <summary>

<file list with status>

<shortstat>
```

#### 主流程：環境檢查 → 暫存 → 提交 → 推送

```bash
git add -A
COMMIT_MSG=$(generate_commit_message)
git commit -m "$COMMIT_MSG" --no-verify 2>/dev/null || true
git push 2>/dev/null && echo "✅ ..." || echo "⚠️ ..."
```

- **`git add -A`**：暫存所有變更（modified、untracked、deleted）
- **`--no-verify`**：跳過 Git pre-commit/commit-msg hooks，避免 linting 阻擋自動提交
- **`|| true`**：確保 commit 失敗不會中止腳本（`set -e` 保護）
- **`exit 0`**：無論結果都正常退出，hook 失敗不應阻擋代理執行[^6]

### 3.3 執行流程圖

```
stop-hook.sh 被觸發
        │
        ▼
┌─────────────────────────┐
│ 是否在 Git 工作樹內？     │
└───────┬─────────────────┘
        │
   是   │   否
   ▼    └──────► exit 0（靜默退出）
┌─────────────────────────┐
│ 是否有未提交的變更？       │
└───────┬─────────────────┘
        │
   有   │   無
   ▼    └──────► 顯示 "📦 No changes to push." → exit 0
┌─────────────────────────┐
│ git add -A              │
├─────────────────────────┤
│ generate_commit_message │
│  ├ git diff --cached    │
│  ├ infer_commit_type()  │
│  ├ summary + body       │
│  └ shortstat            │
├─────────────────────────┤
│ git commit + git push   │
└───────┬─────────────────┘
        │
   ┌────┴────┐
   │         │
 成功      失敗
   │         │
   ▼         ▼
 "✅"      "⚠️"
   │         │
   └────┬────┘
        ▼
     exit 0
```

### 3.4 Commit Message 範例

修改 2 個 Markdown 檔案、新增 1 個 JSON 設定檔時，產生的 commit message：

```
docs: update 2 file(s), add 1 file(s)

M	README.md
M	github-hooks.md
A	.github/hooks/hooks.json

 3 files changed, 45 insertions(+), 12 deletions(-)
```

僅修改 1 個 Shell 腳本時：

```
chore: update 1 file(s)

M	.github/hooks/stop-hook.sh

 1 file changed, 69 insertions(+), 2 deletions(-)
```

### 3.5 潛在風險與注意事項

| 風險 | 說明 | 建議 |
|------|------|------|
| 敏感資料洩漏 | `git add -A` 會加入所有檔案，包括可能的 `.env`、金鑰等 | 確保 `.gitignore` 完善 |
| 合併衝突 | 如果遠端有新的 commit，`git push` 會失敗 | 腳本已用 `\|\| echo "⚠️"` 處理 |
| 繞過品質檢查 | `--no-verify` 跳過所有 Git hooks | 這是有意設計，自動 commit 不需要 linting |
| 類型推斷不精確 | 自動推斷的 type 可能與實際意圖不符（如 bug fix 被標為 feat） | 可之後用 `git rebase -i` 調整 |
| 腳本權限 | Unix 需要執行權限 | 確保執行過 `chmod +x .github/hooks/stop-hook.sh` |

---

## 四、兩個檔案的協作關係

```
┌──────────────────────────┐
│  Copilot CLI / Agent     │
│  會話生命週期             │
└──────────┬───────────────┘
           │ 觸發 "sessionEnd" 事件
           ▼
┌──────────────────────────┐
│  hooks.json              │
│  讀取設定，找到對應的     │
│  hook 定義               │
└──────────┬───────────────┘
           │ 執行命令
           ▼
┌──────────────────────────┐
│  stop-hook.sh            │
│  1. 檢查 Git 環境        │
│  2. 檢查是否有變更        │
│  3. git add -A           │
│  4. 分析變更 → 推斷 type  │
│  5. 產生 Conventional     │
│     Commits 格式訊息      │
│  6. git commit + push    │
└──────────────────────────┘
```

簡而言之：
- **`hooks.json`** 是「設定檔」— 告訴 Copilot **何時**做什麼
- **`stop-hook.sh`** 是「執行檔」— 定義**具體做什麼**

---

## 五、改善建議（✅ 已完成）

以下改善項目已套用至 `hooks.json` 與 `stop-hook.sh`：

1. ✅ `"Stop"` → `"sessionEnd"`（使用官方標準事件名稱）
2. ✅ `"command"` → `"bash"`（使用官方標準欄位名稱）
3. ✅ 新增 `"cwd": "."`（明確指定工作目錄）
4. ✅ 新增 `"timeoutSec": 30`（明確設定超時時間）
5. ✅ `stop-hook.sh` 已加上執行權限（`chmod +x`）
6. ✅ Commit message 從無意義的 `auto-commit: <timestamp>` 改為 **Conventional Commits** 格式，自動推斷類型並列出變更檔案

如果希望在 **主代理完成回應時**（而非整個會話結束時）觸發，則使用 `"agentStop"` 作為事件名稱。

---

## Confidence Assessment

| 項目 | 信心度 | 說明 |
|------|--------|------|
| `.github/hooks/` 的用途 | 🟢 高 | 有完整官方文件支持 |
| `hooks.json` 結構解析 | 🟢 高 | 已更新為官方標準格式 |
| `stop-hook.sh` 行為分析 | 🟢 高 | 直接閱讀原始碼得出 |
| `hooks.json` 設定正確性 | 🟢 高 | 使用標準 `sessionEnd` 事件與 `bash` 欄位 |
| 改善建議的正確性 | 🟢 高 | 基於最新官方文件，已全數套用 |

---

## Footnotes

[^1]: [GitHub Docs — About hooks](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-hooks)：「Copilot agents support hooks stored in JSON files in your repository at `.github/hooks/*.json`.」

[^2]: `project-dev-guide/.github/hooks/`：包含 `hooks.json` 與 `stop-hook.sh` 兩個檔案。

[^3]: [GitHub Docs — Using hooks with GitHub Copilot agents](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/use-hooks)：「Create a new `hooks.json` file... in the `.github/hooks/` folder of your repository.」

[^4]: [GitHub Docs — About hooks](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-hooks)：「Hooks enable you to execute custom shell commands at strategic points in an agent's workflow.」

[^5]: [GitHub Docs — Using hooks](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/use-hooks)：「The hooks configuration file must be present on your repository's default branch to be used by Copilot coding agent. For GitHub Copilot CLI, hooks are loaded from your current working directory.」

[^6]: [GitHub Docs — CLI command reference, Hooks reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#hooks-reference)：「If multiple hooks of the same type are configured, they execute in order... Hook failures (non-zero exit codes or timeouts) are logged and skipped—they never block agent execution.」

[^7]: [GitHub Docs — Using hooks with Copilot CLI for predictable, policy-compliant execution](https://docs.github.com/en/copilot/tutorials/copilot-cli-hooks)

[^8]: [GitHub Docs — Hooks configuration reference](https://docs.github.com/en/copilot/reference/hooks-configuration)：包含所有 hook 類型的完整 input/output 格式、腳本最佳實踐與進階模式。

[^9]: `project-dev-guide/.github/hooks/hooks.json`：第 1-11 行。

[^10]: [GitHub Docs — About hooks](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-hooks)：「The JSON must contain a `version` field with a value of `1`.」

[^11]: [GitHub Docs — Using hooks, Troubleshooting](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/use-hooks#troubleshooting)：「Ensure `version: 1` is specified... Check that the script has a proper shebang.」

[^12]: [GitHub Docs — CLI command reference, Hook events](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#hook-events)：列出所有標準事件名稱。

[^13]: [GitHub Docs — CLI command reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#prompt-hooks)：Prompt hooks 類型 `"prompt"` 僅支援 `sessionStart` 事件。

[^14]: [GitHub Docs — About hooks, Hook configuration format](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-hooks#hook-configuration-format)：標準格式使用 `bash`、`powershell`、`cwd`、`env`、`timeoutSec` 欄位。

[^15]: `project-dev-guide/.github/hooks/stop-hook.sh`：第 1-19 行。
