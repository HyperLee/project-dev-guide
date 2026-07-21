---
description: Project Initialization
---

# proj initialization

## 專案初始化步驟

### 1. 產生 `.gitignore`

```bash
dotnet new gitignore
```

---

### 2. 產生 `.editorconfig`

```bash
dotnet new editorconfig
```

---

### 3. 加入 startDebugging 設定

```text
 幫我產生本專案 debugging 所需要 `launch.json`, `tasks.json` 檔案資料, 執行時候我不要輸入名稱. 我要可以直接執行
```

---

### 4. 產生 AI 工具初始化設定 

CLI 的 slash command 是 `/init`，可以幫助你快速完成專案的 AI 工具初始化設定。

```text
/init
```

---

### 5. 專案收尾與後續步驟

在準備提交或交付前，依序完成以下檢查：

1. 在 `Main` function 或主要進入點加入可執行的測試資料。若 XML 註解是題目描述或原始需求，請不要異動。
2. 為每個主要 function 補上 XML `summary`，說明用途、解題概念、輸入條件與輸出結果。
3. 在關鍵演算法或判斷流程旁加入必要註解，說明解題思路，不要加入無意義的逐行註解。
4. 參考 `docs/readme-template.md` 建立或整理 `README.md`。
5. `README.md` 應包含題目說明、限制條件、解題概念與出發點、每一種解法的設計說明(越詳細越好)，以及每一種解法的範例演示流程。
6. 完成後執行專案可用的建置、測試或範例執行命令，確認 README 中記錄的指令與實際結果一致。
7. 執行 `git diff --check`，確認沒有多餘空白或換行問題。


---

> 依照上述步驟逐一執行，確保專案初始化設定完善。

---

Let's do this step by step to ensure the project initialization is complete.
