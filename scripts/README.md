# Firebase 設定ファイル管理スクリプト

`.gitignore` に登録されている Firebase 機密設定ファイル（`firebase_options.dart`、`google-services.json`、`GoogleService-Info.plist` など）を Firebase 公式から直接取得したり、安全にバックアップ・復元するためのスクリプト群です。

---

## 📁 管理対象ファイル

- `lib/firebase_options.dart` (FlutterFire 構成コード)
- `android/app/google-services.json` (Android 向け Google サービス定義)
- `ios/Runner/GoogleService-Info.plist` (iOS 向け Google サービス定義)
- `firebase.json` (Firebase プロジェクト定義)
- `.firebaserc` (Firebase プロジェクトエイリアス)

---

## 🚀 使い方

### 1. Firebase公式（FlutterFire CLI）から直接自動取得

Firebase CLI でログイン中のアカウントに紐づく Firebase プロジェクトから、最新の設定ファイルをダウンロード・自動構成します。
実行すると CLI 上でプロジェクト一覧が表示され、矢印キーで選択できます（コード内に Project ID を残す必要はありません）。

#### PowerShell (Windows):
```powershell
.\scripts\setup_firebase.ps1

# （任意）特定のプロジェクトIDを直接引数で指定したい場合
.\scripts\setup_firebase.ps1 -ProjectId <YOUR_PROJECT_ID>
```

#### Bash (macOS / Linux / Git Bash):
```bash
./scripts/setup_firebase.sh
# または自動承認
./scripts/setup_firebase.sh --yes
```

> **Note**:
> - Firebase CLI (`firebase-tools`) や FlutterFire CLI (`flutterfire_cli`) が未インストールの場合は、スクリプトが自動でインストール・PATH 設定までサポートします。
> - Firebase へのログイン（`firebase login`）が必要な場合は、自動でブラウザが開いて Google 認証を行えます。

---

### 2. モック生成モード（Firebase 未接続で今すぐビルド・解析を通したい場合）

Firebase アカウント権限の付与待ちやオフライン時など、とりあえず静的解析エラーを解消したい場合は、テンプレートからダミー設定ファイルを即座に生成できます。

#### PowerShell (Windows):
```powershell
.\scripts\setup_firebase.ps1 -Mock
```

#### Bash (macOS / Linux / Git Bash):
```bash
./scripts/setup_firebase.sh --mock
```

---

### 3. バックアップ & 復元（安全な別ディレクトリでの保管）

一度取得した機密設定ファイルをローカルの安全なディレクトリ（既定: `~/.scuba_life_secrets`）に退避、または別PC・新規クローン時に復元できます。

#### バックアップの作成:
```powershell
# PowerShell
.\scripts\backup_firebase_configs.ps1 -Action Backup

# Bash
./scripts/backup_firebase_configs.sh --backup
```

#### バックアップからの復元:
```powershell
# PowerShell
.\scripts\backup_firebase_configs.ps1 -Action Restore

# Bash
./scripts/backup_firebase_configs.sh --restore
```
