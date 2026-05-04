<#
.SYNOPSIS
    從 GitHub 資料夾 URL 下載所有內容（包含子資料夾）

.DESCRIPTION
    解析 GitHub tree URL，呼叫 GitHub API 遞迴列出所有檔案並下載。
    支援公開倉庫（無需 Token）與私有倉庫（需設定 GITHUB_TOKEN）。

.PARAMETER Url
    GitHub 資料夾 URL，格式：
    https://github.com/{owner}/{repo}/tree/{branch}/{path}

.PARAMETER OutputDir
    本地下載目標目錄，預設為目前工作目錄。

.PARAMETER Token
    GitHub Personal Access Token，預設讀取環境變數 GITHUB_TOKEN。
    私有倉庫或避免 API Rate Limit 時使用。

.EXAMPLE
    .\download-github-folder.ps1 -Url "https://github.com/anthropics/skills/tree/main/skills/pdf"
    .\download-github-folder.ps1 -Url "https://github.com/owner/repo/tree/main/docs" -OutputDir "C:\MyDocs"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Url,

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = $PWD.Path,

    [Parameter(Mandatory = $false)]
    [string]$Token = $env:GITHUB_TOKEN
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── URL 解析 ──────────────────────────────────────────────
function ConvertFrom-GitHubUrl {
    param([string]$Url)

    $pattern = '^https://github\.com/([^/]+)/([^/]+)/tree/([^/]+)(/(.+))?$'
    if ($Url -notmatch $pattern) {
        throw "無效的 GitHub URL 格式。期望格式：`nhttps://github.com/{owner}/{repo}/tree/{branch}/{path}"
    }
    return @{
        Owner  = $Matches[1]
        Repo   = $Matches[2]
        Branch = $Matches[3]
        Path   = if ($Matches[5]) { $Matches[5].TrimEnd('/') } else { '' }
    }
}

# ── 建立 HTTP Headers ────────────────────────────────────
function New-GitHubHeaders {
    param([string]$Token)
    $h = @{
        'User-Agent' = 'GitHub-Folder-Downloader/1.0'
        'Accept'     = 'application/vnd.github.v3+json'
    }
    if ($Token) { $h['Authorization'] = "Bearer $Token" }
    return $h
}

# ── 遞迴取得並平鋪下載所有檔案（所有子目錄的檔案皆直接放入 OutputDir）────
function Invoke-DownloadFolder {
    param(
        [string]$Owner,
        [string]$Repo,
        [string]$Branch,
        [string]$FolderPath,   # 在 repo 中的路徑
        [string]$OutputDir,    # 所有檔案的目標目錄（平鋪，不建立內層子目錄）
        [hashtable]$Headers
    )

    $encodedPath = [uri]::EscapeDataString($FolderPath) -replace '%2F', '/'
    $apiUrl = "https://api.github.com/repos/$Owner/$Repo/contents/$encodedPath"
    if ($Branch) { $apiUrl += "?ref=$Branch" }

    try {
        $items = Invoke-RestMethod -Uri $apiUrl -Headers $Headers -ErrorAction Stop
    }
    catch {
        $statusCode = $_.Exception.Response?.StatusCode.value__
        switch ($statusCode) {
            403 { throw "GitHub API Rate Limit 超限，請設定 GITHUB_TOKEN 環境變數後重試。" }
            404 { throw "路徑不存在：$FolderPath（分支：$Branch）" }
            default { throw "GitHub API 呼叫失敗（HTTP $statusCode）：$_" }
        }
    }

    # 確保 $items 為陣列（單一檔案時 API 回傳物件）
    if ($items -isnot [array]) { $items = @($items) }

    foreach ($item in $items) {
        if ($item.type -eq 'file') {
            # 平鋪：只取檔案名稱，不重建子目錄結構
            $localPath = Join-Path $OutputDir $item.name

            Write-Host "  下載：$($item.path)" -ForegroundColor Cyan
            try {
                Invoke-WebRequest -Uri $item.download_url -OutFile $localPath -Headers $Headers -ErrorAction Stop
            }
            catch {
                Write-Warning "下載失敗：$($item.path) — $_"
            }
        }
        elseif ($item.type -eq 'dir') {
            # 遞迴子目錄，但輸出目錄不變（維持平鋪）
            Invoke-DownloadFolder `
                -Owner      $Owner `
                -Repo       $Repo `
                -Branch     $Branch `
                -FolderPath $item.path `
                -OutputDir  $OutputDir `
                -Headers    $Headers
        }
    }
}

# ── 主程式 ────────────────────────────────────────────────
$parsed  = ConvertFrom-GitHubUrl -Url $Url
$headers = New-GitHubHeaders -Token $Token

# 以 URL 路徑的最後一段作為子資料夾名稱（例如 skills/pdf → pdf）
$folderName = if ($parsed.Path) { Split-Path $parsed.Path -Leaf } else { $parsed.Repo }
$finalOutputDir = Join-Path $OutputDir $folderName

if (-not (Test-Path $finalOutputDir)) {
    New-Item -ItemType Directory -Path $finalOutputDir -Force | Out-Null
}

Write-Host ""
Write-Host "GitHub 資料夾下載器" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "  倉庫  ：$($parsed.Owner)/$($parsed.Repo)" -ForegroundColor Gray
Write-Host "  分支  ：$($parsed.Branch)" -ForegroundColor Gray
Write-Host "  路徑  ：$(if ($parsed.Path) { $parsed.Path } else { '（根目錄）' })" -ForegroundColor Gray
Write-Host "  輸出  ：$finalOutputDir" -ForegroundColor Gray
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

Invoke-DownloadFolder `
    -Owner      $parsed.Owner `
    -Repo       $parsed.Repo `
    -Branch     $parsed.Branch `
    -FolderPath $parsed.Path `
    -OutputDir  $finalOutputDir `
    -Headers    $headers

Write-Host ""
Write-Host "✓ 下載完成！檔案已儲存至：$finalOutputDir" -ForegroundColor Green
