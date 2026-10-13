/// 分析・イベント追跡サービスのドメイン抽象インターフェース (Pure Dart)
abstract class AnalyticsService {
  /// 汎用イベント送信
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  });

  /// ユーザーID設定 (サインイン時/サインアウト時)
  Future<void> setUserId(String? userId);

  /// ユーザー属性設定 (Cカード指導団体や経験ランク等)
  Future<void> setUserProperty({
    required String name,
    required String? value,
  });

  // --- ドメイン特化イベント ---

  /// ダイビングログ作成イベント
  Future<void> logDiveLogCreated({
    required String spotName,
    required double maxDepth,
    required int durationMinutes,
    int? rating,
  });

  /// 水面空気消費率 (SACレート) 計算イベント
  Future<void> logSacCalculated({
    required double sacRate,
    required double avgDepth,
    required int durationMinutes,
  });

  /// マイ機材登録イベント
  Future<void> logGearCreated({
    required String name,
    required String category,
  });

  /// オーバーホール完了記録イベント
  Future<void> logOverhaulCompleted({
    required String gearName,
    required String category,
    required int divesReset,
  });

  /// 画面表示イベント
  Future<void> logScreenView({
    required String screenName,
  });
}
