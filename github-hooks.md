# `.github/hooks/` 資料夾超完整詳細說明

## Executive Summary

`.github/hooks/` 是 GitHub Copilot 代理（Copilot CLI 與 Copilot coding agent）的 **Hooks 機制設定資料夾**，用於在代理工作階段的特定生命週期時刻（如啟動、結束、工具執行前後等）自動執行自訂的 Shell 腳本。Copilot agents 會自動從 `.github/hooks/*.json` 讀取所有 JSON 設定檔[^1]，然後根據其中定義的事件觸發對應腳本。

在本專案（`project-dev-guide`）中，`.github/hooks/` 內包含兩個檔案[^2]：
1. **`hooks.json`** — Hook 設定檔，定義在 `Stop` 事件觸發時執行 `stop-hook.sh`
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
		"Stop": [
			{
				"type": "command",
				"command": ".github/hooks/stop-hook.sh"
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
    "Stop": [...]
}
```

- 以事件名稱為 key，值為 hook 定義陣列
- 每個事件可以對應多個 hook（依序執行）

#### `"Stop"` 事件

這是本專案使用的事件名稱。

> ⚠️ **重要注意事項**：根據官方文件[^12]，標準的 hook 事件名稱為 `sessionStart`、`sessionEnd`、`userPromptSubmitted`、`preToolUse`、`postToolUse`、`agentStop`、`subagentStop`、`errorOccurred`。
>
> 本專案使用的 `"Stop"` **不在官方文件列出的標準事件名稱中**。根據語意推斷，它最可能對應：
> - **`agentStop`**：主代理完成一輪回應時觸發
> - **`sessionEnd`**：整個會話結束時觸發
>
> 由於 `stop-hook.sh` 的功能是「在結束時 auto-commit 並 push」，語意上更接近 `sessionEnd`。
>
> 建議將 `"Stop"` 改為官方文件中標準的事件名稱（如 `"sessionEnd"` 或 `"agentStop"`），以確保相容性。

#### Hook 定義物件

```json
{
    "type": "command",
    "command": ".github/hooks/stop-hook.sh"
}
```

| 欄位 | 值 | 說明 |
|-----|---|-----|
| `type` | `"command"` | **必填**。目前唯一支援的類型（另有 `"prompt"` 僅用於 `sessionStart`）[^13] |
| `command` | `".github/hooks/stop-hook.sh"` | 要執行的腳本路徑 |

> ⚠️ **另一個注意事項**：官方文件的標準格式使用 `bash` 和 `powershell` 作為分開的欄位[^14]，而非 `command`。例如：
> ```json
> {
>     "type": "command",
>     "bash": "./scripts/cleanup.sh",
>     "powershell": "./scripts/cleanup.ps1",
>     "cwd": ".",
>     "timeoutSec": 30
> }
> ```
>
> 本專案使用的 `"command"` 欄位可能是 Copilot CLI 的簡化格式或早期語法。為確保跨平台相容性，建議改用 `"bash"` 欄位。

### 2.3 官方標準格式對照

以下是按照官方建議的標準格式，等效的 `hooks.json` 應該長這樣：

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

set -euo pipefail

if git rev-parse --is-inside-work-tree &>/dev/null; then
  if [[ -n "$(git status --porcelain)" ]]; then
    echo "📦 Auto-committing and pushing changes..."
    git add -A
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    git commit -m "auto-commit: $TIMESTAMP" --no-verify 2>/dev/null || true
    git push 2>/dev/null && echo "✅ Changes pushed successfully." || echo "⚠️  Push failed."
  else
    echo "📦 No changes to push."
  fi
fi

exit 0
```
[^15]

### 3.2 逐行深入解析

#### Shebang 與註解

```bash
#!/bin/bash
# Stop Hook - Auto-commit and push changes on session exit
```

- `#!/bin/bash`：指定使用 Bash 作為直譯器（hooks 腳本需要正確的 shebang）[^11]
- 註解明確說明用途：在 Copilot session 退出時自動 commit 並 push

#### 嚴格模式設定

```bash
set -euo pipefail
```

| 旗標 | 作用 |
|------|------|
| `-e` | 任何命令回傳非零結束碼時立即退出 |
| `-u` | 使用未定義變數時報錯退出 |
| `-o pipefail` | 管線中任何一個命令失敗時，整個管線的結束碼為失敗 |

這是 Shell 腳本的最佳實踐，確保錯誤不會被靜默忽略。

#### Git 環境檢查

```bash
if git rev-parse --is-inside-work-tree &>/dev/null; then
```

- `git rev-parse --is-inside-work-tree`：檢查當前目錄是否在 Git 工作樹內
- `&>/dev/null`：將 stdout 與 stderr 都導向 /dev/null（靜默執行）
- **防禦性程式設計**：如果不在 Git 倉庫中，整個腳本會跳過所有操作

#### 檢查是否有未提交的變更

```bash
if [[ -n "$(git status --porcelain)" ]]; then
```

- `git status --porcelain`：以機器可讀的格式輸出變更狀態
  - 有變更時輸出不為空（如 `M  file.txt`、`?? new-file.txt`）
  - 無變更時輸出為空
- `-n`：判斷字串是否非空（有內容 = 有未提交的變更）

#### 暫存所有變更

```bash
git add -A
```

- `-A`（`--all`）：暫存所有變更，包括：
  - 修改的檔案（modified）
  - 新增的檔案（untracked）
  - 刪除的檔案（deleted）
- 等同於在 repo 根目錄執行 `git add .` + `git add -u`

#### 產生時間戳並提交

```bash
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
git commit -m "auto-commit: $TIMESTAMP" --no-verify 2>/dev/null || true
```

- `date '+%Y-%m-%d %H:%M:%S'`：產生格式化時間戳（如 `2026-03-28 15:45:12`）
- Commit 訊息格式：`auto-commit: 2026-03-28 15:45:12`
- **`--no-verify`**：跳過 Git 的 pre-commit 和 commit-msg hooks
  - 這很重要！避免 Git hooks（如 linting）阻止自動 commit
- `2>/dev/null`：隱藏 stderr（如果 commit 失敗不顯示錯誤）
- `|| true`：即使 commit 失敗也不中止腳本（因為 `set -e` 會讓失敗命令中止執行）

#### 推送至遠端

```bash
git push 2>/dev/null && echo "✅ Changes pushed successfully." || echo "⚠️  Push failed."
```

- `git push`：推送到當前追蹤的遠端分支
- `2>/dev/null`：隱藏 push 的 stderr 輸出
- 使用 `&&` / `||` 進行條件式回饋：
  - 成功 → 顯示 `✅ Changes pushed successfully.`
  - 失敗 → 顯示 `⚠️  Push failed.`（例如沒有遠端、網路問題、權限不足）

#### 無變更的處理

```bash
else
    echo "📦 No changes to push."
fi
```

- 當 `git status --porcelain` 為空（沒有變更）時的友善提示

#### 確保正常退出

```bash
exit 0
```

- 無論什麼情況都以 exit code 0 結束
- 這是 hook 腳本的最佳實踐：hooks 失敗不應阻擋代理的正常執行[^6]
- 官方文件指出：「Hook 失敗（非零退出碼或超時）會被記錄並跳過——它們永遠不會阻擋代理執行」[^6]

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
│ git commit (with ts)    │
│ git push                │
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

### 3.4 潛在風險與注意事項

| 風險 | 說明 | 建議 |
|------|------|------|
| 敏感資料洩漏 | `git add -A` 會加入所有檔案，包括可能的 `.env`、金鑰等 | 確保 `.gitignore` 完善 |
| 合併衝突 | 如果遠端有新的 commit，`git push` 會失敗 | 腳本已用 `\|\| echo "⚠️"` 處理 |
| 繞過品質檢查 | `--no-verify` 跳過所有 Git hooks | 這是有意設計，自動 commit 不需要 linting |
| 不明確的 commit 歷史 | 大量 `auto-commit: <timestamp>` 會汙染 git log | 可考慮之後 squash 或 rebase |
| 腳本權限 | Unix 需要執行權限 | 確保執行過 `chmod +x .github/hooks/stop-hook.sh` |

---

## 四、兩個檔案的協作關係

```
┌──────────────────────────┐
│  Copilot CLI / Agent     │
│  會話生命週期             │
└──────────┬───────────────┘
           │ 觸發 "Stop" 事件
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
│  4. git commit           │
│  5. git push             │
└──────────────────────────┘
```

簡而言之：
- **`hooks.json`** 是「設定檔」— 告訴 Copilot **何時**做什麼
- **`stop-hook.sh`** 是「執行檔」— 定義**具體做什麼**

---

## 五、改善建議

為了確保與最新官方文件相容[^14]，建議將 `hooks.json` 更新為以下格式：

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

主要變更：
1. `"Stop"` → `"sessionEnd"`（使用官方標準事件名稱）
2. `"command"` → `"bash"`（使用官方標準欄位名稱）
3. 新增 `"cwd": "."`（明確指定工作目錄）
4. 新增 `"timeoutSec": 30`（明確設定超時時間）

如果希望在 **主代理完成回應時**（而非整個會話結束時）觸發，則使用 `"agentStop"` 作為事件名稱。

---

## Confidence Assessment

| 項目 | 信心度 | 說明 |
|------|--------|------|
| `.github/hooks/` 的用途 | 🟢 高 | 有完整官方文件支持 |
| `hooks.json` 結構解析 | 🟢 高 | 與官方 schema 對照驗證 |
| `stop-hook.sh` 行為分析 | 🟢 高 | 直接閱讀原始碼得出 |
| `"Stop"` 事件名稱的有效性 | 🟡 中 | 不在官方事件列表中，可能是 CLI 私有別名或早期格式 |
| `"command"` 欄位的支援 | 🟡 中 | 官方文件使用 `"bash"`/`"powershell"`，`"command"` 可能是簡化語法 |
| 改善建議的正確性 | 🟢 高 | 基於最新官方文件 |

---

## Footnotes

[^1]: [GitHub Docs — About hooks](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-hooks)：「Copilot agents support hooks stored in JSON files in your repository at `.github/hooks/*.json`.」

[^2]: `/Users/qiuzili/project-dev-guide/.github/hooks/`：包含 `hooks.json` 與 `stop-hook.sh` 兩個檔案。

[^3]: [GitHub Docs — Using hooks with GitHub Copilot agents](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/use-hooks)：「Create a new `hooks.json` file... in the `.github/hooks/` folder of your repository.」

[^4]: [GitHub Docs — About hooks](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-hooks)：「Hooks enable you to execute custom shell commands at strategic points in an agent's workflow.」

[^5]: [GitHub Docs — Using hooks](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/use-hooks)：「The hooks configuration file must be present on your repository's default branch to be used by Copilot coding agent. For GitHub Copilot CLI, hooks are loaded from your current working directory.」

[^6]: [GitHub Docs — CLI command reference, Hooks reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#hooks-reference)：「If multiple hooks of the same type are configured, they execute in order... Hook failures (non-zero exit codes or timeouts) are logged and skipped—they never block agent execution.」

[^7]: [GitHub Docs — Using hooks with Copilot CLI for predictable, policy-compliant execution](https://docs.github.com/en/copilot/tutorials/copilot-cli-hooks)

[^8]: [GitHub Docs — Hooks configuration reference](https://docs.github.com/en/copilot/reference/hooks-configuration)：包含所有 hook 類型的完整 input/output 格式、腳本最佳實踐與進階模式。

[^9]: `/Users/qiuzili/project-dev-guide/.github/hooks/hooks.json`：第 1-11 行。

[^10]: [GitHub Docs — About hooks](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-hooks)：「The JSON must contain a `version` field with a value of `1`.」

[^11]: [GitHub Docs — Using hooks, Troubleshooting](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/use-hooks#troubleshooting)：「Ensure `version: 1` is specified... Check that the script has a proper shebang.」

[^12]: [GitHub Docs — CLI command reference, Hook events](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#hook-events)：列出所有標準事件名稱。

[^13]: [GitHub Docs — CLI command reference](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#prompt-hooks)：Prompt hooks 類型 `"prompt"` 僅支援 `sessionStart` 事件。

[^14]: [GitHub Docs — About hooks, Hook configuration format](https://docs.github.com/en/copilot/concepts/agents/coding-agent/about-hooks#hook-configuration-format)：標準格式使用 `bash`、`powershell`、`cwd`、`env`、`timeoutSec` 欄位。

[^15]: `/Users/qiuzili/project-dev-guide/.github/hooks/stop-hook.sh`：第 1-19 行。
