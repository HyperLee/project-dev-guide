# Code Review Skill — 全方位評估報告

> 評估日期: 2026-03-16
> 評估標準: 基於 `skill-creator` 的 Skill Writing Guide、Progressive Disclosure 模型、Eval 品質標準、及 Grader/Comparator/Analyzer 代理的評估維度
> 評估對象: `.github/skills/code-review/`

---

## 目錄

1. [執行摘要](#1-執行摘要)
2. [結構與組織評估](#2-結構與組織評估)
3. [YAML Frontmatter 評估](#3-yaml-frontmatter-評估)
4. [SKILL.md 主體內容評估](#4-skillmd-主體內容評估)
5. [參考文件評估](#5-參考文件評估)
6. [Eval 測試案例評估](#6-eval-測試案例評估)
7. [觸發描述品質評估](#7-觸發描述品質評估)
8. [寫作風格與指令品質評估](#8-寫作風格與指令品質評估)
9. [邊界情況與完備性評估](#9-邊界情況與完備性評估)
10. [與 Skill-Creator 最佳實踐的合規性](#10-與-skill-creator-最佳實踐的合規性)
11. [量化評分卡](#11-量化評分卡)
12. [改進建議](#12-改進建議)
13. [綜合評價](#13-綜合評價)

---

## 1. 執行摘要

`code-review` 是一個設計良好、結構完整的高品質 skill，旨在讓 Claude 扮演資深軟體工程師進行全面的程式碼審查。該 skill 展現了多項最佳實踐：清晰的工作流程、分層的嚴重性分類、豐富的實際範例、以及四個整理得當的參考文件。Eval 測試案例涵蓋了 6 種程式語言和多種漏洞類型。

**整體評級: A- (88/100)**

主要優點：
- 結構化的三步驟工作流程（Context → Analysis → Review）邏輯清晰
- Output Template 提供一致且可操作的格式
- 參考文件有效利用 Progressive Disclosure 模型
- 8 個 Eval 覆蓋多語言、多場景，包含正面案例和邊界情況
- 兩個完整的 Example（有問題的碼和良好的碼）展示預期行為

主要不足：
- 缺少 `files` 欄位在 evals.json 中（格式略偏離 schema）
- 參考文件 `language-patterns.md` 的 C# 段落包含項目專屬慣例，有過度耦合風險
- 缺少 description optimization（觸發描述未經 `run_loop.py` 優化）
- Eval 只有 should-trigger 案例，無 should-not-trigger 案例
- 缺少若干語言（如 Kotlin、Swift、PHP）的覆蓋

---

## 2. 結構與組織評估

### 2.1 目錄結構

```
code-review/
├── SKILL.md              (307 行, ~16.8 KB) ✅
├── evals/
│   └── evals.json        (116 行)           ✅
└── references/
    ├── language-patterns.md   (118 行)      ✅
    ├── performance-patterns.md (96 行)      ✅
    ├── security-checklist.md   (64 行)      ✅
    └── testing-patterns.md     (80 行)      ✅
```

**評分: 9/10**

| 檢查項目 | 結果 | 說明 |
|---------|------|------|
| SKILL.md 存在 | ✅ PASS | 位於根目錄 |
| 有 YAML frontmatter | ✅ PASS | 格式正確 |
| SKILL.md 行數 ≤ 500 | ✅ PASS | 307 行，在理想範圍內 |
| 使用 references/ 目錄 | ✅ PASS | 4 個有組織的參考文件 |
| 有 evals/ 目錄 | ✅ PASS | 包含 evals.json |
| 無不必要的 scripts/ | ✅ PASS | Code review 作為純指令 skill 不需要腳本 |
| 無 `__pycache__` 或垃圾文件 | ✅ PASS | 目錄乾淨 |

**優點:**
- 目錄結構完全遵循 skill-creator 的 Anatomy of a Skill 規範
- 參考文件按照功能領域（語言模式、效能、安全、測試）進行了清晰的領域組織
- 所有參考文件都在 300 行以內，不需要額外的 TOC
- SKILL.md 自身只有 307 行，遠低於 500 行的建議上限

**不足:**
- 缺少 `assets/` 目錄（非必需，但若未來需要輸出模板可考慮）
- 沒有 `scripts/` 目錄（對於 code-review skill 這是合理的，因為不需要確定性腳本）

---

## 3. YAML Frontmatter 評估

```yaml
---
name: code-review
description: "Perform a thorough, senior-engineer-level code review with actionable
  feedback. Use whenever the user asks for code review, PR review, diff inspection,
  code audit, quality assessment, or asks for feedback on pasted code — even without
  explicitly saying 'code review'. Also triggers when the user pastes code and asks
  for opinions, improvement suggestions, or whether it's ready to merge."
---
```

**評分: 8.5/10**

### 3.1 name 欄位驗證

| 規則 | 結果 | 詳情 |
|------|------|------|
| 全小寫 kebab-case | ✅ PASS | `code-review` |
| 僅含小寫字母、數字、連字號 | ✅ PASS | |
| 不以連字號開頭/結尾 | ✅ PASS | |
| 無連續連字號 | ✅ PASS | |
| ≤ 64 字元 | ✅ PASS | 11 字元 |

### 3.2 description 欄位驗證

| 規則 | 結果 | 詳情 |
|------|------|------|
| 無角括號 `< >` | ✅ PASS | |
| ≤ 1024 字元 | ✅ PASS | 約 380 字元 |
| 描述觸發條件 | ✅ PASS | 列出了具體觸發場景 |
| 描述功能 | ✅ PASS | "Perform a thorough, senior-engineer-level code review" |
| 適度「推動性」 | ✅ PASS | "even without explicitly saying 'code review'" 擴展了觸發範圍 |

### 3.3 Description 品質深度分析

**優點:**
- 明確列出了 6 種觸發場景：code review、PR review、diff inspection、code audit、quality assessment、feedback on pasted code
- 包含隱式觸發場景："even without explicitly saying 'code review'"
- 覆蓋了用戶可能用的非正式措辭（opinions, improvement suggestions, ready to merge）

**不足:**
- 缺少一些常見的觸發措辞，如：
  - "look over my code"、"check my implementation"
  - "find bugs in this"
  - "is this production ready"
  - "refactor suggestions"
  - "security review" / "security audit"
- 未提及特定語言的觸發（例如 "review this Python/Go/Java code"）
- 建議通過 `run_loop.py` 和 `run_eval.py` 進行 description optimization 以獲得最佳觸發率

---

## 4. SKILL.md 主體內容評估

### 4.1 總體結構

SKILL.md 包含以下主要段落：

| 段落 | 行數範圍 | 用途 | 評價 |
|------|----------|------|------|
| 角色定義 | 6-8 | 設定 Claude 的方式和態度 | ✅ 優秀 — 平衡了徹底性與實用性 |
| Review Workflow | 10-77 | 三步驟工作流程 | ✅ 優秀 — 強調先理解再分析 |
| Output Template | 85-113 | 結構化輸出格式 | ✅ 優秀 — 一致且易掃描 |
| Severity Classification | 115-138 | 分級標準 | ✅ 優秀 — 清晰的三級分類 |
| Feedback Principles | 140-149 | 回饋原則 | ✅ 優秀 — 強調教學而非把關 |
| Example | 151-279 | 兩個完整範例 | ✅ 優秀 — 一正一反，展示全面 |
| Special Considerations | 281-290 | 額外檢查維度 | ✅ 良好 |
| Edge Cases | 292-300 | 特殊情況處理 | ✅ 良好 |
| Focus Area Parameter | 302-307 | 用戶可配置的重點領域 | ✅ 創新 — 利用 `${input:focus:...}` |

### 4.2 工作流程設計 (Step 1-3)

**Step 1: Understand the Context** — 評分: 10/10
- 正確強調「先閱讀、再評論」的原則
- 要求使用 Read、Grep、Glob 工具來獲取上下文
- 「Risk-based depth allocation」是一個非常好的概念，根據風險而非行數分配審查深度
- 要求檢查團隊慣例（.editorconfig, CONTRIBUTING.md 等），避免強加個人偏好

**Step 2: Analyze the Code** — 評分: 9/10
- 六個分析維度涵蓋全面：Security、Correctness、Performance、Code Quality、Architecture、Testing
- 每個維度包含具體的檢查要點（子彈點）
- 正確引用了四個參考文件，並說明何時查閱每個文件
- 輕微不足：缺少「Accessibility」維度（對前端代碼相關）；缺少「Documentation」維度

**Step 3: Write the Review** — 評分: 9/10
- 按變更大小（<50, 50-300, >300 行）調整審查深度，非常實用
- 大型變更的指引（先架構觀察、再深入關鍵部分）正確
- 輕微不足：未提及對 PR 中的 commit 順序或 commit message 品質的評估

### 4.3 Output Template

```
## Code Review: [file name, PR title, or brief description]
### Summary
### 🔴 Critical Issues
### 🟡 Suggestions
### ✅ Good Practices
### Metrics
```

**評分: 9.5/10**

**優點:**
- 使用 emoji 圖標（🔴🟡✅）增加可讀性和快速掃描能力
- Metrics 段提供量化摘要
- 明確說明了「no issues found」的處理方式
- 涵蓋了 multi-file review 的組織建議

**輕微不足:**
- Metrics 段沒有包含「Severity score」或「Overall confidence」等進階指標
- 沒有明確的「Actionable next steps」段落（雖然 Critical Issues 隱含了這一點）

### 4.4 Example 品質

**Example 1: Python `get_user()` 函數** — 評分: 10/10
- 展示了需要修復的代碼
- 包含 SQL Injection 和 None 處理兩個 Critical Issues
- 包含 `SELECT *` 和 index access 兩個 Suggestions
- 包含 1 個 Good Practice
- 每個 issue 都有：具體行號引用、影響解釋、修復代碼

**Example 2: TypeScript `debounce()` 函數** — 評分: 10/10
- 展示了優質代碼的審查方式
- 正確示範「不製造假問題來填充段落」
- 0 Critical Issues、1 Suggestion、2 Good Practices
- 證明 skill 能適當處理正面案例

**兩個 Example 互補性:** 完美搭配 — 一個展示有大量問題的代碼審查，另一個展示高品質代碼的積極回饋。這是 skill-creator 推薦的最佳實踐。

### 4.5 Feedback Principles

**評分: 9.5/10**

六項原則完整且實用：
1. **Be specific** — "Line 42: `query = f'SELECT...'`" 而非模糊描述 ✅
2. **Explain the impact** — 描述不修復會怎樣 ✅
3. **Show the fix** — 提供具體代碼範例 ✅
4. **Stay constructive** — 協作性措辭 ✅
5. **Praise intentionally** — 具體說明 WHY 好 ✅
6. **Don't overwhelm** — 聚焦 5-7 個最重要發現 ✅

特別值得一提的是「code review is a teaching opportunity — not just a gatekeeping exercise」這句話完美體現了 skill-creator 所推崇的「解釋 why」原則。

---

## 5. 參考文件評估

### 5.1 references/security-checklist.md

**評分: 9/10** | 64 行

| 維度 | 評價 |
|------|------|
| 涵蓋範圍 | ✅ 7 大安全領域，39 個檢查項目 |
| 組織方式 | ✅ 使用 checkbox 格式，便於系統性檢查 |
| 實用性 | ✅ 每項都是具體可操作的檢查 |
| OWASP 覆蓋 | ✅ 涵蓋 Top 10 中的大部分 |
| 語言無關性 | ✅ 跨語言適用 |

**涵蓋的 7 個領域:**
1. Input Handling (7 項) — 涵蓋 SQLi、XSS、命令注入、路徑穿越、ReDoS、反序列化
2. Authentication & Authorization (7 項) — 涵蓋端點認證、資源授權、JWT 驗證、密碼雜湊
3. Data Protection (7 項) — 涵蓋硬編碼密鑰、日誌中的敏感資料、CORS、HTTP 安全標頭
4. Cryptography (4 項) — 涵蓋標準庫、CSPRNG、金鑰衍生、TLS
5. Dependency & Supply Chain (5 項) — 涵蓋依賴維護、版本鎖定、已知漏洞
6. API Security (5 項) — 涵蓋速率限制、Body 大小限制、分頁
7. Logging & Monitoring (4 項) — 涵蓋 PII 日誌、安全事件日誌、稽核追蹤

**不足:**
- 缺少 SSRF (Server-Side Request Forgery) 的明確檢查
- 缺少 IDOR (Insecure Direct Object Reference) 的獨立項目（部分被 Authorization 覆蓋）
- 缺少 CSP (Content Security Policy) 的具體配置建議

### 5.2 references/language-patterns.md

**評分: 8/10** | 118 行

| 語言 | Anti-Patterns | Idiomatic Patterns | 評價 |
|------|:---:|:---:|------|
| JavaScript/TypeScript | 8 | 5 | ✅ 全面 |
| Python | 7 | 6 | ✅ 全面 |
| Go | 6 | 5 | ✅ 全面 |
| Java | 6 | 4 | ✅ 良好 |
| Rust | 4 | 4 | ✅ 良好但較簡短 |
| C# | 8 + 項目慣例 | 8 | ✅ 最詳盡 |

**優點:**
- 每種語言都覆蓋了最常見的陷阱
- Anti-patterns 和 Idiomatic patterns 的分離有助於快速查閱
- C# 段落特別詳盡，包含了現代 C# 12+ 的功能

**不足:**
- C# 段落包含「Project Conventions (this project)」子段落（第 112-118 行），這是項目專屬的硬編碼慣例（4-space indent、CRLF、Allman braces 等）。這違反了 skill 的通用性原則 — 如果此 skill 被分發到其他項目使用，這些慣例可能不適用。建議將項目專屬慣例移出或明確標記為可配置
- 缺少以下語言的覆蓋：Kotlin、Swift、PHP、Ruby — 這些在產業中有相當的使用率
- 各語言段落的長度不均（C# 28 行 vs Rust 12 行）

### 5.3 references/performance-patterns.md

**評分: 9/10** | 96 行

涵蓋 5 大效能維度：

| 維度 | Pattern 數量 | 評價 |
|------|:---:|------|
| Algorithm & Data Structure | 3 | ✅ 含代碼範例 |
| Database Performance | 4 | ✅ 涵蓋 N+1 問題 |
| Memory & Resource | 3 | ✅ 跨語言適用 |
| Async & Concurrency | 3 | ✅ 含 `Promise.all` 修復 |
| Frontend Performance | 4 | ✅ React 特定模式 |

**優點:**
- 每個 pattern 都有「Pattern → Fix」結構
- Algorithm 段有完整的代碼範例（O(n²) → O(n+m)）
- 覆蓋了從底層（記憶體）到高層（前端）的完整堆疊

**不足:**
- 缺少 caching 策略相關的 patterns
- 缺少 lazy loading / pagination 的後端 patterns
- Database 段缺少 ORM 特有的效能陷阱

### 5.4 references/testing-patterns.md

**評分: 8.5/10** | 80 行

| 區域 | 內容 | 評價 |
|------|------|------|
| Common Anti-Patterns | 7 個 | ✅ 全面且有解釋 |
| Good Tests 特徵 | 4 個 | ✅ 簡明 |
| JS/TS (Jest/Vitest) | 4 項 | ✅ |
| Python (pytest) | 4 項 | ✅ |
| C# (xUnit/NUnit) | 4 項 | ✅ |
| Go | 4 項 | ✅ |

**優點:**
- 「Assertion-Free Tests」和「Testing Implementation Instead of Behavior」是非常有洞察力的 anti-patterns
- 每個 anti-pattern 都有「Pattern → Why it's bad → Fix」結構
- 語言特定段落與 language-patterns.md 的語言覆蓋一致

**不足:**
- 缺少 Java 測試模式（JUnit 5）的段落，但 language-patterns.md 有 Java 段
- 缺少 Rust 測試模式的段落
- 缺少 Integration Test 和 E2E Test 的反模式
- 缺少 test doubles 的策略指引（何時用 mock vs stub vs fake vs spy）

### 5.5 參考文件引用品質

SKILL.md 中的引用方式（第 69-77 行）非常好：

```markdown
- **`references/security-checklist.md`** — Read when reviewing code that handles
  user input, authentication, data storage, or external communication.
- **`references/language-patterns.md`** — Read when reviewing code in
  JavaScript/TypeScript, Python, Go, Java, C#, or Rust.
```

每個文件都有：
1. ✅ 明確的檔案路徑
2. ✅ 何時讀取的條件說明
3. ✅ 內容的簡短描述

這完全符合 skill-creator 的 "Reference files clearly from SKILL.md with guidance on when to read them" 原則。

---

## 6. Eval 測試案例評估

### 6.1 Eval 結構合規性

**與 `references/schemas.md` 的 `evals.json` schema 對照:**

| Schema 欄位 | code-review 中是否存在 | 評價 |
|-------------|:---:|------|
| `skill_name` | ✅ | `"code-review"` — 與 frontmatter 一致 |
| `evals[].id` | ✅ | 1-8 的唯一整數 |
| `evals[].prompt` | ✅ | 每個都是完整的用戶提示 |
| `evals[].expected_output` | ✅ | 簡短描述期望結果 |
| `evals[].files` | ❌ 缺失 | Schema 說 "Optional list of input file paths" |
| `evals[].expectations` | ✅ | 6-8 個具體斷言 |

**評分: 8/10**

`files` 欄位的缺失是合理的（因為 code review 的輸入直接嵌入 prompt 中），但明確設為空陣列 `[]` 會更嚴格地遵循 schema。

### 6.2 Eval 覆蓋範圍分析

| Eval ID | 語言 | 關注領域 | 代碼品質 | 預期嚴重性 |
|:---:|------|---------|:---:|:---:|
| 1 | Python (Flask) | 安全: pickle + 路徑穿越 | 差 | 🔴 Critical |
| 2 | React (JSX) | 正確性: useEffect deps + key | 差 | 🔴 Critical |
| 3 | Go | 安全: 路徑穿越 + 資源洩漏 | 差 | 🔴 Critical |
| 4 | Java (Spring) | 安全: Optional misuse + 權限提升 | 差 | 🔴 Critical |
| 5 | TypeScript | 效能: sequential await + any type | 中 | 🟡 Suggestions |
| 6 | Docker Compose (YAML) | 安全: 硬編碼密鑰 + 配置 | 差 | 🔴 Critical |
| 7 | TypeScript | 正面案例: 寫得好的 LRU Cache | 好 | ✅ Good Practices |
| 8 | C# (ASP.NET Core) | 多維度: 併發 + 資源 + 慣例 | 差 | 🔴 Critical |

### 6.3 覆蓋矩陣

**語言覆蓋:**
| 語言 | 有 Eval | 有 Reference |
|------|:---:|:---:|
| Python | ✅ (1) | ✅ |
| JavaScript/React | ✅ (2) | ✅ |
| Go | ✅ (3) | ✅ |
| Java | ✅ (4) | ✅ |
| TypeScript | ✅ (5,7) | ✅ |
| C# | ✅ (8) | ✅ |
| Rust | ❌ | ✅ |
| YAML/Config | ✅ (6) | — |

**問題類型覆蓋:**
| 問題類型 | Eval 涵蓋 |
|---------|:---:|
| SQL Injection | ❌（eval 1 是 pickle，不是 SQL） |
| 路徑穿越 | ✅ (1, 3) |
| 不安全的反序列化 | ✅ (1) |
| 硬編碼秘密 | ✅ (6) |
| 併發安全 | ✅ (8) |
| 資源洩漏 | ✅ (3, 8) |
| 前端特定 (React) | ✅ (2) |
| 正確使用 Optional | ✅ (4) |
| 效能 (async) | ✅ (5) |
| 類型安全 | ✅ (5) |
| 配置安全 | ✅ (6) |
| 正面評審 | ✅ (7) |

### 6.4 Eval 斷言品質

**總計斷言數: 55 個** (8 個 eval，平均 6.9 個/eval)

**斷言品質評估:**

| 品質維度 | 評分 | 說明 |
|---------|:---:|------|
| 可客觀驗證 | 9/10 | 大部分斷言可由 grader 客觀檢查 |
| 描述性 | 9/10 | 斷言名稱清晰，在 benchmark viewer 中可讀 |
| 區分度 | 8/10 | 大部分需要 skill 才能通過 |
| 避免過度具體 | 8/10 | 大部分不要求特定措辭 |
| 涵蓋結構合規性 | 9/10 | 多個斷言檢查 output template 使用 |

**頂級斷言範例（高品質）:**
- `"Review identifies pickle.loads on untrusted user input as a 🔴 Critical security vulnerability (arbitrary code execution)"` — 具體、可驗證、包含預期分類
- `"Review does not manufacture false critical issues just to fill sections"` — 測試 edge case 行為，非常好
- `"Review identifies that changing the search input won't actually re-filter because useEffect deps are empty"` — 測試深層理解而非表面符合

**可改進的斷言:**
- `"Review identifies at least one Good Practice or positive aspect of the code"` — 太寬泛，幾乎任何回覆都能通過
- `"Review follows the structured output template"` — 缺少具體性（哪些段落？Summary?Metrics?）
- `"Review uses the severity classification system (Critical/Suggestions/Good Practices)"` — 與 output template 斷言重疊

### 6.5 Eval 的缺口

1. **缺少 Rust eval** — language-patterns.md 涵蓋了 Rust，但沒有 eval 測試
2. **缺少 SQL injection eval** — security-checklist.md 的首要項目，但沒有專門的 eval
3. **缺少 multi-file review eval** — SKILL.md 特別提到 multi-file review 策略，但沒有 eval 測試
4. **缺少 diff/PR review eval** — 只有 eval 6 (docker-compose diff)，但缺少完整的 code diff review
5. **缺少 test code review eval** — testing-patterns.md 整個參考文件沒有被任何 eval 測試
6. **缺少 focus area eval** — `${input:focus:...}` 功能沒有被測試

---

## 7. 觸發描述品質評估

### 7.1 觸發詞分析

Description 中包含的觸發詞/場景：

| 觸發場景 | 是否包含 | 評價 |
|---------|:---:|------|
| "code review" | ✅ | 直接匹配 |
| "PR review" | ✅ | |
| "diff inspection" | ✅ | |
| "code audit" | ✅ | |
| "quality assessment" | ✅ | |
| "feedback on pasted code" | ✅ | |
| "opinions" / "improvement suggestions" | ✅ | |
| "ready to merge" | ✅ | |
| "find bugs" | ❌ | 常見的非正式措辭 |
| "check my code" | ❌ | 常見的非正式措辭 |
| "is this production ready" | ❌ | 部署前的常見問題 |
| "security audit/review" | ❌ | 專門的安全審查請求 |
| "look over / take a look" | ❌ | 非正式措辭 |
| "refactor suggestions" | ❌ | 重構建議有時需要 code review |

### 7.2 推動性 (Pushiness) 評估

skill-creator 指出：「Claude has a tendency to 'undertrigger' skills — to not use them when they'd be useful. To combat this, please make the skill descriptions a little bit 'pushy'.」

當前 description 的推動性: **中等偏上** — "even without explicitly saying 'code review'" 和 "Also triggers when the user pastes code and asks for opinions" 有效擴展了觸發範圍，但缺少更積極的例如「any time the user shares code and seems to want feedback of any kind」之類的推動語。

### 7.3 建議

建議使用 `skill-creator` 的 `scripts/run_loop.py` 和 `scripts/run_eval.py` 進行系統性的 description optimization，以量化觸發率並自動改進描述。這需要：
1. 建立 20 個 trigger eval queries（10 should-trigger + 10 should-not-trigger）
2. 運行 `run_loop.py --max-iterations 5`
3. 用 `generate_report.py` 查看結果

---

## 8. 寫作風格與指令品質評估

### 8.1 與 skill-creator Writing Style 的合規性

skill-creator 的核心寫作指導：

| 指導原則 | 遵循程度 | 證據 |
|---------|:---:|------|
| 使用祈使語氣 | ✅ 優秀 | "Read the code", "Identify the language", "Examine the code" |
| 解釋 why | ✅ 優秀 | "context-gathering must happen before analysis", "a review with 20+ items is likely to be ignored entirely" |
| 避免繁重的 MUST | ✅ 良好 | 使用語較為自然，少數地方用 "MUST"/"ALWAYS" |
| 通用性（不過度窄化） | ✅ 良好 | 適用於多語言、多場景 |
| 利用理論心智 | ✅ 優秀 | "code review is a teaching opportunity" 的定位 |

### 8.2 語氣基調

SKILL.md 的語氣非常專業，符合「資深工程師」的角色定位：
- ✅ 不居高臨下
- ✅ 建設性而非批判性
- ✅ 具體而非模糊
- ✅ 平衡了嚴謹與實用

### 8.3 MUST/ALWAYS/NEVER 使用頻率

| 強調用語 | 出現次數 | 評價 |
|---------|:---:|------|
| "MUST" | 2 次 | ✅ 適度 — 僅用於 "MUST be fixed" 和 "Must fix before merge" |
| "ALWAYS" | 1 次 | ✅ 適度 — "ALWAYS use this exact template" |
| "NEVER" | 1 次 | ✅ 適度 — "Never review code you haven't fully read" |

skill-creator 警告：「If you find yourself writing ALWAYS or NEVER in all caps, or using super rigid structures, that's a yellow flag」。此 skill 的使用非常克制。

### 8.4 Progressive Disclosure 使用

| 層級 | 使用情況 | 評價 |
|------|---------|------|
| Level 1: Metadata | Name + Description (~100 words) | ✅ 正確 |
| Level 2: SKILL.md body | 307 行核心指令 | ✅ 在 500 行限制內 |
| Level 3: References | 4 個按需讀取的文件，共 ~358 行 | ✅ 正確使用 |

Progressive Disclosure 的使用是此 skill 的一個強項：核心審查邏輯在 SKILL.md 主體中，而語言特定的 anti-patterns、安全檢查清單、效能模式和測試模式都被適當地推遲到參考文件中。

---

## 9. 邊界情況與完備性評估

### 9.1 SKILL.md 明確處理的邊界情況

| 邊界情況 | 處理方式 | 評價 |
|---------|---------|------|
| 無問題的代碼 | 明確說明用 Good Practices 填充 | ✅ 優秀 |
| 不完整的代碼片段 | 說明假設並要求澄清 | ✅ 良好 |
| 超大文件 (>500 行) | 說明深度審查 vs. 掃描的區域 | ✅ 良好 |
| 配置文件 | 聚焦安全、正確性、操作問題 | ✅ 良好 |
| 多語言文件 (HTML+JS+CSS) | 按關注領域而非語言組織 | ✅ 良好 |
| Multi-file reviews | 按嚴重性排序，非按文件 | ✅ 良好 |

### 9.2 未明確處理的邊界情況

| 邊界情況 | 風險等級 | 建議 |
|---------|:---:|------|
| 用戶提供的代碼含語法錯誤 | 中 | 增加處理語法錯誤代碼的指引 |
| 自動生成的代碼（如 Protobuf 生成） | 中 | 說明何時跳過自動生成的代碼 |
| 測試代碼 vs 生產代碼 | 低 | 已有 Testing 維度和參考文件 |
| 混合了新舊 API 的遷移代碼 | 低 | 可在 Special Considerations 中添加 |
| 非英語的變量名/註釋 | 低 | 少見但可以提及 |
| AI 生成的代碼 | 中 | 現代場景中越來越常見 |

---

## 10. 與 Skill-Creator 最佳實踐的合規性

### 10.1 清單式合規檢查

| Skill-Creator 最佳實踐 | 合規 | 說明 |
|------------------------|:---:|------|
| SKILL.md 存在於根目錄 | ✅ | |
| 有效的 YAML frontmatter | ✅ | |
| name 為 kebab-case | ✅ | `code-review` |
| description ≤ 1024 chars | ✅ | ~380 chars |
| description 無角括號 | ✅ | |
| SKILL.md < 500 行 | ✅ | 307 行 |
| 參考文件有使用條件說明 | ✅ | 第 69-77 行 |
| 參考文件 < 300 行 | ✅ | 最長 118 行 |
| 使用祈使語氣 | ✅ | |
| 解釋 why | ✅ | |
| 包含 Examples | ✅ | 2 個完整範例 |
| 有 evals.json | ✅ | 8 個 eval |
| evals 有 expectations | ✅ | 55 個斷言 |
| 不含惡意/利用代碼 | ✅ | 安全 |
| Description 夠「推動性」 | ⚠️ | 中等偏上，仍有改進空間 |
| 經過 description optimization | ❌ | 未用 run_loop.py 優化 |
| frontmatter 只含允許的屬性 | ✅ | 只有 name, description |
| 內容通用（不過度耦合特定項目） | ⚠️ | language-patterns.md 有項目專屬慣例 |

### 10.2 進階功能使用

| 功能 | 使用情況 | 評價 |
|------|:---:|------|
| `${input:...}` 參數 | ✅ | Focus Area Parameter |
| References 目錄 | ✅ | 4 個文件 |
| Scripts 目錄 | ❌ 不需要 | 合理 — code review 是純指令 skill |
| Assets 目錄 | ❌ 不需要 | 合理 — 輸出是 Markdown 文本 |
| License 文件 | ❌ | 可考慮添加 |

---

## 11. 量化評分卡

### 11.1 各維度評分

| 評估維度 | 權重 | 評分 (1-10) | 加權分 |
|---------|:---:|:---:|:---:|
| **結構與組織** | 10% | 9.0 | 0.90 |
| **YAML Frontmatter** | 10% | 8.5 | 0.85 |
| **SKILL.md 內容品質** | 20% | 9.5 | 1.90 |
| **參考文件品質** | 15% | 8.5 | 1.28 |
| **Eval 測試案例** | 15% | 8.0 | 1.20 |
| **觸發描述品質** | 10% | 7.5 | 0.75 |
| **寫作風格與指令品質** | 10% | 9.0 | 0.90 |
| **邊界情況完備性** | 5% | 8.0 | 0.40 |
| **最佳實踐合規性** | 5% | 8.5 | 0.43 |
| **總計** | **100%** | — | **8.61** |

### 11.2 等級對照

| 等級 | 分數範圍 | 說明 |
|:---:|:---:|------|
| **A+** | 9.5-10.0 | 卓越，可作為範本 |
| **A** | 9.0-9.4 | 優秀，僅有微小改進空間 |
| **A-** | 8.5-8.9 | 非常好，少數可改進點 |
| **B+** | 8.0-8.4 | 良好，有明確的改進方向 |
| **B** | 7.0-7.9 | 合格，需要一些改進 |
| **C** | 6.0-6.9 | 需要較多改進 |
| **D** | < 6.0 | 需要重大修改 |

### **最終評級: A- (86.1/100)**

---

## 12. 改進建議

### 12.1 高優先級 (High Priority)

#### 建議 1: 執行 Description Optimization
**影響**: 直接提升觸發準確率
**方法**: 使用 `skill-creator` 的 `run_loop.py`:
1. 建立 20 個 trigger eval queries
2. 運行 `python -m scripts.run_loop --eval-set trigger_evals.json --skill-path code-review/ --max-iterations 5`
3. 使用 `generate_report.py` 查看 per-iteration 結果
4. 將 `best_description` 應用到 frontmatter

#### 建議 2: 補充缺失的 Eval 案例
**影響**: 提升 eval 覆蓋率和可信度
**建議新增的 eval:**

| ID | 語言 | 聚焦 | 說明 |
|:---:|------|------|------|
| 9 | Rust | Safety + ownership | 測試 References/language-patterns.md 的 Rust 段 |
| 10 | Python/JS | SQL Injection | 直接測試最常見的安全漏洞 |
| 11 | Multi-file | 架構審查 | 測試 multi-file review 策略 |
| 12 | Any | Test code review | 測試 testing-patterns.md 的參考文件 |
| 13 | Any | Focus area | 測試 `${input:focus:security}` 功能 |

#### 建議 3: 移除 language-patterns.md 中的項目專屬慣例
**影響**: 提升 skill 的可移植性
**方法**: 將 `language-patterns.md` 第 112-118 行的 "Project Conventions (this project)" 段落移至項目的 CLAUDE.md 或 .editorconfig 中，而非嵌入在通用 skill 的參考文件中。

### 12.2 中優先級 (Medium Priority)

#### 建議 4: 在 evals.json 中添加 `files` 欄位
**方法**: 為每個 eval 添加空的 `"files": []`，使格式嚴格遵循 schema。

#### 建議 5: 擴展觸發描述
**建議添加的觸發場景:**
```
"find bugs in", "check my code", "is this production ready",
"look over this", "security review", "refactoring suggestions"
```

#### 建議 6: 為 testing-patterns.md 添加 Java 段落
目前 language-patterns.md 有 Java 段，但 testing-patterns.md 缺少 JUnit 5 的測試模式。建議添加：
- `@ParameterizedTest` + `@ValueSource`/`@MethodSource`
- `assertThrows` 用法
- `@BeforeEach` / `@AfterEach` 生命週期
- `@Nested` 測試類組織

#### 建議 7: 在 security-checklist.md 中添加 SSRF 和 IDOR 項目
在 Input Handling 段添加：
```markdown
- [ ] Server-side requests do not use user-controlled URLs without allowlist validation (SSRF prevention)
```
在 Authentication & Authorization 段添加：
```markdown
- [ ] Object-level authorization checks prevent accessing other users' resources via ID manipulation (IDOR prevention)
```

### 12.3 低優先級 (Low Priority)

#### 建議 8: 添加 License 文件
如果計劃分發此 skill，建議添加 `license.txt`（如 Apache 2.0，與 skill-creator 一致）。

#### 建議 9: 為 performance-patterns.md 添加 Caching 段落
```markdown
## Caching Patterns
### Missing Cache Invalidation
### Cache Stampede / Thundering Herd
### Caching Derived Data Instead of Source Data
```

#### 建議 10: 添加 AI 生成代碼的審查指引
在 Edge Cases 段中添加：
```markdown
- **AI-generated code**: Pay extra attention to hallucinated APIs,
  subtle logic errors that "look right", over-engineered solutions,
  and missing error handling. AI code often passes a cursory glance
  but fails on edge cases.
```

#### 建議 11: 考慮添加 should-not-trigger eval queries
建立一些不應觸發 code-review skill 的查詢，例如：
- "Write a sorting function in Python"（寫代碼，非審查）
- "Explain how async/await works"（教學，非審查）
- "Help me debug this error"（除錯，非審查）

---

## 13. 綜合評價

### 13.1 SWOT 分析

| | 正面 | 負面 |
|--|------|------|
| **內部** | **S (Strengths):** <br>- 三步驟工作流設計精良 <br>- Output Template 一致且可操作 <br>- 兩個互補的 Example 展示正/負面案例 <br>- Progressive Disclosure 運用恰當 <br>- Feedback Principles 體現教學精神 <br>- Focus Area Parameter 提供靈活性 | **W (Weaknesses):** <br>- Description 未經 optimization <br>- Eval 缺少 Rust/SQL injection/test code 案例 <br>- 項目專屬慣例嵌入通用參考文件 <br>- 缺少 should-not-trigger evals <br>- Testing patterns 缺少 Java 段落 |
| **外部** | **O (Opportunities):** <br>- 可利用 run_loop.py 自動優化描述 <br>- 可擴展至更多語言 (Kotlin, Swift, PHP) <br>- 可添加 AI-generated code 審查指引 <br>- 可用 benchmark mode 量化 skill 的附加價值 | **T (Threats):** <br>- 隨著語言/框架演變需要定期更新 <br>- C# 項目慣例可能導致其他項目使用時混淆 <br>- 過多的語言覆蓋可能讓參考文件膨脹 |

### 13.2 總結

`code-review` skill 是一個**成熟度高、設計良好**的 skill，其核心架構和指令品質處於高水平。它成功地將複雜的程式碼審查流程分解為可執行的步驟，並通過 Progressive Disclosure 模型有效管理了信息層次。

**最大亮點**是其 Feedback Principles 和 Example 段落 — 它們不僅定義了技術上「做什麼」，更解釋了「為什麼」，這完全體現了 skill-creator 所推崇的「explain the why」原則。

**最需改進的方面**是觸發描述的優化和 eval 測試的完整性。通過執行 skill-creator 的 description optimization pipeline 並補充缺失的 eval 案例，此 skill 可以從 A- 提升到 A 或 A+ 等級。

此 skill 可以被視為一個優秀的參考範本，特別是在以下方面值得其他 skill 學習：
1. 如何利用參考文件實現 Progressive Disclosure
2. 如何編寫包含正面和負面案例的 Example
3. 如何使用 `${input:...}` 提供用戶可配置性
4. 如何在 Feedback Principles 中體現教學精神而非把關思維

---

*此報告由 Claude Opus 4.6 根據 `skill-creator` 框架的全部評估維度生成。*
