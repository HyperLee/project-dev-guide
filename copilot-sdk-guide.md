# GitHub Copilot SDK 深度整理與教學文件

> 最後更新：2026-03-29 | 官方倉庫：[github/copilot-sdk](https://github.com/github/copilot-sdk)
>
> 狀態：**Technical Preview** (v0.2.0) — 2026 年 1 月 14 日發布

---

## 什麼是 GitHub Copilot SDK？

GitHub Copilot SDK 是 GitHub 官方提供的多語言 SDK，讓開發者可以**將 Copilot 的 AI Agent Runtime 以程式化方式嵌入到任何應用程式中**。它暴露了與 Copilot CLI 相同的代理引擎 — 你只需定義 Agent 行為，Copilot 處理規劃 (planning)、工具調用 (tool invocation)、檔案編輯等所有複雜的編排工作。

### 核心特色

- 🏗️ **生產級 Agent Loop** — 開箱即用的多輪對話、工具編排、上下文管理
- 🌐 **多語言支援** — Node.js/TypeScript、Python、Go、.NET（Java 開發中）
- 🔌 **自定義工具** — 註冊你自己的函數讓 Copilot 調用
- 📡 **即時串流** — 逐步接收 AI 回應
- 🤖 **自定義 Agent** — 定義專屬子代理
- 🔧 **MCP 整合** — 連接 Model Context Protocol 伺服器
- 🔑 **BYOK** — 自帶 API Key，支援 OpenAI、Azure、Anthropic、Ollama 等
- 📊 **OpenTelemetry** — 內建分散式追蹤支援

---

## 架構概覽

```
┌─────────────────────┐
│   你的應用程式       │
│  ┌───────────────┐  │
│  │  SDK Client   │  │
│  └───────┬───────┘  │
└──────────┼──────────┘
           │ JSON-RPC (stdio 或 TCP)
           ▼
┌─────────────────────┐
│  Copilot CLI        │
│  (Server Mode)      │
│                     │
│  • JSON-RPC Server  │
│  • 認證管理          │
│  • Session 管理      │
│  • 模型路由          │
│  • 工具執行          │
└─────────────────────┘
```

**設計重點：**
- SDK 透過 JSON-RPC 與 Copilot CLI 通訊
- SDK 不直接處理 auth token — 委託給 CLI 處理，增強安全性
- SDK 自動管理 CLI 程序生命週期（也支援連接外部 CLI Server）
- 協議版本管理確保 SDK 與 CLI 相容性

---

## 安裝指南

### 前置需求

1. **安裝 Copilot CLI** — 請參考 [安裝指南](https://docs.github.com/en/copilot/how-tos/set-up/install-copilot-cli)
2. **GitHub Copilot 訂閱**（使用 BYOK 時可免）
3. 對應語言的 runtime：Node.js 18+、Python 3.8+、Go 1.21+、.NET 8.0+

```bash
# 驗證 CLI 安裝
copilot --version
```

### SDK 安裝

| 語言 | 安裝指令 |
|------|---------|
| Node.js / TypeScript | `npm install @github/copilot-sdk` |
| Python | `pip install github-copilot-sdk` |
| Go | `go get github.com/github/copilot-sdk/go` |
| .NET | `dotnet add package GitHub.Copilot.SDK` |
| Java (WIP) | Maven: `com.github:copilot-sdk-java` |

---

## 快速開始：四種語言範例

### Node.js / TypeScript

```bash
mkdir copilot-demo && cd copilot-demo
npm init -y --init-type module
npm install @github/copilot-sdk tsx
```

建立 `index.ts`：

```typescript
import { CopilotClient } from "@github/copilot-sdk";

const client = new CopilotClient();
const session = await client.createSession({ model: "gpt-4.1" });

const response = await session.sendAndWait({ prompt: "用一句話解釋什麼是 REST API" });
console.log(response?.data.content);

await client.stop();
process.exit(0);
```

```bash
npx tsx index.ts
```

### Python

```bash
pip install github-copilot-sdk
```

建立 `main.py`：

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
    response = await session.send_and_wait("用一句話解釋什麼是 REST API")
    print(response.data.content)

    await client.stop()

asyncio.run(main())
```

### Go

```bash
mkdir copilot-demo && cd copilot-demo
go mod init copilot-demo
go get github.com/github/copilot-sdk/go
```

建立 `main.go`：

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

    response, err := session.SendAndWait(ctx, copilot.MessageOptions{
        Prompt: "用一句話解釋什麼是 REST API",
    })
    if err != nil {
        log.Fatal(err)
    }

    fmt.Println(*response.Data.Content)
    os.Exit(0)
}
```

### .NET (C#)

```bash
dotnet new console -n CopilotDemo && cd CopilotDemo
dotnet add package GitHub.Copilot.SDK
```

`Program.cs`：

```csharp
using GitHub.Copilot.SDK;

await using var client = new CopilotClient();
await using var session = await client.CreateSessionAsync(
    new SessionConfig { Model = "gpt-4.1" });

var response = await session.SendAndWaitAsync(
    new MessageOptions { Prompt = "用一句話解釋什麼是 REST API" });
Console.WriteLine(response?.Data.Content);
```

---

## 串流回應 (Streaming)

即時接收 AI 的回應片段，不需等到整個回應完成：

### TypeScript 範例

```typescript
import { CopilotClient } from "@github/copilot-sdk";

const client = new CopilotClient();
const session = await client.createSession({
    model: "gpt-4.1",
    streaming: true,
});

session.on("assistant.message_delta", (event) => {
    process.stdout.write(event.data.deltaContent);
});
session.on("session.idle", () => {
    console.log();
});

await session.sendAndWait({ prompt: "講一個程式設計師的笑話" });
await client.stop();
```

### Python 範例

```python
from copilot.generated.session_events import SessionEventType

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
await session.send_and_wait("講一個程式設計師的笑話")
```

---

## 自定義工具 (Custom Tools)

讓 Copilot 呼叫你的函數 — 這是 SDK 最強大的功能之一：

### TypeScript 範例

```typescript
import { CopilotClient, defineTool } from "@github/copilot-sdk";

// 定義一個查詢天氣的工具
const weatherTool = defineTool("get_weather", {
    description: "Get current weather for a city",
    parameters: {
        type: "object",
        properties: {
            city: { type: "string", description: "City name" },
        },
        required: ["city"],
    },
    handler: async ({ city }) => {
        // 在這裡呼叫你的 API
        return `Weather in ${city}: 25°C, sunny`;
    },
});

const client = new CopilotClient();
const session = await client.createSession({
    model: "gpt-4.1",
    tools: [weatherTool],
    onPermissionRequest: async () => ({ kind: "approved" }),
});

const res = await session.sendAndWait({
    prompt: "What's the weather in Taipei?"
});
console.log(res?.data.content);
```

### .NET 範例

```csharp
using GitHub.Copilot.SDK;
using Microsoft.Extensions.AI;

// 使用 AIFunctionFactory 建立工具
var weatherTool = AIFunctionFactory.Create(
    ([Description("City name")] string city) => $"Weather in {city}: 25°C, sunny",
    "get_weather",
    "Get current weather for a city"
);

await using var session = await client.CreateSessionAsync(new SessionConfig
{
    Model = "gpt-4.1",
    Tools = [weatherTool],
    OnPermissionRequest = (req, inv) =>
        Task.FromResult(new PermissionRequestResult
        { Kind = PermissionRequestResultKind.Approved }),
});

var response = await session.SendAndWaitAsync(
    new MessageOptions { Prompt = "What's the weather in Taipei?" });
Console.WriteLine(response?.Data.Content);
```

---

## 認證方式

| 方法 | 適用場景 | 需 Copilot 訂閱 |
|------|---------|-----------------|
| **GitHub 登入用戶** | 桌面應用、本地開發 | ✅ |
| **OAuth GitHub App** | Web 應用、SaaS 產品 | ✅ |
| **環境變數** | CI/CD、伺服器端自動化 | ✅ |
| **BYOK (自帶金鑰)** | 企業自管模型、無需 GitHub 帳號 | ❌ |

### 環境變數認證（最簡單）

```bash
export COPILOT_GITHUB_TOKEN="your-token"
# 或 GH_TOKEN / GITHUB_TOKEN
```

```typescript
// SDK 自動偵測環境變數
const client = new CopilotClient();
```

### BYOK 範例（使用 OpenAI）

```typescript
const session = await client.createSession({
    model: "gpt-4.1",
    provider: {
        type: "openai",
        baseUrl: "https://api.openai.com/v1",
        apiKey: process.env.OPENAI_API_KEY,
    },
});
```

### BYOK 支援的 Provider

| Provider | type 值 | 說明 |
|----------|---------|------|
| OpenAI | `"openai"` | OpenAI 與相容端點 |
| Azure AI Foundry | `"azure"` | Azure 託管模型 |
| Anthropic | `"anthropic"` | Claude 系列 |
| Ollama | `"openai"` | 本地模型 |
| Microsoft Foundry Local | `"openai"` | 本地裝置模型 |

---

## 進階功能

### 1. Hooks（生命週期鉤子）

在 Session 每個階段插入自定義邏輯：

| Hook | 用途 |
|------|------|
| `onPermissionRequest` | 控制工具執行權限 |
| `preToolUse` | 工具調用前攔截、修改參數 |
| `postToolUse` | 工具完成後攔截、轉換結果 |
| `onUserPromptSubmitted` | 修改用戶訊息 |
| `onSessionStart/End` | Session 生命週期事件 |
| `onError` | 自定義錯誤處理 |

### 2. Custom Agents（自定義子代理）

```typescript
const session = await client.createSession({
    customAgents: [
        { name: "researcher", prompt: "You are a research assistant." },
        { name: "coder", prompt: "You are a code expert." },
    ],
    agent: "researcher", // 預選代理
});
```

### 3. MCP Server 整合

連接 Model Context Protocol 伺服器擴展能力：

```typescript
const session = await client.createSession({
    mcpServers: {
        filesystem: {
            type: "local",
            command: "npx",
            args: ["-y", "@modelcontextprotocol/server-filesystem", "/tmp"],
            tools: ["*"],
        },
    },
});
```

### 4. Skills（可重用技能模組）

從目錄載入 `SKILL.md` 檔案，注入領域知識：

```
skills/
├── code-review/
│   └── SKILL.md
└── security/
    └── SKILL.md
```

```typescript
const session = await client.createSession({
    skillDirectories: ["./skills"],
});
```

### 5. Session 持久化

Session 可以跨重啟恢復：

```typescript
// 建立可恢復的 Session
const session = await client.createSession({
    sessionId: "user-123-task-456",
});

// 之後恢復
const resumed = await client.resumeSession("user-123-task-456");
```

### 6. System Prompt 客製化 (v0.2.0)

精確編輯系統提示的各個區段：

```typescript
const session = await client.createSession({
    systemMessage: {
        mode: "customize",
        sections: {
            identity: {
                action: (current) =>
                    current.replace("GitHub Copilot", "我的 AI 助手"),
            },
            tone: {
                action: "replace",
                content: "使用繁體中文，語氣專業簡潔。"
            },
        },
    },
});
```

可配置區段：`identity`、`tone`、`tool_efficiency`、`environment_context`、`code_change_rules`、`guidelines`、`safety`、`tool_instructions`、`custom_instructions`、`last_instructions`

### 7. OpenTelemetry 追蹤

```typescript
const client = new CopilotClient({
    telemetry: {
        otlpEndpoint: "http://localhost:4318",
        sourceName: "my-app",
    },
});
```

---

## 部署模式

### 模式 1：本地開發（Auto-managed CLI）

```typescript
// 最簡單 — SDK 自動 spawn CLI 程序
const client = new CopilotClient();
```

### 模式 2：後端服務（External CLI Server）

```bash
# 啟動 headless CLI
copilot --headless --port 4321
```

```typescript
// 連接到外部 CLI Server
const client = new CopilotClient({
    cliUrl: "localhost:4321",
});
```

### 模式 3：Docker Compose

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
    volumes:
      - session-data:/root/.copilot/session-state

  api:
    build: .
    environment:
      - CLI_URL=copilot-cli:4321
    depends_on:
      - copilot-cli

volumes:
  session-data:
```

---

## 版本歷程

| 版本 | 日期 | 重點更新 |
|------|------|---------|
| **v0.2.0** | 2026-03-20 | System Prompt 客製化、OpenTelemetry、Blob 附件、預選 Agent |
| v0.1.32 | 2026-03-07 | 向後相容 v2 CLI Server |
| v0.1.31 | 2026-03-07 | 協議 v3、多客戶端工具廣播 |
| v0.1.30 | 2026-03-03 | 覆寫內建工具、`session.setModel()` |
| 初始發布 | 2026-01-14 | Technical Preview 公開發布 |

### v0.2.0 破壞性變更注意

- **Python**：`CopilotClient` 建構子從 `TypedDict` 改為 `keyword arguments + dataclass`
- **Python**：`send()` 直接接受字串（`await session.send_and_wait("Hello!")` 取代 `{"prompt": "Hello!"}`）
- **Go**：`Client.Start()` 的 context 不再殺掉 CLI 程序
- **全部**：`autoRestart` 已棄用

---

## 相關資源

| 資源 | 連結 |
|------|------|
| 官方倉庫 | https://github.com/github/copilot-sdk |
| 官方文件 | https://docs.github.com/en/copilot/how-tos/copilot-sdk |
| Getting Started | https://docs.github.com/en/copilot/how-tos/copilot-sdk/sdk-getting-started |
| Cookbook 範例集 | https://github.com/github/awesome-copilot/blob/main/cookbook/copilot-sdk |
| Java SDK | https://github.com/github/copilot-sdk-java |
| 發布公告 | https://github.blog/changelog/2026-01-14-copilot-sdk-in-technical-preview/ |
| Blog 文章 | https://github.blog/news-insights/company-news/build-an-agent-into-any-app-with-the-github-copilot-sdk/ |
| MS 實戰指南 | https://techcommunity.microsoft.com/blog/azuredevcommunityblog/building-agents-with-github-copilot-sdk-a-practical-guide-to-automated-tech-upda/4488948 |
| InfoQ 報導 | https://www.infoq.com/news/2026/02/github-copilot-sdk/ |

### 社群非官方 SDK

| 語言 | 倉庫 |
|------|------|
| Rust | https://github.com/copilot-community-sdk/copilot-sdk-rust |
| Clojure | https://github.com/copilot-community-sdk/copilot-sdk-clojure |
| C++ | https://github.com/0xeb/copilot-sdk-cpp |

---

## 注意事項

- ⚠️ **目前為 Technical Preview** — API 可能會變更，不建議用於生產環境
- 💰 **計費** — 每個 prompt 計入 Copilot premium request 配額（BYOK 除外）
- 🔐 **BYOK 限制** — 不支援 Entra ID、Managed Identity、OIDC/SAML
- 📋 **Copilot CLI 必須獨立安裝** — SDK 依賴 CLI 運行
