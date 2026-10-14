#!/usr/bin/env bash
# =============================================================================
# Scuba Life - Firebase 設定ファイル取得・自動構成スクリプト (Bash / macOS / Linux)
# =============================================================================
set -euo pipefail

PROJECT_ID=""
PLATFORMS="android,ios"
ANDROID_PACKAGE="com.life_124c41.scuba_life"
IOS_BUNDLE_ID="com.life-124c41.scuba-life"
MOCK_MODE=false
YES_MODE=false

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# オプション解析
for arg in "$@"; do
  case $arg in
    --mock|-m)
      MOCK_MODE=true
      shift
      ;;
    --yes|-y)
      YES_MODE=true
      shift
      ;;
    --project=*)
      PROJECT_ID="${arg#*=}"
      shift
      ;;
    *)
      ;;
  esac
done

echo "========================================================="
echo "  Scuba Life - Firebase 設定ファイル取得・自動構成ツール"
echo "========================================================="
echo "プロジェクトルート: $PROJECT_ROOT"
echo ""

# 1. モック（テンプレート）モード
if [ "$MOCK_MODE" = true ]; then
  echo ">> [MOCK] テンプレートから仮設定ファイルを生成します..."
  if [ -f "$PROJECT_ROOT/lib/firebase_options.dart.example" ]; then
    cp "$PROJECT_ROOT/lib/firebase_options.dart.example" "$PROJECT_ROOT/lib/firebase_options.dart"
    echo "[OK] lib/firebase_options.dart をテンプレートから生成しました！"
    exit 0
  else
    echo "[ERROR] lib/firebase_options.dart.example が見つかりません。"
    exit 1
  fi
fi

# 2. PATH に Pub Cache bin を追加
if [ -d "$HOME/.pub-cache/bin" ]; then
  export PATH="$HOME/.pub-cache/bin:$PATH"
fi

# 3. 依存コマンドチェック
echo "[1/4] 開発ツールの依存関係をチェック中..."
command -v flutter >/dev/null 2>&1 || { echo "[ERROR] Flutter SDK が見つかりません。PATH を確認してください。"; exit 1; }
command -v dart >/dev/null 2>&1 || { echo "[ERROR] Dart SDK が見つかりません。"; exit 1; }

if ! command -v firebase >/dev/null 2>&1; then
  echo "  ⚠ Firebase CLI ('firebase') が見つかりません。"
  if command -v npm >/dev/null 2>&1; then
    echo "  >> npm install -g firebase-tools を実行しますか？"
    if [ "$YES_MODE" = true ]; then
      npm install -g firebase-tools
    else
      read -p "実行しますか？ (y/N): " ans
      if [[ "$ans" =~ ^[yY]$ ]]; then
        npm install -g firebase-tools
      else
        echo "[ERROR] Firebase CLI が必要です。手動でインストールしてください。"
        exit 1
      fi
    fi
  else
    echo "[ERROR] npm が見つかりません。Firebase CLI を手動でインストールしてください。"
    exit 1
  fi
fi

if ! command -v flutterfire >/dev/null 2>&1; then
  echo "  ⚠ FlutterFire CLI ('flutterfire') が見つかりません。"
  echo "  >> dart pub global activate flutterfire_cli を実行中..."
  dart pub global activate flutterfire_cli
  export PATH="$HOME/.pub-cache/bin:$PATH"
fi

# 4. Firebase 認証チェック
echo ""
echo "[2/4] Firebase 認証状態を確認中..."
if ! firebase projects:list >/dev/null 2>&1; then
  echo "  ⚠ Firebase にログインしていません。ログインを実行します..."
  firebase login
fi
echo "  ✔ Firebase ログイン確認済み"

# 5. FlutterFire configure 実行
echo ""
echo "[3/4] Firebase サーバーから最新設定を取得・自動生成中..."
EXTRA_ARGS=()
if [ -n "$PROJECT_ID" ]; then
  EXTRA_ARGS+=("--project=$PROJECT_ID")
fi
if [ "$YES_MODE" = true ]; then
  EXTRA_ARGS+=("--yes")
fi

flutterfire configure \
  --platforms="$PLATFORMS" \
  --android-package-name="$ANDROID_PACKAGE" \
  --ios-bundle-id="$IOS_BUNDLE_ID" \
  --out="lib/firebase_options.dart" \
  "${EXTRA_ARGS[@]}"

# 6. 結果確認
echo ""
echo "[4/4] 生成結果の検証..."
declare -a FILES=("lib/firebase_options.dart" "android/app/google-services.json" "ios/Runner/GoogleService-Info.plist")
ALL_PASSED=true

for file in "${FILES[@]}"; do
  if [ -f "$PROJECT_ROOT/$file" ]; then
    echo "  [OK] $file"
  else
    echo "  [NG (未生成)] $file"
    ALL_PASSED=false
  fi
done

echo ""
if [ "$ALL_PASSED" = true ]; then
  echo "========================================================="
  echo "  🎉 Firebase 設定ファイルの取得・構成が完了しました！   "
  echo "========================================================="
  flutter analyze --no-fatal-infos
else
  echo "一部のファイルが取得できませんでした。権限や手動実行をご確認ください。"
fi
