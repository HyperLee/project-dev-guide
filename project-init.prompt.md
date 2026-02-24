---
agent: 'agent'
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

### 3. 修改 `.editorconfig` 以強制程式碼風格

請將以下 `.editorconfig` 設定合併到專案根目錄的 `.editorconfig` 檔案：

```ini
[*]
insert_final_newline = true

# 設定預設字元集為 UTF-8-bom
[*.{cs, csx, vb, vbx, txt, html, css, js, json, yml, yaml, xml, config, ini, sh,
ps1, psm1, ps1xml, csproj, sln, gitignore, gitattributes,
editorconfig, md, markdown, txt, asciidoc, adoc, asc, asciidoc, txt, ipynb, py}]
charset = utf-8-bom
```

---

### 4. 加入 startDebugging 設定

```text
 幫我產生本專案 debugging 所需要 `launch.json`, `tasks.json` 檔案資料, 執行時候我不要輸入名稱. 我要可以直接執行
```

---

> 依照上述步驟逐一執行，確保專案初始化設定完善。

---

Let's do this step by step to ensure the project initialization is complete.
