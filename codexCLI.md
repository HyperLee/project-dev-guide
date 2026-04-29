# Codex CLI 深度研究報告與教學手冊

研究對象：

- 原始碼倉庫：[openai/codex](https://github.com/openai/codex)
- 官方文件入口：[Codex Documentation](https://developers.openai.com/codex)

本報告以公開官方來源為準，並以倉庫 `openai/codex` 的 commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d` 為程式碼分析基準。[^1][^2][^3]

## Executive Summary

Codex CLI 是 OpenAI 的本機終端機 coding agent：它能在你指定的工作目錄中讀檔、改檔、執行命令、做 code review、接上 MCP 工具，並支援互動式 TUI 與非互動式 `codex exec` 兩種主要操作模式。官方入口目前把它定位成「本地端可執行的開發代理」，推薦安裝方式是 `npm i -g @openai/codex`，但維護中的核心實作其實是 Rust monorepo，而不是單純的 Node CLI。[^1][^3]

如果你只想快速上手，最短路徑是：安裝 `@openai/codex`、執行 `codex`、用 ChatGPT 或 API key 登入、先用預設的 `workspace-write + on-request` 權限開始，再逐步學 `codex exec`、`codex review`、`codex mcp`、`resume/fork`、`/review`、`/model`、`/permissions` 這些高頻工作流。[^1][^4][^5][^6][^13][^14][^23]

如果你要把它用到團隊或自動化，真正該理解的是五件事：`config.toml` 的多層設定、登入憑證儲存方式、sandbox/approval 安全模型、MCP 擴充機制，以及它其實是由 `cli`、`tui`、`exec`、`core`、`config`、`login`、`app-server`、`mcp-server`、`sandboxing` 等多個 crate 組成的 monorepo。[^3][^7][^8][^10][^11][^15][^18][^19][^20][^21][^22]

---

## 1. 這套工具到底是什麼？

Codex CLI 是 OpenAI 的本地開發代理工具。官方 README 直接把它描述為「runs locally on your computer」；官方 CLI 頁面則說它可以在選定目錄中讀取、修改與執行程式碼。[^1][^13]

它不是只有單一互動式聊天介面。從 CLI 主入口的子命令可以看出，它至少包含：

- 互動式 TUI（不帶子命令時的預設模式）
- 非互動模式 `exec`
- 非互動 code review
- `login` / `logout`
- `mcp`
- `mcp-server`
- `app-server`
- `completion`
- `update`
- `sandbox`
- `resume` / `fork`
- `cloud`
- `features`[^4]

從 `codex-rs/README.md` 與 Cargo workspace 也看得出，今天被維護的正式版本是 Rust 版 CLI，而且它不是一個小工具專案，而是一個拆成大量 crate 的大型 monorepo。[^3][^18]

### 與其他 Codex 產品面的關係

官方 README 明確區分了幾個表面：

| 表面 | 定位 | 你什麼時候用它 |
|---|---|---|
| Codex CLI | 終端機本機代理 | 你想在 shell / repo 裡直接工作 |
| Codex IDE | 編輯器整合 | 你主要待在 VS Code / Cursor / Windsurf |
| Codex App | 桌面體驗 | 你要 worktree、automations、圖形化體驗 |
| Codex Web | 雲端代理 | 你要 OpenAI 管理的 cloud agent 體驗 |

README 也直接把 CLI、IDE、App、Web 分流到不同入口，因此使用者不該把它們當成完全同一件產品。[^1]

### 授權與開源治理

這個 repo 採 Apache-2.0 授權；但外部程式碼貢獻目前是「invitation only」，也就是 issue / 討論 / 分析可以公開參與，但未受邀 PR 會被關閉。這代表你可以研究、使用、分叉它，但若你想對官方主倉提 code change，現實上要先走 issue / 對齊方案。[^1][^27]

---

## 2. 架構總覽：Codex CLI 不是單一 binary，而是一整套執行平台

從 workspace 成員清單與 Rust README，可以把它理解成下面這個層次：[^3][^18][^19]

```text
┌────────────────────────────────────────────────────────────┐
│                        codex cli                          │
│                (top-level multitool entry)               │
└───────────────┬───────────────────────┬──────────────────┘
                │                       │
                ▼                       ▼
      ┌─────────────────┐     ┌─────────────────┐
      │   codex-tui     │     │   codex-exec    │
      │ interactive UI  │     │ non-interactive │
      └────────┬────────┘     └────────┬────────┘
               │                       │
               └────────────┬──────────┘
                            ▼
                   ┌─────────────────┐
                   │   codex-core    │
                   │ agent/business  │
                   │ logic, threads, │
                   │ tools, reviews, │
                   │ sandbox hooks   │
                   └───────┬─────────┘
                           │
        ┌──────────────────┼───────────────────┐
        ▼                  ▼                   ▼
┌──────────────┐  ┌─────────────────┐  ┌─────────────────┐
│ codex-config │  │  codex-login    │  │  sandboxing     │
│ config load  │  │ auth/session    │  │ OS sandbox impl │
│ layering     │  │ storage          │  │                 │
└──────────────┘  └─────────────────┘  └─────────────────┘
        │                  │                   │
        ▼                  ▼                   ▼
┌──────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  app-server  │  │   mcp-server    │  │ cloud / skills  │
│ remote TUI   │  │ expose Codex as │  │ hooks / models  │
│ transport    │  │ an MCP server   │  │ rollout/state   │
└──────────────┘  └─────────────────┘  └─────────────────┘
```

### 核心模組職責

| 模組 | 角色 | 證據 |
|---|---|---|
| `cli` | 最上層多工具入口，負責子命令路由 | `codex-rs/cli/src/main.rs`[^4] |
| `tui` | 全螢幕互動終端 UI | `codex-rs/tui/src/lib.rs`[^6] |
| `exec` | 非互動 / 自動化執行模式 | `codex-rs/exec/src/cli.rs`, `lib.rs`[^5] |
| `core` | 真正的 agent/business logic、thread、MCP、review、sandbox glue | `codex-rs/core/src/lib.rs`[^19] |
| `config` | 設定型別、載入、合併、MCP/server config 編輯 | `codex-rs/config/src/lib.rs`[^10] |
| `login` | ChatGPT / API key / agent identity 登入與 token 儲存 | `codex-rs/login/src/lib.rs`, `auth/*`[^11] |
| `app-server` | 遠端 TUI / 控制通道 / transport | `codex-rs/app-server/src/lib.rs`[^20] |
| `mcp-server` | 讓 Codex 自己成為 MCP server | `codex-rs/mcp-server/src/lib.rs`[^21] |
| `sandboxing` | 平台 sandboxes 的抽象層 | `codex-rs/sandboxing/src/lib.rs`[^22] |

### 一個實用觀察：repo 根目錄的 `package.json` 不是 CLI 發行包本體

根目錄 `package.json` 名稱是 `codex-monorepo`、`private: true`，內容主要是 repo 維護腳本與格式化依賴，這表示如果你從 repo 結構理解產品，不能把根目錄的 Node 設定誤認成公開 npm 套件本身。相反地，Rust README 說明今天的正式 CLI 是 Rust 實作，並透過 npm/Homebrew/Release 提供安裝入口。[^3][^28]

---

## 3. 安裝手冊

## 3.1 最推薦的安裝方式

官方對一般使用者最推薦的安裝方式是：

```bash
npm i -g @openai/codex
codex
```

Homebrew 也屬於一級安裝路徑：

```bash
brew install --cask codex
codex
```

另外也可以直接下載 GitHub Release 的平台二進位檔。官方 README 目前明列了 macOS 與 Linux 常用檔名；對 Windows 使用者，官方網站則更偏向 npm + 原生 Windows / WSL2 安裝路徑。[^1][^24]

### 安裝方式比較

| 方法 | 指令 / 來源 | 適合誰 | 備註 |
|---|---|---|---|
| npm | `npm i -g @openai/codex` | 大多數開發者 | 官方 quickstart 首選[^1] |
| Homebrew | `brew install --cask codex` | macOS 使用者 | 安裝與升級體驗好[^1] |
| GitHub Release | 下載 tar.gz / 可執行檔 | 想避開 package manager 的使用者 | README 主要列出 macOS/Linux 檔名[^1] |
| 從原始碼建置 | `cargo build` / `cargo run --bin codex` | 想研究原始碼、客製或貢獻的人 | 需要 Rust toolchain[^2] |

## 3.2 系統需求

repo 內 `docs/install.md` 對原始碼建置寫得很保守：macOS 12+、Ubuntu 20.04+/Debian 10+、或 Windows 11 via WSL2，建議 Git 2.23+、至少 4GB RAM。[^2]

但官方 Windows 指南又明確說 Codex 可以：

1. 原生跑在 Windows（`elevated` sandbox）
2. 原生跑在 Windows（`unelevated` sandbox）
3. 跑在 WSL2（Linux sandbox）[^24]

**實務建議：**

- 一般跨平台使用者：照 CLI 頁面先裝 npm 版即可。[^13]
- Windows 使用者：如果你只看 repo 內 `docs/install.md`，會以為只能走 WSL2；但比較新的官方 Windows 文件顯示「原生 Windows」已是官方支援路徑，所以要以 Windows 專頁為準。[^2][^24]

## 3.3 從原始碼建置

如果你要研究或開發 Codex 本身，官方流程大致是：

```bash
git clone https://github.com/openai/codex.git
cd codex/codex-rs

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup component add rustfmt
rustup component add clippy
cargo install just
cargo install --locked cargo-nextest   # optional

cargo build
cargo run --bin codex -- "explain this codebase to me"
just fmt
just fix -p <crate-you-touched>
cargo test -p codex-tui
just test
```

這段資訊的重要性不只在建置，它同時也告訴你官方自己的開發工作流是 `cargo + just (+ nextest)`。[^2]

## 3.4 升級

官方 CLI 頁面說新版本會持續釋出，npm 升級方式是：

```bash
npm i -g @openai/codex@latest
```

CLI 主程式本身也有 `update` 子命令，表示產品內建了更新入口；只是對一般終端機使用者來說，官方文件目前還是更偏向用 npm 升級來教學。[^4][^13]

---

## 4. 第一次啟動：登入、權限、設定檔

## 4.1 啟動

最基本的第一次啟動就是：

```bash
codex
```

首次執行時，官方文件說它會提示你用 ChatGPT 帳號或 API key 驗證。[^13]

## 4.2 登入方式

官方支援兩大登入模式：

1. **Sign in with ChatGPT**：走 ChatGPT 訂閱權限與工作區政策。
2. **Sign in with API key**：走 OpenAI API 計費與 API 組織的資料政策。[^12]

CLI 原始碼的 `login` 子命令也對應到這兩種模式，並且另外支援：

- `codex login --with-api-key`：從 stdin 讀取 API key
- `codex login --device-auth`：裝置碼登入
- `codex login status`：查看登入狀態[^4]

### ChatGPT vs API key 怎麼選？

| 模式 | 何時用 | 優點 | 注意事項 |
|---|---|---|---|
| ChatGPT 登入 | 日常互動使用、想用 ChatGPT 方案額度 | 官方主推，CLI 頁面直接推薦這條路 | Codex cloud 必須用這條[^1][^12] |
| API key | 腳本、自動化、CI/CD | 最適合機器流程 | 用量走 API 計費；官方建議自動化優先用這種[^12][^14] |

## 4.3 憑證會存在哪裡？

官方文件說 CLI / IDE 會共用登入快取，憑證可能存在 `~/.codex/auth.json` 或 OS credential store。[^12]

原始碼更精確：

- `$CODEX_HOME/auth.json` 的資料結構叫 `AuthDotJson`
- `auth.json` 位置是 `codex_home.join("auth.json")`
- file 模式會直接讀寫這個檔
- keyring 模式則用 `Codex Auth` service 與 `cli|<hash>` key
- auto 模式會先試 keyring，失敗才 fallback 到 file[^11]

也就是說，**你在文件裡看到的安全建議是真實對應到程式碼的，不是口號**。如果你選 file-based storage，真的要把 `auth.json` 當密碼看待。[^11][^12]

### 控制憑證儲存位置

`config-reference` 與 auth 文件都說可以用：

```toml
cli_auth_credentials_store = "keyring"  # file | keyring | auto
```

如果你在企業環境或共用機器上使用 Codex，建議優先 `keyring`。[^9][^12]

## 4.4 Headless / remote login

如果本機 browser callback 不方便，官方文件提供三條替代路：

1. 裝置碼登入 `codex login --device-auth`
2. 在有 browser 的機器登入後，安全地複製 `auth.json`
3. 用 SSH port-forward 把 localhost callback tunnel 回來[^12]

## 4.5 設定檔在哪裡？

最重要的設定檔是：

- 使用者層：`~/.codex/config.toml`
- 專案層：`.codex/config.toml`（只在 trusted project 載入）[^8]

Rust 原始碼也顯示 `find_codex_home()` 會解析 `CODEX_HOME`，而設定會透過 `ConfigBuilder` 與 `load_config_layers_state()` 去合併多層來源。[^10]

---

## 5. 日常使用手冊：互動式 TUI

如果你什麼都不加，`codex` 會直接進互動式 TUI。CLI 主入口註解就寫得很清楚：**如果沒有指定 subcommand，參數會轉送到 interactive CLI**。[^4]

## 5.1 最常用的啟動方式

```bash
codex
codex "Explain this codebase to me"
codex -m gpt-5.5
codex --cd path\to\repo
codex --add-dir ..\shared
codex --image screenshot.png "Explain this error"
```

這些能力分別來自官方 feature docs 與共用 CLI 選項：

- 初始 prompt
- 指定 model
- `--cd`
- `--add-dir`
- `--image`
- `--sandbox`
- `--profile`
- `--oss` / `--local-provider`[^7][^13]

## 5.2 TUI 核心旗標

TUI 自己另外加了幾個常用控制：

- `--ask-for-approval` / `-a`
- `--search`
- `--no-alt-screen`[^6]

這意味著互動模式裡最重要的三個控制旋鈕其實是：

1. **模型**（`--model` / `/model`）
2. **權限**（`--sandbox` + `--ask-for-approval` / `/permissions`）
3. **是否允許 live web search**（`--search`）[^6][^7][^13][^23][^25]

## 5.3 你在 TUI 裡真正會用到的功能

官方 feature docs 把互動流程講得很完整，重點如下：[^13]

| 能力 | 操作 |
|---|---|
| 啟動互動會話 | `codex` |
| 清畫面並開新聊天 | `/clear` |
| 複製最新輸出 | `/copy` 或 `Ctrl+O` |
| 搜尋 prompt 歷史 | `Ctrl+R` |
| 用外部編輯器改 prompt | `Ctrl+G` |
| 切換 model | `/model` |
| 切換權限 | `/permissions` |
| 主題 | `/theme` |
| 查看狀態 | `/status` |
| review | `/review` |
| apps/connectors | `/apps` |
| 切 agent thread | `/agent` |
| attach file mention | `@` |
| 跑 shell 指令 | 在 prompt 前加 `!` |

### 進階但很實用的互動習慣

官方最佳實務文件非常值得直接採用：[^26]

1. prompt 盡量包含 **Goal / Context / Constraints / Done when**
2. 複雜任務先進 Plan mode
3. 把長期規則放進 `AGENTS.md`
4. 不要一個 thread 做整個專案；**一個 thread 對一個 coherent task**
5. 反覆出現的工作用 skill，穩定後再做 automation[^26]

---

## 6. `resume`、`fork`、本地 transcripts

Codex 會把 transcripts 存在本機，因此你可以：

```bash
codex resume
codex resume --last
codex resume --all
codex resume <SESSION_ID>
codex fork --last
codex fork <SESSION_ID>
```

`features` 頁面說 session ID 可以從 picker、`/status`、或 `~/.codex/sessions/` 下的檔案找到。CLI 原始碼也顯示 `resume` / `fork` 是正式子命令，而且 `resume` 甚至可以 `--include-non-interactive`。[^4][^13]

這很重要：**Codex CLI 並不是「一次性問答工具」，它天生是 thread-based agent workflow。** 這也是它與一般單發 CLI wrapper 最大的差異。[^13][^19][^26]

---

## 7. 非互動模式：`codex exec`

`codex exec` 是自動化與腳本整合的核心。Rust README 與官方 non-interactive 文件都把它定位成「programmatic / non-interactive」入口。[^3][^14]

## 7.1 基本用法

```bash
codex exec "summarize the repository structure"
codex exec --ephemeral "triage this repository"
codex exec --json "summarize the repo structure"
codex exec "Extract project metadata" --output-schema .\schema.json -o .\result.json
```

`exec` 的原始碼與文件共同揭示了幾個關鍵行為：

- `stdout` 在一般模式下只印最終 agent message
- `--json` 時 `stdout` 變 JSONL event stream
- `stderr` 用來輸出進度 / 非最終訊息
- `--output-schema` 可要求 final response 符合 JSON Schema
- `-o/--output-last-message` 可把最後訊息寫檔
- `--ephemeral` 不持久化 session files[^5][^14]

## 7.2 `stdin` 行為

`exec` 有三種 `stdin` 行為，原始碼寫得很清楚：

- 沒有 positional prompt 時，piped stdin 可作為 prompt
- 明確用 `codex exec -` 時，stdin 強制當 prompt
- 如果「有 prompt + 有 pipe」，stdin 會附加成 `<stdin>` 區塊[^5]

這使它很適合做 shell pipeline，例如：

```bash
npm test 2>&1 | codex exec "summarize the failing tests"
tail -n 200 app.log | codex exec "identify the likely root cause"
```

## 7.3 `exec` 的安全預設

官方 non-interactive 文件明說：`codex exec` 預設跑在 **read-only sandbox**。[^14]

這很合理，因為自動化腳本通常比互動 UI 更需要保守預設。若你真的要讓它改檔或放寬限制，應顯式指定權限。[^14][^23]

## 7.4 自動化與 CI/CD

官方對 CI 的建議很明確：

- **預設用 API key**
- 非信任環境不要暴露 Codex 執行
- `CODEX_API_KEY` 僅支援 `codex exec`
- `codex exec` 預設要求在 Git repo 中執行；必要時可用 `--skip-git-repo-check` 覆蓋[^12][^14]

也就是說，`exec` 不是附屬功能，而是官方明確設計來接 CI/CD 的第一級介面。[^14]

---

## 8. Code review、雲端任務、completion 與其他高價值子命令

## 8.1 Code review

有兩條 review 路：

1. TUI 裡用 `/review`
2. 直接跑 `codex review` / `codex exec review` 類型工作流[^4][^5][^13]

CLI 原始碼顯示 `ReviewArgs` 支援：

- `--uncommitted`
- `--base <branch>`
- `--commit <sha>`
- `--title`
- 自訂 prompt[^5]

對開發者來說，這很實用，因為它把「請代理看 diff」變成正式 workflow，而不是臨時 prompt。

## 8.2 Cloud tasks

CLI 主入口內建 `cloud` 子命令，官方 feature docs 也說可以：

```bash
codex cloud
codex cloud exec --env ENV_ID "Summarize open bugs"
codex cloud exec --env ENV_ID --attempts 3 "Summarize open bugs"
```

這表示 CLI 不只支援本地代理，也能成為 Codex cloud 的前端。[^4][^13]

## 8.3 Shell completions

官方提供：

```bash
codex completion bash
codex completion zsh
codex completion fish
```

這對重度使用者非常值得安裝，尤其是 `codex` 子命令多、旗標多、workflow 也多。[^4][^13]

---

## 9. 設定手冊：`config.toml`、層級、profiles、常用鍵

## 9.1 設定來源優先序

官方 `config-basic` 頁面給了清楚的 precedence：[^8]

1. CLI flags 與 `--config` overrides
2. `--profile <name>`
3. 專案層 `.codex/config.toml`（從 project root 往 cwd，近者勝）
4. 使用者層 `~/.codex/config.toml`
5. 系統層 `/etc/codex/config.toml`（Unix）
6. 內建 defaults

Rust config loader 也證實它是透過 layer stack 做合併，不是單純讀一個檔案。[^10]

## 9.2 最常用設定範例

```toml
model = "gpt-5.5"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
web_search = "cached"
model_reasoning_effort = "high"
log_dir = "/absolute/path/to/codex-logs"
cli_auth_credentials_store = "keyring"

[windows]
sandbox = "elevated"

[sandbox_workspace_write]
network_access = true
```

這些 key 都是官方文件認可的一級設定，且 `config-reference` 裡有更完整的型別清單。[^8][^9][^12][^23][^24][^25]

## 9.3 profiles

官方也支援 profile，例如：

```toml
[profiles.full_auto]
approval_policy = "on-request"
sandbox_mode = "workspace-write"

[profiles.readonly_quiet]
approval_policy = "never"
sandbox_mode = "read-only"
```

再用：

```bash
codex --profile full_auto
```

這個能力很適合把「本機探索」、「CI」、「審查」三種情境分開。[^8][^23]

## 9.4 AGENTS.md 與 repo 規範

如果要長期把 Codex 用得好，最佳實務頁面明確推薦把持久規則放進 `AGENTS.md`。[^26]

它建議 `AGENTS.md` 至少寫：

- repo layout
- 如何 run project
- build / test / lint commands
- 工程慣例
- 禁則
- done 的定義[^26]

CLI 還有 `/init` 可快速 scaffold 一份 starter `AGENTS.md`。這是實務上非常關鍵的「把 prompt 轉成長期規範」能力。[^26]

---

## 10. 安全模型：sandbox、approval、network

Codex 的安全模型不是單一開關，而是兩層一起運作：[^23]

1. **Sandbox mode**：技術上能做什麼
2. **Approval policy**：什麼時候必須停下來問你

## 10.1 常見組合

| 意圖 | 建議旗標 | 效果 |
|---|---|---|
| 預設互動工作 | `codex` | 典型是 workspace-write + on-request[^23] |
| 只讀分析 | `--sandbox read-only --ask-for-approval on-request` | 能看不能改，敏感[^23] |
| 安靜 CI | `--sandbox read-only --ask-for-approval never` | 完全不互動[^23] |
| 很危險的全權模式 | `--dangerously-bypass-approvals-and-sandbox` / `--yolo` | 無 sandbox、無 approval[^7][^23] |

共用 CLI 選項也證明 `--yolo` 只是 `--dangerously-bypass-approvals-and-sandbox` 的 alias。[^7]

## 10.2 `workspace-write` 不是「全部可寫」

官方 approvals/security 文件特別指出，就算是 writable roots，以下仍受保護：

- `.git`
- `.agents`
- `.codex`[^23]

也就是說，它不是粗暴地把整個 repo 完全打開，而是帶保護路徑的可寫模式。

## 10.3 網路預設

官方安全頁面說，預設 agent **不開網路**；`workspace-write` 也預設不開網路，除非你在：

```toml
[sandbox_workspace_write]
network_access = true
```

另一方面，web search 可以與一般 shell network permission 分開控制，且預設是 `cached` 模式，不是直接 live 抓任意頁面。[^8][^23]

## 10.4 一個重要的文件差異：`--full-auto`

官方安全文件還在把 `--full-auto` 描述成 convenience alias。[^23]

但 **目前原始碼** 已把 `--full-auto` 當成 **deprecated / hidden compatibility trap**，並在 `exec` 內顯示警告：改用 `--sandbox workspace-write`。[^5]

**實務建議：** 寫新教學、腳本、CI 時，請優先使用：

```bash
codex --sandbox workspace-write --ask-for-approval on-request
codex exec --sandbox workspace-write ...
```

不要再把 `--full-auto` 當成未來穩定介面。[^5][^23]

---

## 11. Windows 專章

官方 Windows 指南是必讀頁面，因為 Codex 在 Windows 上有三條主要路徑：[^24]

1. 原生 Windows + `elevated` sandbox
2. 原生 Windows + `unelevated` sandbox
3. WSL2（走 Linux sandbox）

## 11.1 原生 Windows

設定方式：

```toml
[windows]
sandbox = "elevated"   # 推薦
# sandbox = "unelevated" # fallback
```

`elevated` 是首選；`unelevated` 是企業政策或本機權限卡住時的 fallback。[^24]

## 11.2 WSL2

官方文件也提供完整 WSL2 安裝路徑，包含：

```bash
wsl --install
wsl
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
nvm install 22
npm i -g @openai/codex
codex
```

且明確提醒 repo 最好放在 Linux home 目錄，不要放 `/mnt/c/...`。[^24]

## 11.3 WSL1 已不支援

Windows 指南與安全文件都指出：WSL1 支援只到 Codex `0.114`；從 `0.115` 起 Linux sandbox 改用 `bubblewrap`，因此 WSL1 不再支援。[^23][^24]

---

## 12. MCP 手冊：讓 Codex 連外部工具，或讓 Codex 自己變成工具

MCP 是 Codex CLI 的一級功能，不是附加腳本。Rust README、官方 MCP 文件與 CLI 原始碼三邊一致證明這點。[^3][^15][^16]

## 12.1 作為 MCP client

你可以用 CLI 直接管理外部 MCP server：

```bash
codex mcp list
codex mcp get context7
codex mcp add context7 -- npx -y @upstash/context7-mcp
codex mcp add figma --url https://mcp.figma.com/mcp --bearer-token-env-var FIGMA_OAUTH_TOKEN
codex mcp login figma
codex mcp logout figma
```

原始碼顯示 `mcp` 子命令正式支援：

- `list`
- `get`
- `add`
- `remove`
- `login`
- `logout`[^16]

官方文件則補齊 MCP 兩種 transport：

- STDIO server
- Streamable HTTP server（可帶 bearer token 或 OAuth）[^15]

## 12.2 MCP 設定檔範例

```toml
[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]
env_vars = ["LOCAL_TOKEN"]

[mcp_servers.figma]
url = "https://mcp.figma.com/mcp"
bearer_token_env_var = "FIGMA_OAUTH_TOKEN"
```

MCP 設定與一般 Codex 設定放在同一份 `config.toml` 裡，而且 CLI 與 IDE extension 共用。[^15]

## 12.3 作為 MCP server

Codex 自己也能被別的 agent / MCP client 使用：

```bash
codex mcp-server
```

Rust README 直接稱它是 experimental MCP server；`mcp-server` crate 的實作也顯示它是用 **stdio + JSON-RPC** 工作，內部由：

1. stdin reader
2. message processor
3. stdout writer

三個 async task 用 channel 串起來。[^3][^21]

如果你是平台工程師，這很有價值，因為這表示 Codex 不只是一個終端機 UI，也能成為更大 agent 系統中的工具節點。[^21]

---

## 13. Subagents / 多代理工作流

官方現在把 subagent workflow 當成 stable capability，且預設開啟。[^8][^17]

重點有三個：

1. 只有你**明確要求**時才會 spawn subagent
2. subagent 會繼承當前 sandbox policy
3. subagent 會增加 token 消耗[^13][^17]

## 13.1 內建 agent 類型

官方 subagents 文件列出三個 built-ins：

- `default`
- `worker`
- `explorer`[^17]

## 13.2 自訂 agent

可放在：

- `~/.codex/agents/`
- `.codex/agents/`

每個 agent 檔至少要有：

- `name`
- `description`
- `developer_instructions`[^17]

## 13.3 併發控制

全域設定主要是：

- `agents.max_threads`
- `agents.max_depth`
- `agents.job_max_runtime_seconds`[^17][^9]

這代表 Codex 的 subagent 能力不是「prompt 魔法」，而是有明確 config surface 與 runtime 限制的正式系統。

---

## 14. 內部技術深潛：從命令列到 agent 執行的資料流

### 14.1 `cli` 是總入口

`codex-rs/cli/src/main.rs` 用 clap 定義了 top-level multitool。沒有 subcommand 時，參數會轉給 interactive TUI；有 subcommand 時就進 `exec`、`mcp`、`sandbox`、`cloud`、`resume` 等模式。[^4]

### 14.2 `exec` 與 `tui` 其實共享大量選項

`SharedCliOptions` 顯示兩者共享：

- `--image`
- `--model`
- `--oss`
- `--local-provider`
- `--profile`
- `--sandbox`
- `--dangerously-bypass-approvals-and-sandbox`
- `--cd`
- `--add-dir`[^7]

這說明互動與非互動模式不是兩套割裂產品，而是共享同一套 agent 執行面。

### 14.3 `exec` 透過 app-server client 進行事件流處理

`exec/src/lib.rs` 顯示 `exec` 不是簡單的同步函式，而是：

- 使用 app-server client / protocol
- 建立 request / response / thread events
- 把 JSONL、human output、schema output 等做不同 event processor[^5]

因此 `codex exec --json` 才能合理地輸出完整事件流，而不是只印一段最終文字。[^5][^14]

### 14.4 `tui` 內嵌 app-server

`tui/src/lib.rs` 顯示 TUI 會用 `InProcessAppServerClient` 或 `RemoteAppServerClient`，也就是說 TUI 並不是把所有 agent 邏輯都直接做在 UI 裡，而是建立在 app-server 抽象之上。[^6]

### 14.5 `app-server` 是真正的 transport / control plane

`app-server/src/lib.rs` 顯示它有：

- stdio / websocket / control socket transports
- config manager
- thread state / status
- outgoing router
- graceful shutdown / restart handling[^20]

對理解 remote TUI 很重要：你看到的 `codex --remote ws://...` 並不是「單純 SSH UI 轉發」，而是有明確 app-server transport 架構支撐。[^13][^20]

### 14.6 `sandboxing` 是跨平台抽象

`sandboxing/src/lib.rs` 封裝了：

- Linux `bwrap`
- Linux `landlock`
- macOS `seatbelt`
- 平台 sandbox manager / transform logic[^22]

這也呼應官方安全文件中「不同 OS 有不同 sandbox 實作」的說法。[^22][^23]

---

## 15. 模型、provider 與本地 OSS 模式

官方 models 文件建議：

- 能用就先用 `gpt-5.5`
- 若尚未可用，繼續用 `gpt-5.4`
- 想要更快 / 更省可用 `gpt-5.4-mini`
- `gpt-5.3-codex-spark` 是 ChatGPT Pro 的 research preview[^25]

同時，共用 CLI 選項顯示它也支援：

- `--oss`
- `--local-provider`

而 models 文件又指出 Codex 可以指向支援 Chat Completions 或 Responses API 的 provider，但 **Chat Completions 已被標記 deprecated**、未來會移除。[^7][^25]

**實務結論：**

- 日常使用 OpenAI 官方模型：優先 `gpt-5.5` / `gpt-5.4`
- 腳本 / CI：顯式指定 model
- 想接本地 provider：研究 `--oss`、`--local-provider`、`model_providers.*`
- 新整合盡量以 Responses API 思維為主[^7][^9][^25]

---

## 16. 我建議的實際使用路線圖

## 16.1 個人開發者入門路線

1. 安裝 `npm i -g @openai/codex`
2. 跑 `codex`
3. 用 ChatGPT 登入
4. 在可信 repo 先用預設權限
5. 建一份簡潔的 `AGENTS.md`
6. 學會 `/model`、`/permissions`、`/review`、`resume`[^1][^12][^13][^26]

## 16.2 團隊落地路線

1. 在 repo 裡放 `.codex/config.toml`
2. 把 build/test/review 規則寫進 `AGENTS.md`
3. 接 1~2 個真正高價值的 MCP（例如 docs / GitHub / browser）
4. 對 recurring workflow 做 skill
5. 再考慮自動化與 subagent workflows[^15][^17][^26]

## 16.3 CI / automation 路線

1. 用 `codex exec`
2. 用 API key，不要用互動登入
3. 預設 read-only
4. 要改檔時顯式調整 sandbox
5. 若要對接別的工具，用 `--json` 或 `--output-schema`[^12][^14][^23]

---

## 17. 關鍵優點與限制

### 優點

- 安裝入口簡單，但底層是正式維護的 Rust CLI，性能與部署面都較扎實。[^1][^3]
- TUI / exec / MCP / review / subagents / cloud 任務不是拼裝功能，而是有源碼模組支撐的完整平台。[^4][^5][^15][^17][^18][^19]
- 安全模型清楚：sandbox 與 approvals 分開控制。[^22][^23]
- 對進階使用者友善：支援 JSONL、output schema、remote TUI、MCP server、local providers。[^5][^13][^14][^15][^21][^25]

### 限制 / 注意事項

- 官方文件有部分**版本差異**：例如 Windows 支援範圍、`--full-auto` 說法，網站與源碼並不完全同步。[^2][^5][^23][^24]
- 外部程式碼貢獻不是完全開放式；如果你要 upstream 修改，要先走 issue / 受邀流程。[^27]
- Subagents 很強，但成本更高，也更容易把流程搞複雜；官方也明講它會增加 token 消耗。[^17]
- 危險模式 `--yolo` 確實非常危險，不應在不可信 repo 使用。[^7][^23]

---

## 18. Confidence Assessment

### 高信心（幾乎可視為確定）

- Codex CLI 的正式維護核心是 Rust 版 CLI，而 repo 是大型 monorepo。[^3][^18]
- 一般使用者的首選安裝方式是 npm，全域套件名為 `@openai/codex`。[^1][^13]
- 互動式 TUI 與 `codex exec` 是兩條主工作流，並共享大量底層選項。[^5][^6][^7]
- `config.toml` 是核心設定面，且有多層 precedence。[^8][^10]
- sandbox / approval / network 是 Codex 的核心安全模型。[^22][^23]
- MCP 是官方一級能力，Codex 既能當 MCP client，也能當 MCP server。[^3][^15][^16][^21]

### 中信心（來源一致，但文件有版本落差）

- Windows 安裝與 sandbox 的官方最佳路徑，應以新版 Windows 文件為準，而不是 repo 內較保守的 `docs/install.md`。兩者資訊存在明顯時間差。[^2][^24]
- `--full-auto` 在網站文件仍被描述為可用 alias，但源碼已把它當成 deprecated 相容陷阱；因此本報告將「改用顯式 `--sandbox workspace-write`」視為較新的實務建議。[^5][^23]

### 低信心 / 推論

- npm 發行包內部如何包裝 Rust 執行檔，本報告只根據公開 repo 結構、Rust README 與 devcontainer install boundary 做推論，未對 npm registry tarball 內容做解包驗證。因此本報告能確定「安裝入口是 npm、核心維護實作是 Rust」，但不把 npm 包內部細節講得超過公開證據。[^3][^28]

---

## Footnotes

[^1]: [`README.md:13-60`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/README.md#L13-L60) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
[^2]: [`docs/install.md:3-64`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/docs/install.md#L3-L64) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
[^3]: [`codex-rs/README.md:1-105`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/README.md#L1-L105) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
[^4]: [`codex-rs/cli/src/main.rs:71-177`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/cli/src/main.rs#L71-L177), [`codex-rs/cli/src/main.rs:275-446`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/cli/src/main.rs#L275-L446) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
[^5]: [`codex-rs/exec/src/cli.rs:14-107`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/exec/src/cli.rs#L14-L107), [`codex-rs/exec/src/cli.rs:160-293`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/exec/src/cli.rs#L160-L293), [`codex-rs/exec/src/lib.rs:1-4`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/exec/src/lib.rs#L1-L4), [`codex-rs/exec/src/lib.rs:164-320`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/exec/src/lib.rs#L164-L320) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
[^6]: [`codex-rs/tui/src/cli.rs:10-74`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/tui/src/cli.rs#L10-L74), [`codex-rs/tui/src/lib.rs:1-79`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/tui/src/lib.rs#L1-L79) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
[^7]: [`codex-rs/utils/cli/src/shared_options.rs:1-57`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/utils/cli/src/shared_options.rs#L1-L57) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
[^8]: [Codex docs: Config basics](https://developers.openai.com/codex/config-basic) (public docs page, accessed 2026-04-29)
[^9]: [Codex docs: Config reference](https://developers.openai.com/codex/config-reference) (public docs page, accessed 2026-04-29)
[^10]: [`codex-rs/core/src/config/mod.rs:818-910`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/core/src/config/mod.rs#L818-L910), [`codex-rs/core/src/config/mod.rs:1080-1104`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/core/src/config/mod.rs#L1080-L1104), [`codex-rs/core/src/config/mod.rs:2938-2945`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/core/src/config/mod.rs#L2938-L2945) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
[^11]: [`codex-rs/login/src/lib.rs:9-24`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/login/src/lib.rs#L9-L24), [`codex-rs/login/src/lib.rs:39-50`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/login/src/lib.rs#L39-L50), [`codex-rs/login/src/auth/storage.rs:31-87`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/login/src/auth/storage.rs#L31-L87), [`codex-rs/login/src/auth/storage.rs:125-157`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/login/src/auth/storage.rs#L125-L157), [`codex-rs/login/src/auth/storage.rs:160-174`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/login/src/auth/storage.rs#L160-L174), [`codex-rs/login/src/auth/storage.rs:220-290`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/login/src/auth/storage.rs#L220-L290), [`codex-rs/login/src/auth/manager.rs:48-55`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/login/src/auth/manager.rs#L48-L55), [`codex-rs/login/src/auth/manager.rs:93-97`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/login/src/auth/manager.rs#L93-L97), [`codex-rs/login/src/auth/manager.rs:198-253`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/login/src/auth/manager.rs#L198-L253) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
[^12]: [Codex docs: Authentication](https://developers.openai.com/codex/auth) (public docs page, accessed 2026-04-29)
[^13]: [Codex docs: CLI features](https://developers.openai.com/codex/cli/features) (public docs page, accessed 2026-04-29)
[^14]: [Codex docs: Non-interactive mode](https://developers.openai.com/codex/noninteractive) (public docs page, accessed 2026-04-29)
[^15]: [Codex docs: MCP](https://developers.openai.com/codex/mcp) (public docs page, accessed 2026-04-29)
[^16]: [`codex-rs/cli/src/mcp_cmd.rs:31-55`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/cli/src/mcp_cmd.rs#L31-L55), [`codex-rs/cli/src/mcp_cmd.rs:75-157`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/cli/src/mcp_cmd.rs#L75-L157), [`codex-rs/cli/src/mcp_cmd.rs:239-347`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/cli/src/mcp_cmd.rs#L239-L347) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
[^17]: [Codex docs: Subagents](https://developers.openai.com/codex/subagents) (public docs page, accessed 2026-04-29)
[^18]: [`codex-rs/Cargo.toml:1-105`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/Cargo.toml#L1-L105) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
[^19]: [`codex-rs/core/src/lib.rs:1-6`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/core/src/lib.rs#L1-L6), [`codex-rs/core/src/lib.rs:27-55`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/core/src/lib.rs#L27-L55), [`codex-rs/core/src/lib.rs:83-125`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/core/src/lib.rs#L83-L125), [`codex-rs/core/src/lib.rs:151-179`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/core/src/lib.rs#L151-L179), [`codex-rs/core/src/lib.rs:203-204`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/core/src/lib.rs#L203-L204) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
[^20]: [`codex-rs/app-server/src/lib.rs:72-147`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/app-server/src/lib.rs#L72-L147), [`codex-rs/app-server/src/lib.rs:161-229`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/app-server/src/lib.rs#L161-L229) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
[^21]: [`codex-rs/mcp-server/src/lib.rs:1-55`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/mcp-server/src/lib.rs#L1-L55), [`codex-rs/mcp-server/src/lib.rs:59-191`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/mcp-server/src/lib.rs#L59-L191) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
[^22]: [`codex-rs/sandboxing/src/lib.rs:1-21`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/sandboxing/src/lib.rs#L1-L21), [`codex-rs/sandboxing/src/lib.rs:32-47`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/codex-rs/sandboxing/src/lib.rs#L32-L47) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
[^23]: [Codex docs: Agent approvals & security](https://developers.openai.com/codex/agent-approvals-security) (public docs page, accessed 2026-04-29)
[^24]: [Codex docs: Windows setup](https://developers.openai.com/codex/windows) (public docs page, accessed 2026-04-29)
[^25]: [Codex docs: Models](https://developers.openai.com/codex/models) (public docs page, accessed 2026-04-29)
[^26]: [Codex docs: Best practices](https://developers.openai.com/codex/learn/best-practices) (public docs page, accessed 2026-04-29)
[^27]: [`docs/contributing.md:1-72`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/docs/contributing.md#L1-L72) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
[^28]: [`package.json:1-36`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/package.json#L1-L36), [`.devcontainer/codex-install/package.json:1-13`](https://github.com/openai/codex/blob/3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d/.devcontainer/codex-install/package.json#L1-L13) (commit `3d10ba9f36a7c94b2d9413363df6ae5cd22ea09d`)
