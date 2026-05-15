# C# / .NET 專案建立 `.gitattributes` 完整流程手冊

## 目的

建立 `.gitattributes` 主要是為了：

* 統一 LF / CRLF 換行符號
* 避免 Windows / macOS / Linux 跨平台問題
* 改善 Git diff 與 merge
* 正確處理 binary 檔案
* 避免 shell script 因 CRLF 爆炸

特別適合：

* ASP.NET Core
* .NET
* C#
* GitHub
* Docker
* Linux CI/CD
* macOS + Windows 混合團隊

---

# 1. 參考 GitHub `.gitattributes` 範例

可先搜尋 GitHub 上的現成範例：

```text
github .gitattributes csharp
```

或參考：

[GitHub gitignore 官方 repository](https://github.com/github/gitignore?utm_source=chatgpt.com)

---

# 2. 建立 `.gitattributes`

在專案根目錄建立：

```text
.gitattributes
```

---

# 3. 加入推薦 C# / .NET 模板

將以下內容貼入 `.gitattributes`：

```gitattributes
# =========================================
# Auto detect text files
# =========================================

* text=auto


# =========================================
# C# / .NET
# =========================================

*.cs         text diff=csharp
*.csproj     text
*.sln        text eol=crlf


# =========================================
# Config / Structured files
# =========================================

*.json       text
*.xml        text
*.yml        text eol=lf
*.yaml       text eol=lf


# =========================================
# Scripts
# =========================================

*.sh         text eol=lf
*.ps1        text eol=crlf
*.cmd        text eol=crlf
*.bat        text eol=crlf


# =========================================
# Markdown / Documentation
# =========================================

*.md         text


# =========================================
# Binary files
# =========================================

*.png        binary
*.jpg        binary
*.jpeg       binary
*.gif        binary
*.ico        binary
*.zip        binary
*.dll        binary
```

---

# 4. 初次加入 `.gitattributes`

加入 Git：

```bash
git add .gitattributes
```

建立 commit：

```bash
git commit -m "Add .gitattributes"
```

---

# 5. 重新正規化（非常重要）

## 為什麼需要這步？

新增 `.gitattributes` 後：

Git 不會自動重新處理舊檔案的換行格式。

因此需要：

```bash
git add --renormalize .
```

這會：

* 重新套用 `.gitattributes`
* 修正 LF / CRLF
* 更新 Git index

---

# 6. 提交正規化結果

```bash
git commit -m "Normalize line endings"
```

---

# 7. 完整流程（一次看）

## 建立 `.gitattributes`

```bash
touch .gitattributes
```

---

## 編輯 `.gitattributes`

貼入推薦模板。

---

## 初次加入 Git

```bash
git add .gitattributes
git commit -m "Add .gitattributes"
```

---

## 重新套用換行規則

```bash
git add --renormalize .
```

---

## 提交 normalization

```bash
git commit -m "Normalize line endings"
```

---

# 8. 檢查目前 EOL 狀態

可查看 Git 如何處理換行：

```bash
git ls-files --eol
```

可能看到：

```text
i/lf    w/crlf  attr/text=auto
```

---

## 欄位說明

| 欄位     | 意思                  |
| ------ | ------------------- |
| `i`    | Git index 內部格式      |
| `w`    | Working tree 實際格式   |
| `attr` | `.gitattributes` 規則 |

---

# 9. 建議搭配 `.editorconfig`

`.gitattributes`：

* 管 Git 行為

`.editorconfig`：

* 管編輯器格式

建議兩者一起使用。

---

## 建立 `.editorconfig`

```bash
dotnet new editorconfig
```

---

# 10. 建議 Git 設定

## macOS / Linux

```bash
git config --global core.autocrlf input
```

---

## Windows

```bash
git config --global core.autocrlf true
```

---

# 11. 常見問題

---

## Q1：為什麼 `.sh` 一定要 LF？

Linux shell script 若使用 CRLF：

可能出現：

```text
bad interpreter: /bin/bash^M
```

因此：

```gitattributes
*.sh text eol=lf
```

非常重要。

---

## Q2：為什麼 `.sln` 常用 CRLF？

因為：

* Visual Studio
* Windows 生態
* 某些舊工具

較偏好 CRLF。

---

## Q3：`binary` 有什麼作用？

例如：

```gitattributes
*.png binary
```

表示：

* 不做 diff
* 不做 merge
* 不做換行轉換

避免圖片檔損壞。

---

# 12. 推薦最佳實務

## 新專案

建立 repo 後立刻加入：

* `.gitignore`
* `.editorconfig`
* `.gitattributes`

避免後期大量 normalization diff。

---

## 舊專案

加入 `.gitattributes` 後：

務必執行：

```bash
git add --renormalize .
```

否則規則不會完全生效。

---

# 13. 最終建議

對於現代 C# / ASP.NET Core 專案：

非常建議固定配置：

* `.gitignore`
* `.editorconfig`
* `.gitattributes`

這能大幅減少：

* CRLF/LF 混亂
* CI/CD 問題
* Docker 問題
* shell script 爆炸
* Git diff 污染
* merge conflict
