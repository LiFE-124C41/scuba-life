# Scuba Life (スクーバダイバー向け総合支援アプリ)

スクーバダイバーのためのオールインワン・モバイルアプリケーションです。
ダイビングログの記録・分析、ツアーやトリップのスケジュール管理、海洋気象・海況情報の確認、器材セールのチェックまでを一括してサポートします。

---

## 🌊 主要機能

### 1. ログブック（Logbook）
- **詳細ダイビング記録の登録・管理（全画面フォーム）**:
  - ダイアログから専用のフルスクリーン入力フォーム（`DiveLogFormPage`）に移行。
  - **記録項目（24項目以上）**:
    - **基本・評価**: 5段階星評価、日付、ポイント名、主催センター/ショップ名、ダイビング目的（ファン/講習/体験等）
    - **潜水・エントリー**: 潜水開始・終了時刻、潜水時間（分）、エントリー方式（ボート/ビーチ）、水域（海洋/湖等）、水質（海水/淡水）
    - **深度・気圧（実績＆計画）**: 最大水深/平均水深、開始/終了タンク残圧、計画水深、計画時間、計画残圧
    - **環境・海況・潮汐**: 天気、気温、最高/最低水温、透明度、潮流タイプ（大潮/中潮等）、水中/水面の流れ、潮汐時刻（満潮/干潮 各2回）
    - **機材・シリンダー**: シリンダー材質（スチール/アルミ）・容量（L）、ウェイト量（kg）、使用機材
    - **バディ・生物・メモ**: バディ名（複数タグ追加）、出会った生物（タグ追加）、自由記入メモ
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
│   │   │       ├── dive_log_page.dart      # ログ一覧（ConsumerWidget）
│   │   │       └── dive_log_form_page.dart # ログ作成・編集フォーム
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