---
name: github-folder-downloader
description: "下載 GitHub 資料夾中的所有內容。當使用者提供 GitHub tree URL（格式：https://github.com/{owner}/{repo}/tree/{branch}/{path}）並要求下載其中所有檔案時使用此 skill。支援遞迴下載子資料夾、私有倉庫（透過 GITHUB_TOKEN）、指定本地輸出目錄。觸發關鍵字：下載 GitHub 資料夾、download github folder、clone github directory、抓取 GitHub 目錄內容。"
argument-hint: "GitHub 資料夾 URL，例如：https://github.com/owner/repo/tree/main/path"
---

# GitHub 資料夾下載器

## 功能
從 GitHub 的資料夾 URL 遞迴下載其中所有檔案（含子資料夾）至本地目錄。

## 觸發時機
- 使用者提供 `https://github.com/.../tree/...` 格式的 URL 並要求下載內容
- 需要將 GitHub 上某個目錄的完整內容複製到本地
- 需要批次下載 GitHub repo 中某個路徑下的所有檔案

## 使用限制
- **不支援** `https://github.com/{owner}/{repo}` 整個 repo 下載（請改用 `git clone`）
- URL 必須包含 `/tree/` 路徑段才能識別分支與目錄
- 公開倉庫無需 Token；私有倉庫需設定 `GITHUB_TOKEN`
- GitHub API 未授權時每小時限 60 次請求；有 Token 時每小時 5000 次

## 執行程序

### 步驟一：確認輸入
向使用者確認或收集以下資訊：
- **GitHub URL**（必填）：完整的 tree URL
- **輸出目錄**（選填）：本地儲存路徑，預設為當前工作目錄
- **GitHub Token**（選填）：私有倉庫或大量下載時建議設定

### 步驟二：執行下載腳本
呼叫 [download-github-folder.ps1](./scripts/download-github-folder.ps1) 進行下載：

```powershell
# 基本用法（公開倉庫）
.\download-github-folder.ps1 -Url "https://github.com/owner/repo/tree/main/path/to/folder"

# 指定輸出目錄
.\download-github-folder.ps1 -Url "https://github.com/owner/repo/tree/main/path" -OutputDir "C:\MyDownloads"

# 私有倉庫（使用 Token）
$env:GITHUB_TOKEN = "ghp_xxxxxxxxxxxx"
.\download-github-folder.ps1 -Url "https://github.com/owner/repo/tree/main/path"

# 或直接傳入 Token
.\download-github-folder.ps1 -Url "..." -Token "ghp_xxxxxxxxxxxx"
```

### 步驟三：驗證結果
下載完成後確認：
1. 輸出目錄中的檔案數量是否符合預期
2. 是否有任何下載失敗的警告訊息
3. 子資料夾結構是否完整保留

## 腳本說明

[download-github-folder.ps1](./scripts/download-github-folder.ps1) 的核心邏輯：

| 函式 | 說明 |
|------|------|
| `ConvertFrom-GitHubUrl` | 解析 URL，提取 owner/repo/branch/path |
| `New-GitHubHeaders` | 建立 API Headers（含可選 Token 認證） |
| `Invoke-DownloadFolder` | 遞迴呼叫 GitHub Contents API 並下載所有檔案 |

## 錯誤處理

| 錯誤訊息 | 原因 | 解決方式 |
|----------|------|----------|
| 無效的 GitHub URL 格式 | URL 不含 `/tree/` | 確認使用 tree URL |
| GitHub API Rate Limit 超限 | 未授權 API 達到限制 | 設定 `GITHUB_TOKEN` |
| 路徑不存在 | 路徑或分支名稱有誤 | 確認 URL 是否正確 |
| 下載失敗（個別檔案） | 網路或權限問題 | 檢查 Warning 訊息後手動下載 |
