<#
.SYNOPSIS
    Firebase設定ファイル群（.gitignore対象の機密ファイル）を
    ローカルの安全なバックアップ先へ保存・またはバックアップ先から復元するスクリプト

.DESCRIPTION
    以下の機密設定ファイルを一括バックアップ / 復元します：
      - lib/firebase_options.dart
      - android/app/google-services.json
      - ios/Runner/GoogleService-Info.plist
      - firebase.json
      - .firebaserc

.PARAMETER Action
    実行するアクション ("Backup" または "Restore", 既定: Backup)
.PARAMETER BackupDir
    バックアップ保存先フォルダパス（既定: $HOME\.scuba_life_secrets）

.EXAMPLE
    # 現在のプロジェクト内の設定ファイルをバックアップ
    .\scripts\backup_firebase_configs.ps1 -Action Backup

.EXAMPLE
    # 保存済みバックアップからプロジェクト内へ復元
    .\scripts\backup_firebase_configs.ps1 -Action Restore
#>

[CmdletBinding()]
param (
    [ValidateSet("Backup", "Restore")]
    [string]$Action = "Backup",

    [string]$BackupDir = (Join-Path $env:USERPROFILE ".scuba_life_secrets")
)

$ErrorActionPreference = "Stop"

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ScriptDir) { $ScriptDir = (Get-Location).Path }
if ((Split-Path -Leaf $ScriptDir) -eq "scripts") {
    $ProjectRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path
} else {
    $ProjectRoot = (Resolve-Path $ScriptDir).Path
}

$TargetFiles = @(
    "lib/firebase_options.dart",
    "android/app/google-services.json",
    "ios/Runner/GoogleService-Info.plist",
    "firebase.json",
    ".firebaserc"
)

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "  Scuba Life - Firebase Configs Backup / Restore Tool    " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "Action:       $Action" -ForegroundColor Gray
Write-Host "Project Root: $ProjectRoot" -ForegroundColor Gray
Write-Host "Backup Dir:   $BackupDir" -ForegroundColor Gray
Write-Host ""

if ($Action -eq "Backup") {
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    }

    $count = 0
    foreach ($relPath in $TargetFiles) {
        $sourcePath = Join-Path $ProjectRoot $relPath
        if (Test-Path $sourcePath) {
            $destPath = Join-Path $BackupDir $relPath
            $destDir = Split-Path -Parent $destPath
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            Write-Host "  [BACKED UP] $relPath" -ForegroundColor Green
            $count++
        } else {
            Write-Host "  [NOT FOUND - SKIPPED] $relPath" -ForegroundColor Gray
        }
    }
    Write-Host ""
    Write-Host "[OK] $count file(s) backed up to '$BackupDir'." -ForegroundColor Green
}
elseif ($Action -eq "Restore") {
    if (-not (Test-Path $BackupDir)) {
        Write-Error "Backup directory not found: $BackupDir"
        exit 1
    }

    $count = 0
    foreach ($relPath in $TargetFiles) {
        $sourcePath = Join-Path $BackupDir $relPath
        if (Test-Path $sourcePath) {
            $destPath = Join-Path $ProjectRoot $relPath
            $destDir = Split-Path -Parent $destPath
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            Write-Host "  [RESTORED] $relPath" -ForegroundColor Green
            $count++
        } else {
            Write-Host "  [NO BACKUP] $relPath" -ForegroundColor Gray
        }
    }
    Write-Host ""
    Write-Host "[OK] $count file(s) restored into project." -ForegroundColor Green
}
