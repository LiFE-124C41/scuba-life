#!/usr/bin/env bash
# =============================================================================
# Scuba Life - Firebase 設定ファイル バックアップ/復元スクリプト (Bash)
# =============================================================================
set -euo pipefail

ACTION="Backup"
BACKUP_DIR="${HOME}/.scuba_life_secrets"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

for arg in "$@"; do
  case $arg in
    --action=*)
      ACTION="${arg#*=}"
      shift
      ;;
    --restore|-r)
      ACTION="Restore"
      shift
      ;;
    --backup|-b)
      ACTION="Backup"
      shift
      ;;
    --dir=*)
      BACKUP_DIR="${arg#*=}"
      shift
      ;;
    *)
      ;;
  esac
done

TARGET_FILES=(
  "lib/firebase_options.dart"
  "android/app/google-services.json"
  "ios/Runner/GoogleService-Info.plist"
  "firebase.json"
  ".firebaserc"
)

echo "========================================================="
echo "  Scuba Life - Firebase Configs Backup / Restore Tool    "
echo "========================================================="
echo "Action:       $ACTION"
echo "Project Root: $PROJECT_ROOT"
echo "Backup Dir:   $BACKUP_DIR"
echo ""

if [ "$ACTION" = "Backup" ]; then
  mkdir -p "$BACKUP_DIR"
  count=0
  for file in "${TARGET_FILES[@]}"; do
    src="$PROJECT_ROOT/$file"
    if [ -f "$src" ]; then
      dest="$BACKUP_DIR/$file"
      mkdir -p "$(dirname "$dest")"
      cp -f "$src" "$dest"
      echo "  [BACKED UP] $file"
      count=$((count + 1))
    else
      echo "  [NOT FOUND - SKIPPED] $file"
    fi
  done
  echo ""
  echo "[OK] $count file(s) backed up to '$BACKUP_DIR'."
elif [ "$ACTION" = "Restore" ]; then
  if [ ! -d "$BACKUP_DIR" ]; then
    echo "[ERROR] Backup directory not found: $BACKUP_DIR"
    exit 1
  fi
  count=0
  for file in "${TARGET_FILES[@]}"; do
    src="$BACKUP_DIR/$file"
    if [ -f "$src" ]; then
      dest="$PROJECT_ROOT/$file"
      mkdir -p "$(dirname "$dest")"
      cp -f "$src" "$dest"
      echo "  [RESTORED] $file"
      count=$((count + 1))
    else
      echo "  [NO BACKUP] $file"
    fi
  done
  echo ""
  echo "[OK] $count file(s) restored into project."
fi
