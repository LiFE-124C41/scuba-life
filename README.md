# Scuba Life (スクーバダイバー向け総合支援アプリ)

スクーバダイバーのためのオールインワン・モバイルアプリケーションです。
ダイビングログの記録・分析、ツアーやトリップのスケジュール管理、海洋気象・海況情報の確認、器材セールのチェックまでを一括してサポートします。

---

## 🌊 主要機能

### 1. ログブック（Logbook）
- **潜水記録の登録・管理**: エントリー/エグジット時刻、最大水深、平均水深、開始/終了タンク残圧、ダイブポイント、メモの記録。
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

本プロジェクトでは**クリーンアーキテクチャ（Clean Architecture）**と**Feature-First（機能単位分割）**を組み合わせた構成を採用しています。

### 設計方針
1. **依存関係の単方向性（内側への依存）**:
   - `domain`（最内層: Pure Dart） $\leftarrow$ `usecase`（Pure Dart） $\leftarrow$ `interface` (UI/State) / `infrastructure` (外部DB/API)
2. **フレームワーク非依存のビジネスロジック**:
   - ダイビング物理計算（SACレート等）やバリデーションは、Flutter SDKやUIパッケージに一切依存しないPure Dartとしてドメイン層にカプセル化。
3. **拡張性と保守性**:
   - データ層はリポジトリインターフェース（抽象）を挟むことで、インメモリ $\rightarrow$ SQLite (sqflite / Drift) / Isar / Firebase への差し替えが容易。

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
│   │   ├── interface/                      # インターフェース層（UI、Controller）
│   │   │   └── views/dive_log_page.dart
│   │   └── infrastructure/                 # インフラ層（データ永続化実装、外部連携）
│   │       └── repositories/in_memory_dive_log_repository.dart
│   ├── schedule/                           # ② スケジュール管理機能
│   │   ├── domain/
│   │   ├── usecase/
│   │   ├── interface/
│   │   └── infrastructure/
│   ├── weather/                            # ③ 海況・気象予報機能
│   │   ├── domain/
│   │   ├── usecase/
│   │   ├── interface/
│   │   └── infrastructure/
│   └── gear_sale/                          # ④ 機材セール情報機能
│       ├── domain/
│       ├── usecase/
│       ├── interface/
│       └── infrastructure/
└── main.dart                               # エントリーポイント
```

---

## 🧪 テスト方針

ロジック層（Domain / UseCase）を対象としたユニットテストを重視しています。

- **Domain層のテスト**: SAC計算ロジック、潜水時間の計算、異常系バリデーション（`ArgumentError`）の検証。
- **UseCase層のテスト**: リポジトリのインターフェースをモック（Mock/Fake）化し、外部依存を切り離した上でビジネスフローを **Arrange / Act / Assert** 形式で検証。

### テスト実行方法
```bash
flutter test
```