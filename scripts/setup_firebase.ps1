<#
.SYNOPSIS
    Firebase設定ファイル（firebase_options.dart 等）を
    Firebase公式（FlutterFire CLI）から直接ダウンロード・自動生成するスクリプト

.DESCRIPTION
    1. Flutter, Firebase CLI, FlutterFire CLI の依存関係を自動検出＆必要に応じてセットアップ
    2. Firebase アカウントへのログイン確認（未ログイン時はログイン画面へ誘導）
    3. flutterfire configure を実行し、Scuba Life プロジェクトの最新設定ファイルを一括取得・生成
       - lib/firebase_options.dart
       - android/app/google-services.json
       - ios/Runner/GoogleService-Info.plist
       - firebase.json
    4. 生成結果の検証（ファイル存在チェック & flutter analyze 検証）

.PARAMETER ProjectId
    Firebase プロジェクト ID（省略時は FlutterFire CLI の対話選択メニューから選択）
.PARAMETER Platforms
    構成するプラットフォーム（既定: android,ios）
.PARAMETER AndroidPackage
    Android パッケージ名（既定: com.life_124c41.scuba_life）
.PARAMETER IosBundleId
    iOS Bundle ID（既定: com.life-124c41.scuba-life）
.PARAMETER Mock
    Firebase サーバーに接続せず、example テンプレートから仮設定ファイルを生成（オフライン/解析エラー即時解消用）
.PARAMETER Yes
    対話プロンプトなしで自動適用（--yes）

.EXAMPLE
    .\scripts\setup_firebase.ps1
.EXAMPLE
    .\scripts\setup_firebase.ps1 -Mock
.EXAMPLE
    .\scripts\setup_firebase.ps1 -Yes
#>

[CmdletBinding()]
param (
    [string]$ProjectId = "",
    [string]$Platforms = "android,ios",
    [string]$AndroidPackage = "com.life_124c41.scuba_life",
    [string]$IosBundleId = "com.life-124c41.scuba-life",
    [switch]$Mock,
    [switch]$Yes
)

$ErrorActionPreference = "Stop"

# プロジェクトルートディレクトリの特定
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $ScriptDir) { $ScriptDir = (Get-Location).Path }
if ((Split-Path -Leaf $ScriptDir) -eq "scripts") {
    $ProjectRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path
} else {
    $ProjectRoot = (Resolve-Path $ScriptDir).Path
}
Set-Location $ProjectRoot

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "  Scuba Life - Firebase Configuration Fetcher / Setup    " -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "Project Root: $ProjectRoot" -ForegroundColor Gray
Write-Host ""

# -----------------------------------------------------------------------------
# 1. モック（テンプレート）モードの処理
# -----------------------------------------------------------------------------
if ($Mock) {
    Write-Host "[MOCK] Generating temporary configuration from template..." -ForegroundColor Yellow
    $exampleFile = Join-Path $ProjectRoot "lib\firebase_options.dart.example"
    $targetFile = Join-Path $ProjectRoot "lib\firebase_options.dart"

    if (-not (Test-Path $exampleFile)) {
        Write-Error "Template file not found: $exampleFile"
        exit 1
    }

    Copy-Item -Path $exampleFile -Destination $targetFile -Force
    Write-Host "[OK] Created lib/firebase_options.dart from example template!" -ForegroundColor Green
    Write-Host "[NOTE] This is a mock template with dummy credentials." -ForegroundColor Yellow
    Write-Host "       To connect to real Firebase, rerun this script without -Mock." -ForegroundColor Yellow
    exit 0
}

# -----------------------------------------------------------------------------
# 2. 環境変数 PATH への Pub Cache 追加（Windows）
# -----------------------------------------------------------------------------
$pubCacheBin = Join-Path $env:LOCALAPPDATA "Pub\Cache\bin"
if (Test-Path $pubCacheBin) {
    if ($env:PATH -notlike "*$pubCacheBin*") {
        $env:PATH = "$pubCacheBin;$env:PATH"
    }
}

# -----------------------------------------------------------------------------
# 3. 依存コマンドのチェック & 自動インストール案内
# -----------------------------------------------------------------------------
Write-Host "[1/4] Checking development dependencies..." -ForegroundColor Cyan

# 3-1. Flutter
$flutterCmd = Get-Command "flutter" -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    Write-Error "Flutter SDK not found in PATH."
    exit 1
}
Write-Host "  [OK] Flutter: $($flutterCmd.Source)" -ForegroundColor Green

# 3-2. Dart
$dartCmd = Get-Command "dart" -ErrorAction SilentlyContinue
if (-not $dartCmd) {
    Write-Error "Dart SDK not found."
    exit 1
}
Write-Host "  [OK] Dart:    $($dartCmd.Source)" -ForegroundColor Green

# 3-3. Firebase CLI (firebase)
$firebaseCmd = Get-Command "firebase" -ErrorAction SilentlyContinue
if (-not $firebaseCmd) {
    Write-Host "  [WARN] Firebase CLI ('firebase') not found." -ForegroundColor Yellow
    $npmCmd = Get-Command "npm" -ErrorAction SilentlyContinue
    if ($npmCmd) {
        Write-Host "  npm found. Install Firebase CLI globally? (Y/n): " -ForegroundColor Yellow -NoNewline
        $ans = if ($Yes) { "Y" } else { Read-Host }
        if ($ans -eq "" -or $ans -match "^[yY]") {
            Write-Host "  >> Running 'npm install -g firebase-tools'..." -ForegroundColor Cyan
            npm install -g firebase-tools
            $firebaseCmd = Get-Command "firebase" -ErrorAction SilentlyContinue
        }
    }
    
    if (-not $firebaseCmd) {
        Write-Host ""
        Write-Host "[ERROR] Firebase CLI is required. Please install it:" -ForegroundColor Red
        Write-Host "  1. Via npm: npm install -g firebase-tools" -ForegroundColor White
        Write-Host "  2. Standalone: https://firebase.google.com/docs/cli#install_the_firebase_cli" -ForegroundColor White
        Write-Host ""
        Write-Host "Hint: To resolve code analysis errors immediately without Firebase," -ForegroundColor Gray
        Write-Host "      run: .\scripts\setup_firebase.ps1 -Mock" -ForegroundColor Gray
        exit 1
    }
}
Write-Host "  [OK] Firebase CLI: $($firebaseCmd.Source)" -ForegroundColor Green

# 3-4. FlutterFire CLI (flutterfire)
$flutterfireCmd = Get-Command "flutterfire" -ErrorAction SilentlyContinue
if (-not $flutterfireCmd) {
    Write-Host "  [WARN] FlutterFire CLI ('flutterfire') not found." -ForegroundColor Yellow
    Write-Host "  >> Running 'dart pub global activate flutterfire_cli'..." -ForegroundColor Cyan
    dart pub global activate flutterfire_cli
    
    if (Test-Path $pubCacheBin -and ($env:PATH -notlike "*$pubCacheBin*")) {
        $env:PATH = "$pubCacheBin;$env:PATH"
    }
    $flutterfireCmd = Get-Command "flutterfire" -ErrorAction SilentlyContinue
    
    if (-not $flutterfireCmd) {
        $directBat = Join-Path $pubCacheBin "flutterfire.bat"
        if (Test-Path $directBat) {
            $flutterfireCmd = $directBat
        } else {
            Write-Error "Failed to activate flutterfire_cli. Run 'dart pub global activate flutterfire_cli' manually."
            exit 1
        }
    }
}
Write-Host "  [OK] FlutterFire CLI: $flutterfireCmd" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 4. Firebase 認証チェック
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "[2/4] Checking Firebase authentication status..." -ForegroundColor Cyan
$loginTest = & firebase projects:list 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "  [WARN] Not logged into Firebase or credentials expired." -ForegroundColor Yellow
    Write-Host "  >> Launching browser to sign in to Firebase..." -ForegroundColor Cyan
    & firebase login
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Firebase login failed. Please sign in and try again."
        exit 1
    }
}
Write-Host "  [OK] Firebase authentication verified." -ForegroundColor Green

# -----------------------------------------------------------------------------
# 5. FlutterFire configure の実行
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "[3/4] Fetching latest configurations from Firebase..." -ForegroundColor Cyan
if ($ProjectId) {
    Write-Host "  Project ID:      $ProjectId" -ForegroundColor Gray
} else {
    Write-Host "  Project ID:      (Interactive selection via CLI)" -ForegroundColor Gray
}
Write-Host "  Platforms:       $Platforms" -ForegroundColor Gray
Write-Host "  Android Package: $AndroidPackage" -ForegroundColor Gray
Write-Host "  iOS Bundle ID:   $IosBundleId" -ForegroundColor Gray
Write-Host "  Output File:     lib/firebase_options.dart" -ForegroundColor Gray
Write-Host ""

$configureArgs = @(
    "configure",
    "--platforms=$Platforms",
    "--android-package-name=$AndroidPackage",
    "--ios-bundle-id=$IosBundleId",
    "--out=lib/firebase_options.dart"
)

if ($ProjectId) {
    $configureArgs += "--project=$ProjectId"
}

if ($Yes) {
    $configureArgs += "--yes"
}

# FlutterFire 実行
& $flutterfireCmd @configureArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "[WARN] 'flutterfire configure' exited with code $LASTEXITCODE." -ForegroundColor Yellow
    if ($ProjectId) {
        Write-Host "Please check that your account has access to project '$ProjectId'." -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------------------
# 6. 生成結果の検証
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "[4/4] Verifying generated configuration files..." -ForegroundColor Cyan

$expectedFiles = @(
    @{ Path = "lib/firebase_options.dart"; Required = $true },
    @{ Path = "android/app/google-services.json"; Required = $true },
    @{ Path = "ios/Runner/GoogleService-Info.plist"; Required = $true },
    @{ Path = "firebase.json"; Required = $false },
    @{ Path = ".firebaserc"; Required = $false }
)

$allPassed = $true
foreach ($file in $expectedFiles) {
    $fullPath = Join-Path $ProjectRoot $file.Path
    if (Test-Path $fullPath) {
        Write-Host "  [FOUND] $($file.Path)" -ForegroundColor Green
    } else {
        if ($file.Required) {
            Write-Host "  [MISSING] $($file.Path)" -ForegroundColor Red
            $allPassed = $false
        } else {
            Write-Host "  [SKIPPED] $($file.Path)" -ForegroundColor Gray
        }
    }
}

Write-Host ""
if ($allPassed) {
    Write-Host "=========================================================" -ForegroundColor Green
    Write-Host "  SUCCESS: Firebase configuration files are ready!       " -ForegroundColor Green
    Write-Host "=========================================================" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Running static analysis (flutter analyze)..." -ForegroundColor Cyan
    & flutter analyze --no-fatal-infos
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] 0 issues found. Ready to build and run!" -ForegroundColor Green
    }
} else {
    Write-Host "=========================================================" -ForegroundColor Yellow
    Write-Host "  Some configuration files could not be generated.       " -ForegroundColor Yellow
    Write-Host "=========================================================" -ForegroundColor Yellow
    Write-Host "You can run flutterfire configure manually:" -ForegroundColor Yellow
    if ($ProjectId) {
        Write-Host "  flutterfire configure --project=$ProjectId" -ForegroundColor White
    } else {
        Write-Host "  flutterfire configure" -ForegroundColor White
    }
}
