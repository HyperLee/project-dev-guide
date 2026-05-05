# Hermes Agent 自學習智能體

**執行摘要：** Hermes Agent 是 Nous Research 開發的開源 AI 代理框架，強調「與你共成長」——具有閉環學習能力、持久記憶、多端接入和自主技能生成【75†L99-L108】【73†L114-L122】。它作為 24/7 在線服務運行，使用大型語言模型作為推理引擎，能調用各種工具（終端、瀏覽器、搜尋等）完成任務，並將結果長期儲存、逐步累積經驗。Hermes Agent 支持多通道（CLI、Telegram/Discord/Slack 等訊息網關、REST API）輸入、定時任務、自動並行子代理等。部署上可在本地、容器、雲端或遠端機器上運行，提供完整的監控和升級工具。在社群生態方面，Hermes Agent 為 MIT 許可的開源專案，與 OpenClaw、LangChain、AutoGPT 等框架同屬自動化代理領域的代表，特色在於深度的持久記憶和閉環學習【33†L74-L83】【75†L99-L108】。

## 目錄

- [定義與背景](#定義與背景)  
- [架構與設計](#架構與設計)  
- [核心功能與 API](#核心功能與-api)  
- [部署與運維](#部署與運維)  
- [安全性與隱私](#安全性與-隱私)  
- [效能與可擴展性](#效能與可擴展性)  
- [生態系與比較](#生態系與比較)  
- [實作範例](#實作範例)  
- [常見問題與故障排除](#常見問題與故障排除)  
- [參考資源](#參考資源)  

## 定義與背景

Hermes Agent 是 Nous Research（研究實驗室 Hermes、Nomos、Psyche 模型背後的團隊）於 2026 年推出的**開源 AI 代理框架**【73†L114-L122】【75†L99-L108】。其口號「The agent that grows with you（隨著使用不斷成長的 Agent）」強調了閉環自學習和持久演進的設計理念【75†L89-L97】。具體而言，Hermes Agent 的目標是成為一個長期在線的數位「員工」，而非一次性交互的聊天機器人【75†L89-L97】。它旨在持續記憶用戶上下文和專案資料，自動產生並優化「技能」（Skills）以解決重複任務，並可跨多個會話和任務之間累積知識【73†L114-L122】【75†L99-L108】。Hermes Agent 提供 CLI 界面，也可通過 Telegram、Discord、Slack、WhatsApp 等訊息平台或 REST API 接入用戶；甚至支援語音錄入與轉錄功能。它採用 Python 實現，遵循 MIT 許可證發布【73†L114-L122】。核心開發組織是 Nous Research，但社群活躍、開發者可自由提交 pull request 及插件擴充。版本演進方面，該專案於 2026 年初開源發布（最早版本 v0.1 未公開指定日期），迄今已更新多個月，最近一次發佈為 v0.10.0 （2026 年 4 月 16 日）【53†L998-L1010】。由於歷史較短，具體時間線若無明確資料則標註「未指定」。  

## 架構與設計

Hermes Agent 的**架構**採模組化設計，分為多個核心元件【7†L12-L22】【60†L49-L58】：

- **輸入端 (Entry Points)：**包括 CLI 介面、對話網關 (Gateway)、排程器 (Cron)、API 伺服器、批處理 (Batch Runner) 等多種入口。其中 *Gateway* 負責接收來自 Telegram、Discord、Slack、WhatsApp、Signal 等平台的訊息，並將其轉給核心代理處理【7†L12-L22】。CLI 則提供互動式終端界面；排程器和批處理可按時觸發任務。【參考文獻：官方架構文檔【7†L12-L22】】  
- **AIAgent 核心：**處於架構中心，負責對用戶輸入進行解析、生成提示，調用模型推理並執行相應操作。核心包含**提示生成器**（Prompt Builder）、**Provider 解析器**（負責選擇對應的 LLM 提供者）、**工具調度器**（Tool Dispatch，將模型輸出映射到具體工具）、**記憶系統**（Memory Module，管理長期記憶檢索與存儲）、**多任務與子代理**（可並行執行子工作代理）等子元件【7†L12-L22】【60†L42-L51】。  
- **工具系統：**Hermes 內建多種工具（Tool）供 Agent 調用，例如 **終端工具**（Terminal，執行 shell 命令）、**瀏覽器工具**（利用 Playwright MCP 在瀏覽器中執行操作）、**網路工具**（Web 搜索、API 調用）、**視覺處理工具**（image captioning/recognition）、**檔案系統工具**（檢索與編輯本機檔案）等【7†L12-L22】。每個工具按型別定義接口，使用者可自定義插件擴充。  
- **資料存儲：**使用 SQLite（帶 FTS5）作為預設的本地儲存，保存會話歷史、短期記憶、壓縮記憶索引等【7†L12-L22】。所有狀態（配置、憑證、記憶、技能等）保存在用戶目錄（~/.hermes）中，可使用備份/還原功能【61†L13-L22】。  
- **通訊協定：**內部使用 JSON-RPC 和 RESTful API。Agent 核心與 LLM 服務溝通使用 OpenAI 兼容的聊天完成 API，與工具交互使用定義好的函數調用格式。外部提供一個 OpenAI 兼容的 HTTP API 伺服器（/v1/chat/completions、/v1/responses、/v1/runs 等）供第三方使用【12†L14-L22】【78†L290-L299】。此外，跨平台網關則依各訊息服務協定（如 Telegram Bot API）實現連接。  
- **模組化與擴充點：**Hermes 核心高度可擴展，使用者可以透過定義新的工具和技能來擴展功能。技能（Skills）系統允許將模型建議的流程步驟轉為可重用模組【21†L1-L5】。插件系統則可增加新的輸入通道或資料庫後端（如 Chroma、Qdrant 等矢量庫）【7†L12-L22】【75†L99-L108】。  
- **相依性：**基於 Python (3.11+)，依賴 `uv` 軟體包管理器、常見 LLM 客戶端庫、Playwright MCP (Node.js) 等。支援容器化運行，所以未強制要求 GPU，可透過外部 LLM 提供者使用 GPU 加速。  

以下使用 Mermaid 語法示意 Hermes Agent 的高階架構：

```mermaid
flowchart LR
  subgraph 輸入端
    CLI[CLI 介面] -->|輸入| AgentCore[AIAgent 核心]
    Gateway[訊息網關 (Telegram/Discord/...)] --> AgentCore
    Cron[排程任務] --> AgentCore
    APIServer[API 伺服器 (/v1)] --> AgentCore
  end
  subgraph AIAgent核心
    AgentCore --> PromptBuilder[提示生成]
    AgentCore --> ProviderResolver[模型供應者選擇]
    AgentCore --> ToolDispatcher[工具調度]
    AgentCore --> MemoryModule[記憶系統]
  end
  subgraph 工具系統
    Terminal[終端工具]
    Browser[瀏覽器工具]
    Web[網路工具]
    FileSys[檔案工具]
    Vision[視覺工具]
  end
  subgraph 儲存層
    DB[(SQLite + FTS5 資料庫)]
  end
  ToolDispatcher --> Terminal
  ToolDispatcher --> Browser
  ToolDispatcher --> Web
  ToolDispatcher --> FileSys
  ToolDispatcher --> Vision
  MemoryModule --> DB
  AgentCore --> DB
```

## 核心功能與 API

Hermes Agent 的主要功能與服務包括：  

- **持久記憶 (Memory)**：內建短期與長期記憶系統，可自動提取相關背景資訊，記錄事實和偏好。記憶存於本地資料庫，並可使用外部矢量庫（Mem0、Honcho、OpenViking 等插件）【33†L74-L83】。  
- **閉環學習 (Skill)**：代理會根據經驗自動生成和改進「技能」（Steps 列程），讓其在類似任務中重用以提升效率【21†L1-L5】【75†L99-L108】。  
- **多終端接入**：單一 gateway 同時連接 CLI、Telegram、Discord、Slack、WhatsApp 等多種通訊平台【75†L118-L125】。另外還有內置 WebUI 儀表板和 API 伺服器。  
- **工具使用 (Toolsets)**：支持多種**工具**，如終端命令執行、網頁搜尋、瀏覽器自動化、程式碼編輯、文字/語音轉換等【75†L118-L125】。用戶可啟用或禁用特定工具集，以約束代理行為。  
- **排程與自動化 (Cron)**：內置計時排程系統，可設定定期任務（如每日簡報、定期備份、審計報告等）【75†L118-L125】。CRON 任務運行在「乾淨的」新會話中，確保自包含輸入。  
- **並行子代理 (Delegation)**：支援啟動多個隔離的子代理同時處理任務，並可透過 RPC (如 `python` 工具) 讓它們並行合作【21†L1-L5】【75†L119-L125】。  
- **外部記憶與顧問**：可以連接外部專家 API（如 天氣、知識庫）作為工具。還有「SOUL.md」設定檔允許定義代理個性/背景【57†L79-L87】。  
- **CLI 和 Slash 指令**：在互動式 CLI 中可使用 `/` 開頭的快捷命令，如 `/status`、`/tools`、`/goals` 等快速查狀態或控制代理【20†L1-L4】。  
- **API 端點**：Hermes 提供與 OpenAI 兼容的 REST API 伺服器【12†L14-L22】：

  - `POST /v1/chat/completions`：送出聊天完成請求。請求範例：  
    ```json
    {
      "model": "hermes-agent",
      "messages": [{"role": "user", "content": "請告訴我今天的天氣"}]
    }
    ```  
    成功回應包含 `choices` 等字段【12†L14-L22】。如請求不是合法 JSON，或上傳不支援的檔案，會返回 400 錯誤【14†L206-L214】。例：  
    ```bash
    curl http://localhost:8642/v1/chat/completions \
      -H "Authorization: Bearer <token>" \
      -H "Content-Type: application/json" \
      -d '{"model":"hermes-agent","messages":[{"role":"user","content":"你好"}]}'
    ```  

  - `POST /v1/responses`：以 OpenAI Responses 格式（`input` + `instructions`）向 Hermes 發送單輪請求，可選 `store: true` 保存回應。請求範例：  
    ```json
    {
      "model": "hermes-agent",
      "input": "寫一個Python排序程式",
      "instructions": "你是有創意的程式員",
      "store": true
    }
    ```  
    回應包括 `response_id` 等資料，並保留在服務端【12†L14-L22】。

  - `POST /v1/runs`：提交一個新運行以支援流式事件。返回 `run_id`【77†L1-L4】【78†L290-L299】。

  - `GET /v1/runs/{run_id}`：輪詢獲取該運行狀態和結果【77†L7-L13】【78†L311-L320】。

  - `GET /v1/runs/{run_id}/events`：使用 SSE（服務器推送）獲取運行進度事件，如工具執行輸出、生成 token 等【77†L13-L22】。

  - `POST /v1/runs/{run_id}/stop`：中斷正在運行的任務【77†L19-L28】。

  - **Jobs API**：管理背景定時任務（CRUD 操作），對應 Hermes 的 `cronjob`【78†L336-L344】。

  - **輔助接口**：`GET /v1/models` 列出可用模型（Hermes 本身即是模型）；`GET /v1/capabilities` 說明伺服器功能；`GET /health` 和 `/health/detailed` 提供健康檢查【78†L274-L283】。

- **錯誤與異常處理**：若未提供/錯誤的 API Key 返回 401。非法請求（如非 JSON、上傳不支援文件）返回 400【14†L206-L214】。LLM 提供者端的錯誤則透過 Hermes 反饋用戶（例：模型不支援）。對於終端執行，偵測到“rm -rf”等危險命令時要求用戶手動批准【72†L402-L410】。API 伺服器也可能在限流時返回 429，建議切換模型或提供者【71†L346-L355】。

**範例程式碼 (Python)**：以下示例使用 `requests` 調用 Hermes 的聊天 API：
```python
import requests

url = "http://localhost:8642/v1/chat/completions"
headers = {"Authorization": "Bearer <YOUR_KEY>", "Content-Type": "application/json"}
payload = {
    "model": "hermes-agent",
    "messages": [{"role": "user", "content": "請用一句話介紹自己"}]
}
response = requests.post(url, headers=headers, json=payload)
print(response.status_code, response.json())
```
預期回傳類似：
```json
{
  "id": "chatcmpl-xxx",
  "object": "chat.completion",
  "model": "hermes-agent",
  "choices": [{"message": {"role": "assistant", "content": "你好，我是 Hermes Agent，一個自我學習的 AI 助手。"}, "finish_reason": "stop"}],
  "usage": {"prompt_tokens": 10, "completion_tokens": 8, "total_tokens": 18}
}
```
（以上為示例回應，具體取決於所選模型和記憶狀態。）

## 部署與運維

Hermes Agent 支持多種部署方式：在本地機器、容器、雲服務、遠端機（透過 SSH）、Daytona、Modal 等環境運行【75†L121-L125】。關鍵注意事項與步驟如下：

- **安裝步驟**：推薦使用官方一鍵安裝腳本（Linux/Mac/WSL2/Termux 可用）：  
  ```bash
  curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
  ```  
  這會安裝 `uv` 包管理器並建立 Python 虛擬環境，所需相依自動處理【75†L129-L139】。安裝後執行 `hermes` 應可使用命令行工具。

- **系統需求**：Hermes 需要 Python 3.11+；推薦至少 4GB 以上記憶體（取決於使用的 LLM ）。開啟大上下文模型（16K+）時需要更多記憶體和更快的網路連線。欲使用本地模型，需配置對應服務（如 Ollama、vLLM 或 llama.cpp API）【68†L99-L107】。

- **配置**：首次運行後，在 `~/.hermes/` 目錄生成 `.env` 和 `config.yaml`，可使用 `hermes model` 指令設定 LLM 提供者和模型；使用 `hermes config set <KEY> <VALUE>` 設定環境變數（如 `OPENAI_API_KEY`、`FIRECRAWL_API_KEY`、`HERMES_DASHBOARD` 等）。也可手動編輯 `~/.hermes/.env` 及 `config.yaml`。【57†L59-L68】【60†L54-L63】

- **容器化部署**：官方提供 Docker 映像（`nousresearch/hermes-agent`）。例如：
  ```bash
  mkdir -p ~/.hermes
  docker run -d \
    --name hermes \
    --restart unless-stopped \
    -v ~/.hermes:/opt/data \
    -p 8642:8642 \
    -e API_SERVER_ENABLED=1 \
    -e API_SERVER_KEY=<your_token> \
    nousresearch/hermes-agent gateway run
  ```  
  上述命令會以後台模式啟動 Hermes gateway，將宿主機的 `~/.hermes` 掛載到容器的 `/opt/data`（存儲配置與狀態），並映射 8642 端口供 API 使用【60†L73-L82】。可加 `-p 9119:9119 -e HERMES_DASHBOARD=1` 來開啟內置 Dashboard【60†L90-L100】。

- **遠端/雲端**：可在雲伺服器或 VPS 上運行，建議使用反向代理（Nginx）與 HTTPS 保護 API 端點。同樣可在 Kubernetes 中部署多副本，每個實例使用不同資料卷以隔離狀態。

- **監控與日誌**：Hermes 支援健康檢查接口（`GET /health` 回傳 `{"status":"ok"}`，`/health/detailed` 回傳詳細指標）【78†L274-L283】。日誌檔案位於 `~/.hermes/logs/`，可用 `hermes logs` 指令查看錯誤和運行情況【61†L1-L4】。Docker 可透過 `docker logs hermes` 觀察輸出。建議將重要日誌外掛到外部服務（如 ELK、Prometheus）以便集中監控。

- **升級與備援**：使用 `hermes update` 來拉取最新代碼並重啟服務，可加 `--backup` 自動備份現有狀態【62†L55-L63】。如有重大更新，先執行 `hermes backup`（或透過 CLI 帶 `--quick`）生成 zip 備份【61†L13-L22】，保險起見也可使用 Docker 版本直接拉新版映像。高可用方面，可在多個容器實例前置負載均衡，但注意不要同時共用同一資料庫。**備援策略**：定期備份 `.hermes` 目錄（`hermes backup`），並可配置主從或多個模型節點來冗餘 LLM 提供者。

- **其他維運**：Hermes 提供命令管理工具（`hermes cron`、`gateway`、`skills` 等），可列出或配置定時任務、查看會話狀態、管理安裝的社群技能（Hub Skills）等【61†L1-L4】【62†L54-L63】。亦可設 `systemd` 或 Windows 任務排程自動開機啟動 Hermes Gateway；WSL 用戶可參照 FAQ 在 tmux 或 nohup 下保持運行【72†L506-L515】。

## 安全性與隱私

Hermes Agent 在設計上採取多層安全機制與使用者隔離【23†L48-L57】：

- **認證與授權**：Hermes API Server 需要 HTTP Bearer 權杖（在環境變數 `API_SERVER_KEY` 或自訂密鑰中設定）。未經授權的請求將被拒絕。跨來源請求 (CORS) 可在設定中限制允許的來源。對於訊息平台，Hermes 提供用戶允許清單（allowlist）與 DM 配對機制【63†L1-L9】：只有在清單中的用戶或經過「配對碼」授權的用戶才能交互【63†L13-L22】。管理員可設定像 `GATEWAY_ALLOWED_USERS`、`TELEGRAM_ALLOWED_USERS` 之類的環境變數來限制訪問【63†L7-L16】，預設情況下未知用戶 DM Hermes 會收到配對碼，需要用戶通過 CLI 授權後才能繼續【63†L13-L22】。

- **資料加密**：Hermes 本身不集中收集數據，對話記錄、記憶和技能均存儲在本地檔案系統【68†L96-L103】。與 LLM 服務的傳輸建議走 HTTPS（加密通道）。用戶可以自行選擇部署在內網或設定反向代理來加密保護 API 端口。

- **攻擊面控管**：由於 Hermes 支援執行本地 shell 命令，風險較高。為此採用「危險命令批准」機制：對於被偵測為可能破壞性（如 `rm -rf /`、`DROP TABLE`）的命令，Hermes 不會自動執行，而是要求使用者二次確認【72†L402-L410】。還有**黑白名單**配置，可預設禁止特定命令或語句模式。`Yolo mode`（全自動模式）可關閉以上安全檢查，但不建議在未完全信任環境下使用【23†L61-L72】。跨會話記憶時會執行內容掃描，以防範 prompt injection（例如不允許透過 context 文件埋入惡意指令）【23†L61-L72】。

- **最小權限和沙箱**：建議在容器或受控環境（Docker、Singularity、Modal 等）中運行 Hermes 及其工具，將重要系統資源隔離【23†L61-L72】。使用者可設定 `terminal.backend=docker` 讓代理在 Docker 沙箱內運行本地命令【59†L7-L10】。對於需要提升權限的操作，不應在 Hermes 內直接使用 `sudo`；如確需使用，可配置免密碼 sudo 或改到終端介面執行【72†L418-L427】。

- **最佳實踐**：遵循「配置最小化」原則，只啟用必要的功能（如關閉 TTS, Voice 模式，關閉無需用到的工具集）。定期更新 Hermes 和依賴庫以獲取安全修補【62†L55-L63】。監控網關日誌（位於 `~/.hermes/logs`）以偵測異常訪問。若部署在公網，務必通過防火牆或代理限制端口，並為 API 加入額外認證（如 API Gateway）。

## 效能與可擴展性

Hermes Agent 的效能主要受制於底層 LLM 提供者和工具執行時間【72†L565-L574】。一般來說，其瓶頸可能包括：

- **LLM 調用時延**：對話生成和工具觸發都依賴大型模型，若使用 GPT-4 等高階模型，平均每輪可能需要幾秒至數十秒。網路延遲、模型併發配額也會影響響應速度。使用本地 GPU 或加速推理服務（如 NVIDIA NIM、vLLM）可降低延遲。  
- **上下文壓縮開銷**：當長對話超出模型上下文限制時，Hermes 會嘗試壓縮對話歷史【71†L356-L364】。這個過程需要額外計算。避免頻繁壓縮，可在對話前即限定足夠的大上下文模型或手動 `/compress` 清理會話。  
- **工具執行開銷**：調用如瀏覽器或 GPT 除模型之外的外部工具，也需時間。若代理使用多重工具並行工作，可能發生阻塞。Hermes 支援並行子任務，但現階段還主要以順序執行為主（可透過自定義腳本和 RPC 實現更高併發）。  
- **儲存 I/O**：使用 SQLite 存儲大量記憶和會話時，磁碟 I/O 可能成為瓶頸。在高頻讀寫場景中，建議將資料庫放在 SSD 或考慮使用內存映射（如將數據庫移至 tmpfs）提升速度。  
- **可擴展性**：Hermes 本身作為單個代理實例運行，每個實例綁定一個資料目錄。要支援更多用戶，可部署多個 Hermes 實例，並前端負載均衡或設置不同資料目錄（profiles）分擔。透過 `hermes profile` 可管理多個獨立代理，每個代理獨立資源。對於更密集的佈署，可使用容器編排 (如 Kubernetes) 來擴容 Hermes Gateway。  

基準測試方面，目前官方文檔未提供具體效能數據，且實際表現高度取決於模型、硬體和網路環境。一般建議：  
- **模型選擇**：對於大部分任務，使用中等大小的模型（8B~20B 參數）可達到性價比平衡；專案需要長上下文時選擇 32K+ 參數模型（如指令微調的 Llama 3 或 GPT-4o-32k）。  
- **並行處理**：適度使用子代理並行獨立任務（例如透過 `asyncio` 或多進程）可提升吞吐量。  
- **延遲優化**：避免每次對話都重啟代理；長時間運行一個連續會話可重用 API 連線。可使用 Hermes 的 SSE 流模式 (runs API) 來減少多次握手開銷【12†L14-L22】【78†L290-L299】。  
- **監測資源**：利用 `/health/detailed` 監控 CPU、記憶體和活動會話，及時調整容器資源限制。  

整體而言，Hermes Agent 具備**良好的擴展性**：它的架構允許在功能豐富的同時，可橫向擴充至多個實例和雲端環境。使用者和團隊可根據實際工作負載適當提升機器規格，或者透過分布式方式部署多個代理來支持更多任務。  

## 生態系與比較

Hermes Agent 在開源智能體領域與多個框架和產品同台競爭。以下列出三個主要的類似方案，並與 Hermes Agent 進行比較（特點、授權、社群活躍度、適用場景等）：

| **特性／平台**        | **Hermes Agent**                                | **OpenClaw**                                     | **LangChain**                                  | **AutoGPT**                               |
|--------------------|------------------------------------------------|------------------------------------------------|----------------------------------------------|------------------------------------------|
| **授權**             | MIT 開源【73†L114-L122】                           | MIT 開源【48†L1099-L1107】                         | Apache 2.0 開源【43†L162-L170】【44†L1-L4】     | MIT（平台組件部分限 Polyform Shield）【37†L480-L490】 |
| **功能焦點**         | 持久化記憶、閉環技能、自我優化、多端併行、開發導向【75†L99-L108】【33†L74-L83】 | 即時聊天助手，自動化任務，開箱即用工具集（搜尋、文件、程式執行）【34†L37-L45】【34†L91-L99】 | LLM 工具鏈與代理庫，極多集成，強大多智能體編排 (LangGraph)【43†L130-L139】【44†L1-L4】 | 任務驅動型代理，強調目標導向任務分解，無內建長期記憶            |
| **社群與生態**       | 新興快速增長，GitHub 星標數突出（數十萬）、Nous 研究團隊維護【75†L99-L108】【33†L74-L83】 | 已成熟且擁有大規模星標（數十萬），多人貢獻，文檔完善【48†L1099-L1107】【34†L37-L45】 | 社群最廣泛，超過10萬星，生態系眾多插件與工具（Langsmith 監控）【43†L134-L142】【44†L1-L4】 | 曾非常流行（約18萬星【51†L1-L3】），近期活躍度下降，由社群維護，新手友好度較高 |
| **適用場景**         | 長期自動化專案，個性化私人助理，研發導向需數據累積的任務【33†L74-L83】【43†L122-L130】 | 快速部署聊天任務，日常信息查詢，跨平臺即時助手【34†L79-L87】【34†L100-L109】 | 構建複雜 LLM 應用（RAG、管道、工具型代理等），企業級解決方案【43†L118-L127】【44†L1-L4】 | 目標驅動自動化，如自動影片生成或社交媒體任務，適合教學和實驗用途    |

**參考來源說明**：以上比較資訊綜合官方文檔及技術部落格【33†L74-L83】【34†L37-L45】【43†L122-L131】等。  
- *Hermes Agent* 強調深度學習循環和記憶累積，適合需要隨時間“學習”和個人化的專案【75†L99-L108】【33†L74-L83】。  
- *OpenClaw* 提供即裝即用的自動代理體驗，內建多種工具，適合快速上手和基本自動化【34†L79-L87】【34†L99-L109】。  
- *LangChain* 不是單一代理，而是一個通用 LLM 應用框架，適合構建定製工作流和多智能體系統【43†L126-L134】【44†L1-L4】。  
- *AutoGPT* 側重於目標管理，能自動產生子任務，但不具備長期記憶和技能系統。  

## 實作範例

下面提供一個端到端範例：部署 Hermes Agent 為 API 服務，並用 Python 調用聊天 API。

1. **設定**：假設已安裝 Docker 並希望以容器運行 Hermes Gateway，在宿主機建立資料目錄並設定 API 密鑰：  
   ```bash
   mkdir -p ~/.hermes
   export API_SERVER_KEY="mysecretkey"
   ```
2. **啟動服務**：使用官方 Docker 映像啟動 Hermes Gateay（同時開啟 API Server）：  
   ```bash
   docker run -d --name hermes-agent \
     -v ~/.hermes:/opt/data \
     -p 8642:8642 \
     -e API_SERVER_ENABLED=1 \
     -e API_SERVER_KEY="$API_SERVER_KEY" \
     nousresearch/hermes-agent gateway run
   ```  
   此時可透過 `hermes logs` 或 `docker logs hermes-agent` 查看初始化日誌【60†L54-L63】。服務啟動後，CLI 或 API 均可使用。  
3. **測試 API**：以下 Python 程式碼調用剛啟動的 Hermes，發送簡單問句並印出回應：  
   ```python
   import requests

   url = "http://localhost:8642/v1/chat/completions"
   headers = {
       "Authorization": f"Bearer {API_SERVER_KEY}",
       "Content-Type": "application/json"
   }
   payload = {
       "model": "hermes-agent",
       "messages": [{"role": "user", "content": "Hello Hermes!"}]
   }
   resp = requests.post(url, headers=headers, json=payload)
   print(resp.json())
   ```  
   執行後應收到類似以下格式的 JSON 回應：  
   ```json
   {
     "id": "chatcmpl-abc123",
     "object": "chat.completion",
     "model": "hermes-agent",
     "choices": [
       {
         "message": {"role": "assistant", "content": "Hello! How can I assist you today?"},
         "finish_reason": "stop"
       }
     ],
     "usage": {"prompt_tokens": 5, "completion_tokens": 9, "total_tokens": 14}
   }
   ```  
   這證明 Hermes API 已正常運作。可進一步測試流式輸出、連續對話等功能。  
4. **部署與測試**：示例中使用 Docker 運行 Hermes，實際部署時可選擇使用 `hermes gateway install`（將 Hermes 作為系統服務）或手動配置系統服務管理啟動。測試步驟包括：確保通過 `hermes config show` 查看 API Server 已啟用和密鑰正確；使用 `curl` 或上述代碼重複呼叫 `/v1/chat/completions` 和 `/v1/health` 以確認響應。

## 常見問題與故障排除

- **`hermes: command not found`**：安裝完成後若提示找不到指令，可能是 `$HOME/.local/bin` 未加到 PATH。可執行 `source ~/.bashrc` 或手動加入路徑【71†L182-L191】。  
- **Python 版本過舊**：Hermes 需 Python ≥3.11。若系統 Python 版本低，先升級 Python【71†L202-L211】。  
- **模型/金鑰配置問題**：在對話中使用 `/model` 列表無法切換所有提供者，是因為只配置了部分。正確做法是退出對話，使用終端 `hermes model` 新增或修改提供者與模型【71†L280-L289】。若 API Key 無效則會 401，檢查是否放在正確提供者下並重新設定【71†L311-L320】。  
- **對話溢出錯誤**：當會話上下文超出模型窗口或配置錯誤時，可能報「context length exceeded」。可使用 `/compress` 指令壓縮歷史，或手動重開新對話；也可以切換到更大窗口的模型【72†L401-L409】【71†L356-L364】。必要時可在 `config.yaml` 中顯式設定正確的 `context_length`【72†L379-L388】。  
- **工具命令被禁止**：若 Hermes 偵測到「危險命令」（如可能刪除檔案的大型 `rm` 命令），預設會要求確認。這是正確行為，只需檢查並輸入 `y` 繼續【72†L402-L410】。若需要跳過，可在配置中調整 `terminal.command_allowlist` 或安全設定。  
- **Docker 後端無法連接**：如果設定使用 Docker 沙箱（`terminal.backend=docker`）時出現錯誤，請確認本機 Docker daemon 正在執行且當前用戶已加入 `docker` 群組【72†L430-L439】。  
- **Bot 在訊息平台不回應**：檢查 Hermes Gateway 是否運行（`hermes gateway status`）；若關閉請 `hermes gateway start`（或使用 `docker start`）。同時檢查日誌 `~/.hermes/logs/gateway.log` 有無錯誤【72†L450-L459】。確保已為對應平台配置正確的驗證憑證，且對話允許清單（allowlist）沒有阻擋發送者【72†L477-L486】。  
- **Cron 任務不觸發**：確保 Hermes Gateway 已安裝為系統服務（`hermes gateway install`）或已使用 `hermes cron` 正確新增了工作【66†L145-L154】。查看 `~/.hermes/logs/cron.log` 了解執行情況。  
- **WSL 下 Gateway 不穩定**：WSL2 不一定支援 systemd，自動重啟服務可能失效。建議在終端直接使用 `hermes gateway run` 或透過 tmux/`nohup` 開啟持久模式【72†L506-L515】。亦可在 Windows 啟動時使用 Task Scheduler 執行 WSL Hermes Gateway。  

## 參考資源

- Hermes Agent **官方文件** — 包含架構設計、使用手冊、API 說明【7†L12-L22】【60†L42-L51】【12†L14-L22】。  
- Hermes Agent **原始碼倉庫** (GitHub) — 官方代碼及發佈歷史【53†L998-L1010】【46†L439-L448】。  
- Hermes vs OpenClaw 比較 — MindStudio 技術部落格【33†L74-L83】【34†L37-L45】。  
- Hermes vs LangChain 比較 — Respan 市場對比報告【43†L122-L131】【44†L1-L4】。  
- Hostinger 部落格 — 「什麼是 Hermes Agent」介紹文章【73†L114-L122】【73†L156-L164】。  
- 菜鳥教程 (中文) — Hermes Agent 功能總結和安裝指南【75†L99-L108】【75†L118-L125】。  
- Hermes FAQ — 官方常見問題與排錯指南【71†L182-L191】【72†L402-L410】。  

以上資料綜合官方文件、社區文獻與技術部落格，可作為深入瞭解 Hermes Agent 的依據。