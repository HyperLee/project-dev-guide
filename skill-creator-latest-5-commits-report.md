# `skills/skill-creator` 最近 5 個變更波次整理報告

本報告整理 `anthropics/skills` 儲存庫（預設分支：`main`）中 `skills/skill-creator` 的最近 5 個相關變更波次。`skill-creator` 是一個用來建立、修改、評估與優化其他 skills 的 meta-skill；本文件僅根據已提供的 canonical facts 撰寫，方便直接閱讀與後續追蹤。  
檔案位置：`/Users/qiuzili/project-dev-guide/skill-creator-latest-5-commits-report.md`

## 方法與限制說明

- 本報告**不使用瀏覽或額外查詢**，僅根據題目提供的事實整理。
- 直接追溯 `skills/skill-creator` 在搬移到 `skills/` 命名空間後的路徑歷史，**只得到 4 個直接相關的提交／變更波次**。
- 因此，第 5 項特別納入 **在路徑搬移之前、且與 skill-creator 直接相關的最近一波更新：PR #112**，作為最接近的前序參考波次。
- 換言之，本報告的「最近 5 個」是：
  1. 搬移後路徑下可直接辨識的 4 波變更；以及
  2. 搬移前、緊接在命名空間重構之前的 skill-creator 相關更新波次。

## 摘要表

| 項次 | SHA / PR | 日期 | 標題 | 核心主題 |
| --- | --- | --- | --- | --- |
| 1 | `b0cbd3df1533b396d281a6886d5132f623393a9c` / PR #547 | 2026-03-06 20:06:23Z | `skill-creator: drop ANTHROPIC_API_KEY requirement from description optimizer` | 移除 Anthropic SDK 依賴，改用 `claude` CLI，並補強安裝後技能更新指引 |
| 2 | `3d59511518591fa82e6cfcf0438d68dd5dad3e76` / PR #465 | 2026-02-25 04:28:38Z | `chore: export latest skills` | 從簡單建置工具擴張為完整 skill 生命週期工具鏈 |
| 3 | `1ed29a03dc852d30fa6ef2ca53a67dc2c2c2c563` / PR #350 | 2026-02-06 21:19:32Z | `Update skill-creator and make scripts executable` | 新增 `compatibility` 中繼資料、放寬命名長度並同步驗證規則 |
| 4 | `ef740771ac901e03fbca3ce4e1c453a96010f30a` / PR #129 | 2025-12-01 18:05:36Z | `Move example skills into dedicated folder and create minimal top-level folder structure` | 將 skill-creator 搬入 `skills/` 命名空間，屬結構性重整 |
| 5 | PR #112 | 2025-11-17 21:34:29Z | `Update example skills and rename 'artifacts-builder'` | 搬移前的重要前序更新：補齊 skill 設計原則、參考文件與更嚴格封裝／驗證流程 |

## 各變更波次詳解

### 1. 2026-03-06 — 移除描述優化器對 `ANTHROPIC_API_KEY` 的要求（PR #547）

**識別資訊**

- SHA：`b0cbd3df1533b396d281a6886d5132f623393a9c`
- 日期：`2026-03-06 20:06:23Z`
- 標題：`skill-creator: drop ANTHROPIC_API_KEY requirement from description optimizer (#547)`

**變更檔案**

- `skills/skill-creator/SKILL.md`（`+8/-2`）
- `scripts/improve_description.py`（`+51/-52`）
- `scripts/run_loop.py`（`-4`）

**實質行為變更**

- `improve_description.py` 移除 Anthropic SDK 的使用方式，改為新增 `_call_claude(prompt, model, timeout)`：
  - 透過 shell 執行 `claude -p --output-format text`
  - 以 stdin 傳入 prompt
  - 可選擇性帶入 `--model`
  - 從環境變數中移除 `CLAUDECODE`
  - 若 CLI 非零退出則拋出 `RuntimeError`
- Prompt 文字明確加入**1024 字元硬上限**警示。
- 對超長描述的重試策略，從原本多輪 SDK 對話，改成**重新發送一次性 prompt**，並直接引用超長描述內容。
- `run_loop.py` 不再建立 `anthropic.Anthropic` client，也不再將該 client 往下傳遞。
- `SKILL.md` 文案更新：
  - 將 “update” 改成 “edit”
  - 移除過時的 “extended thinking” 用語
  - 補上已安裝技能的實務更新方式：保留原始名稱、若安裝路徑唯讀則先複製到 `/tmp`、從可寫的 staging 區封裝；同樣的指引也同步到 Cowork 流程

**對使用者的影響**

- 使用者不再需要額外準備 `ANTHROPIC_API_KEY` 這種獨立依賴，描述優化流程與 `run_eval.py` 的授權模式更一致。
- 對長描述的處理更直接，失敗重試的邏輯也更容易理解與除錯。
- 對於已安裝 skill 的修改與重新封裝，文件給出更務實的操作路徑，可降低權限或唯讀目錄造成的卡關情況。

**為何重要**

這一波等於把描述優化器從 SDK 綁定中解耦，轉為與既有 CLI 流程一致的操作模式。對維護者而言，依賴面縮小；對使用者而言，成功率、可攜性與文件一致性都提升了。

---

### 2. 2026-02-25 — skill-creator 大幅擴張為完整生命週期工具鏈（PR #465）

**識別資訊**

- SHA：`3d59511518591fa82e6cfcf0438d68dd5dad3e76`
- 日期：`2026-02-25 04:28:38Z`
- 標題：`chore: export latest skills (#465)`

**變更檔案**

- 大幅修改：`skills/skill-creator/SKILL.md`（`+336/-214`）
- 新增 agents：
  - `agents/analyzer.md`
  - `agents/comparator.md`
  - `agents/grader.md`
- 新增檢視與報告資產：
  - `assets/eval_review.html`
  - `eval-viewer/generate_review.py`
  - `eval-viewer/viewer.html`
- 參考文件調整：
  - 移除 `references/output-patterns.md`
  - 移除 `references/workflows.md`
  - 新增 `references/schemas.md`
- 新增 scripts：
  - `scripts/__init__.py`
  - `scripts/aggregate_benchmark.py`
  - `scripts/generate_report.py`
  - `scripts/improve_description.py`
  - `scripts/run_eval.py`
  - `scripts/run_loop.py`
  - `scripts/utils.py`
- 移除 `scripts/init_skill.py`
- 修改 `scripts/package_skill.py`（`+33/-7`）

**實質行為變更**

- skill-creator 從原本偏向**初始化／封裝**的工具，擴展成涵蓋：
  - evaluator agents
  - 瀏覽器式評估檢視 UI
  - benchmark 聚合
  - 報告生成
  - 描述優化迴圈
- 文件重心從較泛化的 workflows / output patterns，轉為更偏向**schema 導向**的說明方式。
- `package_skill.py` 也隨此波更新，表示封裝能力仍被保留，但已成為整體生命週期中的一部分，而非唯一焦點。

**對使用者的影響**

- 使用者不再只拿到「建立一個 skill 骨架」的能力，而是可用同一套 skill 進行建立、評估、比較、報告與優化。
- 有了 analyzer / comparator / grader 這類角色分工，評估流程更具結構性。
- 有瀏覽器式 review UI 與報表工具後，skill 的迭代不再只是手動比對文字輸出，而能進入更系統化的 review 與 benchmark 流程。

**為何重要**

這是 skill-creator 演化中的關鍵躍遷：從「幫你做出 skill」升級為「幫你管理整個 skill 生命週期」。它也讓 meta-skill 的定位更鮮明，不只是產生器，而是 skill 工程化流程的核心工具。

---

### 3. 2026-02-06 — 新增 `compatibility` 欄位並同步強化驗證規則（PR #350）

**識別資訊**

- SHA：`1ed29a03dc852d30fa6ef2ca53a67dc2c2c2c563`
- 日期：`2026-02-06 21:19:32Z`
- 標題：`Update skill-creator and make scripts executable (#350)`

**變更檔案與重點**

- `SKILL.md`
  - 新增可選的 `compatibility` frontmatter 欄位
  - 明確說明只有 `name` 與 `description` 會影響觸發，`compatibility` 只用於記錄環境需求
- `scripts/init_skill.py`
  - 將 “Hyphen-case” 改名為更精確的 “Kebab-case”
  - skill 名稱長度上限由 40 提升為 64
- `scripts/quick_validate.py`
  - 允許 `compatibility`
  - 驗證其必須為字串，且長度不得超過 500 字
  - 驗證訊息中的名稱改為 kebab-case
  - 同步套用 64 字的 skill 名稱上限
- 儲存庫層級的附帶影響：
  - 其他 skills 的多個 script 被設為可執行（`chmod +x`）

**實質行為變更**

- skill metadata 模型更完整：除了名稱與描述之外，開始能表達環境或相容性要求。
- 建立與驗證流程被同步調整，表示這不是單純文件補充，而是**實際納入工具規則**的 schema 擴充。
- 命名規範措辭更一致，且 skill 名稱長度限制放寬，讓較長但仍具語意的名稱成為可行選項。

**對使用者的影響**

- 作者可以在不影響觸發邏輯的前提下，清楚記錄 skill 所需環境。
- 建立 skill 時對命名的包容度提高，但同時保留結構化驗證，避免 metadata 品質下降。
- 驗證器與文件一致，能減少「文件允許但工具拒絕」或反之的混亂。

**為何重要**

這一波顯示 skill-creator 開始以較成熟的產品心態管理 metadata：哪些欄位影響觸發、哪些只影響說明，被切分得更清楚。這有助於後續擴充欄位而不破壞核心觸發模型。

---

### 4. 2025-12-01 — 搬移到 `skills/` 命名空間（PR #129）

**識別資訊**

- SHA：`ef740771ac901e03fbca3ce4e1c453a96010f30a`
- 日期：`2025-12-01 18:05:36Z`
- 標題：`Move example skills into dedicated folder and create minimal top-level folder structure (#129)`

**對 skill-creator 的變更檔案**

此波對 skill-creator 的直接影響，主要是**路徑搬移**：

- `skill-creator/LICENSE.txt` → `skills/skill-creator/LICENSE.txt`
- `skill-creator/SKILL.md` → `skills/skill-creator/SKILL.md`
- `skill-creator/references/output-patterns.md` → `skills/skill-creator/references/output-patterns.md`
- `skill-creator/references/workflows.md` → `skills/skill-creator/references/workflows.md`
- `skill-creator/scripts/init_skill.py` → `skills/skill-creator/scripts/init_skill.py`
- `skill-creator/scripts/package_skill.py` → `skills/skill-creator/scripts/package_skill.py`
- `skill-creator/scripts/quick_validate.py` → `skills/skill-creator/scripts/quick_validate.py`

**實質行為變更**

- 就 skill-creator 本身來看，**未觀察到實質內容編輯**；重點是結構位置調整。
- 儲存庫層面則建立了 `skills/` 命名空間，將多個 example skills 收攏到一致的資料夾架構下。

**對使用者的影響**

- 使用者需要更新對 skill-creator 路徑的認知與引用方式。
- 對於依賴固定路徑的腳本、文件或安裝流程，這是一個需要同步調整的重要節點。
- 一旦遷移完成，整體儲存庫的組織會更一致，也更利於規模化維護。

**為何重要**

雖然這一波對功能沒有新增，但它是後續歷史辨識與維護方式的分水嶺：從這裡開始，skill-creator 的直接路徑歷史要在 `skills/skill-creator` 下追蹤。也正因如此，若只看搬移後路徑，會只看到 4 波直接相關更新。

---

### 5. 2025-11-17 — 搬移前最近的 skill-creator 重要前序更新（PR #112）

**識別資訊**

- PR：`#112`
- 合併時間：`2025-11-17 21:34:29Z`
- 標題：`Update example skills and rename 'artifacts-builder'`

> 這一波被納入本報告，是因為直接追溯 `skills/skill-creator` 的路徑歷史只會得到搬移後的 4 波更新；因此此處明確補入**在 2025-12-01 路徑搬移之前、最近且與 skill-creator 直接相關的前序變更波次**。

**變更檔案**

- `skill-creator/SKILL.md`
- 新增 `skill-creator/references/output-patterns.md`
- 新增 `skill-creator/references/workflows.md`
- `skill-creator/scripts/package_skill.py`
- `skill-creator/scripts/quick_validate.py`

**實質行為變更**

- `skill-creator/SKILL.md` 進行大幅補強，加入：
  - Core Principles
  - 精簡與 context window 的指引
  - degrees of freedom
  - 明確的 frontmatter / body 結構
  - 不該放進 skill 的內容
  - progressive disclosure 模式
  - 明確的 6 步驟建立流程
  - 參考 workflows / output-patterns
  - 更強的測試指引
  - frontmatter 撰寫規則
  - 更清楚的迭代工作流
- `scripts/package_skill.py`
  - 輸出格式從 `.zip` 改為 `.skill`
  - 對應訊息也同步更新
- `scripts/quick_validate.py`
  - 驗證變得更嚴格：
    - 安全解析 YAML
    - 拒絕未預期的 frontmatter keys
    - 更嚴格檢查型別
    - 更嚴格檢查名稱格式
    - 更嚴格檢查描述長度

**對使用者的影響**

- skill 作者得到更成熟的設計指南，知道 skill 該寫什麼、不該寫什麼，以及如何循序迭代。
- 封裝副檔名改為 `.skill`，讓產物語義更清楚，也更像專用封裝格式，而非一般壓縮檔。
- 驗證器更嚴格後，早期就能攔下 metadata 或格式錯誤，減少後續分發與安裝問題。

**為何重要**

PR #112 可視為 skill-creator 由「範例工具」走向「可複製方法論」的重要起點。它奠定了後續 schema、文件、驗證與封裝流程的基礎，也直接解釋了為什麼搬移到 `skills/` 之後，skill-creator 能快速進一步擴張。

## 整體演化總結

綜觀這 5 個變更波次，`skill-creator` 的演進可以分成四個階段：

1. **方法論成形（PR #112）**  
   先把 skill 該如何設計、封裝與驗證的規範立起來，建立可複製的創作流程。

2. **結構穩定化（PR #129）**  
   透過搬移到 `skills/` 命名空間，將 skill-creator 放入更一致的儲存庫拓樸中，為後續擴張鋪路。

3. **資料模型與規則成熟（PR #350）**  
   加入 `compatibility`，同步擴充初始化器與驗證器，顯示 skill metadata 開始往更正式的 schema 管理發展。

4. **平台化與流程整合（PR #465、PR #547）**  
   skill-creator 不再只是生成器，而是涵蓋建立、評估、比較、報告、描述優化與實務更新流程的完整工具鏈；接著再透過 CLI 化與文件修正，降低額外依賴並提升落地性。

整體來看，`skills/skill-creator` 已從一個偏「範例／腳手架」性質的 skill，逐步發展成一個支援 **建立、修改、評估、優化其他 skills** 的 meta-skill 平台。若後續要理解它的定位，最值得記住的不是單一腳本變動，而是它正在把 skill 開發流程制度化、工具化與可評估化。

---


