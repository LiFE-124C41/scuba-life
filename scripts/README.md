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

---

## 🚀 4. Firebase App Distribution への配布 (GitHub Actions)

CI/CD によるビルド＆テスター配布は、GitHub Actions ワークフロー [`.github/workflows/firebase_app_distribution.yml`](../.github/workflows/firebase_app_distribution.yml) により全自動化されています。

### 🐙 実行方法
1. GitHub リポジトリの **Actions** タブを開きます。
2. 左メニューから **Firebase App Distribution** を選択します。
3. **Run workflow** をクリックし、以下を指定して実行します：
   - 対象プラットフォーム (`android` / `ios`)
   - バイナリ形式 (`apk` / `aab`)
   - 配布先テスターグループ名 (`testers` 等)
   - リリースノート（任意、未入力時は直近のコミット情報から自動生成）

### 🔐 必要な GitHub Repository Secrets
リポジトリの **Settings** > **Secrets and variables** > **Actions** に以下を登録します：

| Secret 名 | 必須度 | 説明 |
| :--- | :---: | :--- |
| `FIREBASE_SERVICE_ACCOUNT` | **推奨** | GCPコンソールで発行した Firebase 管理者権限を持つサービスアカウントキー JSON の全文 |
| `FIREBASE_TOKEN` | 代替 | `firebase login:ci` コマンドで生成された CI 認証トークン |
| `GOOGLE_SERVICES_JSON_BASE64` | 任意 | `android/app/google-services.json` を base64 エンコードした文字列（`.gitignore` されている場合） |
| `FIREBASE_OPTIONS_DART_BASE64` | 任意 | `lib/firebase_options.dart` を base64 エンコードした文字列（`.gitignore` されている場合） |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | 任意 | `ios/Runner/GoogleService-Info.plist` を base64 エンコードした文字列（iOS配布時） |

> **Base64 文字列の作成方法（PowerShell）:**
> ```powershell
> [Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/google-services.json")) | Set-Clipboard
> ```

---

### ⚠️ Android のバイナリ形式に関する注意点 (`apk` vs `aab`)

| 形式 | Google Play 連携 | 推奨ユースケース | 特徴 |
| :--- | :---: | :--- | :--- |
| **`apk`** | **不要** | **テスター配布（既定・推奨）** | Firebase App Distribution 単体ですぐに配布可能。テスターはそのままアプリをインストールできます。 |
| **`aab`** | **必須** | 本番ストア提出の事前検証 | Google Play の内部アプリ共有バックエンドを利用するため、**Firebase プロジェクトと Google Play Console の連携**が必須です。未連携の場合は `This project is not linked to a Google Play account.` エラーになります。 |

> **Google Play との連携手順（AAB 配布を行いたい場合）:**
> 1. [Firebase Console](https://console.firebase.google.com/) を開く。
> 2. プロジェクトの「設定（歯車マーク）」>「統合（Integrations）」タブを開く。
> 3. 「Google Play」カードの「リンク」をクリックし、Google Play Developer アカウントとリンクを完了させる。



