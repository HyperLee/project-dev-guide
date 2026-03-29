# GitHub Copilot SDK 深度研究報告

> 研究日期：2026-03-29 | 官方倉庫：[github/copilot-sdk](https://github.com/github/copilot-sdk) | 狀態：Technical Preview (v0.2.0)

---

## Executive Summary

GitHub Copilot SDK 是 GitHub 於 2026 年 1 月 14 日發布的 Technical Preview 產品，讓開發者可以用程式化的方式將 Copilot 的 agentic workflow（代理工作流）嵌入到自己的應用程式中。SDK 支援 Node.js/TypeScript、Python、Go、.NET 四種語言（Java 開發中），透過 JSON-RPC 協議與 Copilot CLI 通訊，提供完整的 AI Agent Runtime：包括多輪對話、工具調用、檔案編輯、串流回應、自定義 Agent、MCP 伺服器整合、Session 持久化等能力。最新穩定版本為 v0.2.0（2026-03-20 發布），帶來了系統提示客製化、OpenTelemetry 支援、Blob 附件等重大更新。[^1][^2][^3]

---

## 目錄

1. [架構概覽](#1-架構概覽)
2. [支援語言與安裝方式](#2-支援語言與安裝方式)
3. [快速開始教學](#3-快速開始教學)
4. [核心概念](#4-核心概念)
5. [認證方式](#5-認證方式)
6. [進階功能](#6-進階功能)
7. [部署架構](#7-部署架構)
8. [版本歷程與最新更新](#8-版本歷程與最新更新)
9. [相關資源與社群](#9-相關資源與社群)
10. [信心評估](#10-信心評估)

---

## 1. 架構概覽

### 核心通訊架構

所有 SDK 都遵循相同的架構模式 — SDK Client 透過 **JSON-RPC** 協議與 Copilot CLI（運行於 server mode）通訊：[^4]

```
┌─────────────────────────┐
│   Your Application      │
│                         │
│   ┌───────────────┐     │
│   │  SDK Client   │     │
│   └───────┬───────┘     │
└───────────┼─────────────┘
            │ JSON-RPC (stdio 或 TCP)
            ▼
┌─────────────────────────┐
│   Copilot CLI           │
│   (Server Mode)         │
│                         │
│   ┌─────────────────┐   │
│   │ JSON-RPC Server │   │
│   ├─────────────────┤   │
│   │ Authentication  │   │
│   ├─────────────────┤   │
│   │ Session Manager │   │
│   ├─────────────────┤   │
│   │ Model Provider  │   │
│   └─────────────────┘   │
└─────────────────────────┘
```

**關鍵設計決策：**

- SDK **不直接**處理 auth token，而是委託給 Copilot CLI，增強安全性[^4]
- SDK 自動管理 CLI 程序的生命週期（也支援連接外部 CLI Server）[^5]
- 透過 `sdk-protocol-version.json` 管理 SDK 與 CLI 之間的協議版本（目前為 v3）[^6]

### 原始碼結構

| 目錄 | 用途 | 主要檔案 |
|------|------|----------|
| `nodejs/src/` | Node.js/TypeScript SDK | `client.ts` (67KB), `session.ts` (36KB), `types.ts` (41KB) |
| `python/copilot/` | Python SDK | `client.py` (91KB), `session.py` (51KB), `tools.py` (8KB) |
| `go/` | Go SDK | `client.go` (51KB), `session.go` (27KB), `types.go` (41KB) |
| `dotnet/src/` | .NET SDK | 基於 `GitHub.Copilot.SDK` 命名空間 |
| `docs/` | 文件 | 完整的 getting-started、auth、features、hooks 等 |
| `test/` | 跨 SDK 測試 | 端對端測試與整合測試 |
| `scripts/` | 建置腳本 | 自動化程式碼生成與發布 |

[^7][^8][^9]

---

## 2. 支援語言與安裝方式

| SDK | 套件名稱 | 安裝指令 | 最低版本要求 |
|-----|---------|---------|-------------|
| **Node.js / TypeScript** | `@github/copilot-sdk` | `npm install @github/copilot-sdk` | Node.js 18+ |
| **Python** | `github-copilot-sdk` | `pip install github-copilot-sdk` | Python 3.8+ |
| **Go** | `github.com/github/copilot-sdk/go` | `go get github.com/github/copilot-sdk/go` | Go 1.21+ |
| **.NET** | `GitHub.Copilot.SDK` | `dotnet add package GitHub.Copilot.SDK` | .NET 8.0+ |
| **Java** | `com.github:copilot-sdk-java` | Maven/Gradle | 開發中 (WIP) |

[^1]

### 前置需求

1. **安裝 Copilot CLI** — 必須獨立安裝 Copilot CLI 並確保 `copilot` 在 PATH 中[^10]
2. **GitHub Copilot 訂閱** — 需要有效的 Copilot 訂閱（除非使用 BYOK 模式）[^1]

```bash
# 驗證 CLI 安裝
copilot --version
```

---

## 3. 快速開始教學

### Step 1：建立專案

#### Node.js / TypeScript

```bash
mkdir copilot-demo && cd copilot-demo
npm init -y --init-type module
npm install @github/copilot-sdk tsx
```

#### Python

```bash
pip install github-copilot-sdk
```

#### Go

```bash
mkdir copilot-demo && cd copilot-demo
go mod init copilot-demo
go get github.com/github/copilot-sdk/go
```

#### .NET

```bash
dotnet new console -n CopilotDemo && cd CopilotDemo
dotnet add package GitHub.Copilot.SDK
```

[^10]

### Step 2：發送第一個訊息

#### Node.js / TypeScript (`index.ts`)

```typescript
import { CopilotClient } from "@github/copilot-sdk";

const client = new CopilotClient();
const session = await client.createSession({ model: "gpt-4.1" });

const response = await session.sendAndWait({ prompt: "What is 2 + 2?" });
console.log(response?.data.content);

await client.stop();
process.exit(0);
```

```bash
npx tsx index.ts
```

#### Python (`main.py`)

```python
import asyncio
from copilot import CopilotClient
from copilot.session import PermissionHandler

async def main():
    client = CopilotClient()
    await client.start()

    session = await client.create_session(
        on_permission_request=PermissionHandler.approve_all,
        model="gpt-4.1"
    )
    response = await session.send_and_wait("What is 2 + 2?")
    print(response.data.content)

    await client.stop()

asyncio.run(main())
```

#### Go (`main.go`)

```go
package main

import (
    "context"
    "fmt"
    "log"
    "os"

    copilot "github.com/github/copilot-sdk/go"
)

func main() {
    ctx := context.Background()
    client := copilot.NewClient(nil)
    if err := client.Start(ctx); err != nil {
        log.Fatal(err)
    }
    defer client.Stop()

    session, err := client.CreateSession(ctx, &copilot.SessionConfig{Model: "gpt-4.1"})
    if err != nil {
        log.Fatal(err)
    }

    response, err := session.SendAndWait(ctx, copilot.MessageOptions{Prompt: "What is 2 + 2?"})
    if err != nil {
        log.Fatal(err)
    }

    fmt.Println(*response.Data.Content)
    os.Exit(0)
}
```

#### .NET (`Program.cs`)

```csharp
using GitHub.Copilot.SDK;

await using var client = new CopilotClient();
await using var session = await client.CreateSessionAsync(
    new SessionConfig { Model = "gpt-4.1" });

var response = await session.SendAndWaitAsync(
    new MessageOptions { Prompt = "What is 2 + 2?" });
Console.WriteLine(response?.Data.Content);
```

[^10]

### Step 3：串流回應 (Streaming)

#### Node.js / TypeScript

```typescript
import { CopilotClient } from "@github/copilot-sdk";

const client = new CopilotClient();
const session = await client.createSession({
    model: "gpt-4.1",
    streaming: true,
});

// 監聽回應片段
session.on("assistant.message_delta", (event) => {
    process.stdout.write(event.data.deltaContent);
});
session.on("session.idle", () => {
    console.log(); // 完成時換行
});

await session.sendAndWait({ prompt: "Tell me a short joke" });
await client.stop();
process.exit(0);
```

#### Python

```python
import asyncio
import sys
from copilot import CopilotClient
from copilot.session import PermissionHandler
from copilot.generated.session_events import SessionEventType

async def main():
    client = CopilotClient()
    await client.start()

    session = await client.create_session(
        on_permission_request=PermissionHandler.approve_all,
        model="gpt-4.1",
        streaming=True
    )

    def handle_event(event):
        if event.type == SessionEventType.ASSISTANT_MESSAGE_DELTA:
            sys.stdout.write(event.data.delta_content)
            sys.stdout.flush()
        if event.type == SessionEventType.SESSION_IDLE:
            print()

    session.on(handle_event)
    await session.send_and_wait("Tell me a short joke")
    await client.stop()

asyncio.run(main())
```

[^10]

### Step 4：自定義工具 (Custom Tools)

SDK 的強大之處在於你可以定義自己的工具讓 Copilot 在對話中調用：

#### Node.js / TypeScript

```typescript
import { CopilotClient, defineTool } from "@github/copilot-sdk";

const weatherTool = defineTool("get_weather", {
    description: "Get the current weather for a location",
    parameters: {
        type: "object",
        properties: {
            location: { type: "string", description: "City name" },
        },
        required: ["location"],
    },
    handler: async ({ location }) => {
        // 你的 API 呼叫邏輯
        return `Weather in ${location}: 72°F and sunny`;
    },
});

const client = new CopilotClient();
const session = await client.createSession({
    model: "gpt-4.1",
    tools: [weatherTool],
    onPermissionRequest: async () => ({ kind: "approved" }),
});

const response = await session.sendAndWait({
    prompt: "What's the weather like in Seattle?"
});
console.log(response?.data.content);
```

#### Python

```python
from copilot import CopilotClient
from copilot.tools import define_tool
from copilot.session import PermissionHandler

weather_tool = define_tool(
    "get_weather",
    description="Get the current weather for a location",
    parameters={
        "type": "object",
        "properties": {
            "location": {"type": "string", "description": "City name"},
        },
        "required": ["location"],
    },
    handler=lambda location: f"Weather in {location}: 72°F and sunny",
)

async def main():
    client = CopilotClient()
    await client.start()

    session = await client.create_session(
        on_permission_request=PermissionHandler.approve_all,
        model="gpt-4.1",
        tools=[weather_tool],
    )

    response = await session.send_and_wait("What's the weather in Seattle?")
    print(response.data.content)
    await client.stop()
```

[^10]

---

## 4. 核心概念

### 4.1 Client 與 Session

- **CopilotClient** — SDK 的入口點，負責管理 CLI 程序生命週期與建立 Session[^7]
- **Session** — 一個對話上下文，包含對話歷史、工具狀態、計劃上下文。支援建立、恢復、持久化[^11]

```
CopilotClient
  ├── start()           → 啟動 CLI 程序
  ├── createSession()   → 建立新 Session
  ├── resumeSession()   → 恢復已存在的 Session
  ├── listSessions()    → 列出所有 Session
  ├── deleteSession()   → 永久刪除 Session
  ├── listModels()      → 列出可用模型
  └── stop()            → 停止 CLI 程序

Session
  ├── send()            → 發送訊息（非阻塞）
  ├── sendAndWait()     → 發送訊息並等待完成
  ├── on()              → 訂閱事件
  ├── setModel()        → 切換模型
  ├── disconnect()      → 斷開連線（保留磁碟資料）
  └── rpc.*             → 低階 RPC 方法
```

### 4.2 事件系統 (Streaming Events)

SDK 提供 40+ 種事件類型，可以即時監聽 Agent 的每一個動作：[^12]

| 事件類型 | 說明 |
|---------|------|
| `assistant.message` | 完整的助手回應 |
| `assistant.message_delta` | 串流回應的增量片段 |
| `tool.execution_start` | 工具開始執行 |
| `tool.execution_complete` | 工具執行完成 |
| `permission.requested` | 權限請求（如執行 shell 命令） |
| `session.idle` | Session 進入閒置狀態 |
| `session.start` | Session 開始 |
| `system.notification` | 系統通知 |

### 4.3 權限管理 (Permissions)

預設情況下，SDK 以 `--allow-all` 模式運行，啟用所有第一方工具（包括檔案系統操作、Git 操作、網路請求）。你可以透過 `onPermissionRequest` hook 自訂權限邏輯：[^1]

```typescript
// 全部批准
onPermissionRequest: async () => ({ kind: "approved" })

// 選擇性批准
onPermissionRequest: async (request, invocation) => {
    if (request.toolName === "shell_exec") {
        return { kind: "denied-interactively-by-user" };
    }
    return { kind: "approved" };
}
```

---

## 5. 認證方式

SDK 支援多種認證方式，適應不同部署場景：[^13]

| 方法 | 適用場景 | 需要 Copilot 訂閱 |
|------|---------|------------------|
| **GitHub 登入用戶** | 桌面應用、開發環境 | ✅ 是 |
| **OAuth GitHub App** | Web 應用、SaaS | ✅ 是 |
| **環境變數** | CI/CD、自動化、伺服器 | ✅ 是 |
| **BYOK (自帶金鑰)** | 自管模型、企業部署 | ❌ 否 |

### 認證優先順序

```
1. 明確傳入的 githubToken
2. HMAC key (CAPI_HMAC_KEY / COPILOT_HMAC_KEY)
3. Direct API token (GITHUB_COPILOT_API_TOKEN + COPILOT_API_URL)
4. 環境變數 token (COPILOT_GITHUB_TOKEN → GH_TOKEN → GITHUB_TOKEN)
5. 儲存的 OAuth 憑證（copilot CLI login）
6. GitHub CLI 憑證（gh auth）
```

[^13]

### BYOK (Bring Your Own Key)

BYOK 讓你無需 GitHub Copilot 訂閱即可使用 SDK，支援多種 Provider：[^14]

| Provider | type 值 | 說明 |
|----------|---------|------|
| OpenAI | `"openai"` | OpenAI API 與相容端點 |
| Azure OpenAI / AI Foundry | `"azure"` | Azure 託管模型 |
| Anthropic | `"anthropic"` | Claude 模型 |
| Ollama | `"openai"` | 本地模型（OpenAI 相容 API） |
| Microsoft Foundry Local | `"openai"` | 本地裝置上的 AI 模型 |

**BYOK 使用範例（Node.js）：**

```typescript
const session = await client.createSession({
    model: "gpt-5.2-codex",
    provider: {
        type: "openai",
        baseUrl: "https://api.openai.com/v1",
        apiKey: process.env.OPENAI_API_KEY,
    },
});
```

**BYOK 限制：**
- ❌ 不支援 Microsoft Entra ID（Azure AD）
- ❌ 不支援第三方身份提供者（OIDC、SAML）
- ❌ 不支援 Azure Managed Identity
- 只支援 API Key 或靜態 Bearer Token[^14]

---

## 6. 進階功能

### 6.1 Hooks（鉤子）

Hooks 讓你在 Session 的每個階段插入自定義邏輯：[^15]

| Hook | 用途 |
|------|------|
| `onPermissionRequest` | 控制工具執行權限 — 批准、拒絕或修改 |
| `preToolUse` | 在工具調用前攔截 — 修改參數或取消 |
| `postToolUse` | 在工具完成後攔截 — 轉換結果 |
| `onUserPromptSubmitted` | 修改或過濾用戶訊息 |
| `onSessionStart` / `onSessionEnd` | Session 生命週期事件 |
| `onError` | 自定義錯誤處理 |

### 6.2 Custom Agents（自定義代理）

定義具有專屬工具和提示的子代理：[^16]

```typescript
const session = await client.createSession({
    customAgents: [
        {
            name: "researcher",
            prompt: "You are a research assistant.",
        },
        {
            name: "editor",
            prompt: "You are a code editor.",
        },
    ],
    agent: "researcher", // 預選代理
    onPermissionRequest: approveAll,
});
```

### 6.3 MCP Server 整合

整合 Model Context Protocol (MCP) 伺服器以擴展 Copilot 的能力：[^17]

```typescript
const session = await client.createSession({
    model: "gpt-5",
    mcpServers: {
        // 本地 MCP 伺服器
        "filesystem": {
            type: "local",
            command: "npx",
            args: ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"],
            tools: ["*"],
        },
        // 遠端 MCP 伺服器
        "github": {
            type: "http",
            url: "https://api.githubcopilot.com/mcp/",
            headers: { "Authorization": "Bearer ${TOKEN}" },
            tools: ["*"],
        },
    },
});
```

支援兩種類型：
- **Local/Stdio** — 作為子程序運行，透過 stdin/stdout 通訊
- **HTTP/SSE** — 遠端伺服器，透過 HTTP 存取[^17]

### 6.4 Skills（技能）

Skills 是可重用的 prompt 模組，從目錄載入以賦予 Copilot 特定領域的能力：[^18]

```
skills/
├── code-review/
│   └── SKILL.md      ← 包含 YAML frontmatter + Markdown 指令
└── documentation/
    └── SKILL.md
```

```typescript
const session = await client.createSession({
    skillDirectories: ["./skills"],
    disabledSkills: ["experimental-feature"],
});
```

### 6.5 Session 持久化

透過提供自定義 `sessionId`，Session 可以跨重啟、跨容器恢復：[^11]

```typescript
// 建立可恢復的 Session
const session = await client.createSession({
    sessionId: "user-123-task-456",
    model: "gpt-5.2-codex",
});

// 之後恢復（甚至可以在不同的 client 實例）
const resumed = await client.resumeSession("user-123-task-456");
await resumed.sendAndWait({ prompt: "What did we discuss earlier?" });
```

**持久化內容：**
- ✅ 對話歷史、工具調用結果、Agent 計劃狀態、Session 產物
- ❌ Provider/API Key（安全性考量，恢復時需重新提供）

### 6.6 System Prompt 客製化（v0.2.0 新增）

新的 `"customize"` 模式讓你可以精確編輯系統提示的各個部分：[^19]

```typescript
const session = await client.createSession({
    systemMessage: {
        mode: "customize",
        sections: {
            identity: {
                action: (current) =>
                    current.replace("GitHub Copilot", "Acme Assistant"),
            },
            tone: {
                action: "replace",
                content: "Be concise and professional."
            },
            code_change_rules: { action: "remove" },
        },
    },
});
```

可配置的 10 個區段：`identity`、`tone`、`tool_efficiency`、`environment_context`、`code_change_rules`、`guidelines`、`safety`、`tool_instructions`、`custom_instructions`、`last_instructions`[^19]

### 6.7 OpenTelemetry 追蹤

所有四個 SDK 語言都支援分散式追蹤：[^20]

```typescript
const client = new CopilotClient({
    telemetry: {
        otlpEndpoint: "http://localhost:4318",
        sourceName: "my-app",
    },
});
```

支援 W3C Trace Context 自動傳播，在 `session.create`、`session.resume`、`session.send` 操作上自動附加追蹤上下文[^20]

### 6.8 圖片輸入與 Blob 附件（v0.2.0 新增）

```typescript
await session.send({
    prompt: "What's in this image?",
    attachments: [
        { type: "blob", data: base64Str, mimeType: "image/png" }
    ],
});
```

[^19]

---

## 7. 部署架構

### 7.1 本地開發（Auto-managed CLI）

最簡單的方式 — SDK 自動管理 CLI 程序：

```typescript
// SDK 自動 spawn CLI 程序
const client = new CopilotClient();
```

### 7.2 後端服務（External CLI Server）

CLI 以 headless server 模式運行，SDK 透過 TCP 連接：[^21]

```bash
# 啟動 headless CLI
copilot --headless --port 4321
```

```typescript
// SDK 連接到外部 CLI Server
const client = new CopilotClient({
    cliUrl: "localhost:4321",
});
```

### 7.3 Docker Compose 部署

```yaml
version: "3.8"
services:
  copilot-cli:
    image: ghcr.io/github/copilot-cli:latest
    command: ["--headless", "--port", "4321"]
    environment:
      - COPILOT_GITHUB_TOKEN=${COPILOT_GITHUB_TOKEN}
    ports:
      - "4321:4321"
    restart: always
    volumes:
      - session-data:/root/.copilot/session-state

  api:
    build: .
    environment:
      - CLI_URL=copilot-cli:4321
    depends_on:
      - copilot-cli
    ports:
      - "3000:3000"

volumes:
  session-data:
```

[^21]

### 7.4 擴展與多租戶

```
推薦模式 1：每用戶一個 CLI Server（強隔離）
┌──────────┐   ┌────────┐
│ User A   │──▶│ CLI A  │──▶ Storage A
│ User B   │──▶│ CLI B  │──▶ Storage B
│ User C   │──▶│ CLI C  │──▶ Storage C
└──────────┘   └────────┘

推薦模式 2：共享 CLI Server（資源高效）
┌──────────┐   ┌────────────────┐
│ User A   │──▶│               │──▶ Session A
│ User B   │──▶│  共享 CLI     │──▶ Session B
│ User C   │──▶│               │──▶ Session C
└──────────┘   └────────────────┘
```

[^22]

---

## 8. 版本歷程與最新更新

### v0.2.0（2026-03-20）— 最新穩定版

重大更新包括：[^19]

**新功能：**
- ✨ 細粒度系統提示客製化（`systemMessage` `customize` 模式）
- ✨ 全 SDK OpenTelemetry 支援
- ✨ Blob 附件（inline binary data）
- ✨ 建立 Session 時預選 Custom Agent
- ✨ `skipPermission` 工具定義選項
- ✨ `reasoningEffort` 模型切換參數
- ✨ 自定義模型列表（BYOK）
- ✨ Node.js CJS 相容性
- ✨ 實驗性 API 標註

**新增 RPC 方法：**
- `session.rpc.skills.list()` / `.enable()` / `.disable()` / `.reload()`
- `session.rpc.mcp.list()` / `.enable()` / `.disable()` / `.reload()`
- `session.rpc.extensions.list()` / `.enable()` / `.disable()` / `.reload()`
- `session.rpc.ui.elicitation(...)` — 結構化使用者輸入
- `session.rpc.shell.exec()` / `.kill()`

**⚠️ 破壞性變更：**
- Python：`CopilotClient` 建構子重新設計（`TypedDict` → 關鍵字引數 + dataclass）
- Python：`send()` 接受位置引數字串（不再需要 `{"prompt": "..."}` dict）
- Go：`Client.Start()` context 不再殺掉 CLI 程序
- 所有 SDK：`autoRestart` 已棄用

### v0.1.31-32（2026-03-07）

- 協議 v3：多客戶端工具與權限廣播
- 向後相容 v2 CLI Server[^23]

### v0.1.30（2026-03-03）

- 支援覆寫內建工具（`overridesBuiltInTool`）
- 簡化的 `session.setModel()` API[^24]

---

## 9. 相關資源與社群

### 官方資源

| 資源 | 連結 |
|------|------|
| 官方 GitHub 倉庫 | [github/copilot-sdk](https://github.com/github/copilot-sdk) |
| 官方文件首頁 | [GitHub Docs - Copilot SDK](https://docs.github.com/en/copilot/how-tos/copilot-sdk) |
| Getting Started 教學 | [docs/getting-started.md](https://github.com/github/copilot-sdk/blob/main/docs/getting-started.md) |
| Cookbook（實用範例） | [github/awesome-copilot - cookbook](https://github.com/github/awesome-copilot/blob/main/cookbook/copilot-sdk) |
| Java SDK | [github/copilot-sdk-java](https://github.com/github/copilot-sdk-java) |
| Copilot 開發指令集 | [awesome-copilot/instructions](https://github.com/github/awesome-copilot/blob/main/instructions/) |
| 發布公告 | [GitHub Changelog - SDK Technical Preview](https://github.blog/changelog/2026-01-14-copilot-sdk-in-technical-preview/) |
| Blog 文章 | [Build an Agent into Any App](https://github.blog/news-insights/company-news/build-an-agent-into-any-app-with-the-github-copilot-sdk/) |

### 非官方 / 社群 SDK

| SDK | 倉庫 |
|-----|------|
| Rust | [copilot-community-sdk/copilot-sdk-rust](https://github.com/copilot-community-sdk/copilot-sdk-rust) |
| Clojure | [copilot-community-sdk/copilot-sdk-clojure](https://github.com/copilot-community-sdk/copilot-sdk-clojure) |
| C++ | [0xeb/copilot-sdk-cpp](https://github.com/0xeb/copilot-sdk-cpp) |

[^1]

### 外部文章與教學

| 文章 | 來源 |
|------|------|
| [Building Agents with GitHub Copilot SDK](https://techcommunity.microsoft.com/blog/azuredevcommunityblog/building-agents-with-github-copilot-sdk-a-practical-guide-to-automated-tech-upda/4488948) | Microsoft Tech Community |
| [GitHub Copilot SDK Lets Developers Integrate Copilot CLI's Agent Runtime](https://www.infoq.com/news/2026/02/github-copilot-sdk/) | InfoQ |
| [The GitHub Copilot SDK: Agents for Every App](https://htek.dev/articles/github-copilot-sdk-agents-for-every-app/) | htek.dev |
| [GitHub Copilot Evolves: SDK Launch, Agentic Memory & New AI Models](https://dev.to/dharani0419/github-copilot-evolves-sdk-launch-agentic-memory-new-ai-models-february-2026-update-35g9) | DEV Community |

### 計費說明

SDK 使用量與 Copilot CLI 相同計費模式，每個 prompt 計入 **premium request 配額**。使用 BYOK 時不消耗 Copilot 配額，計費由你的 model provider 處理。[^1]

---

## 10. 信心評估

| 項目 | 信心等級 | 說明 |
|------|---------|------|
| 架構與通訊協議 | 🟢 高 | 直接來自官方 README 與文件 |
| 安裝與快速開始 | 🟢 高 | 直接來自 getting-started.md 與各 SDK README |
| 認證方式 | 🟢 高 | 直接來自 auth/index.md 與 byok.md |
| 進階功能（Hooks, Agents, MCP, Skills） | 🟢 高 | 直接來自 docs/features/ 下各文件 |
| 版本歷程與變更 | 🟢 高 | 直接來自 CHANGELOG.md |
| 部署模式 | 🟢 高 | 直接來自 setup/ 下的文件 |
| 計費模式 | 🟡 中 | FAQ 中提及，但詳細定價需參考 GitHub 官方頁面 |
| Java SDK 成熟度 | 🟡 中 | 標示為 WIP，功能完整度未確認 |
| Production Readiness | 🟡 中 | 官方明確標示為 Technical Preview，不建議用於生產 |

---

## Footnotes

[^1]: [`README.md`](https://github.com/github/copilot-sdk/blob/main/README.md) — GitHub Copilot SDK 主要 README
[^2]: [GitHub Blog - Build an agent into any app with the GitHub Copilot SDK](https://github.blog/news-insights/company-news/build-an-agent-into-any-app-with-the-github-copilot-sdk/)
[^3]: [GitHub Changelog - Copilot SDK in technical preview](https://github.blog/changelog/2026-01-14-copilot-sdk-in-technical-preview/)
[^4]: [`docs/setup/index.md`](https://github.com/github/copilot-sdk/blob/main/docs/setup/index.md) — 架構說明
[^5]: [`docs/setup/backend-services.md`](https://github.com/github/copilot-sdk/blob/main/docs/setup/backend-services.md) — 後端服務設定
[^6]: [`sdk-protocol-version.json`](https://github.com/github/copilot-sdk/blob/main/sdk-protocol-version.json) — 協議版本定義
[^7]: [`nodejs/src/client.ts`](https://github.com/github/copilot-sdk/blob/main/nodejs/src/client.ts) — Node.js SDK Client 實作 (67KB)
[^8]: [`python/copilot/client.py`](https://github.com/github/copilot-sdk/blob/main/python/copilot/client.py) — Python SDK Client 實作 (91KB)
[^9]: [`go/client.go`](https://github.com/github/copilot-sdk/blob/main/go/client.go) — Go SDK Client 實作 (51KB)
[^10]: [`docs/getting-started.md`](https://github.com/github/copilot-sdk/blob/main/docs/getting-started.md) — Getting Started 完整教學
[^11]: [`docs/features/session-persistence.md`](https://github.com/github/copilot-sdk/blob/main/docs/features/session-persistence.md) — Session 持久化文件
[^12]: [`docs/features/streaming-events.md`](https://github.com/github/copilot-sdk/blob/main/docs/features/streaming-events.md) — 串流事件參考
[^13]: [`docs/auth/index.md`](https://github.com/github/copilot-sdk/blob/main/docs/auth/index.md) — 認證概覽
[^14]: [`docs/auth/byok.md`](https://github.com/github/copilot-sdk/blob/main/docs/auth/byok.md) — BYOK 文件
[^15]: [`docs/features/hooks.md`](https://github.com/github/copilot-sdk/blob/main/docs/features/hooks.md) — Hooks 功能文件
[^16]: [`docs/features/custom-agents.md`](https://github.com/github/copilot-sdk/blob/main/docs/features/custom-agents.md) — 自定義 Agent 文件
[^17]: [`docs/features/mcp.md`](https://github.com/github/copilot-sdk/blob/main/docs/features/mcp.md) — MCP 伺服器整合
[^18]: [`docs/features/skills.md`](https://github.com/github/copilot-sdk/blob/main/docs/features/skills.md) — Skills 技能文件
[^19]: [`CHANGELOG.md` - v0.2.0](https://github.com/github/copilot-sdk/blob/main/CHANGELOG.md) — v0.2.0 更新日誌
[^20]: [`docs/observability/opentelemetry.md`](https://github.com/github/copilot-sdk/blob/main/docs/observability/opentelemetry.md) — OpenTelemetry 文件
[^21]: [`docs/setup/backend-services.md`](https://github.com/github/copilot-sdk/blob/main/docs/setup/backend-services.md) — 後端服務部署
[^22]: [`docs/setup/index.md`](https://github.com/github/copilot-sdk/blob/main/docs/setup/index.md) — 擴展與多租戶
[^23]: [`CHANGELOG.md` - v0.1.31-32](https://github.com/github/copilot-sdk/blob/main/CHANGELOG.md) — 協議 v3 更新
[^24]: [`CHANGELOG.md` - v0.1.30](https://github.com/github/copilot-sdk/blob/main/CHANGELOG.md) — 工具覆寫功能
