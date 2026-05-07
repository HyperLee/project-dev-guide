# `dotnet-xunit` Skill 詳細解說

---

## 📁 檔案結構

```
.github/skills/dotnet-xunit/
├── SKILL.md                  ← 主定義檔（觸發條件、流程、輸出格式）
└── references/
    ├── xunit.md              ← xUnit 框架參考（安裝、偵測、CLI 指令）
    ├── patterns.md           ← 測試正確寫法範例集
    └── anti-patterns.md      ← 測試反模式與修正對照
```

---

## 🎯 SKILL.md — 核心定義

### Metadata（前置資訊）

- **name**: `dotnet-xunit`，version `1.0.0`，分類 `Testing`
- **description**: 專門處理使用 xUnit 的 .NET 測試專案（涵蓋 v2、v3、VSTest、Microsoft.Testing.Platform）
- **compatibility**: 需要有 xUnit 套件的 .NET solution/project

### Trigger On（何時觸發）

1. Repo 使用 xUnit v2 或 v3
2. 需要新增、執行、除錯或修復 xUnit 測試
3. 團隊不確定 project 用的是 VSTest 還是 Microsoft.Testing.Platform

### Do Not Use For（不適用）

- TUnit、MSTest 專案，或無 xUnit 特定需求的通用測試策略

### Inputs（輸入來源）

1. 最近的 `AGENTS.md`（取得 repo 層級的指令與約束）
2. 測試專案的 `.csproj` 和套件引用
3. 該專案的 runner model（VSTest / MTP / standalone）

---

## 🔄 Workflow（核心工作流程）— 6 步驟

| 步驟 | 動作 | 說明 |
|------|------|------|
| **1. Detect** | 偵測 xUnit model | 用 `.csproj` 中的套件判斷：`xunit` = v2、`xunit.v3` = v3、有 `xunit.runner.visualstudio` + `Microsoft.NET.Test.Sdk` = VSTest、有 `TestingPlatformDotnetTestSupport` = MTP |
| **2. Read** | 讀取測試指令 | 優先用 `AGENTS.md` 裡定義的指令，沒有就用 `dotnet test` |
| **3. Consistency** | 保持 runner 一致性 | v2 走 VSTest、v3 可 standalone (`dotnet run`) 或 MTP，**不混用** VSTest 和 MTP 的 flag |
| **4. Narrow scope** | 最小範圍先跑 | 先跑一個 project → 一個 class → 一個 trait → 一個 method |
| **5. Prefer Theory** | 優先用 `[Theory]` | 資料驅動用 `[Theory]`，單一路徑不變量用 `[Fact]` |
| **6. Analyzers** | 保持分析器開啟 | `xunit.analyzers` 有啟用就保持，修問題而非靜音 |

---

## 🏗️ Bootstrap When Missing（從零設定 xUnit）

當 repo 還沒設定 xUnit 時的自動設定流程：

```bash
# 1. 先偵測現有框架
rg -n "xunit|TUnit|MSTest" -g '*.csproj' .

# 2. 如果是 TUnit/MSTest → 不自動遷移，回傳 status: not_applicable

# 3. 新增 xUnit 套件
dotnet add TEST_PROJECT.csproj package xunit.v3
dotnet add TEST_PROJECT.csproj package xunit.runner.visualstudio  # 選用

# 4. 更新 AGENTS.md 記錄測試指令
# 5. 跑一次驗證 → 回傳 status: configured
```

---

## 🔁 Ralph Loop（迭代品質迴圈）

這是此 skill 的**核心執行引擎**，適用於所有任務類型：

```
Plan → Execute → Review → Fix → Update Plan → Repeat
```

1. **Plan first**（必要）：分析現狀、定義目標、列驗證步驟
2. **Execute**：執行一個計畫步驟，產出具體成果
3. **Review**：檢視結果，記錄可行的修復項目
4. **Fix**：小批量修復，重跑相關檢查
5. **Update plan**：每次迭代後更新計畫
6. **Repeat**：直到結果可接受或只剩明確的例外
7. **Missing dep**：缺東西就 bootstrap，或回傳 `not_applicable`

### Required Result Format（必要輸出格式）

| 欄位 | 說明 |
|------|------|
| `status` | `complete` / `clean` / `improved` / `configured` / `not_applicable` / `blocked` |
| `plan` | 簡要計畫和當前迭代步驟 |
| `actions_taken` | 具體做了什麼修改 |
| `validation_skills` | 最終跑了哪些驗證 |
| `verification` | 命令、檢查或 review 的證據摘要 |
| `remaining` | 未解決的項目或 `none` |

---

## 📚 references/ — 三份參考文件

### 1. `xunit.md` — 框架操作手冊

- **安裝**：`dotnet add package xunit.v3`（v3）、`xunit.runner.visualstudio`（VSTest 橋接）
- **偵測指令**：用 `rg` 搜尋 `.csproj` 裡的套件標記來判斷 runner model
- **常用 CLI**：
  - `dotnet test` — VSTest 通用
  - `dotnet test --filter "FullyQualifiedName~..."` — VSTest 篩選
  - `dotnet run --project ...` — v3 standalone
  - `dotnet run ... -- --filter-class ...` — v3 + MTP 篩選
- **CI 注意事項**：一個 project 一個 runner model、先 build 再 `--no-build`、coverage driver 要對應 runner

### 2. `patterns.md` — 正確測試模式（9 種）

| 模式 | 重點 |
|------|------|
| **AAA** | Arrange-Act-Assert 三階段分離 |
| **Class Fixture** | `IClassFixture<T>` + primary constructor 注入共享資源 |
| **Collection Fixture** | `[CollectionDefinition]` + `[Collection]` 跨 class 共享 |
| **InlineData** | 簡單參數化測試用 `[Theory] + [InlineData]` |
| **MemberData** | 複雜物件用 `TheoryData<T>` + `[MemberData]` |
| **ClassData** | 可重用資料集繼承 `TheoryData<T>` |
| **NSubstitute** | 偏好的 mock 框架，語法可讀性高 |
| **Moq** | 專案已用就繼續用 |
| **ITestOutputHelper** | 測試診斷輸出 |
| **Async patterns** | 原生支援 `async Task`，搭配 `CancellationToken` |
| **Trait** | `[Trait("Category", "Unit")]` 用於 CI 過濾，謹慎使用 |

### 3. `anti-patterns.md` — 反模式與修正（9 種）

| 反模式 | 問題 | 修正方向 |
|--------|------|----------|
| **Test Interdependence** | 靜態 `static` 共享狀態，依賴執行順序 | 每個測試自建資料 |
| **Excessive Mocking** | Mock 所有依賴，驗證每個內部呼叫 | 只 mock 外部邊界，用 in-memory 實作 |
| **Testing Implementation** | 驗證「怎麼做」而非「做了什麼」 | 驗證可觀察的行為結果 |
| **Ignoring Isolation** | 直接改環境變數污染其他測試 | `IDisposable` 清理或注入 configuration |
| **Non-Deterministic** | 用 `DateTime.Now`、`Random` 導致隨機失敗 | 注入 `TimeProvider` / `SeededRandom` |
| **Swallowing Exceptions** | `catch {}` 吃掉例外 | `Assert.Throws<T>()` 明確驗證 |
| **Magic Numbers** | 不解釋的常數 `150, 3, true` | 用 `const` 加語義命名 |
| **Assert Too Much/Little** | 一個測試驗 20 件事或只驗 1 件 | 一個測試一個邏輯概念 |
| **Async Void** | `async void` xUnit 不會 await | 改用 `async Task` |
| **Constructor Abuse** | constructor 裡跑測試邏輯 | 用 `IClassFixture<T>` 管共享 setup |

---

## 🧠 設計理念總結

這隻 skill 的設計哲學是：

1. **偵測優先** — 不假設，先用 `rg` 掃 `.csproj` 確認實際使用的 xUnit 版本和 runner
2. **Ralph Loop 迭代** — 不是一次做完，而是 Plan → Do → Check → Fix 的持續循環
3. **結構化輸出** — 每次任務必須回傳 6 欄位的 Result Format，確保可追蹤
4. **不破壞既有** — 不自動遷移 TUnit/MSTest，runner model 不混用
5. **references 分層** — 操作手冊 / 正確範例 / 反模式三份文件分開，AI agent 按需載入
