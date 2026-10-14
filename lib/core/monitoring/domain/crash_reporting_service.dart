/// クラッシュ・エラー報告サービスのドメイン抽象インターフェース (Pure Dart)
abstract class CrashReportingService {
  /// エラーまたは例外の記録
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  });

  /// ユーザーIDの紐付け (認証時/サインアウト時)
  Future<void> setUserId(String userId);

  /// カスタムメタデータキーの設定
  Future<void> setCustomKey(String key, Object value);

  /// 診断用ログメッセージの記録 (パンくずリスト)
  Future<void> log(String message);

  // --- ドメイン特化ヘルパー ---

  /// オフライン・洋上ステータスの設定
  Future<void> setOfflineMode(bool isOffline);

  /// Cカード情報のメタデータ設定
  Future<void> setCertificationInfo({String? org, String? level});
}
