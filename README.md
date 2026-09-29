# Scuba Life (スクーバダイバー向け総合支援アプリ)

スクーバダイバーのためのオールインワン・モバイルアプリケーションです。
ダイビングログの記録・分析、ツアーやトリップのスケジュール管理、海洋気象・海況情報の確認、マイ機材の管理とオーバーホール目安の把握までを一括してサポートします。

---

## 🌊 主要機能

### 1. ログブック（Logbook）
- **コンパクト一覧表示**:
  - 一覧画面（`DiveLogPage`）では情報量を厳選し、「日付・ポイント名・5段階評価・最大深度」を2行構成でシンプルに一覧表示。
- **全情報閲覧・詳細画面（`DiveLogDetailPage`）**:
  - 一覧タップ時に全項目（ダイブプロファイル、SACレート、水深・残圧、海況・潮汐、機材、バディ、生物、メモ等）を網羅した詳細画面に遷移。
  - 詳細画面内の編集ボタンからスムーズに編集フォームへ移行可能。
  - **ログ削除機能**: AppBarの削除ボタンから確認ダイアログを経て安全にログを削除可能。ログに紐付いていたマイ機材の潜水本数も自動で `-1` 減算（巻き戻し）され、機材管理の整合性を保持。
- **詳細ダイビング記録・編集フォーム（`DiveLogFormPage`）**:
  - 24項目以上の詳細項目（5段階評価、主催センター、海況、潮流・潮汐、シリンダー、計画値など）を入力・編集可能なフルスクリーンフォーム。
- **SACレート自動計算（ドメインロジック）**:
  - 水面空気消費率（Surface Air Consumption Rate: $L/\text{min}$）を自動算出。
  - 計算式: $\text{SAC} = \frac{\Delta P \times V_{\text{tank}}}{T_{\text{bottom}} \times (1 + D_{\text{avg}} / 10)}$
  - 自身のエア消費効率を可視化し、安全管理やスキルアップ指標として活用可能。
- **予定管理との双方向連携**:
  - ログ詳細画面（`DiveLogDetailPage`）に関連予定のリンクチップを表示し、ワンタップで予定詳細を展開。
  - ログ作成フォーム（`DiveLogFormPage`）で登録済み予定を選択すると、日程・ポイント・ショップ名を自動補完。
- **機材管理との連携 & ダイブ本数自動インクリメント・デクリメント**:
  - ログ作成・編集フォーム（`DiveLogFormPage`）で登録済みマイ機材をチップからワンタップで複数選択可能。
  - ログ保存時に、新たに選択された機材のオーバーホール後潜水本数が自動的に `+1` インクリメントされ、OH目安（残り本数や状態ステータス）がリアルタイムに更新。
  - ログ編集で機材の選択を解除して保存した場合、誤加算防止のため当該機材のダイブ本数を自動で `-1` デクリメント（巻き戻し）処理。
  - ログ詳細画面（`DiveLogDetailPage`）に使用したマイ機材をカテゴリバッジ付きチップで表示。
- **インストラクター向けダイバー統計・スキルシート表示（`DiveLogStatisticsPage`, `DiveLogSummaryCard`）**:
  - 初めて訪れるダイビングサービスやインストラクターに自身の経験レベル・ブランク状況をスムーズに提示できる専用統計機能。
  - **ログ一覧サマリーカード**: 画面最上部に「総本数・最大水深・累計潜水時間・ブランク日数ステータス」を常時表示し、タップで詳細統計へシームレスに遷移。
  - **スキル & 安全プロファイル**: 最大経験水深、平均最大水深、平均潜水時間、平均SACレート（水面空気消費率/エア燃費の目安）を集約。
  - **ダイブスタイル & 環境適性**: ボート vs ビーチのエントリー比率（ビジュアル進捗バー）、潮流・ドリフトダイビングの経験度（強・中・弱・なしの経験本数）を一覧化。
  - **ブランク状態の自動判定**: 最終潜水日からの経過日数を基に「アクティブ（好調）」「標準」「軽度ブランク」「ブランクあり（要リフレッシュ）」をバッジ表示。
  - **直近の潜水実績**: 最新3件のログダイジェスト（日付・ポイント・最大深度・時間・海況）を表示し、直近のコンディションを即座に共有可能。
- **ポイント地図表示 & マップビュー切替**:
  - ログ一覧画面（`DiveLogPage`）上部のアイコンから「リスト表示」と「マップ表示」をワンタップで切り替え可能。
  - マップ表示では全ログのダイビングポイントが地図（OpenStreetMap）上にピン表示され、ピンタップで概要カードおよび詳細画面へ遷移可能。
  - ログ詳細画面（`DiveLogDetailPage`）にダイビングポイントのミニマップを表示。

### 2. ダイビングスケジュール管理（Schedule）
- **月間カレンダー表示（`CalendarView`）**:
  - 月ごとのカレンダーグリッドで予定を直感的に俯瞰。予定のある日にはドットインジケーターを表示。
  - 前月・次月への移動や「今日」へのワンタップジャンプに対応。
- **日付選択と予定一覧連携**:
  - カレンダー上の日付を選択すると、その日に予定されているダイビングトリップがカード形式で即座に表示。
- **予定詳細モーダル（`ScheduleDetailSheet`）**:
  - 予定カードのタップでボトムシートが展開し、目的地・ショップ・予定本数・準備メモ・削除などの詳細を網羅して確認可能。
  - 予定のダイビングポイント位置を示すミニマップを表示。
  - **予定日の海況・海洋気象予報カード（Open-Meteo連携）**:
    - **外部API自動連携**: 登録されたダイビングポイントの緯度・経度に基づき、**Open-Meteo Marine & Forecast API** から予定日のリアルタイム海況・気象予報を自動取得。
    - **潜水コンディション判定**: 波高・風速から「潜水良好」「注意」「クローズ可能性高」を自動判定。
    - **詳細海洋気象指標**: 天気・気温、海面水温、最大波高、風向・風速、推定透明度（透視度）、潮回りを一覧表示。
    - 予報期間（約7日前〜当日）外の場合や未登録時の親切なガイダンス表示、ワンタップ再取得に対応。
- **カレンダー / マップ表示切替**:
  - 予定一覧画面で「カレンダー表示」と「マップ表示」を切り替え、旅行やツアーの目的地を地図上で一覧確認可能。
- **ログブックとの相互連携 & ログ記録導線**:
  - 予定に紐付く記録済みログ一覧（本数・最大深度・潜水時間・評価）をシート内で直接確認可能。
  - 「この予定からログを記録する」ボタンから、予定情報（日程・ポイント・ショップ名・ID）を引き継いで新規ログフォームを起動可能。
- **予定追加ダイアログ（`ScheduleFormDialog`）**:
  - カレンダー上で選択された日付を初期値として、タイトルやポイント、ショップ、本数を簡単に追加登録可能。ダイビングポイントマスタからの選択にも対応。

### 3. ダイビングポイント管理 & 共通マップ（Dive Spot）
- **ダイビングポイントマスタ（`DiveSpot`）**:
  - 日本の代表的スポット（大瀬崎、伊豆海洋公園、雲見、串本、白浜、慶良間諸島、宮古島、石垣島など）をプリセット初期登録。
  - ユーザーによる新しいポイントの登録やお気に入りトグル（★）に対応。
- **ポイント選択・検索モーダル（`DiveSpotSelectModal`）**:
  - ログブック登録や予定登録時にワンタップで呼び出し、名称・地域での高速検索やお気に入り絞り込み、新規スポット登録が可能。
- **OpenStreetMap 共通ウィジェット（`SpotMapWidget`）**:
  - `flutter_map` + `latlong2` をベースにした API キー不要・クロスプラットフォーム対応の地図コンポーネント。単一マーカー拡大表示から複数ピン一覧表示まで対応。

### 4. マイ機材管理 & オーバーホール目安管理（My Gear）
- **マイ機材一覧とサマリーダッシュボード（`MyGearPage`, `GearSummaryCard`）**:
  - レギュレーター、BCD、ダイブコンピューター、スーツ、軽器材（マスク・スノーケル・フィン）などのマイ機材を一元管理。
  - 画面上部のサマリーカードで「要オーバーホール」「まもなく推奨時期」「状態良好」の件数を一覧集計。期限超過機材がある場合はアラートで注意喚起。
  - カテゴリー別フィルターチップ（レギュレーター、BCD、ダイブコンピューターなど）による絞り込み表示。
- **オーバーホール（OH）目安の自動判定（ドメインロジック）**:
  - **期間基準 & ダイブ本数基準のハイブリッド判定**: 最終OH日（未実施時は購入日）と推奨周期（例: 12ヶ月）、およびOH後潜水本数（例: 100本）を基に次回目安日・残り日数を自動計算。
  - **4段階ステータス**: 「要オーバーホール（期限または本数超過）」「まもなく推奨時期（30日以内または残り10本以内）」「状態良好」「OH対象外（フィン・スーツ等）」をバッジ表示。
- **ログブック連動によるダイブ本数自動インクリメント & デクリメント**:
  - ログブック作成時に使用機材として選択されると、保存時にオーバーホール後ダイブ本数が自動で `+1` カウントアップ。手動カウントの手間なく、正確な機材稼働実績を管理。
  - 既存ログの編集で機材の選択を解除した場合は、自動で `-1` 減算（下限0本で安全保護）され、実態に即した正しい本数が維持されます。
- **ワンタップでのオーバーホール完了記録**:
  - 詳細画面（`GearDetailPage`）から「OH完了を記録」を実行することで、実施日を記録しダイブ本数を0にリセット、メモに作業履歴を自動追記。
- **機材登録・編集フォーム（`GearFormPage`）**:
  - カテゴリー選択、ブランド、モデル、シリアル番号、購入日、最終OH日、OH後ダイブ本数、推奨周期（月数・本数）、メンテナンスメモを詳細に登録可能。

---

## 🏛️ アーキテクチャ設計

本プロジェクトでは**クリーンアーキテクチャ（Clean Architecture）**と**Feature-First（機能単位分割）**、および状態管理・DI基盤として**Flutter Riverpod**を組み合わせた構成を採用しています。

### 設計方針
1. **依存関係の単方向性（内側への依存）**:
   - `domain`（最内層: Pure Dart） $\leftarrow$ `usecase`（Pure Dart） $\leftarrow$ `interface` (UI/Riverpod Notifier) / `infrastructure` (外部DB/API)
2. **フレームワーク非依存のビジネスロジック**:
   - ダイビング物理計算（SACレート等）やオーバーホール時期計算・ステータス判定は、Flutter SDKやRiverpodに一切依存しないPure Dartとしてドメイン層にカプセル化。
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
│   │   │   ├── entities/dive_statistics.dart # ダイバー統計・スキルシートモデル
│   │   │   └── repositories/dive_log_repository.dart
│   │   ├── usecase/                        # ユースケース層（アプリケーションロジック）
│   │   │   ├── get_dive_logs.dart
│   │   │   ├── get_dive_statistics.dart    # 統計指標集計ユースケース
│   │   │   ├── save_dive_log.dart
│   │   │   └── delete_dive_log.dart
│   │   ├── interface/                      # インターフェース層（UI、Riverpod Controller）
│   │   │   ├── controllers/dive_log_controller.dart
│   │   │   ├── controllers/dive_statistics_controller.dart # 統計Provider
│   │   │   └── views/
│   │   │       ├── dive_log_page.dart            # ログ一覧（サマリーカード付き）
│   │   │       ├── dive_log_statistics_page.dart # ダイバー統計・スキルシート画面
│   │   │       ├── dive_log_detail_page.dart     # ログ詳細
│   │   │       ├── dive_log_form_page.dart       # ログ作成・編集フォーム
│   │   │       └── widgets/
│   │   │           └── dive_log_summary_card.dart# 一覧上部サマリーカード
│   │   └── infrastructure/                 # インフラ層（データ永続化実装、外部連携）
│   │       └── repositories/in_memory_dive_log_repository.dart
│   ├── schedule/                           # ② スケジュール管理機能（カレンダーUI）
│   │   ├── domain/
│   │   │   ├── entities/dive_schedule.dart
│   │   │   └── repositories/dive_schedule_repository.dart
│   │   ├── usecase/
│   │   │   ├── get_dive_schedules.dart
│   │   │   ├── add_dive_schedule.dart
│   │   │   └── delete_dive_schedule.dart
│   │   ├── interface/                      # UI・状態管理
│   │   │   ├── controllers/schedule_controller.dart # NotifierProvider (月移動・日付選択・一覧抽出)
│   │   │   └── views/
│   │   │       ├── schedule_page.dart      # カレンダーメイン画面
│   │   │       └── widgets/
│   │   │           ├── calendar_view.dart  # 月間カレンダーグリッド
│   │   │           ├── schedule_detail_sheet.dart # 予定詳細ボトムシート
│   │   │           └── schedule_form_dialog.dart  # 予定追加ダイアログ
│   │   └── infrastructure/
│   ├── dive_spot/                          # ③ ダイビングポイント管理 & 共通マップ
│   │   ├── domain/                         # ドメイン層（エンティティ、リポジトリIF）
│   │   │   ├── entities/dive_spot.dart
│   │   │   └── repositories/dive_spot_repository.dart
│   │   ├── usecase/                        # ユースケース層
│   │   │   └── dive_spot_usecases.dart     # 一覧取得、追加、お気に入りトグル
│   │   ├── interface/                      # UI・状態管理
│   │   │   ├── controllers/dive_spot_controller.dart # NotifierProvider
│   │   │   └── views/
│   │   │       ├── dive_spot_select_modal.dart # ポイント検索・選択モーダル
│   │   │       └── widgets/spot_map_widget.dart # OpenStreetMap共通地図
│   │   └── infrastructure/                 # インフラ層
│   │       └── repositories/in_memory_dive_spot_repository.dart # 日本の代表的スポットプリセット
│   ├── weather/                            # ④ 海況・海洋気象予報（Open-Meteo連携）
│   │   ├── domain/                         # エンティティ（MarineWeather）、リポジトリIF
│   │   ├── usecase/                        # 予定日の海況取得ユースケース（GetMarineWeatherForSchedule）
│   │   ├── interface/                      # controllers（Riverpod Provider群）
│   │   └── infrastructure/                 # Open-Meteo Marine & Forecast API DataSource, リポジトリ実装
│   └── my_gear/                            # ⑤ マイ機材管理 & オーバーホール目安機能
│       ├── domain/                         # ドメイン層（GearItem, GearRepository）
│       │   ├── entities/gear_item.dart
│       │   └── repositories/gear_repository.dart
│       ├── usecase/                        # ユースケース層
│       │   ├── get_gear_items.dart
│       │   ├── save_gear_item.dart
│       │   ├── delete_gear_item.dart
│       │   └── record_overhaul.dart
│       ├── interface/                      # UI・状態管理（Riverpod Notifier）
│       │   ├── controllers/gear_controller.dart
│       │   └── views/
│       │       ├── my_gear_page.dart       # 機材一覧・サマリーカード
│       │       ├── gear_detail_page.dart   # 機材詳細・OH記録
│       │       ├── gear_form_page.dart     # 機材登録・編集フォーム
│       │       └── widgets/
│       │           ├── gear_summary_card.dart     # メンテナンス状況サマリー
│       │           └── overhaul_status_badge.dart # OHステータスバッジ
│       └── infrastructure/                 # インフラ層
│           └── repositories/in_memory_gear_repository.dart
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