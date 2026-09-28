# Scuba Life (スクーバダイバー向け総合支援アプリ)

スクーバダイバーのためのオールインワン・モバイルアプリケーションです。
ダイビングログの記録・分析、ツアーやトリップのスケジュール管理、海洋気象・海況情報の確認、器材セールのチェックまでを一括してサポートします。

---

## 🌊 主要機能

### 1. ログブック（Logbook）
- **コンパクト一覧表示**:
  - 一覧画面（`DiveLogPage`）では情報量を厳選し、「日付・ポイント名・5段階評価・最大深度」を2行構成でシンプルに一覧表示。
- **全情報閲覧・詳細画面（`DiveLogDetailPage`）**:
  - 一覧タップ時に全項目（ダイブプロファイル、SACレート、水深・残圧、海況・潮汐、機材、バディ、生物、メモ等）を網羅した詳細画面に遷移。
  - 詳細画面内の編集ボタンからスムーズに編集フォームへ移行可能。
- **詳細ダイビング記録・編集フォーム（`DiveLogFormPage`）**:
  - 24項目以上の詳細項目（5段階評価、主催センター、海況、潮流・潮汐、シリンダー、計画値など）を入力・編集可能なフルスクリーンフォーム。
- **SACレート自動計算（ドメインロジック）**:
  - 水面空気消費率（Surface Air Consumption Rate: $L/\text{min}$）を自動算出。
  - 計算式: $\text{SAC} = \frac{\Delta P \times V_{\text{tank}}}{T_{\text{bottom}} \times (1 + D_{\text{avg}} / 10)}$
  - 自身のエア消費効率を可視化し、安全管理やスキルアップ指標として活用可能。

### 2. ダイビングスケジュール管理（Schedule）
- **トリップ・ツアー計画**: 今後のダイビング予定、目的地、利用ショップ、予定本数を一元管理。
- **リマインダー・メモ**: 必要な器材（ドライスーツ、ドリフトマーカーなど）や集合場所の事前メモ。

### 3. 海況・海洋気象情報（Weather）
- **スポット別海洋コンディション**: 気温・水温だけでなく、ダイバーにとって死活問題となる「波高」「風向・風速」「潮回り」「予想透明度」を表示。
- **潜水コンディション判定**: 海況データに基づき、「潜水良好」「注意」「クローズ可能性大」の安全指標を自動判定。

### 4. ダイビング器材セール情報（Gear Sale）
- **お得なギア情報の一覧表示**: レギュレーター、ダイブコンピューター、BCD、ウェットスーツなどのセール情報を一覧化。
- **割引率ソート・フィルター**: 割引率（% OFF）やカテゴリーに応じた賢い器材選びを支援。

---

## 🏛️ アーキテクチャ設計

本プロジェクトでは**クリーンアーキテクチャ（Clean Architecture）**と**Feature-First（機能単位分割）**、および状態管理・DI基盤として**Flutter Riverpod**を組み合わせた構成を採用しています。

### 設計方針
1. **依存関係の単方向性（内側への依存）**:
   - `domain`（最内層: Pure Dart） $\leftarrow$ `usecase`（Pure Dart） $\leftarrow$ `interface` (UI/Riverpod Notifier) / `infrastructure` (外部DB/API)
2. **フレームワーク非依存のビジネスロジック**:
   - ダイビング物理計算（SACレート等）やバリデーションは、Flutter SDKやRiverpodに一切依存しないPure Dartとしてドメイン層にカプセル化。
   - `Riverpod` はプレゼンテーション層（`interface`）のUI状態管理および依存性注入（DI: Dependency Injection）としてのみ利用し、ドメイン・ユースケースへのフレームワーク侵入を防止。
3. **拡張性と保守性**:
   - データ層はリポジトリインターフェース（抽象）を挟むことで、インメモリ $\rightarrow$ SQLite (sqflite / Drift) / Isar / Firebase への差し替えが容易。テスト時も `ProviderContainer(overrides: [...])` で容易にモック化可能。

---

## 📁 ディレクトリ構成

```text
lib/
├── app/                                    # アプリ基盤（テーマ、共通ナビゲーション、ルーティング）
│   └── app.dart
├── core/                                   # 全機能共通の基底クラス・ユーティリティ
│   ├── error/
│   │   └── failures.dart                   # 共通エラー・例外クラス
│   └── usecase/
│       └── usecase.dart                    # ユースケース基底インターフェース
├── features/                               # 各機能モジュール（Feature-First Clean Architecture）
│   ├── logbook/                            # ① ログブック機能
│   │   ├── domain/                         # ドメイン層（エンティティ、リポジトリIF）
│   │   │   ├── entities/dive_log.dart
│   │   │   └── repositories/dive_log_repository.dart
│   │   ├── usecase/                        # ユースケース層（アプリケーションロジック）
│   │   │   ├── get_dive_logs.dart
│   │   │   └── save_dive_log.dart
│   │   ├── interface/                      # インターフェース層（UI、Riverpod Controller）
│   │   │   ├── controllers/dive_log_controller.dart  # AsyncNotifier, DI Providers
│   │   │   └── views/
│   │   │       ├── dive_log_page.dart        # ログ一覧（コンパクト2行表示）
│   │   │       ├── dive_log_detail_page.dart # ログ詳細（全情報閲覧・編集遷移）
│   │   │       └── dive_log_form_page.dart   # ログ作成・編集フォーム
│   │   └── infrastructure/                 # インフラ層（データ永続化実装、外部連携）
│   │       └── repositories/in_memory_dive_log_repository.dart
│   ├── schedule/                           # ② スケジュール管理機能
│   │   ├── domain/
│   │   ├── usecase/
│   │   ├── interface/                      # controllers, views
│   │   └── infrastructure/
│   ├── weather/                            # ③ 海況・気象予報機能
│   │   ├── domain/
│   │   ├── usecase/
│   │   ├── interface/                      # controllers, views
│   │   └── infrastructure/
│   └── gear_sale/                          # ④ 機材セール情報機能
│       ├── domain/
│       ├── usecase/
│       ├── interface/                      # controllers, views
│       └── infrastructure/
└── main.dart                               # エントリーポイント (ProviderScope)
```

---

## 🧪 テスト方針

ロジック層（Domain / UseCase）およびRiverpodコントローラーを対象としたユニットテストを重視しています。

- **Domain層のテスト**: SAC計算ロジック、潜水時間の計算、異常系バリデーション（`ArgumentError`）の検証。
- **UseCase層のテスト**: リポジトリのインターフェースをモック（Mock/Fake）化し、外部依存を切り離した上でビジネスフローを **Arrange / Act / Assert** 形式で検証。
- **Riverpod Controllerのテスト**: `ProviderContainer` と `overrideWithValue` を活用し、UIを起動することなくNotifierの状態遷移（ローディング・追加・エラーハンドリング）を検証。

### テスト実行方法
```bash
flutter test
```