# ai_skills

存放通用型的 skill 檔。

## 自動同步機制

每次執行 `git push` 後，git `post-push` hook 會自動呼叫 `sync-skills.bat`，將根目錄層的所有 skill 資料夾（排除 `.github`、`.git`）同步至：

```
C:\Users\Dinoin_Chen\.copilot\skills\
```

**同步範圍**

| 來源（ai_skills 根目錄）| 目標 |
|---|---|
| `pdf/` | `C:\Users\Dinoin_Chen\.copilot\skills\pdf\` |
| 未來新增的 `<skill>/` | `C:\Users\Dinoin_Chen\.copilot\skills\<skill>\` |

> `.github/` 和 `.git/` 資料夾不在同步範圍內。

**手動同步**

```bat
sync-skills.bat
```

---

## 本專案用 Skills

### `github-folder-downloader`

從 GitHub tree URL 遞迴下載資料夾中的所有內容（含子資料夾）至本地。

**AI觸發方式**
- 在 Copilot Chat 輸入 `/github-folder-downloader` 直接指定技能或直接描述需求。
- 描述需求（例：「幫我下載這個 GitHub 資料夾」）並附上 URL

**直接使用範例**

```powershell
# 切換至下載腳本目錄
cd ai_skills/.github/skills/github-folder-downloader/scripts

# 公開倉庫（自動在目前目錄建立 pdf/ 子資料夾）
.\download-github-folder.ps1 -Url "https://github.com/anthropics/skills/tree/main/skills/pdf"
# → 下載至 ./pdf/

# 指定輸出根目錄（自動建立 pdf/ 子資料夾於指定路徑下）
.\download-github-folder.ps1 -Url "https://github.com/anthropics/skills/tree/main/skills/pdf" -OutputDir "C:\Downloads"
# → 下載至 C:\Downloads\pdf\

# 私有倉庫（透過環境變數）
$env:GITHUB_TOKEN = "ghp_xxxxxxxxxxxx"
.\download-github-folder.ps1 -Url "https://github.com/owner/private-repo/tree/main/docs"

# 私有倉庫（直接傳入 Token）
.\download-github-folder.ps1 -Url "..." -Token "ghp_xxxxxxxxxxxx"
```

**輸出目錄規則**

| URL 路徑末段 | OutputDir | 實際下載位置 |
|-------------|-----------|-------------|
| `skills/pdf` | `（預設，目前目錄）` | `./pdf/` |
| `docs/api` | `C:\Downloads` | `C:\Downloads\api\` |
| `src` | `D:\Work` | `D:\Work\src\` |

> **平鋪行為**：子目錄中的檔案也會直接放入 `pdf/`，不重建內層目錄結構。

**注意事項**
- URL 必須包含 `/tree/` 路徑段（GitHub 資料夾的 tree URL）
- 未設定 Token 時，GitHub API 每小時限 60 次請求；設定後提升至 5000 次
- 個別檔案下載失敗時顯示 Warning 並繼續，不中斷整體流程
