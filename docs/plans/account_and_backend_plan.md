# アカウント登録・サーバーデータ管理 導入計画書 & アーキテクチャ設計 (Firebase編)

本ドキュメントは、**Scuba Life** アプリケーションにアカウント登録（サインアップ/サインイン）機能を新設し、各種データ（ログブック・機材・予定・スポット）を **Firebase (Authentication & Cloud Firestore)** で一元管理・同期するための全体設計、ディレクトリ構成、マイルストーン、および実装手順をまとめたものです。

---

## 1. 決定事項サマリー

ユーザーヒアリングに基づき、以下の方針で決定・合意しました：

1. **インフラ・バックエンド基盤**:
   - **Firebase (Google Cloud エコシステム)** を採用。
   - 認証: **Firebase Authentication**
   - データベース: **Cloud Firestore (NoSQL ドキュメント指向DB)**
   - ファイル保存: **Firebase Cloud Storage** (将来のログ写真・ライセンス画像用)
2. **サポートする認証方式**:
   - 【必須・先行実装】**メールアドレス ＋ パスワード認証**
   - 【必須・先行実装】**Google サインイン**
   - 【追加フェーズ】**Apple でサインイン** (iOS App Store 申請要件)
3. **オフライン方針**:
   - **フェーズ分け対応**: まずはオンライン前提で確実な認証とFirestore同期基盤を完成させ、次フェーズでFirestoreのオフライン永続化キャッシュや未同期バッジ表示を最適化。

---

## 2. 全体システムアーキテクチャ

Firebaseのエコシステムを活用しつつ、クライアント側は**クリーンアーキテクチャ（Clean Architecture）**を徹底して外部SDKをインフラ層に閉じ込めます。

```mermaid
graph TD
    subgraph Client["Flutter クライアント (Scuba Life)"]
        UI["UI / Presentation (Interface)"]
        UC["UseCases (Pure Dart)"]
        Dom["Domain Entities & Repositories IF (Pure Dart)"]
        Infra["Infrastructure (Firebase Adapters)"]
        
        UI --> UC
        UC --> Dom
        Infra -.->|implements| Dom
    end

    subgraph FirebaseCloud["Firebase Cloud Platform"]
        Auth["Firebase Authentication<br>(Mail/PW, Google, Apple)"]
        Firestore[("Cloud Firestore<br>(Users / Logs / Gears / Schedules)")]
        Storage["Cloud Storage<br>(Photos & Media)"]
    end

    Infra -->|SDK通信| Auth
    Infra -->|SDK通信| Firestore
    Infra -->|SDK通信| Storage
```

### クリーンアーキテクチャの責務分離（フレームワーク非依存の原則）
- **Domain 層 (Pure Dart)**:
  - `UserAccount`, `DiveLog`, `GearItem` 等のエンティティ。Firebase SDKのクラス（`User`, `DocumentSnapshot` 等）は**一切持ち込みません**。
  - リポジトリインターフェース（`AuthRepository`, `DiveLogRepository`）を定義。
- **UseCase 層 (Pure Dart)**:
  - サインアップ、サインイン、ログ保存などの業務手順をカプセル化。テスト時はリポジトリをFake/Mockに差し替えて100%単体テスト可能。
- **Infrastructure 層 (Firebase 実装)**:
  - `firebase_auth`, `cloud_firestore` のSDK依存をすべてこの層に閉じ込めます。
  - Firestoreの `DocumentSnapshot` / `Map<String, dynamic>` と Domain Entity との相互変換（DTOマッピング）を担当。
- **Interface / UI 層 (Riverpod)**:
  - `AuthController` で認証状態（未ログイン・ログイン済み・ローディング・エラー）を管理し、ログイン画面やメイン画面を制御。

---

## 3. Cloud Firestore データモデル設計

Firestoreはドキュメント指向NoSQLであるため、**ユーザー単位のサブコレクション構造**を採用します。これによりセキュリティルールが極めてシンプルかつ堅牢になり、データ漏洩をDBレベルで防止できます。

```mermaid
erDiagram
    USERS ||--o{ DIVE_LOGS : "sub-collection"
    USERS ||--o{ GEAR_ITEMS : "sub-collection"
    USERS ||--o{ DIVE_SCHEDULES : "sub-collection"
    USERS ||--o{ FAVORITE_SPOTS : "sub-collection"
    DIVE_SPOTS ||--o{ FAVORITE_SPOTS : "references"

    USERS {
        string uid PK "Firebase Auth UID"
        string email "メールアドレス"
        string displayName "表示名"
        string photoUrl "プロフィール画像URL"
        string certificationOrg "Cカード指導団体 (PADI等)"
        string certificationLevel "認定ランク (OW, AOW等)"
        timestamp createdAt "作成日時"
        timestamp updatedAt "更新日時"
    }

    DIVE_LOGS {
        string logId PK "自動採番UUID"
        int logNumber "潜水本数 (通算)"
        timestamp diveDate "潜水日"
        string diveSpotId "スポットID"
        string diveSpotName "スポット名"
        float maxDepth "最大水深 (m)"
        float avgDepth "平均水深 (m)"
        int durationMinutes "潜水時間 (分)"
        array gearIds "使用機材ID配列"
        array marineLife "遭遇生物配列"
        string notes "メモ"
    }

    GEAR_ITEMS {
        string gearId PK "自動採番UUID"
        string name "機材名"
        string category "レギュレーター/BCD等"
        int totalDives "OH後潜水本数"
        timestamp lastOverhaulDate "最終OH日"
        int intervalDives "推奨潜水本数"
        int intervalMonths "推奨月数"
    }

    DIVE_SCHEDULES {
        string scheduleId PK "自動採番UUID"
        string title "トリップ名"
        timestamp startDate "開始日"
        timestamp endDate "終了日"
        string diveSpotId "スポットID"
        map gearCheckList "持参機材・チェック状況"
    }

    DIVE_SPOTS {
        string spotId PK "マスタコレクション"
        string name "スポット名"
        string area "地域 (伊豆、沖縄等)"
        float latitude "緯度"
        float longitude "経度"
        boolean isPreset "初期マスタフラグ"
    }
```

### Firestore セキュリティルール（Security Rules）基本方針
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザー固有データ（サブコレクション）: 本人のみ読み書き可能
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // ダイビングスポット共通マスタ: 認証済みユーザーは読み取り可能、書き込みは要管理者権限または特定条件
    match /dive_spots/{spotId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null; // ユーザー追加スポットの許容
    }
  }
}
```

---

## 4. クライアント側（Flutter）ディレクトリ構成

Clean Architecture + Feature-First に従い、新規機能モジュール `lib/features/auth/` を追加します。

```text
lib/
├── app/
│   ├── app.dart                            # Auth状態に応じて Home / SignInPage を切り替え
│   └── routes.dart                         # 画面遷移ルーティング
├── features/
│   ├── auth/                               # ★新規追加: 認証機能
│   │   ├── domain/
│   │   │   ├── entities/user_account.dart  # ユーザー情報 (Pure Dart)
│   │   │   ├── errors/auth_failure.dart    # 認証エラー定義 (PW不一致、ネットワークエラー等)
│   │   │   └── repositories/auth_repository.dart # 抽象リポジトリIF
│   │   ├── usecase/
│   │   │   ├── sign_in_with_email.dart     # メールログイン
│   │   │   ├── sign_up_with_email.dart     # メール新規登録
│   │   │   ├── sign_in_with_google.dart    # Googleサインイン
│   │   │   ├── sign_out.dart               # サインアウト
│   │   │   ├── send_password_reset.dart    # パスワードリセット
│   │   │   └── watch_auth_state.dart       # ログイン状態のStream監視
│   │   ├── interface/
│   │   │   ├── controllers/auth_controller.dart # Riverpod StateNotifier
│   │   │   └── views/
│   │   │       ├── sign_in_page.dart       # サインイン画面
│   │   │       ├── sign_up_page.dart       # 新規登録画面
│   │   │       ├── profile_page.dart       # アカウント設定・ログアウト
│   │   │       └── password_reset_page.dart# パスワード再設定画面
│   │   └── infrastructure/
│   │       ├── datasources/firebase_auth_datasource.dart # FirebaseAuth, GoogleSignInラッパー
│   │       └── repositories/firebase_auth_repository.dart# リポジトリ実装
│   │
│   ├── logbook/
│   │   └── infrastructure/
│   │       ├── repositories/in_memory_dive_log_repository.dart # テスト用保持
│   │       └── repositories/firestore_dive_log_repository.dart # ★新規: Firestore同期実装
│   │
│   ├── my_gear/
│   │   └── infrastructure/
│   │       └── repositories/firestore_gear_repository.dart     # ★新規: Firestore同期実装
│   │
│   ├── schedule/
│   │   └── infrastructure/
│   │       └── repositories/firestore_schedule_repository.dart # ★新規: Firestore同期実装
│   │
│   └── dive_spot/
│       └── infrastructure/
│           └── repositories/firestore_dive_spot_repository.dart# ★新規: Firestore同期実装
```

---

## 5. プロジェクト推進マイルストーン & ロードマップ

段階的なリリースと品質担保のため、5つのマイルストーンで進行します。

```mermaid
gantt
    title Scuba Life - サーバー化 & アカウント機能 ロードマップ
    dateFormat  YYYY-MM-DD
    section M1: 基盤準備
    Firebaseプロジェクト設定 & FlutterFire連携 :m1_1, 2026-10-10, 3d
    Firestore設計 & セキュリティルール策定      :m1_2, after m1_1, 3d
    section M2: 認証機能
    features/auth クリーンアーキテクチャ実装    :m2_1, after m1_2, 5d
    メール/PW & GoogleサインインUI構築         :m2_2, after m2_1, 4d
    認証フローUT & Riverpodコントローラーテスト  :m2_3, after m2_2, 3d
    section M3: データ同期
    各機能の FirestoreRepository 実装         :m3_1, after m2_3, 7d
    マルチデバイス同期・CRUD疎通検証           :m3_2, after m3_1, 4d
    section M4: 拡張 & オフライン
    Appleでサインイン追加実装                 :m4_1, after m3_2, 4d
    Firestoreオフライン永続化キャッシュ最適化    :m4_2, after m4_1, 4d
    section M5: 本番準備
    退会・アカウント削除 (ストア必須要件)       :m5_1, after m4_2, 3d
    README更新 & リリース確認                 :m5_2, after m5_1, 3d
```

### マイルストーン詳細一覧 & 進捗状況

| マイルストーン | 進捗 | 主なタスク | 完了基準（Definition of Done） |
| :--- | :---: | :--- | :--- |
| **M1: Firebase環境構築 & セキュリティルール策定** | **【完了 ✅】** | - Firebaseコンソールでのプロジェクト作成 (`scuba-life-a29fb`)<br>- `flutterfire configure` によるAndroid/iOS接続設定<br>- Firestore コレクション設計 & セキュリティルール作成・デプロイ<br>- Android デバッグ SHA-1 / SHA-256 フィンガープリント登録<br>- 機密ファイル（`firebase_options.dart` 等）の `.gitignore` 除外 & `.example` テンプレート整備 | Firebase CLIおよび実環境で接続が通り、セキュリティルールが本番デプロイ済みであること。 |
| **M2: 認証機能の実装（メール/PW + Google SSO）** | **【完了 ✅】** | - `features/auth` Clean Architecture 完全準拠実装<br>- メールアドレス登録・ログイン・ログアウト<br>- Googleサインイン / Google SSO 新規登録<br>- パスワードマネージャー（Bitwarden等）Autofill対応<br>- ログイン状態によるアプリ起点ルーティング制御<br>- Riverpod Notifier & UseCase 単体テスト作成（全155件パス） | 新規ユーザー登録、ログイン、Google SSO、ログアウトが実機で動作確認済みであること。 |
| **M2.5: ユーザープロファイル連携 & Cカード情報保存** | **【完了 ✅】** | - Firestore `users/{userId}` 初期ドキュメントの自動生成 (upsert)<br>- Cカード情報（指導団体: PADI等、ランク: OW/AOW等、カード番号、経験本数オフセット）の編集・保存<br>- プロフィール画面（`ProfilePage`）拡張および編集ダイアログ実装<br>- UseCase・UI・小型画面（360px）レスポンシブテスト作成（全162件パス） | プロフィール編集内容が Firestore に永続化され、アプリ再起動後も正しく復元されること。 |
| **M3: 各種データのクラウド永続化（Firestore同期）** | **【完了 ✅】** | - `FirestoreDiveLogRepository` (`/users/{userId}/dive_logs`)<br>- `FirestoreGearRepository` (`/users/{userId}/gear_items`)<br>- `FirestoreScheduleRepository` (`/users/{userId}/dive_schedules`)<br>- `FirestoreDiveSpotRepository` (`/dive_spots`, `favorite_spots`)<br>- リポジトリProviderのFirestore版動的切り替え<br>- `fake_cloud_firestore` によるリポジトリ単体テスト（全177件パス） | ログ登録や機材変更を行うと即座にFirestoreに反映され、別端末・再起動後もデータが完全に復元されること。 |
| **M4: Appleサインイン追加 & オフライン最適化** | **【次回着手】** | - Apple Sign-In の実装（iOS審査必須対応）<br>- Firestore のローカルキャッシュ永続化検証<br>- 機内モード（圏外）での読み書き動作確認 | iOSでAppleサインインが動作し、機内モード時でもアプリがクラッシュせず直前のログを閲覧・追記できること。 |
| **M5: アカウント削除・規約対応・本番準備** | **【予定】** | - アカウント削除機能（Apple/Googleガイドライン準拠）<br>- パスワード再設定メール送信機能の実機検証<br>- 利用規約・プライバシーポリシー画面<br>- README の機能一覧・設計セクション更新 | アカウント削除を含む全規約対応が完了し、READMEが最新状態に同期され、テストがオールグリーンであること。 |

---

## 6. 現在の実装状況詳細（実績）

2026年10月時点の実装実績は以下の通りです。Clean Architecture および強固なセキュリティ設計に基づき、基盤からUIまで堅牢に実装されています。

### 1. インフラ & 環境設定（M1実績）
- **Firebase プロジェクト**: `scuba-life-a29fb`
- **Android 設定**:
  - パッケージ名: `com.life_124c41.scuba_life` (App ID: `1:37794312799:android:c7583980414fa79d3c61ea`)
  - デバッグ証明書 SHA-1 (`6F:A9:83:24:6C:82:27:98:CD:A4:40:EF:93:0B:9C:73:65:C9:46:4D`) および SHA-256 を Firebase CLI 経由で登録完了。
- **iOS 設定**:
  - Bundle Identifier: Appleの命名規則（アンダースコア禁止）に準拠し `com.life-124c41.scuba-life` (App ID: `1:37794312799:ios:b2ee25516922467f3c61ea`) として登録。
  - OAuth クライアントIDおよび反転URLスキームを `Info.plist` に設定完了。
- **機密情報の保護 & セキュリティポリシー**:
  - リポジトリに機密・環境固有ファイル（`firebase.json`, `.firebaserc`, `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`）がコミットされないよう `.gitignore` を設定。
  - 公開・CIビルド用の安全なテンプレートファイル（`.example`）を配備。
  - `lib/main.dart` での Firebase 初期化時、設定ファイルが存在しない環境でも安全にフォールバック起動する設計を導入。
- **Cloud Firestore セキュリティルール**:
  - `/users/{userId}` ドキュメントおよびその配下のサブコレクション（`match /users/{userId} { match /{document=**} }`）へのアクセスを本人の認証トークン（`request.auth.uid == userId`）に限定するセキュリティルール（`firestore.rules`）を策定。

### 2. 認証機能基盤（M2実績）
Clean Architecture に基づき、ビジネスロジックをフレームワークから完全に分離して実装：

- **Domain 層 (Pure Dart)**:
  - `UserAccount`: 認証ユーザーの基本エンティティ（`uid`, `email`, `displayName`, `photoUrl`）。
  - `AuthFailure`: 業務エラーの網羅的モデリング（パスワード強度不足、メール重複、不正メール形式、ユーザー不在、パスワード不一致、Googleポップアップキャンセル、ネットワークエラー、要再ログイン、不明エラー）。
  - `AuthRepository`: 認証操作の抽象インターフェース。
- **UseCase 層 (Pure Dart)**:
  - `SignInWithEmail`: メール/パスワードによるログイン。
  - `SignUpWithEmail`: メール/パスワードによる新規アカウント作成。
  - `SignInWithGoogle`: Googleアカウントによるサインイン/新規登録。
  - `SignOut`: サインアウト。
  - `SendPasswordReset`: パスワード再設定メール送信。
  - `WatchAuthState`: 認証状態の Stream 監視。
  - `GetCurrentUser`: 現在のログインユーザー取得。
- **Infrastructure 層**:
  - `FirebaseAuthDataSource`: `firebase_auth` SDK および `google_sign_in` SDK をラップし、テスタビリティを担保。
  - `FirebaseAuthRepository`: Firebaseの例外（`FirebaseAuthException`）をドメイン例外（`AuthFailure`）へ安全に変換・マッピング。
  - `InMemoryAuthRepository`: オフライン環境やユニットテスト用のスタブ実装。
- **Interface / UI 層 (Riverpod)**:
  - `AuthStateNotifier` (`authStateProvider`): 認証状態（`AsyncValue<UserAccount?>`）のリアクティブ管理。
  - `AuthActionController` (`authActionControllerProvider`): 認証アクション実行中のローディング・エラー状態の管理。
  - `SignInPage`: サインイン画面（メールログイン、Google SSO、パスワード再設定導線）。
  - `SignUpPage`: 新規登録画面（メール会員登録、Google SSO 新規登録ボタン）。
  - `PasswordResetPage`: パスワード再設定画面。
  - `ProfilePage`: ユーザー情報表示およびログアウトボタン。
- **UX & レスポンシブ最適化**:
  - **パスワードマネージャー連携**: `AutofillGroup`、`autofillHints`（`email`, `password`, `newPassword`）、および完了時の `TextInput.finishAutofillContext()` を実装し、Bitwarden や 1Password、Googleパスワードマネージャー等の自動入力・保存に対応。
  - **レスポンシブ設計**: `Wrap` や `SingleChildScrollView` を活用し、幅 350〜370px の端末（2376×968端末等）でもオーバーフローを起こさない堅牢なレイアウトを実装。
- **アプリ全体との統合**:
  - `lib/app/app.dart` で `authStateProvider` の状態に応じて初期画面を自動切り替え（未ログイン時: `SignInPage`、ログイン時: `DiveLogPage`）。
  - ログブック画面（`DiveLogPage`）の AppBar にプロフィール画面（`ProfilePage`）への遷移アイコンを配備。

### 3. ユーザープロファイル連携 & Cカード情報管理（M2.5実績）
- **ドメインモデル & スキーマ策定**:
  - `UserAccount` エンティティに `certificationOrg`（指導団体: PADI, NAUI, SSI, BSAC, CMAS 等）、`certificationLevel`（認定ランク: OW, AOW, RED, MSD, DM, INST 等）、`cCardNumber`（Cカード番号）、`totalDivesOffset`（開始前の経験潜水本数）を追加。
  - 指導団体・認定ランクのプリセット定数クラス `DiverCertification` を作成。
- **クリーンアーキテクチャ階層構造**:
  - `domain`: `UserRepository`（Pure Dart 抽象インターフェース）
  - `usecase`: `GetUserProfile`, `WatchUserProfile`, `UpdateUserProfile`, `SyncInitialProfile`（Pure Dart）
  - `infrastructure`: `FirestoreUserRepository`（`/users/{userId}` への upsert, serverTimestamp）、`InMemoryUserRepository`（テスト・オフライン用）
  - `interface`: `currentUserProfileProvider`（ログインユーザー検知時の自動初期同期 & リアルタイム監視）、`userProfileControllerProvider`（プロファイル更新 Notifier）
- **UI & レスポンシブ拡張**:
  - `ProfilePage` に「Cカード・ダイバー情報」カードを追加（指導団体バッジ、認定ランク、カード番号、経験本数）。
  - 未登録時の親切なガイダンス表示および登録導線ボタン。
  - `EditDiverProfileDialog`（モーダル編集ダイアログ）の実装。Dropdown の `isExpanded: true` や `ConstrainedBox` により幅 360px 小型端末でも堅牢に動作。
- **テスト品質**:
  - 全 **162 件** のユニットテスト・ウィジェットテストがオールグリーン（`flutter test` パス）。
  - 静的解析エラー 0 件（`flutter analyze` 0 issues）。

### 4. 各種データのクラウド同期・Firestore永続化（M3実績）
Clean Architecture のレイヤード設計を厳格に維持し、UI層やUseCase層を変更することなく、インフラ層にFirestore実装を追加・DI動的切り替えを実現：

- **`FirestoreDiveLogRepository` (`lib/features/logbook/infrastructure/repositories/firestore_dive_log_repository.dart`)**:
  - コレクションパス: `/users/{userId}/dive_logs/{logId}`
  - 潜水ログのCRUD操作、`DateTime` と `Timestamp` の相互マッピング、日付降順ソート。
  - プロファイルの `totalDivesOffset` と連動した通算ダイブ本数カウント。
- **`FirestoreGearRepository` (`lib/features/my_gear/infrastructure/repositories/firestore_gear_repository.dart`)**:
  - コレクションパス: `/users/{userId}/gear_items/{gearId}`
  - マイ機材の登録・更新・削除・一覧取得。
  - `GearCategory` enum と文字列の相互マッピング、オーバーホール（OH）日・本数・周期設定のクラウド永続化。
- **`FirestoreScheduleRepository` (`lib/features/schedule/infrastructure/repositories/firestore_schedule_repository.dart`)**:
  - コレクションパス: `/users/{userId}/dive_schedules/{scheduleId}`
  - トリップ予定の保存・更新・削除、月別・期間抽出。
  - 持ち物・機材チェックリスト（Map構造）のクラウド同期。
- **`FirestoreDiveSpotRepository` (`lib/features/dive_spot/infrastructure/repositories/firestore_dive_spot_repository.dart`)**:
  - 共通マスタ: `/dive_spots/{spotId}`、お気に入り: `/users/{userId}/favorite_spots/{spotId}`
  - アプリ初回起動時に日本の代表的9スポットを共通マスタへ自動シード。
  - ユーザー追加スポットの保存、お気に入りトグル（★）のユーザー別保持。
- **DI (Riverpod) 動的切り替え設計**:
  - 各コントローラーの Repository Provider (`diveLogRepositoryProvider`, `gearRepositoryProvider`, `diveScheduleRepositoryProvider`, `diveSpotRepositoryProvider`) において、`ref.watch(authStateProvider)` を参照。
  - ログイン中は各 `Firestore...Repository` を、未ログイン・初期起動時やユニットテスト環境では既存の `InMemory...Repository` を自動返却するシームレスなDI配線を完了。
- **テスト品質**:
  - `fake_cloud_firestore: ^4.3.0` を導入し、ネットワーク通信不要な高速Firestoreリポジトリ単体テスト（全15テスト）を作成。
  - 全体テスト **177 件** がオールグリーン（`flutter test` パス）。
  - 静的解析エラー 0 件（`flutter analyze` 0 issues）。

---

## 7. 今後の対応予定（ネクストアクション詳細）

今後の実装は以下のステップで順次進行します。

```mermaid
flowchart TD
    M1_M2["【完了 ✅】<br>M1: 基盤構築<br>M2: メール & Google 認証"] --> M2_5["【完了 ✅】<br>M2.5: ユーザープロファイル連携<br>& Cカード情報保存"]
    M2_5 --> M3["【完了 ✅】<br>M3: 各種データの Firestore クラウド同期<br>(ログ / 機材 / 予定 / スポット)"]
    M3 --> M4["【次回着手: M4】<br>Apple サインイン追加<br>& オフラインキャッシュ最適化"]
    M4 --> M5["【M5】<br>アカウント削除機能<br>& ストア公開準備"]
```

### ステップ 1: 【次回着手】Appleサインイン追加 & オフライン最適化（M4）

1. **Apple でサインイン（Sign in with Apple）の実装**:
   - iOS App Store 審査ガイドライン 4.8（サードパーティログインを提供するアプリは Apple サインインの提供が必須）に対応。
   - `sign_in_with_apple` パッケージ連携、Firebase Auth クレデンシャル連携。
2. **オフライン永続化キャッシュ検証**:
   - 電波が圏外になる洋上・ボート上でのログ入力・機材チェックを可能にするため、Firestore のオフライン永続化（Local Cache）の動作検証を実施。
   - 機内モードでのログ書き込み $\rightarrow$ オンライン復帰時の自動アップロード同期の確認。

---

### ステップ 2: ストア公開必須要件 & アカウント削除（M5）

1. **アカウント削除（退会）機能の実装**:
   - Apple / Google 審査ガイドライン準拠の必須要件。
   - `ProfilePage` からアカウント削除ダイアログを起動。
   - Firebase Authentication ユーザー削除 ＋ Firestore 内の `/users/{userId}` および全サブコレクションの一括削除処理を実装。
2. **パスワードリセットメールの実機検証**:
   - パスワード再設定画面（`PasswordResetPage`）からのメール送信および再設定リンクの疎通確認。
3. **法的要件 & リリースドキュメント**:
   - 利用規約・プライバシーポリシー画面への導線追加。
   - README の完全同期。

---

## 8. 実装タスク・進捗チェックリスト

開発の進捗に合わせて本チェックリストを更新します。

- [x] **M1: Firebase環境構築**
  - [x] Firebase プロジェクト作成 (`scuba-life-a29fb`)
  - [x] Android / iOS 設定 & 証明書登録
  - [x] 機密ファイルの Git 管理外設定 & テンプレート配備
  - [x] Firestore セキュリティルールの本番デプロイ
- [x] **M2: 認証機能基盤**
  - [x] `features/auth` Clean Architecture 設計・実装
  - [x] メール/パスワード認証 (サインアップ / ログイン / ログアウト)
  - [x] Google SSO 認証 (サインアップ / ログイン)
  - [x] パスワードマネージャー (Bitwarden等) 自動入力連携
  - [x] アプリ起点ルーティング連携 & プロフィール画面導線
  - [x] 全テストパス (155/155 tests passed) & 静的解析エラー0件
- [x] **M2.5: ユーザープロファイル & Cカード情報保存**
  - [x] Firestore `/users/{userId}` スキーマ策定
  - [x] `UserAccount` ドメインモデル拡張（指導団体・ランク・カード番号・本数オフセット）
  - [x] `DiverCertification` 定数クラス作成
  - [x] `UserRepository` 抽象インターフェース & UseCase 作成
  - [x] `FirestoreUserRepository` & `InMemoryUserRepository` 実装
  - [x] サインアップ・ログイン時の初期ドキュメント自動生成 (upsert)
  - [x] `ProfilePage` に Cカード情報表示 & 編集ダイアログ（`EditDiverProfileDialog`）追加
  - [x] 小型画面（幅360px）レスポンシブ対応
  - [x] プロファイル機能の単体 & ウィジェットテスト作成（全162件テスト合格）
- [x] **M3: 各種データの Firestore 同期**
  - [x] `FirestoreDiveLogRepository` 実装 & DI 切り替え
  - [x] `FirestoreGearRepository` 実装 & DI 切り替え
  - [x] `FirestoreScheduleRepository` 実装 & DI 切り替え
  - [x] `FirestoreDiveSpotRepository` 実装 & DI 切り替え
  - [x] 各リポジトリの単体テスト作成 (`fake_cloud_firestore` で全177件テスト合格)
- [ ] **M4: Appleサインイン & オフライン検証**
  - [ ] `sign_in_with_apple` 実装
  - [ ] 圏外（オフライン）キャッシュの動作テスト
- [ ] **M5: アカウント削除 & 本番準備**
  - [ ] アカウント完全削除（退会）機能
  - [ ] パスワードリセットメール疎通確認
  - [ ] README更新 & ストア申請準備



